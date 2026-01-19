import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // Removed Facebook login
// import 'package:speech_to_text/speech_to_text.dart' as stt; // No longer needed, handled by VoiceTextFormField
import '../../widgets/voice_text_field.dart';
import '../../screens/dashboard_screen.dart';

      // Get authentication details
import '../../screens/patient_dashboard_screen.dart';

      // Create credential with idToken and accessToken
import '../../screens/admin_dashboard_screen.dart';
import '../../screens/pharmacy_dashboard_screen.dart';
import '../../screens/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? role;

  const LoginScreen({super.key, this.role});
  @override
  State<LoginScreen> createState() => _LoginScreenState();

}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;
  String? error;
  bool showPassword = false;
  String selectedRole = 'doctor'; // Default role

  @override
  void initState() {
    super.initState();
    // Use the role from constructor parameter if provided
    if (widget.role != null) {
      selectedRole = widget.role!;
    } else {
      // Get the selected role from route arguments
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null && args['role'] != null) {
          setState(() {
            selectedRole = args['role'];
          });
        }
      });
    }
  }

  // Fixed admin credentials
  static const String _adminEmail = 'admin@admin.com';
  static const String _adminPassword = 'Admin@123';

  void _login() async {
    setState(() {
      loading = true;
      error = null;
    });
    
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    
    try {
      // Check for admin login with fixed credentials
      if (selectedRole == 'admin') {
        if (email == _adminEmail && password == _adminPassword) {
          // Admin login successful with fixed credentials
          if (!mounted) return;
          _navigateToRoleDashboard('admin');
          return;
        } else {
          // Invalid admin credentials
          setState(() {
            error = 'Invalid administrator credentials';
            loading = false;
          });
          return;
        }
      }
      
      // Regular Firebase authentication for other roles
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'role': selectedRole,
            'email': cred.user!.email,
            'lastLogin': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

      if (!mounted) return;
      _navigateToRoleDashboard(selectedRole);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _navigateToRoleDashboard(String role) {
    switch (role) {
      case 'patient':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientDashboardScreen()),
        );
        break;
      case 'admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        break;
      case 'pharmacy':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PharmacyDashboardScreen()),
        );
        break;
      default: // doctor
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // Use GoogleSignIn singleton instance
      // Initialize with clientId for Web support
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId:
                  '603628370602-j5ejajnde0nd5d99hfq8g3tpd6obfr39.apps.googleusercontent.com',
            )
          : GoogleSignIn();
      
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        setState(() {
          loading = false;
          error = 'Google sign-in aborted';
        });
        return;
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      String userRole = doc.data()?['role'] ?? selectedRole;

      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': userCredential.user!.displayName ?? '',
              'email': userCredential.user!.email ?? '',
              'role': selectedRole,
              'createdAt': FieldValue.serverTimestamp(),
              'loginMethod': 'google',
            });
        userRole = selectedRole;
      }

      if (mounted) {
        _navigateToRoleDashboard(userRole);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // startListening and stopListening removed, handled by VoiceTextFormField

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Consistent with RoleSelectionScreen)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027), // Deep Space Blue
                  Color(0xFF203A43), // Cyber Teal
                  Color(0xFF2C5364), // Horizon Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Animated Bubbles for depth
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withValues(alpha:0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withValues(alpha:0.2),
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(36.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha:0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated logo
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.tealAccent.withValues(alpha:0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.tealAccent.withValues(alpha:0.2),
                              radius: 48,
                              child: const Icon(
                                Icons.medical_services_rounded,
                                size: 48,
                                color: Colors.tealAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'DiaCare',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha:0.8),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Wrap inputs in Theme to enforce dark mode text styles
                        Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: Colors.black.withValues(alpha:0.2),
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIconColor: Colors.tealAccent,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha:0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.tealAccent,
                                ),
                              ),
                            ),
                            textSelectionTheme: const TextSelectionThemeData(
                              cursorColor: Colors.tealAccent,
                            ),
                            textTheme: const TextTheme(
                              bodyLarge: TextStyle(color: Colors.white),
                              bodyMedium: TextStyle(color: Colors.white),
                            ),
                          ),
                          child: Column(
                            children: [
                              VoiceTextFormField(
                                controller: emailController,
                                labelText: 'Email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              VoiceTextFormField(
                                controller: passwordController,
                                labelText: 'Password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (error != null) ...[
                          Text(
                            error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 12),
                        loading
                            ? const CircularProgressIndicator(
                                color: Colors.tealAccent,
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent,
                                    foregroundColor: Colors.teal[900],
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 8,
                                    shadowColor:
                                        Colors.tealAccent.withValues(alpha:0.4),
                                  ),
                                  onPressed: _login,
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 18),
                        // Registration Logic
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha:0.1)),
                            color: Colors.white.withValues(alpha:0.05),
                          ),
                          child: TextButton.icon(
                            icon: const Icon(
                              Icons.person_add_alt_1,
                              color: Colors.white,
                              size: 24,
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              // final messenger = ScaffoldMessenger.of(context); // Removed unused variable
                              final role = await showDialog<String>(
                                context: context,
                                builder: (dialogCtx) {
                                  return Dialog(
                                    backgroundColor:
                                        const Color(0xFF203A43).withValues(alpha:0.9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: Colors.tealAccent.withValues(alpha:0.5),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.person_add_alt_1,
                                            size: 40,
                                            color: Colors.tealAccent,
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Register as',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          _buildDialogOption(
                                            dialogCtx,
                                            'Doctor',
                                            Icons.medical_services,
                                            Colors.blueAccent,
                                            'doctor',
                                          ),
                                          _buildDialogOption(
                                            dialogCtx,
                                            'Patient',
                                            Icons.person,
                                            Colors.greenAccent,
                                            'patient',
                                          ),
                                          _buildDialogOption(
                                            dialogCtx,
                                            'Pharmacy',
                                            Icons.local_pharmacy,
                                            Colors.purpleAccent,
                                            'pharmacy',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              if (role != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RegistrationScreen(userType: role),
                                  ),
                                );
                              }
                            },
                            label: const Text(
                              'New User? Register',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Feature coming soon')),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.white.withValues(alpha:0.6)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Social login
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.white.withValues(alpha:0.2)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha:0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.white.withValues(alpha:0.2)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Google Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Google Sign In'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: loading ? null : _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.tealAccent.withValues(alpha:0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                selectedRole == 'doctor'
                                    ? Icons.medical_services
                                    : selectedRole == 'patient'
                                        ? Icons.person
                                        : selectedRole == 'admin'
                                            ? Icons.admin_panel_settings
                                            : Icons.local_pharmacy,
                                color: Colors.tealAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Logging in as: ${selectedRole[0].toUpperCase()}${selectedRole.substring(1)}',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogOption(BuildContext context, String title, IconData icon,
      Color color, String role) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      onTap: () => Navigator.pop(context, role),
      hoverColor: Colors.white.withValues(alpha:0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}



