import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

/// Comprehensive security service for Flutter Diacare app
/// Handles biometric authentication, secure storage, data encryption, and security auditing
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // Services
  late final LocalAuthentication _localAuth;
  late final FlutterSecureStorage _secureStorage;
  late final encrypt.Encrypter _encrypter;
  late final encrypt.Key _encryptionKey;

  // Security state
  bool _isInitialized = false;
  bool _biometricEnabled = false;
  bool _encryptionEnabled = true;
  DateTime? _lastAuthTime;
  int _failedAuthAttempts = 0;
  final int _maxFailedAttempts = 5;
  DateTime? _lockoutUntil;

  // Security audit tracking
  final List<SecurityEvent> _securityEvents = [];
  final Map<String, dynamic> _securityMetrics = {};

  // Constants
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _encryptionEnabledKey = 'encryption_enabled';
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutUntilKey = 'lockout_until';

  /// Initialize the security service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _localAuth = LocalAuthentication();

      // Configure secure storage with encryption
      const secureStorageOptions = AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      );

      _secureStorage = const FlutterSecureStorage(
        aOptions: secureStorageOptions,
      );

      // Initialize encryption
      await _initializeEncryption();

      // Load security settings
      await _loadSecuritySettings();

      // Reset lockout if expired
      await _checkLockoutStatus();

      _isInitialized = true;
      _logSecurityEvent('security_service_initialized');
      _log('SecurityService initialized successfully');
    } catch (e, stackTrace) {
      _log('Error initializing SecurityService: $e');
      await _logSecurityEvent(
        'security_service_init_error',
        data: {'error': e.toString(), 'stack_trace': stackTrace.toString()},
      );
    }
  }

  /// Initialize encryption with key generation or retrieval
  Future<void> _initializeEncryption() async {
    try {
      String? keyString = await _secureStorage.read(key: _encryptionKeyKey);

      if (keyString == null) {
        // Generate new key if not found
        final keyBytes = _generateSecureKey();
        keyString = base64.encode(keyBytes);
        await _secureStorage.write(key: _encryptionKeyKey, value: keyString);
      }

      final keyBytes = base64.decode(keyString);
      _encryptionKey = encrypt.Key(keyBytes);
      _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));

      _log('Encryption initialized successfully');
    } catch (e) {
      _log('Error initializing encryption: $e');
      rethrow;
    }
  }

  /// Generate cryptographically secure key
  List<int> _generateSecureKey() {
    final random = Random.secure();
    return List<int>.generate(32, (i) => random.nextInt(256));
  }

  /// Load security settings from secure storage
  Future<void> _loadSecuritySettings() async {
    try {
      final biometricStr = await _secureStorage.read(key: _biometricEnabledKey);
      _biometricEnabled = biometricStr == 'true';

      final encryptionStr = await _secureStorage.read(
        key: _encryptionEnabledKey,
      );
      _encryptionEnabled = encryptionStr != 'false'; // Default to true

      final failedAttemptsStr = await _secureStorage.read(
        key: _failedAttemptsKey,
      );
      _failedAuthAttempts = int.tryParse(failedAttemptsStr ?? '0') ?? 0;

      final lockoutStr = await _secureStorage.read(key: _lockoutUntilKey);
      if (lockoutStr != null) {
        _lockoutUntil = DateTime.tryParse(lockoutStr);
      }
    } catch (e) {
      _log('Error loading security settings: $e');
    }
  }

  /// Check if device supports biometric authentication
  Future<BiometricSupport> checkBiometricSupport() async {
    if (!_isInitialized) {
      return BiometricSupport(false, false, []);
    }

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      return BiometricSupport(
        isAvailable,
        isDeviceSupported,
        availableBiometrics,
      );
    } catch (e) {
      _log('Error checking biometric support: $e');
      return BiometricSupport(false, false, []);
    }
  }

  /// Authenticate user with biometrics
  Future<AuthenticationResult> authenticateWithBiometric({
    String reason = 'Please authenticate to access secure features',
  }) async {
    if (!_isInitialized) {
      return AuthenticationResult.notInitialized();
    }

    if (_isLockedOut()) {
      final remainingTime = _lockoutUntil!.difference(DateTime.now());
      return AuthenticationResult.lockedOut(remainingTime);
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access secure data',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        _lastAuthTime = DateTime.now();
        _failedAuthAttempts = 0;
        await _secureStorage.delete(key: _failedAttemptsKey);
        await _secureStorage.delete(key: _lockoutUntilKey);

        await _logSecurityEvent('biometric_auth_success');
        return AuthenticationResult.success();
      } else {
        await _handleFailedAuth();
        return AuthenticationResult.failed();
      }
    } catch (e) {
      await _handleFailedAuth();
      await _logSecurityEvent(
        'biometric_auth_error',
        data: {'error': e.toString()},
      );
      return AuthenticationResult.error(e.toString());
    }
  }

  /// Handle failed authentication attempts
  Future<void> _handleFailedAuth() async {
    _failedAuthAttempts++;
    await _secureStorage.write(
      key: _failedAttemptsKey,
      value: _failedAuthAttempts.toString(),
    );

    if (_failedAuthAttempts >= _maxFailedAttempts) {
      _lockoutUntil = DateTime.now().add(const Duration(minutes: 30));
      await _secureStorage.write(
        key: _lockoutUntilKey,
        value: _lockoutUntil!.toIso8601String(),
      );

      await _logSecurityEvent(
        'account_locked_out',
        data: {
          'failed_attempts': _failedAuthAttempts,
          'lockout_until': _lockoutUntil!.toIso8601String(),
        },
      );
    }

    await _logSecurityEvent(
      'biometric_auth_failed',
      data: {'failed_attempts': _failedAuthAttempts},
    );
  }

  /// Check if account is locked out
  bool _isLockedOut() {
    return _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  }

  /// Check lockout status and reset if expired
  Future<void> _checkLockoutStatus() async {
    if (_lockoutUntil != null && DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      _failedAuthAttempts = 0;
      await _secureStorage.delete(key: _lockoutUntilKey);
      await _secureStorage.delete(key: _failedAttemptsKey);
      await _logSecurityEvent('lockout_expired');
    }
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    if (!_isInitialized) return;

    try {
      if (enabled) {
        final support = await checkBiometricSupport();
        if (!support.isAvailable) {
          throw SecurityException('Biometric authentication not available');
        }
      }

      _biometricEnabled = enabled;
      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );

      await _logSecurityEvent(
        'biometric_setting_changed',
        data: {'enabled': enabled},
      );
    } catch (e) {
      _log('Error setting biometric enabled: $e');
      rethrow;
    }
  }

  /// Enable or disable encryption
  Future<void> setEncryptionEnabled(bool enabled) async {
    if (!_isInitialized) return;

    try {
      _encryptionEnabled = enabled;
      await _secureStorage.write(
        key: _encryptionEnabledKey,
        value: enabled.toString(),
      );

      await _logSecurityEvent(
        'encryption_setting_changed',
        data: {'enabled': enabled},
      );
    } catch (e) {
      _log('Error setting encryption enabled: $e');
      rethrow;
    }
  }

  /// Securely store encrypted data
  Future<void> storeSecureData(String key, String value) async {
    if (!_isInitialized) {
      throw SecurityException('SecurityService not initialized');
    }

    try {
      String finalValue = value;

      if (_encryptionEnabled) {
        final iv = encrypt.IV.fromSecureRandom(16);
        final encrypted = _encrypter.encrypt(value, iv: iv);
        finalValue = '${iv.base64}:${encrypted.base64}';
      }

      await _secureStorage.write(key: key, value: finalValue);

      await _logSecurityEvent(
        'secure_data_stored',
        data: {'key': key, 'encrypted': _encryptionEnabled},
      );
    } catch (e) {
      await _logSecurityEvent(
        'secure_data_store_error',
        data: {'key': key, 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Retrieve and decrypt stored data
  Future<String?> retrieveSecureData(String key) async {
    if (!_isInitialized) {
      throw SecurityException('SecurityService not initialized');
    }

    try {
      final storedValue = await _secureStorage.read(key: key);
      if (storedValue == null) return null;

      if (_encryptionEnabled && storedValue.contains(':')) {
        final parts = storedValue.split(':');
        if (parts.length == 2) {
          final iv = encrypt.IV.fromBase64(parts[0]);
          final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
          return _encrypter.decrypt(encrypted, iv: iv);
        }
      }

      return storedValue;
    } catch (e) {
      await _logSecurityEvent(
        'secure_data_retrieve_error',
        data: {'key': key, 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Delete secure data
  Future<void> deleteSecureData(String key) async {
    if (!_isInitialized) return;

    try {
      await _secureStorage.delete(key: key);

      await _logSecurityEvent('secure_data_deleted', data: {'key': key});
    } catch (e) {
      await _logSecurityEvent(
        'secure_data_delete_error',
        data: {'key': key, 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Clear all secure storage (for logout/reset)
  Future<void> clearAllSecureData() async {
    if (!_isInitialized) return;

    try {
      await _secureStorage.deleteAll();

      // Reinitialize encryption after clearing
      await _initializeEncryption();
      await _loadSecuritySettings();

      await _logSecurityEvent('all_secure_data_cleared');
    } catch (e) {
      await _logSecurityEvent(
        'secure_data_clear_error',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Generate secure hash for data integrity
  String generateSecureHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify data integrity with hash
  bool verifyDataIntegrity(String data, String expectedHash) {
    final actualHash = generateSecureHash(data);
    return actualHash == expectedHash;
  }

  /// Get security status summary
  SecurityStatus getSecurityStatus() {
    return SecurityStatus(
      isInitialized: _isInitialized,
      biometricEnabled: _biometricEnabled,
      encryptionEnabled: _encryptionEnabled,
      isLockedOut: _isLockedOut(),
      failedAttempts: _failedAuthAttempts,
      maxAttempts: _maxFailedAttempts,
      lockoutUntil: _lockoutUntil,
      lastAuthTime: _lastAuthTime,
      securityEventsCount: _securityEvents.length,
    );
  }

  /// Get security audit report
  SecurityAuditReport getSecurityAudit() {
    final recentEvents = _securityEvents
        .where(
          (event) => DateTime.now().difference(event.timestamp).inDays <= 30,
        )
        .toList();

    return SecurityAuditReport(
      totalEvents: _securityEvents.length,
      recentEvents: recentEvents,
      authSuccessCount: _securityEvents
          .where((e) => e.eventType == 'biometric_auth_success')
          .length,
      authFailureCount: _securityEvents
          .where((e) => e.eventType == 'biometric_auth_failed')
          .length,
      dataAccessCount: _securityEvents
          .where((e) => e.eventType == 'secure_data_retrieved')
          .length,
      securityViolations: _securityEvents
          .where(
            (e) =>
                e.eventType.contains('error') || e.eventType.contains('failed'),
          )
          .toList(),
      lastAuditTime: DateTime.now(),
    );
  }

  /// Log security event for audit trail
  Future<void> _logSecurityEvent(
    String eventType, {
    Map<String, dynamic>? data,
  }) async {
    final event = SecurityEvent(
      eventType: eventType,
      timestamp: DateTime.now(),
      data: data,
    );

    _securityEvents.add(event);

    // Keep only last 1000 events
    if (_securityEvents.length > 1000) {
      _securityEvents.removeRange(0, _securityEvents.length - 1000);
    }

    _log('Security event logged: $eventType');
  }

  /// Check if recently authenticated (within last 5 minutes)
  bool isRecentlyAuthenticated() {
    if (_lastAuthTime == null) return false;
    return DateTime.now().difference(_lastAuthTime!).inMinutes < 5;
  }

  /// Force re-authentication requirement
  void requireReAuthentication() {
    _lastAuthTime = null;
    _logSecurityEvent('reauthentication_required');
  }

  /// Export security events for analysis
  String exportSecurityEvents() {
    final eventsJson = _securityEvents.map((e) => e.toJson()).toList();
    return jsonEncode({
      'export_time': DateTime.now().toIso8601String(),
      'total_events': _securityEvents.length,
      'events': eventsJson,
    });
  }

  /// Get current security metrics
  Map<String, dynamic> getSecurityMetrics() {
    return {
      'initialized': _isInitialized,
      'biometric_enabled': _biometricEnabled,
      'encryption_enabled': _encryptionEnabled,
      'failed_attempts': _failedAuthAttempts,
      'is_locked_out': _isLockedOut(),
      'recently_authenticated': isRecentlyAuthenticated(),
      'total_security_events': _securityEvents.length,
      'last_auth_time': _lastAuthTime?.toIso8601String(),
      'lockout_until': _lockoutUntil?.toIso8601String(),
    };
  }

  /// Dispose and cleanup
  void dispose() {
    _securityEvents.clear();
    _securityMetrics.clear();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get biometricEnabled => _biometricEnabled;
  bool get encryptionEnabled => _encryptionEnabled;
  bool get isLockedOut => _isLockedOut();
  int get failedAttempts => _failedAuthAttempts;
  DateTime? get lastAuthTime => _lastAuthTime;

  /// Log debug messages
  void _log(String message) {
    if (kDebugMode) {
      print('[SecurityService] $message');
    }
  }
}

/// Biometric support information
class BiometricSupport {
  final bool isAvailable;
  final bool isDeviceSupported;
  final List<BiometricType> availableBiometrics;

  BiometricSupport(
    this.isAvailable,
    this.isDeviceSupported,
    this.availableBiometrics,
  );
}

/// Authentication result
class AuthenticationResult {
  final bool success;
  final String? error;
  final Duration? lockoutRemaining;
  final AuthenticationStatus status;

  AuthenticationResult._(
    this.success,
    this.error,
    this.lockoutRemaining,
    this.status,
  );

  factory AuthenticationResult.success() =>
      AuthenticationResult._(true, null, null, AuthenticationStatus.success);
  factory AuthenticationResult.failed() =>
      AuthenticationResult._(false, null, null, AuthenticationStatus.failed);
  factory AuthenticationResult.error(String error) =>
      AuthenticationResult._(false, error, null, AuthenticationStatus.error);
  factory AuthenticationResult.lockedOut(Duration remaining) =>
      AuthenticationResult._(
        false,
        null,
        remaining,
        AuthenticationStatus.lockedOut,
      );
  factory AuthenticationResult.notInitialized() => AuthenticationResult._(
    false,
    'Not initialized',
    null,
    AuthenticationStatus.notInitialized,
  );
}

/// Authentication status enum
enum AuthenticationStatus { success, failed, error, lockedOut, notInitialized }

/// Security status information
class SecurityStatus {
  final bool isInitialized;
  final bool biometricEnabled;
  final bool encryptionEnabled;
  final bool isLockedOut;
  final int failedAttempts;
  final int maxAttempts;
  final DateTime? lockoutUntil;
  final DateTime? lastAuthTime;
  final int securityEventsCount;

  SecurityStatus({
    required this.isInitialized,
    required this.biometricEnabled,
    required this.encryptionEnabled,
    required this.isLockedOut,
    required this.failedAttempts,
    required this.maxAttempts,
    this.lockoutUntil,
    this.lastAuthTime,
    required this.securityEventsCount,
  });
}

/// Security event for audit trail
class SecurityEvent {
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  SecurityEvent({required this.eventType, required this.timestamp, this.data});

  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };
}

/// Security audit report
class SecurityAuditReport {
  final int totalEvents;
  final List<SecurityEvent> recentEvents;
  final int authSuccessCount;
  final int authFailureCount;
  final int dataAccessCount;
  final List<SecurityEvent> securityViolations;
  final DateTime lastAuditTime;

  SecurityAuditReport({
    required this.totalEvents,
    required this.recentEvents,
    required this.authSuccessCount,
    required this.authFailureCount,
    required this.dataAccessCount,
    required this.securityViolations,
    required this.lastAuditTime,
  });
}

/// Security exception
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
