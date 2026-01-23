/// User State Management Provider
/// 
/// Manages user authentication state, profile data, and role information.
/// Integrates with Firebase Auth and Firestore for persistent user data.
/// 
/// Features:
/// - Real-time auth state monitoring
/// - User profile management
/// - Role-based access control (doctor, patient, admin)
/// - Automatic Firestore document creation for new users
/// - Profile updates with Firebase Auth synchronization
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive user state management provider
/// 
/// Extends ChangeNotifier for reactive state updates across the application.
/// Provides centralized access to user data and authentication status.
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;
  UserRole _userRole = UserRole.unknown;

  // Getters
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserRole get userRole => _userRole;
  bool get isAuthenticated => _currentUser != null;
  bool get isDoctor => _userRole == UserRole.doctor;
  bool get isPatient => _userRole == UserRole.patient;
  bool get isPharmacist => _userRole == UserRole.pharmacist;
  bool get isAdmin => _userRole == UserRole.admin;
  /// Check if user is a healthcare professional (doctor or pharmacist)
  bool get isHealthcareProfessional => isDoctor || isPharmacist;

  String get displayName =>
      (_userData?['displayName'] as String?) ??
      _currentUser?.displayName ??
      'Anonymous User';

  String get email => (_userData?['email'] as String?) ?? _currentUser?.email ?? '';

  String get photoUrl => (_userData?['photoUrl'] as String?) ?? _currentUser?.photoURL ?? '';

  /// Initialize user state and listen to auth changes
  Future<void> initialize() async {
    _setLoading(true);

    try {
      // Listen to auth state changes
      FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);

      // Set initial user if already logged in
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        await _loadUserData();
      }

      _clearError();
    } catch (e) {
      _setError('Failed to initialize user state: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Handle authentication state changes
  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;

    if (user != null) {
      await _loadUserData();
    } else {
      _clearUserData();
    }

    notifyListeners();
  }

  /// Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        _userData = doc.data();
        _userRole = _parseUserRole(_userData?['role'] as String?);
      } else {
        // Create user document if it doesn't exist
        await _createUserDocument();
      }

      _clearError();
    } catch (e) {
      _setError('Failed to load user data: $e');
    }
  }

  /// Create new user document in Firestore
  Future<void> _createUserDocument() async {
    if (_currentUser == null) return;

    try {
      _userData = {
        'uid': _currentUser!.uid,
        'email': _currentUser!.email,
        'displayName': _currentUser!.displayName ?? 'User',
        'photoUrl': _currentUser!.photoURL,
        'role': 'patient', // Default role
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set(_userData!);

      _userRole = UserRole.patient;
    } catch (e) {
      _setError('Failed to create user document: $e');
    }
  }

  /// Update user profile data
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);

    try {
      final updates = <String, dynamic>{
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
        // Also update Firebase Auth profile
        await _currentUser!.updateDisplayName(displayName);
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        // Also update Firebase Auth profile
        await _currentUser!.updatePhotoURL(photoUrl);
      }

      if (additionalData != null) {
        updates.addAll(additionalData);
      }

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updates);

      // Update local state
      _userData = {...?_userData, ...updates};

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Switch user role (for demo/testing purposes)
  Future<bool> switchRole(UserRole newRole) async {
    if (_currentUser == null) return false;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'role': newRole.name,
        'roleChangedAt': FieldValue.serverTimestamp(),
      });

      _userRole = newRole;
      if (_userData != null) {
        _userData!['role'] = newRole.name;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to switch role: $e');
      return false;
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin() async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'lastLoginAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Failed to update last login: $e');
    }
  }

  /// Sign out user
  Future<bool> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      _clearUserData();
      return true;
    } catch (e) {
      _setError('Failed to sign out: $e');
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    _setLoading(true);

    try {
      // Delete user document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .delete();

      // Delete Firebase Auth account
      await _currentUser!.delete();

      _clearUserData();
      return true;
    } catch (e) {
      _setError('Failed to delete account: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get user statistics
  Map<String, dynamic> getUserStats() {
    if (_userData == null) return {};

    final createdAt = _userData!['createdAt'] as Timestamp?;
    final lastLoginAt = _userData!['lastLoginAt'] as Timestamp?;

    return {
      'memberSince': createdAt?.toDate(),
      'lastLogin': lastLoginAt?.toDate(),
      'role': _userRole.displayName,
      'isActive': _userData!['isActive'] ?? false,
      'profileCompleteness': _calculateProfileCompleteness(),
    };
  }

  /// Calculate profile completeness percentage
  int _calculateProfileCompleteness() {
    if (_userData == null) return 0;

    int completedFields = 0;
    const totalFields = 5;

    if (_userData!['displayName']?.toString().isNotEmpty ?? false) {
      completedFields++;
    }
    if (_userData!['email']?.toString().isNotEmpty ?? false) completedFields++;
    if (_userData!['photoUrl']?.toString().isNotEmpty ?? false) {
      completedFields++;
    }
    if (_userData!['role']?.toString().isNotEmpty ?? false) completedFields++;
    if (_userData!['phone']?.toString().isNotEmpty ?? false) completedFields++;

    return ((completedFields / totalFields) * 100).round();
  }

  // Helper methods
  UserRole _parseUserRole(String? roleString) {
    if (roleString == null) return UserRole.unknown;

    switch (roleString.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'patient':
        return UserRole.patient;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    debugPrint('UserProvider Error: $error');
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _clearUserData() {
    _userData = null;
    _userRole = UserRole.unknown;
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any subscriptions if needed
    super.dispose();
  }
}

/// User role enumeration
enum UserRole {
  unknown,
  patient,
  doctor,
  pharmacist,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.unknown:
        return 'Unknown';
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get name {
    return toString().split('.').last;
  }
}
