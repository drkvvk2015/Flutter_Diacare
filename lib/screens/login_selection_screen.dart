import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'patient_login_screen.dart';
import 'registration_screen.dart';

Widget _buildLoginColumn(BuildContext context, {required bool isDoctor}) {
  return Column(
    children: [
      Icon(
        isDoctor ? Icons.medical_services : Icons.person,
        size: 48,
        color: isDoctor ? const Color(0xFF185A9D) : const Color(0xFF43CEA2),
      ),
      const SizedBox(height: 8),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDoctor
              ? const Color(0xFF43CEA2)
              : const Color(0xFF185A9D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(isDoctor ? 'Doctor Login' : 'Patient Login'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  isDoctor ? const LoginScreen() : const PatientLoginScreen(),
              settings: RouteSettings(
                arguments: {'role': isDoctor ? 'doctor' : 'patient'},
              ),
            ),
          );
        },
      ),
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RegistrationScreen(userType: isDoctor ? 'Doctor' : 'Patient'),
            ),
          );
        },
        child: Text(
          isDoctor ? 'New Doctor? Register' : 'New Patient? Register',
        ),
      ),
    ],
  );
}

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final cardWidth = isWide ? 500.0 : double.infinity;
          final horizontalPadding = isWide ? 0.0 : 32.0;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'Welcome to DiacarePlus',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Demo Login section removed
                      const SizedBox(height: 32),
                      // --- Regular Login Section ---
                      const Text(
                        'Login as:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      isWide
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildLoginColumn(context, isDoctor: true),
                                _buildLoginColumn(context, isDoctor: false),
                              ],
                            )
                          : Column(
                              children: [
                                _buildLoginColumn(context, isDoctor: true),
                                const SizedBox(height: 24),
                                _buildLoginColumn(context, isDoctor: false),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
