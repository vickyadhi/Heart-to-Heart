import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

class FirebaseService {
  // Sandbox mode is now DISABLED — app runs fully on real Firebase
  static bool _isSandbox = false;

  static bool get isSandbox => _isSandbox;

  static Future<void> initialize({bool isBackground = false}) async {
    try {
      if (isBackground) {
        DartPluginRegistrant.ensureInitialized();
      } else {
        WidgetsFlutterBinding.ensureInitialized();
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isSandbox = false;
      if (kDebugMode) {
        print('❤️ [h2h] Firebase Initialized Successfully! Running in ${isBackground ? 'Background' : 'Production'} Mode.');
      }
    } catch (e) {
      // If Firebase fails, still keep sandbox OFF so errors surface cleanly
      _isSandbox = false;
      if (kDebugMode) {
        print('🧡 [h2h] Firebase initialization error: $e');
      }
      rethrow; // Surface the error so we know what went wrong
    }
  }

  static void setSandbox(bool value) {
    _isSandbox = value;
  }
}
