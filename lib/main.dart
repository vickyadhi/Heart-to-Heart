import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'dart:convert';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/connection_service.dart';
import 'pages/splash_page.dart';
import 'theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await FirebaseService.initialize();
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
        await FirebaseService.initialize();
        final auth = firebase_auth.FirebaseAuth.instance;
        final user = auth.currentUser;
        if (user != null) {
          final myUid = user.uid;
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
          final partnerUid = userDoc.data()?['partnerUid'] as String?;
          
          if (partnerUid != null && partnerUid.isNotEmpty) {
            final convoId = myUid.compareTo(partnerUid) < 0 ? '${myUid}_$partnerUid' : '${partnerUid}_$myUid';
            final eventId = FirebaseFirestore.instance.collection('events').doc().id;
            
            String defaultMsg = 'sent you love';
            if (type == 'love_tap') defaultMsg = 'missed you';
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

            await FirebaseFirestore.instance
                .collection('conversations')
                .doc(convoId)
                .collection('events')
                .doc(eventId)
                .set(event);

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
                  await _sendFcmV1NotificationBackground(
                    serviceAccountJson: serviceAccountJson,
                    token: partnerToken,
                    title: myName,
                    body: defaultMsg,
                    type: type,
                    senderId: myUid,
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
      print('💚 [h2h] Background FCM V1 notification delivered successfully!');
    } else {
      print('🧡 [h2h] Background FCM V1 notification failed: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('🧡 [h2h] Error sending background FCM V1 notification: $e');
  }
}
