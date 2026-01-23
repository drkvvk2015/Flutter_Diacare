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
import 'package:flutter/material.dart';
import 'package:flutter_diacare/features/auth/login_screen.dart';

/// Main entry point for the doctor application
void main() {
  // Initialize Flutter framework bindings
  WidgetsFlutterBinding.ensureInitialized();
  
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
    return MaterialApp(
      title: 'DiaCare Doctor',
      theme: ThemeData(
        // Professional indigo color scheme for doctors
        primarySwatch: Colors.indigo,
        // Adaptive density for different screen sizes
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Use Material Design 3 components
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Start directly at login with doctor role
      home: const LoginScreen(role: 'doctor'),
    );
  }
}
