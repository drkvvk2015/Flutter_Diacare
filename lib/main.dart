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
library;
// import 'package:firebase_app_check/firebase_app_check.dart'; // Disabled for development
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/appointment_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
// State management providers
import 'providers/user_provider.dart';
import 'router.dart';
import 'services/admob_service.dart';
import 'services/hive_service.dart';
import 'themes/app_theme.dart';

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

  // Initialize Hive for local caching
  await initHive();

  // NOTE: App Check disabled for development. Enable for production.
  // await FirebaseAppCheck.instance.activate(
  //   webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY'),
  //   androidProvider: AndroidProvider.playIntegrity,
  //   appleProvider: AppleProvider.appAttest,
  // );

  // Initialize AdMob (only on mobile platforms)
  if (!kIsWeb) {
    await AdMobService().initialize();
  }

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
            // Use AppRouter for all route generation
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
