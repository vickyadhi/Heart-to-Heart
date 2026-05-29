import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  firebase_auth.FirebaseAuth get _firebaseAuth => firebase_auth.FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn();

  UserProfile? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  bool get isPaired => _currentUser?.partnerUid != null && _currentUser!.partnerUid!.isNotEmpty;

  AuthService() {
    // Synchronously check for cached user session to maintain login state instantly on startup
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser != null) {
      _currentUser = UserProfile(
        uid: fbUser.uid,
        displayName: fbUser.displayName ?? '',
        email: fbUser.email ?? '',
        photoUrl: fbUser.photoURL,
        streakCount: 0,
        loveSentCount: 0,
        loveReceivedCount: 0,
        heartsCount: 0,
        isOnline: true,
      );
      refreshUser(fbUser.uid).then((_) {
        _isInitialized = true;
        notifyListeners();
      }).catchError((e) {
        _isInitialized = true;
        notifyListeners();
      });
    } else {
      _isInitialized = true;
    }
    _checkAuthState();
  }

  void _checkAuthState() {
    // Listen to Firebase auth state changes
    try {
      _firebaseAuth.authStateChanges().listen((firebase_auth.User? user) async {
        if (user != null) {
          await refreshUser(user.uid);
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });
    } catch (e) {
      _currentUser = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Generate a unique 4-digit pairing code that doesn't collide with existing active users
  Future<String> _generateUniquePairingCode() async {
    final rand = Random();
    while (true) {
      final code = List.generate(4, (_) => rand.nextInt(10).toString()).join();
      final doc = await _firestore.collection('pairing_codes').doc(code).get();
      if (!doc.exists) {
        return code;
      }
    }
  }

  // Refresh user data from Firestore
  Future<void> refreshUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['pairingCode'] == null || (data['pairingCode'] as String).isEmpty) {
          final pairingCode = await _generateUniquePairingCode();
          await _firestore.collection('users').doc(uid).update({'pairingCode': pairingCode});
          data['pairingCode'] = pairingCode;
        }
        _currentUser = UserProfile.fromMap(data);
        notifyListeners();
      } else {
        // Profile not found — create a minimal one from Firebase Auth
        final fbUser = _firebaseAuth.currentUser;
        if (fbUser != null) {
          final pairingCode = await _generateUniquePairingCode();
          final newProfile = UserProfile(
            uid: fbUser.uid,
            displayName: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'User',
            email: fbUser.email ?? '',
            photoUrl: fbUser.photoURL,
            pairingCode: pairingCode,
            streakCount: 0,
            loveSentCount: 0,
            loveReceivedCount: 0,
            heartsCount: 0,
            isOnline: true,
          );
          await _firestore.collection('users').doc(uid).set(newProfile.toMap());
          _currentUser = newProfile;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }

  // Convert Firebase error codes to human-readable messages
  String _firebaseErrorMessage(dynamic e, {bool isSignUp = false}) {
    final errString = e.toString().toLowerCase();
    if (errString.contains('requires-recent-login') || errString.contains('recent-login')) {
      return 'For security reasons, changing your password requires you to sign out and log in again first.';
    }
    if (errString.contains('invalid-credential') || 
        errString.contains('malformed or has expired') || 
        errString.contains('malformed or have expired')) {
      return isSignUp 
          ? 'Failed to create account. Please verify that email/password sign-in is enabled in the Firebase Console.'
          : 'Incorrect email or password. Please try again.';
    }
    if (errString.contains('email-already-in-use')) {
      return 'This email is already registered. Try signing in instead.';
    }
    if (errString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (errString.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (errString.contains('user-not-found')) {
      return 'No account found for this email. Try signing up.';
    }
    if (errString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (errString.contains('too-many-requests')) {
      return 'Too many attempts. Please wait and try again.';
    }
    if (errString.contains('operation-not-allowed')) {
      return 'Email/password sign-in is not enabled. Please enable it in the Firebase Console.';
    }
    if (errString.contains('network-request-failed')) {
      return 'Network error. Check your internet connection.';
    }
    if (errString.contains('user-disabled')) {
      return 'This account has been disabled.';
    }

    if (e is firebase_auth.FirebaseAuthException) {
      return e.message ?? 'Authentication failed. Please try again.';
    }
    return e.toString().replaceAll(RegExp(r'\[.*?\]\s*'), '').trim();
  }

  // Email login
  Future<bool> loginWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        await refreshUser(cred.user!.uid);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      throw Exception(_firebaseErrorMessage(e, isSignUp: false));
    }
  }

  // Email signup
  Future<bool> signUpWithEmail(String name, String email, String password) async {
    _setLoading(true);
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        // Update display name in Firebase Auth
        await cred.user!.updateDisplayName(name);
        final pairingCode = await _generateUniquePairingCode();
        // Create Firestore profile document
        final newProfile = UserProfile(
          uid: cred.user!.uid,
          displayName: name,
          email: email,
          pairingCode: pairingCode,
          streakCount: 0,
          loveSentCount: 0,
          loveReceivedCount: 0,
          heartsCount: 0,
          isOnline: true,
        );
        await _firestore.collection('users').doc(cred.user!.uid).set(newProfile.toMap());
        _currentUser = newProfile;
        notifyListeners();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      throw Exception(_firebaseErrorMessage(e, isSignUp: true));
    }
  }

  // Google sign in
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false; // User cancelled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _firebaseAuth.signInWithCredential(credential);
      if (cred.user != null) {
        final doc = await _firestore.collection('users').doc(cred.user!.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          if (data['pairingCode'] == null || (data['pairingCode'] as String).isEmpty) {
            final pairingCode = await _generateUniquePairingCode();
            await _firestore.collection('users').doc(cred.user!.uid).update({'pairingCode': pairingCode});
            data['pairingCode'] = pairingCode;
          }
          _currentUser = UserProfile.fromMap(data);
        } else {
          final pairingCode = await _generateUniquePairingCode();
          final newProfile = UserProfile(
            uid: cred.user!.uid,
            displayName: cred.user!.displayName ?? 'User',
            email: cred.user!.email ?? '',
            photoUrl: cred.user!.photoURL,
            pairingCode: pairingCode,
            streakCount: 0,
            loveSentCount: 0,
            loveReceivedCount: 0,
            heartsCount: 0,
            isOnline: true,
          );
          await _firestore.collection('users').doc(cred.user!.uid).set(newProfile.toMap());
          _currentUser = newProfile;
        }
        notifyListeners();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      throw Exception(_firebaseErrorMessage(e, isSignUp: false));
    }
  }

  // Set user profile details
  Future<void> updateProfileDetails(String name, String partnerNickname, DateTime anniversaryDate) async {
    if (_currentUser == null) return;
    _setLoading(true);
    _currentUser = _currentUser!.copyWith(
      displayName: name,
      partnerNickname: partnerNickname,
      anniversaryDate: anniversaryDate,
    );
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'displayName': name,
        'partnerNickname': partnerNickname,
        'anniversaryDate': anniversaryDate.toIso8601String(),
      });
    } catch (e) {
      print('Firestore update profile error: $e');
    }
    _setLoading(false);
  }

  // Update pairing state
  void updatePartnerDetails(String? partnerUid, String? partnerName, {String? partnerNickname, DateTime? connectedAt}) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      partnerUid: partnerUid,
      partnerName: partnerName,
      partnerNickname: partnerNickname ?? partnerName,
      connectedAt: connectedAt ?? DateTime.now(),
    );
    notifyListeners();
  }

  void incrementLoveSent() {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      loveSentCount: _currentUser!.loveSentCount + 1,
      heartsCount: _currentUser!.heartsCount + 1,
    );
    notifyListeners();
    // Persist to Firestore async
    _firestore.collection('users').doc(_currentUser!.uid).update({
      'loveSentCount': FieldValue.increment(1),
      'heartsCount': FieldValue.increment(1),
    }).catchError((e) => print('Firestore increment sent error: $e'));
  }

  void incrementLoveReceived() {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      loveReceivedCount: _currentUser!.loveReceivedCount + 1,
    );
    notifyListeners();
    _firestore.collection('users').doc(_currentUser!.uid).update({
      'loveReceivedCount': FieldValue.increment(1),
    }).catchError((e) => print('Firestore increment received error: $e'));
  }

  // Update a single boolean setting property in Firestore and local model
  Future<void> updateSetting(String settingKey, bool value) async {
    if (_currentUser == null) return;
    try {
      // Update model locally
      switch (settingKey) {
        case 'pushNotificationsEnabled':
          _currentUser = _currentUser!.copyWith(pushNotificationsEnabled: value);
          break;
        case 'soundEnabled':
          _currentUser = _currentUser!.copyWith(soundEnabled: value);
          break;
        case 'vibrationEnabled':
          _currentUser = _currentUser!.copyWith(vibrationEnabled: value);
          break;
        case 'emailNotificationsEnabled':
          _currentUser = _currentUser!.copyWith(emailNotificationsEnabled: value);
          break;
        case 'showOnlineStatus':
          _currentUser = _currentUser!.copyWith(showOnlineStatus: value);
          break;
        case 'readReceipts':
          _currentUser = _currentUser!.copyWith(readReceipts: value);
          break;
      }
      notifyListeners();

      // Write to Firestore in the background
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        settingKey: value,
      });
    } catch (e) {
      print('Firestore update setting $settingKey error: $e');
    }
  }

  // Change password for the current authenticated user
  Future<void> changePassword(String newPassword) async {
    if (_firebaseAuth.currentUser == null) return;
    _setLoading(true);
    try {
      await _firebaseAuth.currentUser!.updatePassword(newPassword);
    } catch (e) {
      _setLoading(false);
      throw Exception(_firebaseErrorMessage(e, isSignUp: false));
    }
    _setLoading(false);
  }

  // Unpair partner
  Future<void> unpairPartner() async {
    if (_currentUser == null) return;
    _setLoading(true);
    final oldPartnerUid = _currentUser!.partnerUid;
    _currentUser = _currentUser!.clearPartner();
    try {
      final uid = _currentUser!.uid;
      await _firestore.collection('users').doc(uid).update({
        'partnerUid': FieldValue.delete(),
        'partnerName': FieldValue.delete(),
        'connectedAt': FieldValue.delete(),
      });
      if (oldPartnerUid != null) {
        await _firestore.collection('users').doc(oldPartnerUid).update({
          'partnerUid': FieldValue.delete(),
          'partnerName': FieldValue.delete(),
          'connectedAt': FieldValue.delete(),
        });
      }
    } catch (e) {
      print('Firestore unpair error: $e');
    }
    _setLoading(false);
  }

  // Clear partner details reactively when partner unpairs us
  void clearPartnerDetails() {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.clearPartner();
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    _currentUser = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
    _setLoading(false);
  }
}
