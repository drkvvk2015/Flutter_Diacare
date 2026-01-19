/// Error Messages
/// 
/// Centralized, standardized error messages for consistent user communication.
/// Provides context-aware error messages with proper categorization.

/// Standard error messages for the application
class ErrorMessages {
  ErrorMessages._();

  // ============================================================================
  // Authentication Errors
  // ============================================================================

  static const String authEmailRequired = 'Email is required';
  static const String authEmailInvalid = 'Please enter a valid email address';
  static const String authPasswordRequired = 'Password is required';
  static const String authPasswordTooShort = 'Password must be at least 8 characters';
  static const String authPasswordWeak = 'Password must contain uppercase, lowercase, number, and special character';
  static const String authPasswordMismatch = 'Passwords do not match';
  static const String authLoginFailed = 'Invalid email or password';
  static const String authUserNotFound = 'No account found with this email';
  static const String authWrongPassword = 'Incorrect password';
  static const String authEmailAlreadyInUse = 'An account already exists with this email';
  static const String authWeakPassword = 'Password is too weak. Please choose a stronger password';
  static const String authInvalidEmail = 'Email address is invalid';
  static const String authUserDisabled = 'This account has been disabled';
  static const String authTooManyRequests = 'Too many failed attempts. Please try again later';
  static const String authOperationNotAllowed = 'This sign-in method is not enabled';
  static const String authSessionExpired = 'Your session has expired. Please log in again';
  static const String authUnauthorized = 'You are not authorized to perform this action';

  // ============================================================================
  // Network Errors
  // ============================================================================

  static const String networkNoConnection = 'No internet connection. Please check your network';
  static const String networkTimeout = 'Request timed out. Please try again';
  static const String networkServerError = 'Server error. Please try again later';
  static const String networkBadRequest = 'Invalid request. Please check your input';
  static const String networkUnauthorized = 'Session expired. Please log in again';
  static const String networkForbidden = 'You do not have permission to access this resource';
  static const String networkNotFound = 'The requested resource was not found';
  static const String networkConflict = 'A conflict occurred. Please refresh and try again';
  static const String networkUnknown = 'An unexpected error occurred. Please try again';

  // ============================================================================
  // Form Validation Errors
  // ============================================================================

  static const String formFieldRequired = 'This field is required';
  static const String formInvalidInput = 'Invalid input. Please check your entry';
  static const String formNameRequired = 'Name is required';
  static const String formNameTooShort = 'Name must be at least 2 characters';
  static const String formPhoneRequired = 'Phone number is required';
  static const String formPhoneInvalid = 'Please enter a valid phone number';
  static const String formDateRequired = 'Date is required';
  static const String formDateInvalid = 'Please select a valid date';
  static const String formTimeRequired = 'Time is required';
  static const String formTimeInvalid = 'Please select a valid time';
  static const String formAgeInvalid = 'Please enter a valid age';
  static const String formAgeTooYoung = 'Age must be at least 1 year';
  static const String formAgeTooOld = 'Please enter a valid age';

  // ============================================================================
  // Health Data Errors
  // ============================================================================

  static const String healthDataRequired = 'Health data is required';
  static const String healthDataInvalid = 'Invalid health data. Please check your input';
  static const String healthBloodGlucoseOutOfRange = 'Blood glucose must be between 20-600 mg/dL';
  static const String healthBloodPressureOutOfRange = 'Blood pressure values are out of valid range';
  static const String healthHeartRateOutOfRange = 'Heart rate must be between 40-220 bpm';
  static const String healthWeightOutOfRange = 'Weight must be between 10-300 kg';
  static const String healthHeightOutOfRange = 'Height must be between 50-250 cm';
  static const String healthTemperatureOutOfRange = 'Temperature must be between 35-42°C';
  static const String healthDataSaveFailed = 'Failed to save health data. Please try again';
  static const String healthDataLoadFailed = 'Failed to load health data. Please try again';

  // ============================================================================
  // Appointment Errors
  // ============================================================================

  static const String appointmentDateRequired = 'Appointment date is required';
  static const String appointmentTimeRequired = 'Appointment time is required';
  static const String appointmentDoctorRequired = 'Please select a doctor';
  static const String appointmentReasonRequired = 'Please provide a reason for appointment';
  static const String appointmentBookingFailed = 'Failed to book appointment. Please try again';
  static const String appointmentCancelFailed = 'Failed to cancel appointment. Please try again';
  static const String appointmentNotFound = 'Appointment not found';
  static const String appointmentSlotUnavailable = 'This time slot is no longer available';
  static const String appointmentPastDate = 'Cannot book appointment in the past';
  static const String appointmentTooFarAhead = 'Cannot book appointment more than 3 months in advance';

  // ============================================================================
  // Prescription Errors
  // ============================================================================

  static const String prescriptionNotFound = 'Prescription not found';
  static const String prescriptionLoadFailed = 'Failed to load prescription. Please try again';
  static const String prescriptionCreateFailed = 'Failed to create prescription. Please try again';
  static const String prescriptionUpdateFailed = 'Failed to update prescription. Please try again';
  static const String prescriptionMedicationRequired = 'Please add at least one medication';
  static const String prescriptionDosageRequired = 'Dosage is required';
  static const String prescriptionFrequencyRequired = 'Frequency is required';
  static const String prescriptionDurationRequired = 'Duration is required';

  // ============================================================================
  // Profile Errors
  // ============================================================================

  static const String profileUpdateFailed = 'Failed to update profile. Please try again';
  static const String profileLoadFailed = 'Failed to load profile. Please try again';
  static const String profilePhotoUploadFailed = 'Failed to upload photo. Please try again';
  static const String profilePhotoTooLarge = 'Photo is too large. Maximum size is 5MB';
  static const String profileInvalidFormat = 'Invalid file format. Please use JPG, PNG, or GIF';

  // ============================================================================
  // Payment Errors
  // ============================================================================

  static const String paymentFailed = 'Payment failed. Please try again';
  static const String paymentCancelled = 'Payment was cancelled';
  static const String paymentInsufficientFunds = 'Insufficient funds';
  static const String paymentCardDeclined = 'Card declined. Please use another card';
  static const String paymentInvalidCard = 'Invalid card details';
  static const String paymentProcessingError = 'Error processing payment. Please contact support';

  // ============================================================================
  // File/Media Errors
  // ============================================================================

  static const String fileUploadFailed = 'Failed to upload file. Please try again';
  static const String fileTooLarge = 'File is too large. Maximum size is 10MB';
  static const String fileInvalidFormat = 'Invalid file format';
  static const String fileNotFound = 'File not found';
  static const String fileAccessDenied = 'Access to file denied';
  static const String imageLoadFailed = 'Failed to load image';
  static const String videoLoadFailed = 'Failed to load video';

  // ============================================================================
  // Device/Bluetooth Errors
  // ============================================================================

  static const String deviceNotFound = 'Device not found';
  static const String deviceConnectionFailed = 'Failed to connect to device';
  static const String deviceDisconnected = 'Device disconnected';
  static const String deviceDataReadFailed = 'Failed to read data from device';
  static const String bluetoothDisabled = 'Bluetooth is disabled. Please enable it in settings';
  static const String bluetoothPermissionDenied = 'Bluetooth permission denied';
  static const String deviceNotSupported = 'This device is not supported';

  // ============================================================================
  // Chat/Video Call Errors
  // ============================================================================

  static const String chatLoadFailed = 'Failed to load messages. Please try again';
  static const String chatSendFailed = 'Failed to send message. Please try again';
  static const String callConnectionFailed = 'Failed to connect call. Please check your internet';
  static const String callPermissionDenied = 'Camera or microphone permission denied';
  static const String callEnded = 'Call has ended';
  static const String callBusy = 'User is currently busy';

  // ============================================================================
  // Permission Errors
  // ============================================================================

  static const String permissionCameraDenied = 'Camera permission is required for this feature';
  static const String permissionMicrophoneDenied = 'Microphone permission is required for this feature';
  static const String permissionLocationDenied = 'Location permission is required for this feature';
  static const String permissionStorageDenied = 'Storage permission is required for this feature';
  static const String permissionContactsDenied = 'Contacts permission is required for this feature';
  static const String permissionNotificationsDenied = 'Notification permission is required for this feature';

  // ============================================================================
  // Generic Errors
  // ============================================================================

  static const String genericError = 'Something went wrong. Please try again';
  static const String genericUnknownError = 'An unknown error occurred';
  static const String genericTryAgainLater = 'Please try again later';
  static const String genericContactSupport = 'If the problem persists, please contact support';
  static const String genericMaintenanceMode = 'App is under maintenance. Please try again later';
  static const String genericFeatureNotAvailable = 'This feature is not available yet';
  static const String genericDataNotFound = 'No data found';
  static const String genericLoadFailed = 'Failed to load data. Please try again';
  static const String genericSaveFailed = 'Failed to save. Please try again';
  static const String genericDeleteFailed = 'Failed to delete. Please try again';
  static const String genericUpdateRequired = 'Please update the app to continue';

  // ============================================================================
  // Helper methods
  // ============================================================================

  /// Get a user-friendly error message for Firebase Auth errors
  static String getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return authUserNotFound;
      case 'wrong-password':
        return authWrongPassword;
      case 'email-already-in-use':
        return authEmailAlreadyInUse;
      case 'weak-password':
        return authWeakPassword;
      case 'invalid-email':
        return authInvalidEmail;
      case 'user-disabled':
        return authUserDisabled;
      case 'too-many-requests':
        return authTooManyRequests;
      case 'operation-not-allowed':
        return authOperationNotAllowed;
      default:
        return authLoginFailed;
    }
  }

  /// Get a user-friendly error message for HTTP status codes
  static String getNetworkErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return networkBadRequest;
      case 401:
        return networkUnauthorized;
      case 403:
        return networkForbidden;
      case 404:
        return networkNotFound;
      case 409:
        return networkConflict;
      case 500:
      case 502:
      case 503:
      case 504:
        return networkServerError;
      case 408:
        return networkTimeout;
      default:
        return networkUnknown;
    }
  }

  /// Get a user-friendly error message for permission types
  static String getPermissionErrorMessage(String permissionType) {
    switch (permissionType.toLowerCase()) {
      case 'camera':
        return permissionCameraDenied;
      case 'microphone':
        return permissionMicrophoneDenied;
      case 'location':
        return permissionLocationDenied;
      case 'storage':
        return permissionStorageDenied;
      case 'contacts':
        return permissionContactsDenied;
      case 'notifications':
        return permissionNotificationsDenied;
      default:
        return 'Permission denied for $permissionType';
    }
  }
}

/// Error message builder for dynamic messages
class ErrorMessageBuilder {
  /// Build a field required message
  static String fieldRequired(String fieldName) {
    return '$fieldName is required';
  }

  /// Build a field too short message
  static String fieldTooShort(String fieldName, int minLength) {
    return '$fieldName must be at least $minLength characters';
  }

  /// Build a field too long message
  static String fieldTooLong(String fieldName, int maxLength) {
    return '$fieldName must not exceed $maxLength characters';
  }

  /// Build a value out of range message
  static String valueOutOfRange(String fieldName, num min, num max) {
    return '$fieldName must be between $min and $max';
  }

  /// Build a not found message
  static String notFound(String itemName) {
    return '$itemName not found';
  }

  /// Build a failed operation message
  static String operationFailed(String operation) {
    return 'Failed to $operation. Please try again';
  }

  /// Build a success message
  static String success(String operation) {
    return '$operation completed successfully';
  }
}
