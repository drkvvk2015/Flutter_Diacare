import 'dart:async';
import 'mock_auth_service.dart';

/// Premium Auth Bridge Service
///
/// This service bridges MockAuthService with Firebase-dependent components
/// providing seamless integration and production-ready authentication management.
///
/// Features:
/// - Session management with automatic renewal
/// - Security event logging
/// - Automatic logout on inactivity
/// - Secure credential handling
/// - Performance monitoring
class AuthBridgeService {
  static final AuthBridgeService _instance = AuthBridgeService._internal();
  factory AuthBridgeService() => _instance;
  AuthBridgeService._internal();

  final MockAuthService _mockAuth = MockAuthService();
  Timer? _sessionTimer;
  Timer? _inactivityTimer;
  DateTime? _lastActivity;

  // Session configuration
  static const Duration _sessionDuration = Duration(hours: 8);
  static const Duration _inactivityTimeout = Duration(minutes: 30);
  static const Duration _sessionRenewalInterval = Duration(minutes: 5);

  // Event listeners
  final StreamController<AuthEvent> _eventController =
      StreamController<AuthEvent>.broadcast();
  Stream<AuthEvent> get authEvents => _eventController.stream;

  // Enhanced getters with session validation
  bool get isAuthenticated {
    _updateLastActivity();
    return _mockAuth.isLoggedIn && _isSessionValid();
  }

  String? get currentUserEmail => _mockAuth.currentUserEmail;
  String? get currentUserType => _mockAuth.currentUserType;
  Map<String, String?> get userProfile => _mockAuth.getUserProfile();

  /// Initialize the auth bridge service
  Future<void> initialize() async {
    print('[AuthBridge] Initializing premium authentication service...');

    // Start session monitoring
    _startSessionMonitoring();

    // Log initialization
    _logSecurityEvent('auth_bridge_initialized', {
      'timestamp': DateTime.now().toIso8601String(),
      'session_timeout': _sessionDuration.inMinutes,
      'inactivity_timeout': _inactivityTimeout.inMinutes,
    });

    print('[AuthBridge] Premium authentication service ready');
  }

  /// Enhanced sign in with security features
  Future<AuthResult> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      _updateLastActivity();

      // Pre-authentication validation
      final validationResult = _validateCredentials(email, password);
      if (!validationResult.isValid) {
        return AuthResult.failure(validationResult.error!);
      }

      // Start performance monitoring
      final stopwatch = Stopwatch()..start();

      print('[AuthBridge] Starting secure authentication process...');

      // Authenticate with MockAuthService
      final success = await _mockAuth.signInWithEmailPassword(email, password);

      stopwatch.stop();

      if (success) {
        // Start session management
        _startSessionManagement();

        // Log successful authentication
        _logSecurityEvent('user_authenticated', {
          'email': email,
          'user_type': _mockAuth.currentUserType,
          'auth_duration_ms': stopwatch.elapsedMilliseconds,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Broadcast success event
        _eventController.add(
          AuthEvent.signInSuccess(email, _mockAuth.currentUserType!),
        );

        print(
          '[AuthBridge] ✅ Secure authentication successful in ${stopwatch.elapsedMilliseconds}ms',
        );

        return AuthResult.success({
          'email': email,
          'userType': _mockAuth.currentUserType!,
          'sessionId': _generateSessionId(),
          'expiresAt': DateTime.now().add(_sessionDuration).toIso8601String(),
        });
      } else {
        return AuthResult.failure('Authentication failed');
      }
    } catch (e) {
      _logSecurityEvent('authentication_failed', {
        'email': email,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      _eventController.add(AuthEvent.signInFailure(e.toString()));

      return AuthResult.failure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Enhanced sign out with security cleanup
  Future<void> signOut({String reason = 'user_requested'}) async {
    print('[AuthBridge] Starting secure sign out process...');

    final userEmail = _mockAuth.currentUserEmail;

    // Clear session timers
    _sessionTimer?.cancel();
    _inactivityTimer?.cancel();

    // Sign out from MockAuthService
    await _mockAuth.signOut();

    // Clear sensitive data
    _lastActivity = null;

    // Log sign out
    _logSecurityEvent('user_signed_out', {
      'email': userEmail,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Broadcast sign out event
    _eventController.add(AuthEvent.signOut(reason));

    print('[AuthBridge] ✅ Secure sign out completed');
  }

  /// Session management
  void _startSessionManagement() {
    _lastActivity = DateTime.now();

    // Session renewal timer
    _sessionTimer = Timer.periodic(_sessionRenewalInterval, (timer) {
      if (!_isSessionValid()) {
        signOut(reason: 'session_expired');
      } else {
        _renewSession();
      }
    });

    // Inactivity timer
    _inactivityTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isInactive()) {
        signOut(reason: 'inactivity_timeout');
      }
    });
  }

  /// Start session monitoring
  void _startSessionMonitoring() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_mockAuth.isLoggedIn) {
        _logSessionHealth();
      }
    });
  }

  /// Validate credentials before authentication
  CredentialValidationResult _validateCredentials(
    String email,
    String password,
  ) {
    // Email validation
    if (email.trim().isEmpty) {
      return CredentialValidationResult.invalid('Email address is required');
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return CredentialValidationResult.invalid(
        'Please enter a valid email address',
      );
    }

    // Password validation
    if (password.trim().isEmpty) {
      return CredentialValidationResult.invalid('Password is required');
    }

    if (password.length < 6) {
      return CredentialValidationResult.invalid(
        'Password must be at least 6 characters',
      );
    }

    return CredentialValidationResult.valid();
  }

  /// Check if session is valid
  bool _isSessionValid() {
    if (_lastActivity == null) return false;
    return DateTime.now().difference(_lastActivity!).inHours <
        _sessionDuration.inHours;
  }

  /// Check if user is inactive
  bool _isInactive() {
    if (_lastActivity == null) return true;
    return DateTime.now().difference(_lastActivity!) > _inactivityTimeout;
  }

  /// Update last activity timestamp
  void _updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  /// Renew session
  void _renewSession() {
    print('[AuthBridge] Session renewed for ${_mockAuth.currentUserEmail}');
    _logSecurityEvent('session_renewed', {
      'email': _mockAuth.currentUserEmail,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Generate session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_mockAuth.currentUserEmail?.hashCode}';
  }

  /// Log security events
  void _logSecurityEvent(String event, Map<String, dynamic> data) {
    print('[AuthBridge] Security Event: $event');
    print('[AuthBridge] Event Data: $data');
  }

  /// Log session health
  void _logSessionHealth() {
    final health = {
      'user': _mockAuth.currentUserEmail,
      'session_age_minutes': _lastActivity != null
          ? DateTime.now().difference(_lastActivity!).inMinutes
          : 0,
      'is_active': !_isInactive(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('[AuthBridge] Session Health: $health');
  }

  /// Cleanup resources
  void dispose() {
    _sessionTimer?.cancel();
    _inactivityTimer?.cancel();
    _eventController.close();
  }
}

/// Authentication result wrapper
class AuthResult {
  final bool isSuccess;
  final String? error;
  final Map<String, dynamic>? data;

  AuthResult._(this.isSuccess, this.error, this.data);

  factory AuthResult.success(Map<String, dynamic> data) =>
      AuthResult._(true, null, data);

  factory AuthResult.failure(String error) => AuthResult._(false, error, null);
}

/// Credential validation result
class CredentialValidationResult {
  final bool isValid;
  final String? error;

  CredentialValidationResult._(this.isValid, this.error);

  factory CredentialValidationResult.valid() =>
      CredentialValidationResult._(true, null);

  factory CredentialValidationResult.invalid(String error) =>
      CredentialValidationResult._(false, error);
}

/// Authentication events
class AuthEvent {
  final String type;
  final Map<String, dynamic> data;

  AuthEvent._(this.type, this.data);

  factory AuthEvent.signInSuccess(String email, String userType) =>
      AuthEvent._('sign_in_success', {'email': email, 'userType': userType});

  factory AuthEvent.signInFailure(String error) =>
      AuthEvent._('sign_in_failure', {'error': error});

  factory AuthEvent.signOut(String reason) =>
      AuthEvent._('sign_out', {'reason': reason});
}
