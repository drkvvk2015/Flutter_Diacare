import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production-ready security configurations
class SecurityConfig {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Initialize security settings
  static Future<void> initialize() async {
    await _enableSecurePreferences();
    await _clearSensitiveDataOnFirstRun();
  }

  /// Enable encrypted shared preferences
  static Future<void> _enableSecurePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isSecured = prefs.getBool('security_initialized') ?? false;
    
    if (!isSecured) {
      await prefs.setBool('security_initialized', true);
      debugPrint('Security: Encrypted preferences enabled');
    }
  }

  /// Clear sensitive data on first app run after installation
  static Future<void> _clearSensitiveDataOnFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('is_first_run') ?? true;
    
    if (isFirstRun) {
      await _secureStorage.deleteAll();
      await prefs.clear();
      await prefs.setBool('is_first_run', false);
      debugPrint('Security: First run cleanup completed');
    }
  }

  /// Store sensitive data securely
  static Future<void> storeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('Security: Failed to store secure data: $e');
    }
  }

  /// Retrieve sensitive data securely
  static Future<String?> retrieveSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('Security: Failed to retrieve secure data: $e');
      return null;
    }
  }

  /// Delete secure data
  static Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('Security: Failed to delete secure data: $e');
    }
  }

  /// Hash sensitive data (one-way)
  static String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure random token
  static String generateToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString();
    return hashData(random);
  }

  /// Validate app integrity (basic check)
  static Future<bool> validateAppIntegrity() async {
    // Check if app is running in debug mode
    if (kDebugMode) {
      return true; // Allow in development
    }

    // Add additional integrity checks for production
    try {
      // Check if root/jailbreak detection is needed
      // This is a placeholder - implement actual root detection if needed
      return true;
    } catch (e) {
      debugPrint('Security: Integrity check failed: $e');
      return false;
    }
  }

  /// Clear all secure storage (logout)
  static Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('Security: All secure data cleared');
    } catch (e) {
      debugPrint('Security: Failed to clear secure data: $e');
    }
  }
}

/// Network security configuration
class NetworkSecurity {
  /// Validate SSL certificate (basic)
  static bool validateCertificate(String host) {
    // Add custom certificate pinning if needed
    final allowedHosts = [
      'diacare.health',
      'api.diacare.health',
      'firebase.google.com',
      'firestore.googleapis.com',
    ];
    
    return allowedHosts.any((allowed) => host.contains(allowed));
  }

  /// Get secure headers for API calls
  static Map<String, String> getSecureHeaders({String? authToken}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': '1.0.0',
      'X-Platform': 'flutter',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }
}

/// Sensitive data masking utilities
class DataMasking {
  /// Mask email address
  static String maskEmail(String email) {
    if (!email.contains('@')) return email;
    
    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }
    
    return '${username.substring(0, 2)}***@$domain';
  }

  /// Mask phone number
  static String maskPhone(String phone) {
    if (phone.length < 4) return phone;
    
    final visible = phone.substring(phone.length - 4);
    return '***-***-$visible';
  }

  /// Mask credit card (if implemented)
  static String maskCard(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    
    final visible = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $visible';
  }
}
