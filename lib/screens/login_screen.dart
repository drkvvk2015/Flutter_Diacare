import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/logger.dart';
import '../widgets/voice_text_field.dart';
import 'dashboard_screen.dart';
import 'patient_dashboard_screen.dart';

/// LoginScreen handles authentication for both doctor and patient roles.
/// The role is passed via navigation arguments and is used for login context.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the role from navigation arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['role'] != null) {
      _role = args['role'] as String;
    }
  }

  /// Sign in with email and password. Navigates to dashboard with role.
  Future<void> _signInWithEmailPassword() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Simulate authentication for testing purposes
      await Future<void>.delayed(const Duration(seconds: 2));

      // Basic validation
      if (emailController.text.trim().isEmpty ||
          passwordController.text.trim().isEmpty) {
        throw Exception('Please enter both email and password');
      }

      if (!emailController.text.contains('@')) {
        throw Exception('Please enter a valid email address');
      }

      if (passwordController.text.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      if (!mounted) return; // context safety
      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
        arguments: {'role': _role},
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Sign in with Google. Navigates to dashboard with role.
  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      UserCredential? userCredential;
      
      if (kIsWeb) {
        // On web, use Firebase Auth popup directly (more reliable)
        userCredential = await _signInWithGoogleWeb();
      } else {
        // On mobile, use google_sign_in package
        userCredential = await _signInWithGoogleMobile();
      }
      
      if (userCredential == null) {
        // User cancelled
        if (mounted) {
          setState(() {
            _error = 'Google sign-in cancelled.';
            _loading = false;
          });
        }
        return;
      }
      
      // Get or create user document in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      String userRole = doc.data()?['role'] as String? ?? _role ?? 'doctor';

      if (!doc.exists) {
        // Create new user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': userCredential.user!.displayName ?? '',
              'email': userCredential.user!.email ?? '',
              'role': _role ?? 'doctor',
              'createdAt': FieldValue.serverTimestamp(),
              'loginMethod': 'google',
            });
        userRole = _role ?? 'doctor';
      }

      if (!mounted) return;
      
      // Navigate to appropriate dashboard based on role
      if (userRole == 'patient') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (_) => const PatientDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      logError('Google sign-in error', e);
      if (mounted) {
        setState(() {
          _error = 'Google sign-in failed: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
  
  /// Web implementation using Firebase Auth popup
  Future<UserCredential?> _signInWithGoogleWeb() async {
    try {
      final googleProvider = GoogleAuthProvider();
      
      // Add scopes
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Set custom parameters for account selection
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });
      
      // Use popup for web
      return FirebaseAuth.instance.signInWithPopup(googleProvider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || 
          e.code == 'cancelled-popup-request' ||
          e.code == 'popup-blocked') {
        return null; // User cancelled
      }
      rethrow;
    }
  }
  
  /// Mobile implementation using google_sign_in package
  Future<UserCredential?> _signInWithGoogleMobile() async {
    final googleSignIn = GoogleSignIn.instance;

    // Optional override. If not provided, plugin uses platform config.
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (serverClientId.isEmpty) {
      await googleSignIn.initialize();
    } else {
      await googleSignIn.initialize(serverClientId: serverClientId);
    }

    // Authenticate user - throws GoogleSignInException on failure
    final GoogleSignInAccount account;
    try {
      account = await googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null; // User cancelled
      }
      throw Exception(e.description ?? 'Google sign-in failed');
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

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cardWidth = isWide ? 420.0 : double.infinity;
        final horizontalPadding = isWide ? 0.0 : 24.0;
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Semantics(
                  label: _role == 'doctor'
                      ? 'Doctor Login Form'
                      : 'Patient Login Form',
                  child: Card(
                    elevation: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Hero(
                            tag: 'login-title',
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFF43CEA2),
                                    Color(0xFF185A9D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Text(
                                _role == 'doctor'
                                    ? 'Doctor Login'
                                    : 'Patient Login',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _error != null
                                ? Padding(
                                    key: ValueKey(_error),
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            title: const Text('Login Error'),
                                            content: Text(_error!),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _error!,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Semantics(
                            label: 'Email Address Field',
                            textField: true,
                            child: VoiceTextFormField(
                              controller: emailController,
                              labelText: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: 'Password Field',
                            textField: true,
                            child: VoiceTextFormField(
                              controller: passwordController,
                              labelText: 'Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Semantics(
                            label: 'Login Button',
                            button: true,
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _loading
                                    ? null
                                    : _signInWithEmailPassword,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login, size: 20),
                                    SizedBox(width: 8),
                                    Text('Login'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: 'Sign in with Google Button',
                            button: true,
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: Hero(
                                  tag: 'google-icon',
                                  child: Image.asset(
                                    'assets/icons/google.png',
                                    height: 24,
                                  ),
                                ),
                                label: const Text('Sign in with Google'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _loading
                                ? Padding(
                                    key: const ValueKey('loading'),
                                    padding: const EdgeInsets.only(top: 32),
                                    child: Center(
                                      child: SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: CircularProgressIndicator(
                                          color: colorScheme.primary,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
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
      },
    );
  }
}
