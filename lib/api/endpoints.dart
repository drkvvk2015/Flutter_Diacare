/// API Endpoints
/// 
/// Centralized definition of all API endpoints.
/// Provides type-safe endpoint construction with parameters.

/// API endpoint constants for DiaCare backend
class ApiEndpoints {
  ApiEndpoints._(); // Private constructor to prevent instantiation

  // Base paths
  static const String auth = '/auth';
  static const String users = '/users';
  static const String patients = '/patients';
  static const String doctors = '/doctors';
  static const String appointments = '/appointments';
  static const String prescriptions = '/prescriptions';
  static const String health = '/health';
  static const String chat = '/chat';
  static const String payments = '/payments';

  // Authentication endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static const String verifyEmail = '$auth/verify-email';

  // User endpoints
  static const String userProfile = '$users/profile';
  static String userById(String id) => '$users/$id';
  static const String updateProfile = '$users/profile';
  static const String changePassword = '$users/change-password';
  static const String userPreferences = '$users/preferences';

  // Patient endpoints
  static const String patientList = patients;
  static String patientById(String id) => '$patients/$id';
  static const String createPatient = patients;
  static String patientHistory(String id) => '$patients/$id/history';
  static String patientVitals(String id) => '$patients/$id/vitals';
  static String patientMedications(String id) => '$patients/$id/medications';

  // Doctor endpoints
  static const String doctorList = doctors;
  static String doctorById(String id) => '$doctors/$id';
  static String doctorAvailability(String id) => '$doctors/$id/availability';
  static String doctorReviews(String id) => '$doctors/$id/reviews';
  static String doctorSchedule(String id) => '$doctors/$id/schedule';

  // Appointment endpoints
  static const String appointmentList = appointments;
  static String appointmentById(String id) => '$appointments/$id';
  static const String createAppointment = appointments;
  static String updateAppointment(String id) => '$appointments/$id';
  static String cancelAppointment(String id) => '$appointments/$id/cancel';
  static String appointmentsByDoctor(String doctorId) => 
      '$appointments/doctor/$doctorId';
  static String appointmentsByPatient(String patientId) => 
      '$appointments/patient/$patientId';

  // Prescription endpoints
  static const String prescriptionList = prescriptions;
  static String prescriptionById(String id) => '$prescriptions/$id';
  static const String createPrescription = prescriptions;
  static String prescriptionsByPatient(String patientId) => 
      '$prescriptions/patient/$patientId';

  // Health data endpoints
  static const String healthRecords = '$health/records';
  static const String bloodGlucose = '$health/blood-glucose';
  static const String bloodPressure = '$health/blood-pressure';
  static const String anthropometry = '$health/anthropometry';
  static const String steps = '$health/steps';
  static const String heartRate = '$health/heart-rate';
  static String healthSummary(String patientId) => '$health/summary/$patientId';

  // Chat endpoints
  static const String chatList = '$chat/conversations';
  static String chatById(String id) => '$chat/conversations/$id';
  static String chatMessages(String conversationId) => 
      '$chat/conversations/$conversationId/messages';
  static const String sendMessage = '$chat/messages';

  // Payment endpoints
  static const String paymentHistory = '$payments/history';
  static const String createPayment = '$payments/create';
  static const String verifyPayment = '$payments/verify';
  static String paymentStatus(String paymentId) => '$payments/$paymentId/status';
}
