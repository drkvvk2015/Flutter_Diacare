import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/glassmorphic_card.dart';
import '../widgets/voice_text_field.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({required this.userType, super.key});
  final String userType;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  /// Convert Firebase Auth error codes to user-friendly messages
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please try logging in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password registration is not enabled.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Registration failed: $code';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final role = widget.userType.toLowerCase();
    
    debugPrint('=== REGISTRATION ATTEMPT ===');
    debugPrint('Email: $email');
    debugPrint('Name: $name');
    debugPrint('Role: $role');
    
    try {
      // Create user in Firebase Auth
      debugPrint('Creating Firebase Auth user...');
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Firebase Auth user created: ${cred.user?.uid}');

      // Create user document in Firestore
      if (cred.user != null) {
        debugPrint('Creating Firestore document...');
        
        // Base user data
        final userData = <String, dynamic>{
          'uid': cred.user!.uid,
          'email': email,
          'displayName': name,
          'name': name, // Also save as 'name' for compatibility with appointment queries
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        };
        
        // Add doctor-specific fields if registering as doctor
        if (role == 'doctor') {
          userData.addAll({
            'specialty': 'General', // Default specialty
            'availability': 'Available',
            'fee': 500.0, // Default consultation fee
            'rating': 4.0,
            'experience': '1+ years',
            'isVerified': false, // Admin needs to verify
          });
        }
        
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set(userData);
        debugPrint('Firestore document created with role: $role');

        // Update display name in Auth
        await cred.user!.updateDisplayName(name);
        debugPrint('Display name updated');
      }

      debugPrint('=== REGISTRATION SUCCESS ===');
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please log in.')),
        );
      }
    } on FirebaseException catch (e) {
      debugPrint('=== FIREBASE ERROR ===');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      setState(() {
        _error = _getFirebaseAuthErrorMessage(e.code);
      });
    } catch (e, stackTrace) {
      debugPrint('=== REGISTRATION ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Hero(
          tag: 'login-title',
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Text(
              'Register as ${widget.userType}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
              label: 'Registration Form',
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VoiceTextFormField(
                          controller: _nameController,
                          labelText: 'Full Name',
                          prefixIcon: Icons.person,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        VoiceTextFormField(
                          controller: _emailController,
                          labelText: 'Email',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        VoiceTextFormField(
                          controller: _passwordController,
                          labelText: 'Password',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          validator: (v) => v == null || v.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _error != null
                              ? Padding(
                                  key: ValueKey(_error),
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                          title: const Text(
                                            'Registration Error',
                                          ),
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
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _register,
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _loading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Register',
                                      key: ValueKey('registerBtn'),
                                    ),
                            ),
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
      ),
    );
  }
}

