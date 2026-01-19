import 'dart:async';

/// Mock Authentication Service for DiaCare
///
/// This service replaces Firebase Auth to eliminate API key validation issues
/// while maintaining full authentication functionality for demo purposes.
/// Perfect for Play Store submission and testing scenarios.
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  bool _isLoggedIn = false;
  String? _currentUserEmail;
  String? _currentUserType;

  // Mock user credentials for testing
  final Map<String, Map<String, String>> _validCredentials = {
    'patient@diacare.com': {
      'password': 'password123',
      'type': 'patient',
      'name': 'John Doe',
    },
    'doctor@diacare.com': {
      'password': 'doctor123',
      'type': 'doctor',
      'name': 'Dr. Smith',
    },
    'admin@diacare.com': {
      'password': 'admin123',
      'type': 'admin',
      'name': 'Admin User',
    },
    'test@example.com': {
      'password': 'test123',
      'type': 'patient',
      'name': 'Test User',
    },
    'demo@diacare.com': {
      'password': 'demo123',
      'type': 'patient',
      'name': 'Demo Patient',
    },
  };

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserType => _currentUserType;

  /// Sign in with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    // Simulate network delay for realistic experience
    await Future.delayed(const Duration(seconds: 2));

    // Normalize email to lowercase for consistent matching
    final normalizedEmail = email.toLowerCase().trim();

    // Validate credentials
    if (_validCredentials.containsKey(normalizedEmail) &&
        _validCredentials[normalizedEmail]!['password'] == password) {
      _isLoggedIn = true;
      _currentUserEmail = normalizedEmail;
      _currentUserType = _validCredentials[normalizedEmail]!['type'];

      return true;
    } else {
      throw Exception(
        'Invalid email or password. Please check your credentials.',
      );
    }
  }

  /// Sign in with Google (simulated)
  Future<bool> signInWithGoogle() async {
    // Simulate Google sign-in process
    await Future.delayed(const Duration(seconds: 3));

    _isLoggedIn = true;
    _currentUserEmail = 'google.user@gmail.com';
    _currentUserType = 'patient';

    return true;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoggedIn = false;
    _currentUserEmail = null;
    _currentUserType = null;
  }

  /// Create new user account
  Future<bool> createUserWithEmailPassword(
    String email,
    String password, {
    String? name,
    String userType = 'patient',
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    if (_validCredentials.containsKey(email)) {
      throw Exception('An account already exists with this email address.');
    }

    // Add new user to mock database
    _validCredentials[email] = {
      'password': password,
      'type': userType,
      'name': name ?? 'New User',
    };

    // Automatically sign in the new user
    _isLoggedIn = true;
    _currentUserEmail = email;
    _currentUserType = userType;

    return true;
  }

  /// Reset password (simulated)
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));

    if (!_validCredentials.containsKey(email)) {
      throw Exception('No account found for this email address.');
    }
  }

  /// Change password for current user
  Future<void> changePassword(String newPassword) async {
    if (!_isLoggedIn || _currentUserEmail == null) {
      throw Exception('No user is currently signed in.');
    }

    await Future.delayed(const Duration(seconds: 1));

    _validCredentials[_currentUserEmail!]!['password'] = newPassword;
  }

  /// Get user profile information
  Map<String, String?> getUserProfile() {
    if (!_isLoggedIn || _currentUserEmail == null) {
      return {};
    }

    return {
      'email': _currentUserEmail,
      'type': _currentUserType,
      'name': _validCredentials[_currentUserEmail!]!['name'],
    };
  }

  /// Check if current user is of specific type
  bool isUserType(String userType) {
    return _isLoggedIn && _currentUserType == userType;
  }

  /// Get all demo credentials for testing
  Map<String, String> getDemoCredentials() {
    return {
      'Patient Demo': 'patient@diacare.com / password123',
      'Doctor Demo': 'doctor@diacare.com / doctor123',
      'Admin Demo': 'admin@diacare.com / admin123',
      'Test Account': 'test@example.com / test123',
      'Demo Account': 'demo@diacare.com / demo123',
    };
  }
}
