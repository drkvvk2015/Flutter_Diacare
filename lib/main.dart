/// DiaCare - Main Application Entry Point
/// 
/// This is the primary entry point for the DiaCare diabetes management application.
/// The app provides comprehensive healthcare management features for patients, doctors,
/// and administrators.
/// 
/// Key Features:
/// - Patient health monitoring and analytics
/// - Doctor consultation and appointment management
/// - Admin dashboard for system oversight
/// - Multi-theme support (light/dark modes)
/// - Firebase integration for backend services
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// State management providers
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/notification_provider.dart';

// Application screens
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/patient_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/health_analytics_screen.dart';

/// Main application entry point
/// 
/// Initializes:
/// - Flutter widget bindings
/// - Environment variables from .env file
/// - Firebase with platform-specific configuration
void main() async {
  // Ensure Flutter bindings are initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (API keys, secrets, etc.)
  await dotenv.load();
  
  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Launch the application
  runApp(const DiaCareApp());
}

/// Root widget for the DiaCare application
/// 
/// Wraps the entire application with:
/// - MultiProvider for state management
/// - Theme configuration (light/dark modes)
/// - Routing configuration
/// - Material Design framework
class DiaCareApp extends StatelessWidget {
  const DiaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Register all application-wide state providers
      providers: [
        // User authentication and profile state
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Application theme state (light/dark mode)
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Appointment scheduling and management state
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        // Push notifications and alerts state
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'DiaCare',
            // Light theme configuration
            theme: AppTheme.lightTheme(),
            // Dark theme configuration
            darkTheme: AppTheme.darkTheme(),
            // Current theme mode (system/light/dark)
            themeMode: themeProvider.themeMode,
            // Hide debug banner in production
            debugShowCheckedModeBanner: false,
            // Start at role selection screen
            initialRoute: '/',
            // Application routing configuration
            routes: {
              '/': (context) => const RoleSelectionScreen(),
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/patientDashboard': (context) => const PatientDashboardScreen(),
              '/adminDashboard': (context) => const AdminDashboardScreen(),
              '/healthAnalytics': (context) => const HealthAnalyticsScreen(),
            },
          );
        },
      ),
    );
  }
}
