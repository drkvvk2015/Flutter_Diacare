/// DiaCare Patient Application Entry Point
/// 
/// This is a specialized entry point for the patient-focused version of DiaCare.
/// Provides a user-friendly interface optimized for patients managing their health.
/// 
/// Features:
/// - Direct login for patients
/// - Patient-specific UI theme (Teal color scheme)
/// - Simplified navigation for non-medical users
library;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/appointment_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'router_patient.dart';
import 'screens/patient_login_screen.dart';
import 'services/admob_service.dart';
import 'services/hive_service.dart';
import 'themes/app_theme.dart';

/// Main entry point for the patient application
void main() async {
  // Initialize Flutter framework bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (API keys, secrets, etc.)
  await dotenv.load();
  
  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive for local caching
  await initHive();

  // Initialize AdMob (only on mobile platforms)
  if (!kIsWeb) {
    await AdMobService().initialize();
  }
  
  // Launch the patient-specific application
  runApp(const DiaCarePatientApp());
}

/// Root widget for the patient-focused DiaCare application
/// 
/// Configured specifically for patients with:
/// - Teal color scheme for a calming, health-focused appearance
/// - Material Design 3 components
/// - Direct login with patient role pre-selected
class DiaCarePatientApp extends StatelessWidget {
  const DiaCarePatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'DiaCare Patient',
            theme: AppTheme.lightTheme().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
              ),
            ),
            darkTheme: AppTheme.darkTheme().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            // Start directly at patient login
            home: const PatientLoginScreen(),
            // Use PatientAppRouter for navigation (no role selection)
            onGenerateRoute: PatientAppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
