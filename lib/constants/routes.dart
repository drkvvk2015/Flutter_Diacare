/// Route Constants
/// 
/// Centralized route names for navigation.

/// Application route names
class Routes {
  Routes._(); // Private constructor

  // Authentication Routes
  static const String roleSelection = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  // Onboarding
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';

  // Main Dashboards
  static const String splash = '/splash';
  static const String dashboard = '/dashboard';
  static const String patientHome = '/patientHome';
  static const String patientDashboard = '/patientDashboard';
  static const String doctorHome = '/doctorHome';
  static const String doctorDashboard = '/doctorDashboard';
  static const String adminHome = '/adminHome';
  static const String adminDashboard = '/adminDashboard';
  static const String pharmacyHome = '/pharmacyHome';
  static const String pharmacyDashboard = '/pharmacy';

  // Profile Routes
  static const String profile = '/profile';
  static const String doctorProfile = '/doctorProfile';
  static const String patientProfile = '/patientProfile';
  static const String editProfile = '/editProfile';
  static const String settings = '/settings';
  static const String securitySettings = '/securitySettings';

  // Health Routes
  static const String healthAnalytics = '/healthAnalytics';
  static const String healthRecords = '/records';
  static const String anthropometry = '/anthropometry';
  static const String bloodPressure = '/bloodPressure';
  static const String bloodGlucose = '/bloodGlucose';
  static const String healthServiceDemo = '/healthServiceDemo';

  // Appointment Routes
  static const String appointments = '/appointments';
  static const String bookAppointment = '/bookAppointment';
  static const String appointmentDetails = '/appointmentDetails';
  static const String quickBookAppointment = '/quickBookAppointment';

  // Prescription Routes
  static const String prescription = '/prescription';
  static const String prescriptionDetails = '/prescriptionDetails';
  static const String createPrescription = '/createPrescription';

  // Patient Management
  static const String patientList = '/patientList';
  static const String patientDetails = '/patientDetails';
  static const String newPatientRegistration = '/newPatientRegistration';

  // Communication Routes
  static const String chat = '/chat';
  static const String chatConversation = '/chatConversation';
  static const String videoCall = '/videoCall';
  static const String callHistory = '/callHistory';

  // Device Management
  static const String deviceManagement = '/deviceManagement';
  static const String devicePairing = '/devicePairing';

  // Diagnostics
  static const String diagnostics = '/diagnostics';
  static const String diagnosticResults = '/diagnosticResults';

  // Payments
  static const String payments = '/payments';
  static const String paymentHistory = '/paymentHistory';
  static const String doctorPayments = '/doctorPayments';

  // Exercise & Wellness
  static const String exerciseLibrary = '/exerciseLibrary';
  static const String exerciseVideo = '/exerciseVideo';

  // Analytics & Monitoring
  static const String analyticsMonitor = '/analyticsMonitor';
  static const String performanceMonitor = '/performanceMonitor';
  static const String stateManagementDemo = '/stateManagementDemo';

  // Error & Info
  static const String error = '/error';
  static const String errorTracking = '/errorTracking';
  static const String notFound = '/404';
  static const String maintenance = '/maintenance';

  // Developer Tools
  static const String devTools = '/devTools';
}
