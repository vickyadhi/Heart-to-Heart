import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
    HomeWidget.registerBackgroundCallback(backgroundCallback);
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          }
        }
      } catch (e) {
        print('🧡 [h2h] Error sending background widget event: $e');
      }
    }
  }
}
