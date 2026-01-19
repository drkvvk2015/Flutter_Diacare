/// Application Constants
/// 
/// Centralized constants used throughout the application.
/// Includes app configuration, limits, and default values.

/// Application-wide constants
class AppConstants {
  AppConstants._(); // Private constructor

  // App Information
  static const String appName = 'DiaCare';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API Configuration
  static const String apiBaseUrl = 'https://api.diacare.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String biometricEnabledKey = 'biometric_enabled';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 50; // MB
  static const int maxImageCacheObjects = 200;
  static const Duration imageCacheExpiration = Duration(days: 7);

  // Health Data Limits
  static const double minHeartRate = 40.0;
  static const double maxHeartRate = 220.0;
  static const double minBPSystolic = 70.0;
  static const double maxBPSystolic = 250.0;
  static const double minBPDiastolic = 40.0;
  static const double maxBPDiastolic = 150.0;
  static const double minBloodGlucose = 20.0;
  static const double maxBloodGlucose = 600.0;
  static const double minWeight = 10.0;
  static const double maxWeight = 300.0;
  static const double minHeight = 50.0;
  static const double maxHeight = 250.0;

  // Blood Glucose Ranges (mg/dL)
  static const double normalFastingGlucoseMin = 70.0;
  static const double normalFastingGlucoseMax = 100.0;
  static const double preDiabeticFastingGlucoseMax = 125.0;
  static const double normalPostMealGlucoseMax = 140.0;

  // Blood Pressure Categories
  static const int normalBPSystolicMax = 120;
  static const int normalBPDiastolicMax = 80;
  static const int elevatedBPSystolicMax = 129;
  static const int stage1HypertensionSystolicMax = 139;
  static const int stage1HypertensionDiastolicMax = 89;

  // BMI Categories
  static const double underweightBMIMax = 18.5;
  static const double normalBMIMax = 24.9;
  static const double overweightBMIMax = 29.9;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Debounce Durations
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration inputDebounce = Duration(milliseconds: 300);

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];

  // Appointment
  static const Duration appointmentSlotDuration = Duration(minutes: 30);
  static const Duration appointmentReminderBefore = Duration(hours: 1);
  static const Duration appointmentCancellationWindow = Duration(hours: 24);

  // Chat
  static const int maxMessageLength = 1000;
  static const int chatHistoryLimit = 100;
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);

  // Video Call
  static const int videoCallQuality = 720;
  static const int videoCallFrameRate = 30;
  static const Duration videoCallTimeout = Duration(minutes: 60);

  // Notification
  static const Duration notificationDisplayDuration = Duration(seconds: 3);
  static const int maxNotificationsToShow = 50;

  // Security
  static const int minPasswordLength = 8;
  static const int maxFailedLoginAttempts = 5;
  static const Duration accountLockoutDuration = Duration(minutes: 30);
  static const Duration sessionTimeout = Duration(hours: 24);

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss';

  // Regular Expressions
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phoneRegex = r'^\+?[\d\s\-\(\)]+$';
  static const String passwordRegex = 
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$';

  // Error Messages
  static const String networkError = 'Network connection failed';
  static const String serverError = 'Server error occurred';
  static const String unknownError = 'An unknown error occurred';
  static const String authError = 'Authentication failed';
  static const String permissionError = 'Permission denied';
  static const String notFoundError = 'Resource not found';
  static const String validationError = 'Validation failed';

  // Success Messages
  static const String saveSuccess = 'Saved successfully';
  static const String updateSuccess = 'Updated successfully';
  static const String deleteSuccess = 'Deleted successfully';
  static const String sendSuccess = 'Sent successfully';
}
