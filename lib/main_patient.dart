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
import 'package:flutter/material.dart';
import 'package:flutter_diacare/features/auth/login_screen.dart';

/// Main entry point for the patient application
void main() {
  // Initialize Flutter framework bindings
  WidgetsFlutterBinding.ensureInitialized();
  
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
    return MaterialApp(
      title: 'DiaCare Patient',
      theme: ThemeData(
        // Calming teal color scheme for patients
        primarySwatch: Colors.teal,
        // Adaptive density for different screen sizes
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Use Material Design 3 components
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Start directly at login with patient role
      home: const LoginScreen(role: 'patient'),
    );
  }
}
