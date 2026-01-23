/// Application Router
/// 
/// Centralized routing configuration for the DiaCare application.
/// Handles navigation between all screens and manages route generation.
/// 
/// Features:
/// - Type-safe route generation
/// - Dynamic user ID retrieval for authenticated routes
/// - Role-based navigation (doctor, patient, admin)
/// - Fallback to role selection for unknown routes
library;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/admin_dashboard_screen.dart';
import 'screens/appointment_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dev_tools_screen.dart';
import 'screens/device_management_screen.dart';
import 'screens/diagnostic_screen.dart';
import 'screens/doctor_profile_screen.dart';
import 'screens/error_tracking_screen.dart';
import 'screens/health_analytics_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/patient_dashboard_screen.dart';
import 'screens/pharmacy_dashboard_screen.dart';
import 'screens/prescription_screen.dart';
import 'screens/records_screen.dart';
import 'screens/role_selection_screen.dart';
// Core screens
import 'screens/splash_screen.dart';

/// Central router class for application navigation
/// 
/// Implements a route generator pattern that maps route names to screen widgets.
/// Handles authentication state and provides user context to screens that need it.
class AppRouter {
  /// Generates routes based on route settings
  /// 
  /// Args:
  ///   settings: RouteSettings containing route name and optional arguments
  /// 
  /// Returns:
  ///   MaterialPageRoute with the appropriate screen widget
  /// 
  /// Defaults to RoleSelectionScreen for unknown routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Initial splash screen
      case '/splash':
        return MaterialPageRoute<void>(builder: (_) => const SplashScreen());
      
      // Onboarding flow for new users
      case '/onboarding':
        return MaterialPageRoute<void>(builder: (_) => const OnboardingScreen());
      
      // Root route - role selection for new users
      case '/':
        return MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen());
      
      // Authentication route
      case '/login':
        return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
      
      // Doctor profile route - requires authenticated user
      case '/doctorProfile':
        {
          // Get currently authenticated user from Firebase
          final user = FirebaseAuth.instance.currentUser;
          final userId = user?.uid ?? '';
          return MaterialPageRoute<void>(
              builder: (_) => DoctorProfileScreen(userId: userId),);
        }
      
      // Doctor dashboard route
      case '/dashboard':
        return MaterialPageRoute<void>(builder: (_) => const DashboardScreen());
      
      // Patient dashboard route
      case '/patientDashboard':
        return MaterialPageRoute<void>(
            builder: (_) => const PatientDashboardScreen(),);
      
      // Admin dashboard route
      case '/adminDashboard':
        return MaterialPageRoute<void>(builder: (_) => const AdminDashboardScreen());
      
      // Health analytics and reporting route
      case '/healthAnalytics':
        return MaterialPageRoute<void>(builder: (_) => const HealthAnalyticsScreen());
      
      // Medical records viewing route
      case '/records':
        return MaterialPageRoute<void>(builder: (_) => const RecordsScreen());
      
      // Prescription management route
      case '/prescription':
        return MaterialPageRoute<void>(builder: (_) => const PrescriptionScreen());
      
      // Appointment scheduling route - requires authenticated user
      case '/appointments':
        {
          final user = FirebaseAuth.instance.currentUser;
          final userId = user?.uid ?? '';
          // Default role is doctor; can be refined with actual role check
          const userRole = 'doctor';
          return MaterialPageRoute<void>(
              builder: (_) =>
                  AppointmentScreen(userRole: userRole, userId: userId),);
        }
      
      // Device management route (glucose monitors, etc.)
      case '/deviceManagement':
        return MaterialPageRoute<void>(
            builder: (_) => const DeviceManagementScreen(),);
      
      // Diagnostic tools route
      case '/diagnostics':
        return MaterialPageRoute<void>(builder: (_) => const DiagnosticScreen());
      
      // Error tracking route (debug only)
      case '/errorTracking':
        return MaterialPageRoute<void>(builder: (_) => const ErrorTrackingScreen());
      
      // Developer tools route (debug only)
      case '/devTools':
        return MaterialPageRoute<void>(builder: (_) => const DevToolsScreen());
      
      // Chat route
      case '/chat':
        return MaterialPageRoute<void>(builder: (_) => const ChatScreen());
      
      // Pharmacy dashboard route
      case '/pharmacy':
        return MaterialPageRoute<void>(
            builder: (_) => const PharmacyDashboardScreen(),);
      
      // Default fallback for unknown routes
      default:
        return MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen());
    }
  }
}

