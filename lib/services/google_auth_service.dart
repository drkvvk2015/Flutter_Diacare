import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Web-compatible Google Sign-In Service
/// 
/// On web, we use Firebase Auth's signInWithPopup for Google authentication
/// which is more reliable than the google_sign_in package on web.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();
  
  /// Sign in with Google
  /// Returns UserCredential on success, null on cancellation
  /// Throws on error
  Future<UserCredential?> signIn() async {
    if (kIsWeb) {
      return _signInWeb();
    } else {
      return _signInMobile();
    }
  }
  
  /// Web implementation using Firebase Auth popup
  Future<UserCredential?> _signInWeb() async {
    try {
      final googleProvider = GoogleAuthProvider();
      
      // Add scopes if needed
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Set custom parameters
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });
      
      // Use popup for web
      final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        // User cancelled
        return null;
      }
      rethrow;
    }
  }
  
  /// Mobile implementation using google_sign_in package
  Future<UserCredential?> _signInMobile() async {
    final googleSignIn = GoogleSignIn.instance;

    // Optional override. If not provided, plugin uses platform config.
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (serverClientId.isEmpty) {
      await googleSignIn.initialize();
    } else {
      await googleSignIn.initialize(serverClientId: serverClientId);
    }
    
    try {
      // Authenticate user
      final GoogleSignInAccount account = await googleSignIn.authenticate();
      
      // Get idToken
      final idToken = account.authentication.idToken;
      
      // Get accessToken
      final authorization = await account.authorizationClient
          .authorizationForScopes(const <String>[]);
      final accessToken = authorization?.accessToken;
      
      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      
      return FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw Exception(e.description ?? 'Google sign-in failed');
    } catch (e) {
      // Check for cancellation
      if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
        return null;
      }
      rethrow;
    }
  }
  
  /// Sign out from Google
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    
    if (!kIsWeb) {
      try {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.signOut();
      } catch (_) {
        // Ignore errors during sign out
      }
    }
  }
}
