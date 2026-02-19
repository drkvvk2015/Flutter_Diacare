/// DiaCare Doctor Application Entry Point
/// 
/// This is a specialized entry point for the doctor-focused version of DiaCare.
/// Provides a streamlined interface specifically for healthcare providers.
/// 
/// Features:
/// - Direct login for doctors
/// - Doctor-specific UI theme (Indigo color scheme)
/// - Optimized workflow for medical professionals
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
import 'router.dart';
import 'screens/role_selection_screen.dart';
import 'services/admob_service.dart';
import 'services/hive_service.dart';
import 'themes/app_theme.dart';

/// Main entry point for the doctor application
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
  
  // Launch the doctor-specific application
  runApp(const DiaCareDoctorApp());
}

/// Root widget for the doctor-focused DiaCare application
/// 
/// Configured specifically for healthcare providers with:
/// - Indigo color scheme for professional appearance
/// - Material Design 3 components
/// - Direct login with doctor role pre-selected
class DiaCareDoctorApp extends StatelessWidget {
  const DiaCareDoctorApp({super.key});

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
            title: 'DiaCare Doctor',
            theme: AppTheme.lightTheme().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
              ),
            ),
            darkTheme: AppTheme.darkTheme().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            // Start at role selection screen
            home: const RoleSelectionScreen(),
            // Use AppRouter for navigation with role selection
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
