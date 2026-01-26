import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_bridge_service.dart';
import '../widgets/voice_text_field.dart';
import 'patient_dashboard_screen.dart';
import 'registration_screen.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthBridgeService _authBridge = AuthBridgeService();

  // Animation controllers for premium UI
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  // Enhanced state management
  bool _loading = false;
  String? _error;
  String? _successMessage;
  StreamSubscription<dynamic>? _authEventSubscription;
  Timer? _errorTimer;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize AuthBridge service
    _initializeAuthBridge();

    // Start entrance animations
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeAuthBridge() async {
    await _authBridge.initialize();

    // Listen to auth events
    _authEventSubscription = _authBridge.authEvents.listen((event) {
      if (mounted) {
        switch (event.type) {
          case 'sign_in_success':
            _showSuccessMessage('Welcome back, ${event.data['email']}!');
            break;
          case 'sign_in_failure':
            _showErrorMessage(event.data['error'] as String);
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _authEventSubscription?.cancel();
    _errorTimer?.cancel();
    _successTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailPassword() async {
    // Clear previous messages
    _clearMessages();

    setState(() {
      _loading = true;
    });

    // Start pulse animation for loading state
    _pulseController.repeat();

    try {
      final result = await _authBridge.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result.isSuccess && mounted) {
        // Success haptic feedback
        HapticFeedback.mediumImpact();

        Navigator.pushReplacementNamed(context, '/patient_dashboard');
      } else if (result.error != null) {
        _showErrorMessage(result.error!);
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _pulseController.stop();
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    _clearMessages();

    setState(() {
      _loading = true;
    });

    _pulseController.repeat();

    try {
      // Use GoogleSignIn singleton instance (google_sign_in 7.x API)
      final googleSignIn = GoogleSignIn.instance;
      
      // Initialize with clientId for Web support
      if (kIsWeb) {
        await googleSignIn.initialize(
          clientId: '603628370602-j5ejajnde0nd5d99hfq8g3tpd6obfr39.apps.googleusercontent.com',
        );
      } else {
        await googleSignIn.initialize();
      }

      // Authenticate user - throws GoogleSignInException on failure
      final GoogleSignInAccount account;
      try {
        account = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (mounted) {
          setState(() {
            _error = e.code == GoogleSignInExceptionCode.canceled 
                ? 'Google sign-in cancelled.'
                : 'Google sign-in failed: ${e.description}';
            _loading = false;
          });
        }
        return;
      }

      // Get idToken from authentication
      final idToken = account.authentication.idToken;
      
      // Get accessToken from authorization (if needed)
      final authorization = await account.authorizationClient.authorizationForScopes([]);
      final accessToken = authorization?.accessToken;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      
      // Get or create user document in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        // Create new user document as patient
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': userCredential.user!.displayName ?? '',
              'email': userCredential.user!.email ?? '',
              'role': 'patient',
              'createdAt': FieldValue.serverTimestamp(),
              'loginMethod': 'google',
            });
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (_) => const PatientDashboardScreen()),
        );
      }
    } catch (e) {
      _showErrorMessage('Google sign-in failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _pulseController.stop();
      }
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _error = message;
      _successMessage = null;
    });

    // Auto-clear error after 5 seconds
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _error = null;
        });
      }
    });

    // Error haptic feedback
    HapticFeedback.lightImpact();
  }

  void _showSuccessMessage(String message) {
    setState(() {
      _successMessage = message;
      _error = null;
    });

    // Auto-clear success message after 3 seconds
    _successTimer?.cancel();
    _successTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
        });
      }
    });

    // Success haptic feedback
    HapticFeedback.mediumImpact();
  }

  void _clearMessages() {
    setState(() {
      _error = null;
      _successMessage = null;
    });
    _errorTimer?.cancel();
    _successTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeController,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _slideController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Premium header with gradient text
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'Patient Login',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure • Private • Professional',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Enhanced message display
                      if (_successMessage != null) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_error != null) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email/password login fields
                      VoiceTextFormField(
                        controller: _emailController,
                        labelText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => _clearMessages(),
                      ),
                      const SizedBox(height: 16),
                      VoiceTextFormField(
                        controller: _passwordController,
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        onChanged: (v) => _clearMessages(),
                      ),
                      const SizedBox(height: 24),

                      // Premium login button with pulse animation
                      SizedBox(
                        width: double.infinity,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _loading
                                  ? 1.0 + (_pulseController.value * 0.05)
                                  : 1.0,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF43CEA2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  elevation: _loading ? 8 : 4,
                                ),
                                onPressed: _loading
                                    ? null
                                    : _signInWithEmailPassword,
                                child: _loading
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Authenticating...'),
                                        ],
                                      )
                                    : const Text('Login'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Premium Google sign-in button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text('Sign in with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            elevation: 2,
                          ),
                          onPressed: _loading ? null : _signInWithGoogle,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Premium demo credentials section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Demo Credentials',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Email: patient@diacare.com\nPassword: password123',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            _emailController.text =
                                                'patient@diacare.com';
                                            _passwordController.text =
                                                'password123';
                                            HapticFeedback.selectionClick();
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Use Demo',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Registration link
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const RegistrationScreen(
                                  userType: 'Patient',
                                ),
                              ),
                            );
                          },
                          child: const Text('New Patient? Register'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
