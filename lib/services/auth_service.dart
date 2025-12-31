import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide User;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _needsCharacterSetup = false;
  bool get needsCharacterSetup => _needsCharacterSetup;

  // Current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ===== Google Sign In =====
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _createOrUpdateUserProfile(userCredential.user!, 'google');

      return userCredential;
    } catch (e) {
      debugPrint('Google login error: $e');
      rethrow;
    }
  }

  // ===== Apple Sign In =====
  Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb) {
        // Web: OAuth popup
        final provider = OAuthProvider("apple.com")
          ..addScope('email')
          ..addScope('name');

        final userCredential = await _auth.signInWithPopup(provider);
        await _createOrUpdateUserProfile(userCredential.user!, 'apple');
        return userCredential;
      } else {
        // iOS/macOS: Native Apple Sign In
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        final userCredential = await _auth.signInWithCredential(oauthCredential);
        await _createOrUpdateUserProfile(userCredential.user!, 'apple');
        return userCredential;
      }
    } catch (e) {
      debugPrint('Apple login error: $e');
      rethrow;
    }
  }

  // ===== Kakao Sign In =====
  Future<UserCredential?> signInWithKakao() async {
    try {
      OAuthToken token;

      if (kIsWeb) {
        // Web: Kakao account login
        token = await UserApi.instance.loginWithKakaoAccount();
      } else {
        // Mobile: Try KakaoTalk first, fallback to account
        if (await isKakaoTalkInstalled()) {
          token = await UserApi.instance.loginWithKakaoTalk();
        } else {
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      }

      // Call Firebase Function for custom token
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyKakaoToken');
      final result = await callable.call({
        'accessToken': token.accessToken,
      });

      final customToken = result.data['customToken'];
      final userCredential = await _auth.signInWithCustomToken(customToken);
      await _createOrUpdateUserProfile(userCredential.user!, 'kakao');

      return userCredential;
    } catch (e) {
      debugPrint('Kakao login error: $e');
      rethrow;
    }
  }

  // ===== Create or Update User Profile =====
  Future<void> _createOrUpdateUserProfile(
      User firebaseUser, String provider) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await userDoc.get();

    if (!doc.exists) {
      // Create new user profile
      await userDoc.set({
        'id': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'displayName': firebaseUser.displayName ?? '',
        'photoURL': firebaseUser.photoURL ?? '',
        'characterName': null,
        'joinDate': FieldValue.serverTimestamp(),
        'loginProvider': provider,
      });
      _needsCharacterSetup = true;
    } else {
      // Check if character setup is needed
      final data = doc.data()!;
      _needsCharacterSetup = data['characterName'] == null;

      // Update last login
      await userDoc.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ===== Update Character Name =====
  Future<void> updateCharacterName(String name) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'characterName': name,
    });
    _needsCharacterSetup = false;
  }

  // ===== Sign Out =====
  Future<void> signOut() async {
    // Sign out from Google if applicable
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    // Sign out from Firebase
    await _auth.signOut();
    _needsCharacterSetup = false;
  }
}
