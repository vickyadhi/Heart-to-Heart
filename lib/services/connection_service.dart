import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:home_widget/home_widget.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:http/http.dart' as http;
import '../models/love_event.dart';
import 'auth_service.dart';

class ConnectionService extends ChangeNotifier {
  final AuthService _authService;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // FCM token cache — reuse OAuth2 token for 55 min (valid 60 min)
  String? _cachedAccessToken;
  DateTime? _tokenExpiry;
  String? _cachedServiceAccountJson;

  List<LoveEvent> _events = [];
  bool _isGeneratingCode = false;
  bool _isConnecting = false;
  String? _generatedCode;
  String? _requesterUid;
  String? _requesterName;

  final _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;
  StreamSubscription<DocumentSnapshot>? _partnerSubscription;
  Timer? _batteryTimer;

  int? _partnerBatteryLevel;
  bool _partnerIsCharging = false;
  String? _partnerPhotoUrl;
  
  // Partner's real-time statuses synced from Firestore
  String? _partnerCustomStatus;
  String? _partnerCustomStatusEmoji;
  DateTime? _partnerNextMeetingDate;
  bool _partnerIsOnline = false;
  bool _partnerShowOnline = true;

  StreamSubscription<Position>? _locationSubscription;
  double? _partnerLatitude;
  double? _partnerLongitude;
  DateTime? _partnerLocationUpdatedAt;
  String? _partnerGender;
  String? _partnerStickyNote;

  StreamSubscription<QuerySnapshot>? _eventsSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<DocumentSnapshot>? _codeSubscription;

  // UI callback for incoming love events (vibration + banner)
  Function(LoveEvent)? onIncomingLoveEvent;

  List<LoveEvent> get events => _events;
  bool get isGeneratingCode => _isGeneratingCode;
  bool get isConnecting => _isConnecting;
  String? get generatedCode => _generatedCode;
  String? get requesterUid => _requesterUid;
  String? get requesterName => _requesterName;
  int? get partnerBatteryLevel => _partnerBatteryLevel;
  bool get partnerIsCharging => _partnerIsCharging;
  String? get partnerPhotoUrl => _partnerPhotoUrl;
  String? get partnerCustomStatus => _partnerCustomStatus;
  String? get partnerCustomStatusEmoji => _partnerCustomStatusEmoji;
  DateTime? get partnerNextMeetingDate => _partnerNextMeetingDate;
  bool get partnerIsOnline => _partnerIsOnline;
  bool get partnerShowOnline => _partnerShowOnline;
  double? get partnerLatitude => _partnerLatitude;
  double? get partnerLongitude => _partnerLongitude;
  DateTime? get partnerLocationUpdatedAt => _partnerLocationUpdatedAt;
  String? get partnerGender => _partnerGender;
  String? get partnerStickyNote => _partnerStickyNote;

  ConnectionService(this._authService) {
    _authService.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _eventsSubscription?.cancel();
    _userSubscription?.cancel();
    _codeSubscription?.cancel();
    _stopBatteryTracking();
    stopLocationTracking();
    _partnerSubscription?.cancel();
    super.dispose();
  }

  // Request FCM Permission and save device token
  Future<void> setupPushNotifications() async {
    if (!_authService.isAuthenticated) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          final myUid = _authService.currentUser!.uid;
          await _firestore.collection('users').doc(myUid).update({
            'fcmToken': token,
          });
          print('💚 [h2h] FCM Token saved: $token');
        }
      }
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('💚 [h2h] Foreground push: ${message.notification?.title}');
        HapticFeedback.vibrate(); // Vibrate the device immediately on receiving a foreground message
      });
    } catch (e) {
      print('🧡 [h2h] FCM setup error: $e');
    }
  }

  void _onAuthChanged() {
    if (_authService.isAuthenticated) {
      _subscribeToUserDoc();
      setupPushNotifications();
      _startBatteryTracking();
      startLocationTracking();
    } else {
      _eventsSubscription?.cancel();
      _userSubscription?.cancel();
      _codeSubscription?.cancel();
      _stopBatteryTracking();
      stopLocationTracking();
      _events = [];
      _generatedCode = null;
      _requesterUid = null;
      _requesterName = null;
    }
    notifyListeners();
  }

  void _startBatteryTracking() {
    _batterySubscription?.cancel();
    _batteryTimer?.cancel();

    _updateMyBatteryStatus();

    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      _updateMyBatteryStatus();
    });

    // Periodic backup update every 10 minutes
    _batteryTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _updateMyBatteryStatus();
    });
  }

  void _stopBatteryTracking() {
    _batterySubscription?.cancel();
    _batteryTimer?.cancel();
    _partnerSubscription?.cancel();
    _partnerBatteryLevel = null;
    _partnerIsCharging = false;
  }

  void startLocationTracking() async {
    _locationSubscription?.cancel();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('🧡 [h2h] Geolocation service is disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('🧡 [h2h] Geolocation permission denied.');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('🧡 [h2h] Geolocation permission denied forever.');
        return;
      }

      // Get initial position immediately to sync coordinates right away
      try {
        Position? initialPos = await Geolocator.getLastKnownPosition();
        initialPos ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        if (_authService.currentUser != null) {
          final myUid = _authService.currentUser!.uid;
          await _firestore.collection('users').doc(myUid).update({
            'latitude': initialPos.latitude,
            'longitude': initialPos.longitude,
            'locationUpdatedAt': DateTime.now().toIso8601String(),
          });
          print('💚 [h2h] Synced initial location: ${initialPos.latitude}, ${initialPos.longitude}');
        }
      } catch (e) {
        print('🧡 [h2h] Failed to fetch initial location: $e');
      }

      // Start listening to coordinate changes
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15, // Update only if user moves 15 meters
        ),
      ).listen((Position position) async {
        if (_authService.currentUser != null) {
          final myUid = _authService.currentUser!.uid;
          await _firestore.collection('users').doc(myUid).update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'locationUpdatedAt': DateTime.now().toIso8601String(),
          });
        }
      }, onError: (e) {
        print('🧡 [h2h] Geolocation stream error: $e');
      });
      print('💚 [h2h] Geolocation tracking started.');
    } catch (e) {
      print('🧡 [h2h] Location tracking error: $e');
    }
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _partnerLatitude = null;
    _partnerLongitude = null;
    _partnerLocationUpdatedAt = null;
    _partnerGender = null;
    print('💚 [h2h] Geolocation tracking stopped.');
  }

  Future<void> _updateMyBatteryStatus() async {
    if (!_authService.isAuthenticated) return;
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final isCharging = state == BatteryState.charging;
      final myUid = _authService.currentUser!.uid;

      await _firestore.collection('users').doc(myUid).update({
        'batteryLevel': level,
        'isCharging': isCharging,
      });
    } catch (e) {
      print('🧡 [h2h] Error updating battery status: $e');
    }
  }

  // Listen to user document for real-time pairing updates
  void _subscribeToUserDoc() {
    _userSubscription?.cancel();
    final myUid = _authService.currentUser?.uid;
    if (myUid == null) return;

    _userSubscription = _firestore
        .collection('users')
        .doc(myUid)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data()!;
      final partnerUid = data['partnerUid'] as String?;
      if (partnerUid != null && partnerUid.isNotEmpty) {
        final prevPartnerUid = _authService.currentUser?.partnerUid;
        if (prevPartnerUid != partnerUid) {
          // Partner paired! Update auth and subscribe to events
          _authService.updatePartnerDetails(
            partnerUid,
            data['partnerName'] as String?,
            partnerNickname: data['partnerNickname'] as String?,
            connectedAt: data['connectedAt'] != null
                ? DateTime.tryParse(data['connectedAt'] as String)
                : null,
          );
        }
        
        // ALWAYS ensure we are subscribed to events and partner details on startup
        if (_eventsSubscription == null || _partnerSubscription == null) {
          _subscribeToEvents();
        }
        
        // Trigger widget update since my user document changed (e.g. sticky note updated by partner)
        if (_authService.currentUser?.partnerName != null) {
          final latest = _events.isNotEmpty ? _events.first : null;
          final statusMsg = latest != null 
              ? '${_authService.currentUser?.partnerName} ${_getDefaultMessage(latest.type)}'
              : 'No taps yet';
          updateHomeScreenWidget(
            _authService.currentUser?.partnerName ?? 'Partner',
            statusMsg,
          );
        }
      } else {
        // No partner (or unpaired)
        final prevPartnerUid = _authService.currentUser?.partnerUid;
        if (prevPartnerUid != null && prevPartnerUid.isNotEmpty) {
          // Partner has unpaired us!
          _authService.clearPartnerDetails();
          _eventsSubscription?.cancel();
          _partnerSubscription?.cancel();
          _events = [];
          _partnerBatteryLevel = null;
          _partnerIsCharging = false;
          notifyListeners();
        }
      }
    });
  }

  // Subscribe to real-time Firestore events
  void _subscribeToEvents() {
    _eventsSubscription?.cancel();

    final myId = _authService.currentUser!.uid;
    final partnerId = _authService.currentUser!.partnerUid!;
    final convoId = _getConversationId(myId, partnerId);

    _eventsSubscription = _firestore
        .collection('conversations')
        .doc(convoId)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          final newEvents = snapshot.docs
              .map((doc) => LoveEvent.fromMap(doc.data()))
              .toList();

          // Detect new incoming events to trigger vibrations/banners
          if (_events.isNotEmpty && newEvents.isNotEmpty) {
            final latestEvent = newEvents.first;
            if (latestEvent.senderId == partnerId && !_containsEvent(latestEvent.id)) {
              onIncomingLoveEvent?.call(latestEvent);
              _authService.incrementLoveReceived();
              // Instantly mark partner as online
              _partnerIsOnline = true;
              notifyListeners();
            }
          }

          _events = newEvents;
          if (_events.isNotEmpty) {
            final latest = _events.first;
            final displayMsg = _getDefaultMessage(latest.type);
            updateHomeScreenWidget(
              _authService.currentUser?.partnerName ?? 'Partner',
              '${_authService.currentUser?.partnerName ?? 'Partner'} $displayMsg',
            );
          }
          notifyListeners();
        }, onError: (e) {
          print('🧡 [h2h] Events subscription error: $e');
        });

    // Subscribe to partner document for battery level and avatar updates
    _partnerSubscription?.cancel();
    _partnerSubscription = _firestore
        .collection('users')
        .doc(partnerId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data();
      if (data != null) {
        _partnerBatteryLevel = data['batteryLevel'] as int?;
        _partnerIsCharging = data['isCharging'] as bool? ?? false;
        _partnerPhotoUrl = data['photoUrl'] as String?;
        _partnerCustomStatus = data['customStatus'] as String?;
        _partnerCustomStatusEmoji = data['customStatusEmoji'] as String?;
        _partnerIsOnline = data['isOnline'] as bool? ?? false;
        _partnerShowOnline = data['showOnlineStatus'] as bool? ?? true;
        _partnerNextMeetingDate = data['nextMeetingDate'] != null 
            ? DateTime.tryParse(data['nextMeetingDate'] as String) 
            : null;
        _partnerLatitude = data['latitude'] != null ? (data['latitude'] as num).toDouble() : null;
        _partnerLongitude = data['longitude'] != null ? (data['longitude'] as num).toDouble() : null;
        _partnerLocationUpdatedAt = data['locationUpdatedAt'] != null 
            ? DateTime.tryParse(data['locationUpdatedAt'] as String) 
            : null;
        _partnerGender = data['gender'] as String?;
        _partnerStickyNote = data['stickyNote'] as String?;
        notifyListeners();
        
        // Trigger widget update so partner's status changes are reflected!
        if (_events.isNotEmpty) {
          final latest = _events.first;
          final displayMsg = _getDefaultMessage(latest.type);
          updateHomeScreenWidget(
            _authService.currentUser?.partnerName ?? 'Partner',
            '${_authService.currentUser?.partnerName ?? 'Partner'} $displayMsg',
          );
        } else {
          updateHomeScreenWidget(
            _authService.currentUser?.partnerName ?? 'Partner',
            'No taps yet',
          );
        }
      }
    });
  }

  bool _containsEvent(String id) => _events.any((e) => e.id == id);

  String _getConversationId(String u1, String u2) =>
      u1.compareTo(u2) < 0 ? '${u1}_$u2' : '${u2}_$u1';

  // Generate a 4-digit pairing code
  Future<String> generatePairingCode() async {
    _isGeneratingCode = true;
    notifyListeners();

    try {
      final uid = _authService.currentUser!.uid;
      var code = _authService.currentUser!.pairingCode;

      if (code == null || code.isEmpty) {
        final rand = Random();
        code = List.generate(4, (_) => rand.nextInt(10).toString()).join();
        await _firestore.collection('users').doc(uid).update({
          'pairingCode': code,
        });
      }

      // Save code to Firestore pairing_codes collection
      await _firestore.collection('pairing_codes').doc(code).set({
        'creatorUid': uid,
        'creatorName': _authService.currentUser!.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'status': 'pending',
        'requesterUid': null,
        'requesterName': null,
      });

      _generatedCode = code;
      _isGeneratingCode = false;

      // Start listening to the code document for requester pairing requests
      _codeSubscription?.cancel();
      _requesterUid = null;
      _requesterName = null;
      _codeSubscription = _firestore
          .collection('pairing_codes')
          .doc(code)
          .snapshots()
          .listen((snap) {
        if (!snap.exists) return;
        final data = snap.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == 'requesting') {
          _requesterUid = data['requesterUid'] as String?;
          _requesterName = data['requesterName'] as String?;
          notifyListeners();
        } else if (status == 'pending') {
          _requesterUid = null;
          _requesterName = null;
          notifyListeners();
        }
      });

      notifyListeners();
      return code;
    } catch (e) {
      _isGeneratingCode = false;
      notifyListeners();
      print('🧡 [h2h] Pairing code generation error: $e');
      rethrow;
    }
  }

  // Accept the incoming pairing request
  Future<void> acceptPairingRequest() async {
    final code = _generatedCode;
    final partnerUid = _requesterUid;
    final partnerName = _requesterName;
    if (code == null || partnerUid == null || partnerName == null) return;

    try {
      final myUid = _authService.currentUser!.uid;
      final myName = _authService.currentUser!.displayName;
      final rightNow = DateTime.now();

      final batch = _firestore.batch();

      // Update both user profiles
      batch.update(_firestore.collection('users').doc(partnerUid), {
        'partnerUid': myUid,
        'partnerName': myName,
        'connectedAt': rightNow.toIso8601String(),
      });

      batch.update(_firestore.collection('users').doc(myUid), {
        'partnerUid': partnerUid,
        'partnerName': partnerName,
        'connectedAt': rightNow.toIso8601String(),
      });

      // Mark status as accepted
      batch.update(_firestore.collection('pairing_codes').doc(code), {
        'status': 'accepted',
      });

      await batch.commit();

      _authService.updatePartnerDetails(partnerUid, partnerName, connectedAt: rightNow);

      // Clean up pairing code doc and subscription
      await _firestore.collection('pairing_codes').doc(code).delete();
      _codeSubscription?.cancel();
      _generatedCode = null;
      _requesterUid = null;
      _requesterName = null;

      notifyListeners();
      _subscribeToEvents();
    } catch (e) {
      print('🧡 [h2h] Accept pairing error: $e');
      rethrow;
    }
  }

  // Decline the incoming pairing request
  Future<void> declinePairingRequest() async {
    final code = _generatedCode;
    if (code == null) return;

    try {
      // Reset the code status back to pending
      await _firestore.collection('pairing_codes').doc(code).update({
        'status': 'rejected',
        'requesterUid': null,
        'requesterName': null,
      });

      // Quick delay then set back to pending so it can be requested again
      await Future.delayed(const Duration(seconds: 1));
      await _firestore.collection('pairing_codes').doc(code).update({
        'status': 'pending',
      });

      _requesterUid = null;
      _requesterName = null;
      notifyListeners();
    } catch (e) {
      print('🧡 [h2h] Decline pairing error: $e');
    }
  }

  // Connect with partner's 4-digit code (sends request and waits for approval)
  Future<bool> connectWithPartnerCode(String code) async {
    _isConnecting = true;
    notifyListeners();

    try {
      final codeDoc = await _firestore.collection('pairing_codes').doc(code).get();

      if (!codeDoc.exists) {
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      final data = codeDoc.data()!;
      final status = data['status'] as String?;
      final partnerUid = data['creatorUid'] as String;
      final myUid = _authService.currentUser!.uid;
      final myName = _authService.currentUser!.displayName;

      if (partnerUid == myUid) {
        throw Exception('You cannot pair with your own code!');
      }

      if (status != 'pending') {
        throw Exception('This code is currently busy or already used.');
      }

      // 1. Submit pairing request by updating the code doc
      await _firestore.collection('pairing_codes').doc(code).update({
        'status': 'requesting',
        'requesterUid': myUid,
        'requesterName': myName,
      });

      // 2. Wait for confirmation (listening to pairing doc status changes)
      final completer = Completer<bool>();
      StreamSubscription<DocumentSnapshot>? sub;

      sub = _firestore
          .collection('pairing_codes')
          .doc(code)
          .snapshots()
          .listen((snap) async {
        if (!snap.exists) {
          // Doc got deleted - check if pairing was successful
          final userDoc = await _firestore.collection('users').doc(myUid).get();
          final userPartnerUid = userDoc.data()?['partnerUid'] as String?;
          if (userPartnerUid != null && userPartnerUid.isNotEmpty) {
            sub?.cancel();
            if (!completer.isCompleted) completer.complete(true);
          } else {
            sub?.cancel();
            if (!completer.isCompleted) completer.complete(false);
          }
          return;
        }

        final docData = snap.data() as Map<String, dynamic>;
        final currentStatus = docData['status'] as String?;
        if (currentStatus == 'accepted') {
          sub?.cancel();
          if (!completer.isCompleted) completer.complete(true);
        } else if (currentStatus == 'rejected') {
          sub?.cancel();
          if (!completer.isCompleted) completer.complete(false);
        }
      }, onError: (err) {
        sub?.cancel();
        if (!completer.isCompleted) completer.complete(false);
      });

      // Set timeout of 60 seconds for pairing response
      final success = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          sub?.cancel();
          // Reset status to pending so it's not locked
          _firestore.collection('pairing_codes').doc(code).update({
            'status': 'pending',
            'requesterUid': null,
            'requesterName': null,
          });
          throw TimeoutException('Pairing request timed out.');
        },
      );

      _isConnecting = false;
      notifyListeners();

      if (success) {
        _subscribeToEvents();
      }
      return success;
    } catch (e) {
      _isConnecting = false;
      notifyListeners();
      rethrow;
    }
  }

  // Send a love event to partner
  Future<void> sendLoveEvent(String type, {String message = ''}) async {
    if (!_authService.isAuthenticated || !_authService.isPaired) return;

    _updateMyBatteryStatus(); // Refresh battery level on love interaction!

    final myId = _authService.currentUser!.uid;
    final partnerId = _authService.currentUser!.partnerUid!;
    final convoId = _getConversationId(myId, partnerId);
    final eventId = _firestore.collection('events').doc().id;

    final event = LoveEvent(
      id: eventId,
      senderId: myId,
      receiverId: partnerId,
      type: type,
      message: message.isNotEmpty ? message : _getDefaultMessage(type),
      timestamp: DateTime.now(),
    );

    // Call correct counter update
    if (type == 'miss_you' || type == 'sad' || type == 'excited' || type == 'thinking') {
      _authService.incrementEmojisSent();
    } else {
      _authService.incrementLoveSent();
    }

    // Dynamic Love Streak Calculation
    int currentStreak = _authService.currentUser?.streakCount ?? 0;
    final now = DateTime.now();
    if (_events.isEmpty) {
      currentStreak = 1;
    } else {
      final lastEvent = _events.first;
      final lastDate = lastEvent.timestamp;
      final differenceInDays = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (differenceInDays == 1) {
        currentStreak += 1;
      } else if (differenceInDays > 1) {
        currentStreak = 1;
      } else if (differenceInDays == 0 && currentStreak == 0) {
        currentStreak = 1;
      }
    }

    try {
      final batch = _firestore.batch();
      batch.set(_firestore.collection('conversations').doc(convoId).collection('events').doc(eventId), event.toMap());
      batch.update(_firestore.collection('users').doc(myId), {'streakCount': currentStreak});
      batch.update(_firestore.collection('users').doc(partnerId), {'streakCount': currentStreak});
      await batch.commit();

      // Log partner FCM token for background notification delivery
      final partnerDoc = await _firestore.collection('users').doc(partnerId).get();
      final partnerToken = partnerDoc.data()?['fcmToken'] as String?;
      if (partnerToken != null && partnerToken.isNotEmpty) {
        print('💚 [h2h] Partner FCM token found.');
        
        // FCM V1 API — secure, uses Service Account from Firestore
        try {
          String? serviceAccountJson = _cachedServiceAccountJson;
          if (serviceAccountJson == null || serviceAccountJson.isEmpty) {
            print('💚 [h2h] Service account JSON missing in cache. Reading from Firestore...');
            final fcmConfigDoc = await _firestore.collection('config').doc('fcm').get();
            serviceAccountJson = fcmConfigDoc.data()?['serviceAccount'] as String?;
            _cachedServiceAccountJson = serviceAccountJson;
          }

          if (serviceAccountJson != null && serviceAccountJson.isNotEmpty) {
            await _sendFcmV1Notification(
              serviceAccountJson: serviceAccountJson,
              token: partnerToken,
              title: _authService.currentUser!.displayName,
              body: event.message,
              type: type,
              senderId: myId,
            );
          } else {
            print('🧡 [h2h] No serviceAccount configured in Firestore config/fcm.');
          }
        } catch (fcmErr) {
          print('🧡 [h2h] FCM V1 notification failed: $fcmErr');
        }
      }
    } catch (e) {
      print('🧡 [h2h] Send event error: $e');
    }
  }

  String _getDefaultMessage(String type) {
    switch (type) {
      case 'love_tap': return 'missed you';
      case 'miss_you': return 'misses you';
      case 'sad': return 'is feeling sad';
      case 'excited': return 'is excited!';
      case 'thinking': return 'is thinking of you';
      case 'love_draw': return 'sent you a drawing! 🎨';
      default: return 'sent you love';
    }
  }

  Future<void> updateHomeScreenWidget(String partnerName, String statusMessage) async {
    try {
      final receivedNote = _authService.currentUser?.stickyNote ?? '';
      await HomeWidget.saveWidgetData<String>('partner_name', partnerName);
      await HomeWidget.saveWidgetData<String>('status_message', statusMessage);
      await HomeWidget.saveWidgetData<String>('received_note', receivedNote);
      await HomeWidget.updateWidget(
        name: 'LoveWidgetProvider',
        androidName: 'LoveWidgetProvider',
        iOSName: 'LoveWidget',
      );
      print('💚 [h2h] Home Screen Widget updated successfully! Note: "$receivedNote"');
    } catch (e) {
      print('🧡 [h2h] Error updating home screen widget: $e');
    }
  }

  /// FCM V1 API — uses a short-lived OAuth2 access token from the Service Account.
  /// The serviceAccount JSON is stored securely in Firestore at config/fcm.
  Future<void> _sendFcmV1Notification({
    required String serviceAccountJson,
    required String token,
    required String title,
    required String body,
    required String type,
    required String senderId,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      String? accessToken = _cachedAccessToken;

      if (accessToken == null || _tokenExpiry == null || now.isAfter(_tokenExpiry!)) {
        print('💚 [h2h] OAuth2 token expired or missing. Fetching new one...');
        // 1. Parse the service account JSON
        final accountCredentials = gauth.ServiceAccountCredentials.fromJson(
          jsonDecode(serviceAccountJson),
        );

        // 2. Get a short-lived OAuth2 access token (valid 1 hour)
        final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
        final authClient = await gauth.clientViaServiceAccount(accountCredentials, scopes);
        accessToken = authClient.credentials.accessToken.data;
        
        // Cache it, set expiry slightly earlier (e.g. 5 minutes before actual expiry)
        _cachedAccessToken = accessToken;
        _tokenExpiry = authClient.credentials.accessToken.expiry.subtract(const Duration(minutes: 5));
        authClient.close();
        print('💚 [h2h] New OAuth2 token fetched. Expiry: $_tokenExpiry');
      } else {
        print('💚 [h2h] Using cached OAuth2 token.');
      }

      // 3. Build emoji for the notification body
      String emojiIcon = '❤️';
      if (type == 'miss_you') emojiIcon = '🥺';
      if (type == 'sad') emojiIcon = '😢';
      if (type == 'excited') emojiIcon = '🤩';
      if (type == 'thinking') emojiIcon = '💭';
      if (type == 'love_draw') emojiIcon = '🎨';

      // 4. FCM V1 API endpoint
      const String projectId = 'heart-to-heart-e3cc1';
      const String endpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // 5. Build the V1 message payload
      final payload = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': '$body $emojiIcon',
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'high_importance_channel',
              'sound': 'default',
              'icon': 'ic_notification',
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default'},
            },
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'senderId': senderId,
            'type': type,
          },
        },
      };

      // 6. POST the notification
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('💚 [h2h] FCM V1 notification delivered successfully!');
      } else {
        print('🧡 [h2h] FCM V1 notification failed: ${response.statusCode} ${response.body}');
        if (response.statusCode == 401) {
          // Token might have been revoked/invalid, clear cache
          _cachedAccessToken = null;
          _tokenExpiry = null;
          print('🧡 [h2h] 401 Unauthorized received. Cleared FCM token cache.');
        }
      }
    } catch (e) {
      print('🧡 [h2h] Error sending FCM V1 notification: $e');
    }
  }

  // Refresh partner location on demand (user tapped the GPS refresh button)
  Future<void> refreshPartnerLocation() async {
    final partnerId = _authService.currentUser?.partnerUid;
    if (partnerId == null || partnerId.isEmpty) return;
    try {
      final snap = await _firestore.collection('users').doc(partnerId).get();
      if (snap.exists) {
        final data = snap.data()!;
        _partnerLatitude = data['latitude'] != null ? (data['latitude'] as num).toDouble() : null;
        _partnerLongitude = data['longitude'] != null ? (data['longitude'] as num).toDouble() : null;
        _partnerLocationUpdatedAt = data['locationUpdatedAt'] != null
            ? DateTime.tryParse(data['locationUpdatedAt'] as String)
            : null;
        notifyListeners();
        print('💚 [h2h] Partner location refreshed on demand.');
      }
    } catch (e) {
      print('🧡 [h2h] refreshPartnerLocation error: $e');
    }
  }

  // Update partner's sticky note text
  Future<void> updatePartnerStickyNote(String note) async {
    final partnerId = _authService.currentUser?.partnerUid;
    if (partnerId == null || partnerId.isEmpty) return;
    try {
      await _firestore.collection('users').doc(partnerId).update({
        'stickyNote': note,
      });
      _partnerStickyNote = note;
      notifyListeners();
      print('💚 [h2h] Partner sticky note updated.');
    } catch (e) {
      print('🧡 [h2h] updatePartnerStickyNote error: $e');
    }
  }
}

