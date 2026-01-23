import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'security_service.dart';

/// Secure data manager for handling encrypted application data
/// Provides high-level interface for secure storage operations
class SecureDataManager {
  factory SecureDataManager() => _instance;
  SecureDataManager._internal();
  static final SecureDataManager _instance = SecureDataManager._internal();

  final SecurityService _securityService = SecurityService();

  // Data keys for different types of secure storage
  static const String _userCredentialsKey = 'user_credentials';
  static const String _medicalDataKey = 'medical_data';
  static const String _appointmentDataKey = 'appointment_data';
  static const String _patientDataKey = 'patient_data';
  static const String _prescriptionDataKey = 'prescription_data';
  static const String _biometricSettingsKey = 'biometric_settings';
  static const String _securitySettingsKey = 'security_settings';
  static const String _apiKeysKey = 'api_keys';
  static const String _tokenDataKey = 'token_data';
  static const String _healthDataKey = 'health_data';

  /// Initialize the secure data manager
  Future<void> initialize() async {
    await _securityService.initialize();
    _log('SecureDataManager initialized');
  }

  /// Store user credentials securely
  Future<void> storeUserCredentials(UserCredentials credentials) async {
    try {
      final jsonData = jsonEncode(credentials.toJson());
      await _securityService.storeSecureData(_userCredentialsKey, jsonData);
      _log('User credentials stored securely');
    } catch (e) {
      _log('Error storing user credentials: $e');
      rethrow;
    }
  }

  /// Retrieve user credentials
  Future<UserCredentials?> getUserCredentials() async {
    try {
      final jsonData = await _securityService.retrieveSecureData(
        _userCredentialsKey,
      );
      if (jsonData == null) return null;

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      return UserCredentials.fromJson(data);
    } catch (e) {
      _log('Error retrieving user credentials: $e');
      return null;
    }
  }

  /// Store medical data securely
  Future<void> storeMedicalData(
    String patientId,
    MedicalData medicalData,
  ) async {
    try {
      final key = '${_medicalDataKey}_$patientId';
      final jsonData = jsonEncode(medicalData.toJson());
      await _securityService.storeSecureData(key, jsonData);
      _log('Medical data stored securely for patient: $patientId');
    } catch (e) {
      _log('Error storing medical data: $e');
      rethrow;
    }
  }

  /// Retrieve medical data
  Future<MedicalData?> getMedicalData(String patientId) async {
    try {
      final key = '${_medicalDataKey}_$patientId';
      final jsonData = await _securityService.retrieveSecureData(key);
      if (jsonData == null) return null;

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      return MedicalData.fromJson(data);
    } catch (e) {
      _log('Error retrieving medical data: $e');
      return null;
    }
  }

  /// Store appointment data securely
  Future<void> storeAppointmentData(List<AppointmentData> appointments) async {
    try {
      final jsonData = jsonEncode(appointments.map((a) => a.toJson()).toList());
      await _securityService.storeSecureData(_appointmentDataKey, jsonData);
      _log(
        'Appointment data stored securely (${appointments.length} appointments)',
      );
    } catch (e) {
      _log('Error storing appointment data: $e');
      rethrow;
    }
  }

  /// Retrieve appointment data
  Future<List<AppointmentData>> getAppointmentData() async {
    try {
      final jsonData = await _securityService.retrieveSecureData(
        _appointmentDataKey,
      );
      if (jsonData == null) return [];

      final List<dynamic> data = jsonDecode(jsonData) as List<dynamic>;
      return data.map((item) => AppointmentData.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      _log('Error retrieving appointment data: $e');
      return [];
    }
  }

  /// Store patient data securely
  Future<void> storePatientData(
    String patientId,
    PatientData patientData,
  ) async {
    try {
      final key = '${_patientDataKey}_$patientId';
      final jsonData = jsonEncode(patientData.toJson());
      await _securityService.storeSecureData(key, jsonData);
      _log('Patient data stored securely for: $patientId');
    } catch (e) {
      _log('Error storing patient data: $e');
      rethrow;
    }
  }

  /// Retrieve patient data
  Future<PatientData?> getPatientData(String patientId) async {
    try {
      final key = '${_patientDataKey}_$patientId';
      final jsonData = await _securityService.retrieveSecureData(key);
      if (jsonData == null) return null;

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      return PatientData.fromJson(data);
    } catch (e) {
      _log('Error retrieving patient data: $e');
      return null;
    }
  }

  /// Store prescription data securely
  Future<void> storePrescriptionData(
    String prescriptionId,
    PrescriptionData prescription,
  ) async {
    try {
      final key = '${_prescriptionDataKey}_$prescriptionId';
      final jsonData = jsonEncode(prescription.toJson());
      await _securityService.storeSecureData(key, jsonData);
      _log('Prescription data stored securely: $prescriptionId');
    } catch (e) {
      _log('Error storing prescription data: $e');
      rethrow;
    }
  }

  /// Retrieve prescription data
  Future<PrescriptionData?> getPrescriptionData(String prescriptionId) async {
    try {
      final key = '${_prescriptionDataKey}_$prescriptionId';
      final jsonData = await _securityService.retrieveSecureData(key);
      if (jsonData == null) return null;

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      return PrescriptionData.fromJson(data);
    } catch (e) {
      _log('Error retrieving prescription data: $e');
      return null;
    }
  }

  /// Store API keys securely
  Future<void> storeApiKeys(Map<String, String> apiKeys) async {
    try {
      final jsonData = jsonEncode(apiKeys);
      await _securityService.storeSecureData(_apiKeysKey, jsonData);
      _log('API keys stored securely (${apiKeys.length} keys)');
    } catch (e) {
      _log('Error storing API keys: $e');
      rethrow;
    }
  }

  /// Retrieve API keys
  Future<Map<String, String>> getApiKeys() async {
    try {
      final jsonData = await _securityService.retrieveSecureData(_apiKeysKey);
      if (jsonData == null) return {};

      final Map<String, dynamic> data = jsonDecode(jsonData) as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      _log('Error retrieving API keys: $e');
      return {};
    }
  }

  /// Store authentication tokens
  Future<void> storeTokenData(TokenData tokenData) async {
    try {
      final jsonData = jsonEncode(tokenData.toJson());
      await _securityService.storeSecureData(_tokenDataKey, jsonData);
      _log('Token data stored securely');
    } catch (e) {
      _log('Error storing token data: $e');
      rethrow;
    }
  }

  /// Retrieve authentication tokens
  Future<TokenData?> getTokenData() async {
    try {
      final jsonData = await _securityService.retrieveSecureData(_tokenDataKey);
      if (jsonData == null) return null;

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      return TokenData.fromJson(data);
    } catch (e) {
      _log('Error retrieving token data: $e');
      return null;
    }
  }

  /// Store health data securely
  Future<void> storeHealthData(String userId, HealthData healthData) async {
    try {
      final key = '${_healthDataKey}_$userId';
      final jsonData = jsonEncode(healthData.toJson());
      await _securityService.storeSecureData(key, jsonData);
      _log('Health data stored securely for user: $userId');
    } catch (e) {
      _log('Error storing health data: $e');
      rethrow;
    }
  }

  /// Retrieve health data
  Future<HealthData?> getHealthData(String userId) async {
    try {
      final key = '${_healthDataKey}_$userId';
      final jsonData = await _securityService.retrieveSecureData(key);
      if (jsonData == null) return null;

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      return HealthData.fromJson(data);
    } catch (e) {
      _log('Error retrieving health data: $e');
      return null;
    }
  }

  /// Store biometric settings
  Future<void> storeBiometricSettings(BiometricSettings settings) async {
    try {
      final jsonData = jsonEncode(settings.toJson());
      await _securityService.storeSecureData(_biometricSettingsKey, jsonData);
      _log('Biometric settings stored securely');
    } catch (e) {
      _log('Error storing biometric settings: $e');
      rethrow;
    }
  }

  /// Retrieve biometric settings
  Future<BiometricSettings?> getBiometricSettings() async {
    try {
      final jsonData = await _securityService.retrieveSecureData(
        _biometricSettingsKey,
      );
      if (jsonData == null) return null;

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      return BiometricSettings.fromJson(data);
    } catch (e) {
      _log('Error retrieving biometric settings: $e');
      return null;
    }
  }

  /// Store security settings
  Future<void> storeSecuritySettings(SecuritySettings settings) async {
    try {
      final jsonData = jsonEncode(settings.toJson());
      await _securityService.storeSecureData(_securitySettingsKey, jsonData);
      _log('Security settings stored securely');
    } catch (e) {
      _log('Error storing security settings: $e');
      rethrow;
    }
  }

  /// Retrieve security settings
  Future<SecuritySettings?> getSecuritySettings() async {
    try {
      final jsonData = await _securityService.retrieveSecureData(
        _securitySettingsKey,
      );
      if (jsonData == null) return null;

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      return SecuritySettings.fromJson(data);
    } catch (e) {
      _log('Error retrieving security settings: $e');
      return null;
    }
  }

  /// Delete specific data by type and ID
  Future<void> deleteData(SecureDataType dataType, String? id) async {
    try {
      String key;
      switch (dataType) {
        case SecureDataType.userCredentials:
          key = _userCredentialsKey;
          break;
        case SecureDataType.medicalData:
          key = id != null ? '${_medicalDataKey}_$id' : _medicalDataKey;
          break;
        case SecureDataType.appointmentData:
          key = _appointmentDataKey;
          break;
        case SecureDataType.patientData:
          key = id != null ? '${_patientDataKey}_$id' : _patientDataKey;
          break;
        case SecureDataType.prescriptionData:
          key = id != null
              ? '${_prescriptionDataKey}_$id'
              : _prescriptionDataKey;
          break;
        case SecureDataType.apiKeys:
          key = _apiKeysKey;
          break;
        case SecureDataType.tokenData:
          key = _tokenDataKey;
          break;
        case SecureDataType.healthData:
          key = id != null ? '${_healthDataKey}_$id' : _healthDataKey;
          break;
        case SecureDataType.biometricSettings:
          key = _biometricSettingsKey;
          break;
        case SecureDataType.securitySettings:
          key = _securitySettingsKey;
          break;
      }

      await _securityService.deleteSecureData(key);
      _log(
        'Deleted secure data: ${dataType.name}${id != null ? ' ($id)' : ''}',
      );
    } catch (e) {
      _log('Error deleting secure data: $e');
      rethrow;
    }
  }

  /// Clear all user-specific data (for logout)
  Future<void> clearUserData() async {
    try {
      await _securityService.deleteSecureData(_userCredentialsKey);
      await _securityService.deleteSecureData(_tokenDataKey);
      await _securityService.deleteSecureData(_appointmentDataKey);
      _log('User data cleared successfully');
    } catch (e) {
      _log('Error clearing user data: $e');
      rethrow;
    }
  }

  /// Clear all stored data (for app reset)
  Future<void> clearAllData() async {
    try {
      await _securityService.clearAllSecureData();
      _log('All secure data cleared successfully');
    } catch (e) {
      _log('Error clearing all data: $e');
      rethrow;
    }
  }

  /// Verify data integrity for critical data
  Future<bool> verifyDataIntegrity(String data, String expectedHash) async {
    return _securityService.verifyDataIntegrity(data, expectedHash);
  }

  /// Generate hash for data integrity checking
  String generateDataHash(String data) {
    return _securityService.generateSecureHash(data);
  }

  /// Export all stored data for backup (requires authentication)
  Future<String?> exportAllData() async {
    try {
      final exportData = <String, dynamic>{};

      // Export user credentials
      final credentials = await getUserCredentials();
      if (credentials != null) {
        exportData['user_credentials'] = credentials.toJson();
      }

      // Export appointments
      final appointments = await getAppointmentData();
      if (appointments.isNotEmpty) {
        exportData['appointments'] = appointments
            .map((a) => a.toJson())
            .toList();
      }

      // Export API keys
      final apiKeys = await getApiKeys();
      if (apiKeys.isNotEmpty) {
        exportData['api_keys'] = apiKeys;
      }

      // Export token data
      final tokenData = await getTokenData();
      if (tokenData != null) {
        exportData['token_data'] = tokenData.toJson();
      }

      exportData['export_timestamp'] = DateTime.now().toIso8601String();
      exportData['export_version'] = '1.0';

      return jsonEncode(exportData);
    } catch (e) {
      _log('Error exporting data: $e');
      return null;
    }
  }

  /// Get data summary for debugging/monitoring
  Future<Map<String, dynamic>> getDataSummary() async {
    final summary = <String, dynamic>{};

    try {
      summary['user_credentials_exists'] = await getUserCredentials() != null;
      summary['appointment_count'] = (await getAppointmentData()).length;
      summary['api_keys_count'] = (await getApiKeys()).length;
      summary['token_data_exists'] = await getTokenData() != null;
      summary['biometric_settings_exists'] =
          await getBiometricSettings() != null;
      summary['security_settings_exists'] = await getSecuritySettings() != null;
      summary['summary_generated'] = DateTime.now().toIso8601String();
    } catch (e) {
      summary['error'] = e.toString();
    }

    return summary;
  }

  /// Log debug messages
  void _log(String message) {
    if (kDebugMode) {
      print('[SecureDataManager] $message');
    }
  }
}

/// Enum for different types of secure data
enum SecureDataType {
  userCredentials,
  medicalData,
  appointmentData,
  patientData,
  prescriptionData,
  apiKeys,
  tokenData,
  healthData,
  biometricSettings,
  securitySettings,
}

/// Data classes for secure storage
class UserCredentials {

  UserCredentials({
    required this.userId,
    required this.email,
    required this.lastLogin, this.hashedPassword,
    this.metadata = const {},
  });

  factory UserCredentials.fromJson(Map<String, dynamic> json) =>
      UserCredentials(
        userId: json['user_id'] as String,
        email: json['email'] as String,
        hashedPassword: json['hashed_password'] as String?,
        lastLogin: DateTime.parse(json['last_login'] as String),
        metadata: Map<String, String>.from(json['metadata'] as Map? ?? {}),
      );
  final String userId;
  final String email;
  final String? hashedPassword;
  final DateTime lastLogin;
  final Map<String, String> metadata;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'email': email,
    'hashed_password': hashedPassword,
    'last_login': lastLogin.toIso8601String(),
    'metadata': metadata,
  };
}

class MedicalData {

  MedicalData({
    required this.patientId,
    required this.lastUpdated, this.allergies = const [],
    this.medications = const [],
    this.medicalHistory = const [],
    this.vitalSigns = const {},
  });

  factory MedicalData.fromJson(Map<String, dynamic> json) => MedicalData(
    patientId: json['patient_id'] as String,
    allergies: List<String>.from(json['allergies'] as List? ?? []),
    medications: List<String>.from(json['medications'] as List? ?? []),
    medicalHistory: List<String>.from(json['medical_history'] as List? ?? []),
    vitalSigns: Map<String, dynamic>.from(json['vital_signs'] as Map? ?? {}),
    lastUpdated: DateTime.parse(json['last_updated'] as String),
  );
  final String patientId;
  final List<String> allergies;
  final List<String> medications;
  final List<String> medicalHistory;
  final Map<String, dynamic> vitalSigns;
  final DateTime lastUpdated;

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'allergies': allergies,
    'medications': medications,
    'medical_history': medicalHistory,
    'vital_signs': vitalSigns,
    'last_updated': lastUpdated.toIso8601String(),
  };
}

class AppointmentData {

  AppointmentData({
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.scheduledTime,
    required this.status,
    this.notes,
    this.metadata = const {},
  });

  factory AppointmentData.fromJson(Map<String, dynamic> json) =>
      AppointmentData(
        appointmentId: json['appointment_id'] as String,
        patientId: json['patient_id'] as String,
        doctorId: json['doctor_id'] as String,
        scheduledTime: DateTime.parse(json['scheduled_time'] as String),
        status: json['status'] as String,
        notes: json['notes'] as String?,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final DateTime scheduledTime;
  final String status;
  final String? notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
    'appointment_id': appointmentId,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'scheduled_time': scheduledTime.toIso8601String(),
    'status': status,
    'notes': notes,
    'metadata': metadata,
  };
}

class PatientData {

  PatientData({
    required this.patientId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.phoneNumber,
    this.address,
    this.emergencyContact,
    this.personalInfo = const {},
  });

  factory PatientData.fromJson(Map<String, dynamic> json) => PatientData(
    patientId: json['patient_id'] as String,
    name: json['name'] as String,
    dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
    gender: json['gender'] as String,
    phoneNumber: json['phone_number'] as String?,
    address: json['address'] as String?,
    emergencyContact: json['emergency_contact'] as String?,
    personalInfo: Map<String, dynamic>.from(json['personal_info'] as Map? ?? {}),
  );
  final String patientId;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String? phoneNumber;
  final String? address;
  final String? emergencyContact;
  final Map<String, dynamic> personalInfo;

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'name': name,
    'date_of_birth': dateOfBirth.toIso8601String(),
    'gender': gender,
    'phone_number': phoneNumber,
    'address': address,
    'emergency_contact': emergencyContact,
    'personal_info': personalInfo,
  };
}

class PrescriptionData {

  PrescriptionData({
    required this.prescriptionId,
    required this.patientId,
    required this.doctorId,
    required this.medications,
    required this.dosage,
    required this.instructions,
    required this.prescribedDate,
    this.expiryDate,
  });

  factory PrescriptionData.fromJson(Map<String, dynamic> json) =>
      PrescriptionData(
        prescriptionId: json['prescription_id'] as String,
        patientId: json['patient_id'] as String,
        doctorId: json['doctor_id'] as String,
        medications: List<String>.from(json['medications'] as List? ?? []),
        dosage: json['dosage'] as String,
        instructions: json['instructions'] as String,
        prescribedDate: DateTime.parse(json['prescribed_date'] as String),
        expiryDate: json['expiry_date'] != null
            ? DateTime.parse(json['expiry_date'] as String)
            : null,
      );
  final String prescriptionId;
  final String patientId;
  final String doctorId;
  final List<String> medications;
  final String dosage;
  final String instructions;
  final DateTime prescribedDate;
  final DateTime? expiryDate;

  Map<String, dynamic> toJson() => {
    'prescription_id': prescriptionId,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'medications': medications,
    'dosage': dosage,
    'instructions': instructions,
    'prescribed_date': prescribedDate.toIso8601String(),
    'expiry_date': expiryDate?.toIso8601String(),
  };
}

class TokenData {

  TokenData({
    required this.accessToken,
    required this.expiresAt, this.refreshToken,
    this.tokenType = 'Bearer',
    this.scopes = const [],
  });

  factory TokenData.fromJson(Map<String, dynamic> json) => TokenData(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String?,
    expiresAt: DateTime.parse(json['expires_at'] as String),
    tokenType: json['token_type'] as String? ?? 'Bearer',
    scopes: List<String>.from(json['scopes'] as List? ?? []),
  );
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String tokenType;
  final List<String> scopes;

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
    'token_type': tokenType,
    'scopes': scopes,
  };
}

class HealthData {

  HealthData({
    required this.userId,
    required this.lastUpdated, this.vitalSigns = const {},
    this.healthMetrics = const [],
    this.healthScore = const {},
  });

  factory HealthData.fromJson(Map<String, dynamic> json) => HealthData(
    userId: json['user_id'] as String,
    vitalSigns: Map<String, dynamic>.from(json['vital_signs'] as Map? ?? {}),
    healthMetrics: List<String>.from(json['health_metrics'] as List? ?? []),
    healthScore: Map<String, dynamic>.from(json['health_score'] as Map? ?? {}),
    lastUpdated: DateTime.parse(json['last_updated'] as String),
  );
  final String userId;
  final Map<String, dynamic> vitalSigns;
  final List<String> healthMetrics;
  final Map<String, dynamic> healthScore;
  final DateTime lastUpdated;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'vital_signs': vitalSigns,
    'health_metrics': healthMetrics,
    'health_score': healthScore,
    'last_updated': lastUpdated.toIso8601String(),
  };
}

class BiometricSettings {

  BiometricSettings({
    required this.enabled,
    required this.lastUpdated, this.enabledBiometrics = const [],
    this.requireForLogin = true,
    this.requireForSensitiveData = true,
  });

  factory BiometricSettings.fromJson(Map<String, dynamic> json) =>
      BiometricSettings(
        enabled: json['enabled'] as bool,
        enabledBiometrics: List<String>.from(json['enabled_biometrics'] as List? ?? []),
        requireForLogin: json['require_for_login'] as bool? ?? true,
        requireForSensitiveData: json['require_for_sensitive_data'] as bool? ?? true,
        lastUpdated: DateTime.parse(json['last_updated'] as String),
      );
  final bool enabled;
  final List<String> enabledBiometrics;
  final bool requireForLogin;
  final bool requireForSensitiveData;
  final DateTime lastUpdated;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'enabled_biometrics': enabledBiometrics,
    'require_for_login': requireForLogin,
    'require_for_sensitive_data': requireForSensitiveData,
    'last_updated': lastUpdated.toIso8601String(),
  };
}

class SecuritySettings {

  SecuritySettings({
    required this.lastUpdated, this.autoLockEnabled = true,
    this.autoLockTimeout = 300, // 5 minutes
    this.dataEncryptionEnabled = true,
    this.secureBackupEnabled = false,
    this.auditLoggingEnabled = true,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      SecuritySettings(
        autoLockEnabled: json['auto_lock_enabled'] as bool? ?? true,
        autoLockTimeout: json['auto_lock_timeout'] as int? ?? 300,
        dataEncryptionEnabled: json['data_encryption_enabled'] as bool? ?? true,
        secureBackupEnabled: json['secure_backup_enabled'] as bool? ?? false,
        auditLoggingEnabled: json['audit_logging_enabled'] as bool? ?? true,
        lastUpdated: DateTime.parse(json['last_updated'] as String),
      );
  final bool autoLockEnabled;
  final int autoLockTimeout;
  final bool dataEncryptionEnabled;
  final bool secureBackupEnabled;
  final bool auditLoggingEnabled;
  final DateTime lastUpdated;

  Map<String, dynamic> toJson() => {
    'auto_lock_enabled': autoLockEnabled,
    'auto_lock_timeout': autoLockTimeout,
    'data_encryption_enabled': dataEncryptionEnabled,
    'secure_backup_enabled': secureBackupEnabled,
    'audit_logging_enabled': auditLoggingEnabled,
    'last_updated': lastUpdated.toIso8601String(),
  };
}
