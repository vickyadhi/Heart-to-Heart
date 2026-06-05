import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'dart:convert';
import 'dart:async';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/connection_service.dart';
import 'pages/splash_page.dart';
import 'theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await FirebaseService.initialize(isBackground: true);
    print("💚 [h2h] FCM Background message: ${message.messageId}");
  } catch (e) {
    print("🧡 [h2h] FCM Background message initialization failed: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register iOS App Group ID for Home screen widgets
  try {
    await HomeWidget.setAppGroupId('group.com.example.h2h');
    // Use registerInteractivityCallback (replaces deprecated registerBackgroundCallback)
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  } catch (e) {
    print('Failed to set HomeWidget AppGroup: $e');
  }


  // Initialize Firebase (production mode — sandbox fully disabled)
  try {
    await FirebaseService.initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Failed to initialize Firebase / FCM: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProxyProvider<AuthService, ConnectionService>(
          create: (context) => ConnectionService(
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, auth, previous) => previous ?? ConnectionService(auth),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _widgetSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupHomeWidgetListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetSubscription?.cancel();
    super.dispose();
  }

  void _setupHomeWidgetListener() {
    // 1. Handle launched URI on cold start
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });

    // 2. Handle launched URI when app is already in memory
    _widgetSubscription = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });
  }

  void _handleWidgetUri(Uri uri) {
    if (uri.scheme == 'homewidget' && uri.host == 'send_love') {
      final type = uri.queryParameters['type'];
      if (type != null) {
        // Wait a short moment to ensure services are fully loaded
        Future.delayed(const Duration(milliseconds: 600), () async {
          if (!mounted) return;
          final conn = Provider.of<ConnectionService>(context, listen: false);
          final auth = Provider.of<AuthService>(context, listen: false);
          
          if (auth.isAuthenticated && auth.isPaired) {
            try {
              await conn.sendLoveEvent(type);
              if (mounted) {
                String label = 'Love';
                if (type == 'miss_you') label = 'Miss You';
                if (type == 'sad') label = 'Sad';
                if (type == 'excited') label = 'Excited';
                if (type == 'thinking') label = 'Thinking';
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sent "$label" to partner from widget! ❤️',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFE91E63), // Pink color matching theme
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              print('Error sending love event from widget tap: $e');
            }
          }
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAuthenticated) {
      if (state == AppLifecycleState.resumed) {
        authService.updateOnlineStatus(true);
      } else if (state == AppLifecycleState.paused || 
                 state == AppLifecycleState.inactive || 
                 state == AppLifecycleState.detached) {
        authService.updateOnlineStatus(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'h2h - Heart to Heart',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}

// Background callback handler for interactive home screen widget taps!
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri == null) return;
  if (uri.scheme == 'homewidget' && uri.host == 'send_love') {
    final type = uri.queryParameters['type'];
    if (type != null) {
      try {
        await FirebaseService.initialize(isBackground: true);
        final auth = firebase_auth.FirebaseAuth.instance;
        firebase_auth.User? user = auth.currentUser;
        if (user == null) {
          print("💚 [h2h] Background callback: currentUser is null. Waiting for auth state to restore...");
          try {
            user = await auth.authStateChanges().firstWhere((u) => u != null).timeout(const Duration(seconds: 2));
          } catch (_) {
            print("🧡 [h2h] Background callback: Auth state restore timed out.");
          }
        }
        if (user != null) {
          final myUid = user.uid;
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
          final partnerUid = userDoc.data()?['partnerUid'] as String?;
          
          if (partnerUid != null && partnerUid.isNotEmpty) {
            final convoId = myUid.compareTo(partnerUid) < 0 ? '${myUid}_$partnerUid' : '${partnerUid}_$myUid';
            final eventId = FirebaseFirestore.instance.collection('events').doc().id;
            
            String defaultMsg = 'sent you love';
            if (type == 'love_tap') defaultMsg = 'loves you';
            if (type == 'miss_you') defaultMsg = 'misses you';
            if (type == 'sad') defaultMsg = 'is feeling sad';
            if (type == 'excited') defaultMsg = 'is excited!';
            if (type == 'thinking') defaultMsg = 'is thinking of you';

            final event = {
              'id': eventId,
              'senderId': myUid,
              'receiverId': partnerUid,
              'type': type,
              'message': defaultMsg,
              'timestamp': FieldValue.serverTimestamp(),
            };

            final updates = <String, dynamic>{
              'loveSentCount': FieldValue.increment(1),
            };
            if (type == 'miss_you' || type == 'sad' || type == 'excited' || type == 'thinking') {
              updates['emojisSentCount'] = FieldValue.increment(1);
            } else {
              updates['heartsCount'] = FieldValue.increment(1);
            }

            final batch = FirebaseFirestore.instance.batch();
            batch.set(
              FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(convoId)
                  .collection('events')
                  .doc(eventId),
              event,
            );
            batch.update(FirebaseFirestore.instance.collection('users').doc(myUid), updates);
            await batch.commit();

            print('💚 [h2h] Background widget tap event sent successfully to Firestore!');

            // Log partner FCM token for background notification delivery
            final partnerDoc = await FirebaseFirestore.instance.collection('users').doc(partnerUid).get();
            final partnerToken = partnerDoc.data()?['fcmToken'] as String?;
            final myName = userDoc.data()?['displayName'] as String? ?? 'Partner';

            if (partnerToken != null && partnerToken.isNotEmpty) {
              try {
                final fcmConfigDoc = await FirebaseFirestore.instance.collection('config').doc('fcm').get();
                final serviceAccountJson = fcmConfigDoc.data()?['serviceAccount'] as String?;
                if (serviceAccountJson != null && serviceAccountJson.isNotEmpty) {
                  final soundEnabled = partnerDoc.data()?['soundEnabled'] as bool? ?? true;
                  await _sendFcmV1NotificationBackground(
                    serviceAccountJson: serviceAccountJson,
                    token: partnerToken,
                    title: myName,
                    body: defaultMsg,
                    type: type,
                    senderId: myUid,
                    soundEnabled: soundEnabled,
                  );
                }
              } catch (fcmErr) {
                print('🧡 [h2h] Background FCM V1 notification failed: $fcmErr');
              }
            }
          }
        }
      } catch (e) {
        print('🧡 [h2h] Error sending background widget event: $e');
      }
    }
  }
}

Future<void> _sendFcmV1NotificationBackground({
  required String serviceAccountJson,
  required String token,
  required String title,
  required String body,
  required String type,
  required String senderId,
  required bool soundEnabled,
}) async {
  try {
    // 1. Parse the service account JSON
    final accountCredentials = gauth.ServiceAccountCredentials.fromJson(
      jsonDecode(serviceAccountJson),
    );

    // 2. Get a short-lived OAuth2 access token (valid 1 hour)
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final authClient = await gauth.clientViaServiceAccount(accountCredentials, scopes);
    final accessToken = authClient.credentials.accessToken.data;
    authClient.close();

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

  String notificationIcon = 'ic_notification';
  if (type == 'miss_you' || type == 'sad') {
    notificationIcon = 'ic_notification_sad';
  } else if (type == 'excited') {
    notificationIcon = 'ic_notification_excited';
  } else if (type == 'thinking') {
    notificationIcon = 'ic_notification_thinking';
  }

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
          'channel_id': soundEnabled ? 'high_importance_channel' : 'silent_importance_channel',
          if (soundEnabled) 'sound': 'default',
          'icon': notificationIcon,
        },
      },
        'apns': {
          'payload': {
            'aps': {
              if (soundEnabled) 'sound': 'default',
            },
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
      print('💚 [h2h] Background FCM V1 notification delivered successfully!');
    } else {
      print('🧡 [h2h] Background FCM V1 notification failed: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('🧡 [h2h] Error sending background FCM V1 notification: $e');
  }
}
