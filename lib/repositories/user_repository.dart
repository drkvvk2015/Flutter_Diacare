/// User Repository
/// 
/// Handles all user-related data operations.
/// Abstracts data sources (API, local storage, cache).
/// 
/// Features:
/// - User CRUD operations
/// - Profile management
/// - Authentication state
/// - Data caching
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api/api_client.dart';
import '../core/error/api_exception.dart';
import '../utils/logger.dart';

/// Repository for user data management
class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiClient _apiClient = ApiClient();

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login with email and password
  Future<User> login(String email, String password) async {
    try {
      logInfo('Attempting login for: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthenticationException('Login failed');
      }

      // Update last login timestamp
      await _updateLastLogin(credential.user!.uid);

      logInfo('Login successful for: $email');
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      logError('Login failed', e);
      throw AuthenticationException(_getAuthErrorMessage(e.code));
    } catch (e) {
      logError('Login error', e);
      rethrow;
    }
  }

  /// Register new user
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
    String role = 'patient',
  }) async {
    try {
      logInfo('Attempting registration for: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw ApiException('Registration failed');
      }

      final user = credential.user!;

      // Update display name
      await user.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserDocument(
        uid: user.uid,
        email: email,
        displayName: displayName,
        role: role,
      );

      logInfo('Registration successful for: $email');
      return user;
    } on FirebaseAuthException catch (e) {
      logError('Registration failed', e);
      throw ApiException(_getAuthErrorMessage(e.code));
    } catch (e) {
      logError('Registration error', e);
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      logInfo('Logging out user');
      await _auth.signOut();
      _apiClient.clearAuthToken();
      logInfo('Logout successful');
    } catch (e) {
      logError('Logout error', e);
      rethrow;
    }
  }

  /// Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        logInfo('User profile not found: $uid');
        return null;
      }

      return doc.data();
    } catch (e) {
      logError('Error fetching user profile', e);
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      logInfo('Updating user profile: $uid');

      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(uid).update(data);

      // Update Firebase Auth profile if display name or photo changed
      if (data.containsKey('displayName') || data.containsKey('photoUrl')) {
        final user = _auth.currentUser;
        if (user != null) {
          if (data.containsKey('displayName')) {
            await user.updateDisplayName(data['displayName'] as String?);
          }
          if (data.containsKey('photoUrl')) {
            await user.updatePhotoURL(data['photoUrl'] as String?);
          }
        }
      }

      logInfo('Profile updated successfully');
    } catch (e) {
      logError('Error updating user profile', e);
      rethrow;
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw AuthenticationException('No authenticated user');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      logInfo('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      logError('Password change failed', e);
      throw ApiException(_getAuthErrorMessage(e.code));
    } catch (e) {
      logError('Password change error', e);
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      logInfo('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      logError('Password reset failed', e);
      throw ApiException(_getAuthErrorMessage(e.code));
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw AuthenticationException('No authenticated user');
      }

      // Re-authenticate before deletion
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete Firestore data
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete auth account
      await user.delete();

      logInfo('User account deleted');
    } catch (e) {
      logError('Account deletion failed', e);
      rethrow;
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    required String role,
  }) async {
    final userData = {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'emailVerified': false,
    };

    await _firestore.collection('users').doc(uid).set(userData);
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logInfo('Failed to update last login: $e');
    }
  }

  /// Get friendly error message from Firebase Auth error code
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'requires-recent-login':
        return 'Please login again to continue';
      default:
        return 'Authentication failed: $code';
    }
  }
}


