// Sign in and get account
import 'package:flutter/material.dart';
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

class LoginScreen extends StatefulWidget {

  const LoginScreen({super.key});
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

  void _login() async {
    // Navigator captured not needed since we call internal navigation helper
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
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
          MaterialPageRoute(builder: (_) => PatientDashboardScreen()),
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
      final GoogleSignInAccount? account = await GoogleSignIn().signIn();
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
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Padding(
              padding: const EdgeInsets.all(36.0),
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
                    child: CircleAvatar(
                      backgroundColor: Colors.teal[50],
                      radius: 48,
                      child: Icon(
                        Icons.medical_services_rounded,
                        size: 48,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'DiaCare',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to your account',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 32),
                  // Email field with glassmorphism effect
                  VoiceTextFormField(
                    controller: emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Password field with glassmorphism effect and voice
                  VoiceTextFormField(
                    controller: passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (error != null) ...[
                    Text(error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                  ],
                  loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[700],
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: Colors.teal[200],
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
                  // Enhanced registration button with gradient and modern style
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.teal[700]!, Colors.teal[400]!],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 28,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final role = await showDialog<String>(
                          context: context,
                          builder: (dialogCtx) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.person_add_alt_1,
                                      size: 40,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Register as',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.medical_services,
                                        color: Colors.teal,
                                      ),
                                      title: const Text(
                                        'Doctor',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'Healthcare professional',
                                      ),
                                      onTap: () =>
                                          Navigator.pop(dialogCtx, 'doctor'),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.person,
                                        color: Colors.blue,
                                      ),
                                      title: const Text(
                                        'Patient',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'Healthcare recipient',
                                      ),
                                      onTap: () =>
                                          Navigator.pop(dialogCtx, 'patient'),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.orange,
                                      ),
                                      title: const Text(
                                        'Administrator',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'System administrator',
                                      ),
                                      onTap: () =>
                                          Navigator.pop(dialogCtx, 'admin'),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.local_pharmacy,
                                        color: Colors.purple,
                                      ),
                                      title: const Text(
                                        'Pharmacy',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: const Text('Pharmacy staff'),
                                      onTap: () =>
                                          Navigator.pop(dialogCtx, 'pharmacy'),
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
                              builder: (_) => RegistrationScreen(role: role),
                            ),
                          );
                        } else {
                          // Optional feedback
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Registration cancelled'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        }
                      },
                      label: const Text(
                        'New User? Register',
                        style: TextStyle(
                          fontSize: 19,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                  const SizedBox(height: 10),
                  // Social login section
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Social login buttons with better styling
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Google Sign In Button
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.only(right: 8),
                          child: ElevatedButton.icon(
                            icon: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Image.asset(
                                'assets/icons/google.png',
                                width: 18,
                                height: 18,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.g_mobiledata,
                                      color: Colors.red[600],
                                      size: 18,
                                    ),
                              ),
                            ),
                            label: const Text('Google'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey[800],
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            onPressed: loading ? null : _signInWithGoogle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Display selected role
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal[200]!),
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
                          color: Colors.teal[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Logging in as: ${selectedRole[0].toUpperCase()}${selectedRole.substring(1)}',
                          style: TextStyle(
                            color: Colors.teal[700],
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
    );
  }
}

class NewPatientRegistrationScreen extends StatefulWidget {
  const NewPatientRegistrationScreen({super.key});

  @override
  State<NewPatientRegistrationScreen> createState() =>
      _NewPatientRegistrationScreenState();
}

class _NewPatientRegistrationScreenState
    extends State<NewPatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController uhidController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageDobController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipController = TextEditingController();
  final TextEditingController bpController = TextEditingController();
  final TextEditingController pulseController = TextEditingController();
  final TextEditingController importController = TextEditingController();
  final TextEditingController historyController = TextEditingController();
  bool loading = false;
  String? error;

  void _registerPatient() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // Save patient data to Firestore (or your backend)
      await FirebaseFirestore.instance.collection('patients').add({
        'uhid': uhidController.text.trim(),
        'name': nameController.text.trim(),
        'ageDob': ageDobController.text.trim(),
        'anthropometry': {
          'height': heightController.text.trim(),
          'weight': weightController.text.trim(),
          'waist': waistController.text.trim(),
          'hip': hipController.text.trim(),
        },
        'vitals': {
          'bp': bpController.text.trim(),
          'pulse': pulseController.text.trim(),
        },
        'history': historyController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientDashboardScreen()),
        );
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Patient Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('UHID'),
              TextFormField(
                controller: uhidController,
                decoration: const InputDecoration(hintText: 'Enter UHID'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              const Text('Name'),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Enter Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              const Text('Age / Date of Birth'),
              TextFormField(
                controller: ageDobController,
                decoration: const InputDecoration(hintText: 'Enter Age or DOB'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              const Text('Extended Anthropometry'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: heightController,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: waistController,
                      decoration: const InputDecoration(
                        labelText: 'Waist (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: hipController,
                      decoration: const InputDecoration(labelText: 'Hip (cm)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.paste),
                label: const Text('Paste/Import Anthropometry'),
                onPressed: () async {
                  final data = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Paste Anthropometry Data'),
                      content: TextField(
                        controller: importController,
                        decoration: const InputDecoration(
                          hintText: 'Paste data here',
                        ),
                        maxLines: 4,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, importController.text),
                          child: const Text('Import'),
                        ),
                      ],
                    ),
                  );
                  if (data != null && data.isNotEmpty) {
                    // Simple parsing logic (expects: height,weight,waist,hip)
                    final parts = data.split(',');
                    if (parts.length >= 4) {
                      heightController.text = parts[0].trim();
                      weightController.text = parts[1].trim();
                      waistController.text = parts[2].trim();
                      hipController.text = parts[3].trim();
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text('Vitals'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: bpController,
                      decoration: const InputDecoration(labelText: 'BP (mmHg)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: pulseController,
                      decoration: const InputDecoration(
                        labelText: 'Pulse (bpm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Import from Device (Coming Soon)'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device integration coming soon!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text('Clinical History'),
              TextFormField(
                controller: historyController,
                decoration: const InputDecoration(
                  hintText: 'Enter Clinical History',
                ),
              ),
              const SizedBox(height: 24),
              if (error != null) ...[
                Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _registerPatient();
                        }
                      },
                      child: const Text('Register Patient'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  final String role;
  const RegistrationScreen({super.key, required this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Role-specific fields
  final TextEditingController licenseController =
      TextEditingController(); // Doctor
  final TextEditingController specialtyController =
      TextEditingController(); // Doctor
  final TextEditingController phoneController =
      TextEditingController(); // All roles
  final TextEditingController addressController =
      TextEditingController(); // All roles
  final TextEditingController organizationController =
      TextEditingController(); // Admin/Pharmacy

  bool loading = false;
  String? error;
  // speech and isListening removed, handled by VoiceTextFormField

  @override
  void initState() {
    super.initState();
  }

  void _register() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Prepare role-specific data
      Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'role': widget.role,
        'createdAt': FieldValue.serverTimestamp(),
        'registrationMethod': 'email',
      };

      // Add role-specific fields
      switch (widget.role) {
        case 'doctor':
          userData.addAll({
            'licenseNumber': licenseController.text.trim(),
            'specialty': specialtyController.text.trim(),
            'verified': false, // Doctors need verification
          });
          break;
        case 'admin':
          userData.addAll({
            'organization': organizationController.text.trim(),
            'adminLevel': 'basic', // Can be upgraded
          });
          break;
        case 'pharmacy':
          userData.addAll({
            'pharmacyName': organizationController.text.trim(),
            'licenseNumber': licenseController.text.trim(),
            'verified': false, // Pharmacies need verification
          });
          break;
        case 'patient':
          userData.addAll({
            'dateOfBirth': '', // Can be added later
            'emergencyContact': '', // Can be added later
          });
          break;
      }

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set(userData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration successful! ${widget.role == 'doctor' || widget.role == 'pharmacy' ? 'Your account is pending verification.' : 'Please log in.'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // startListening and stopListening removed, handled by VoiceTextFormField

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    size: 60,
                    color: Colors.teal[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Register as ${widget.role[0].toUpperCase()}${widget.role.substring(1)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  VoiceTextFormField(
                    controller: nameController,
                    labelText: 'Name',
                    prefixIcon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 16),
                  VoiceTextFormField(
                    controller: emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  VoiceTextFormField(
                    controller: passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Min 6 chars' : null,
                  ),
                  const SizedBox(height: 16),
                  VoiceTextFormField(
                    controller: confirmPasswordController,
                    labelText: 'Confirm Password',
                    prefixIcon: Icons.lock_reset,
                    obscureText: true,
                    validator: (v) => v != passwordController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  VoiceTextFormField(
                    controller: phoneController,
                    labelText: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter phone number' : null,
                  ),
                  const SizedBox(height: 16),
                  VoiceTextFormField(
                    controller: addressController,
                    labelText: 'Address',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter address' : null,
                  ),

                  // Role-specific fields
                  if (widget.role == 'doctor') ...[
                    const SizedBox(height: 16),
                    VoiceTextFormField(
                      controller: licenseController,
                      labelText: 'Medical License Number',
                      prefixIcon: Icons.verified_user_outlined,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter license number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    VoiceTextFormField(
                      controller: specialtyController,
                      labelText: 'Medical Specialty',
                      prefixIcon: Icons.medical_services_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter specialty' : null,
                    ),
                  ],

                  if (widget.role == 'admin') ...[
                    const SizedBox(height: 16),
                    VoiceTextFormField(
                      controller: organizationController,
                      labelText: 'Organization/Hospital Name',
                      prefixIcon: Icons.business_outlined,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter organization name'
                          : null,
                    ),
                  ],

                  if (widget.role == 'pharmacy') ...[
                    const SizedBox(height: 16),
                    VoiceTextFormField(
                      controller: organizationController,
                      labelText: 'Pharmacy Name',
                      prefixIcon: Icons.local_pharmacy_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter pharmacy name' : null,
                    ),
                    const SizedBox(height: 16),
                    VoiceTextFormField(
                      controller: licenseController,
                      labelText: 'Pharmacy License Number',
                      prefixIcon: Icons.verified_user_outlined,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter license number'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (error != null) ...[
                    Text(error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                  ],
                  loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _register();
                              }
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool sent = false;
  String? error;

  void _sendReset() async {
    setState(() {
      error = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      setState(() {
        sent = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_reset, size: 56, color: Colors.teal[700]),
                  const SizedBox(height: 16),
                  const Text(
                    'Reset your password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  VoiceTextFormField(
                    controller: emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter valid email'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (error != null) ...[
                    Text(error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _sendReset();
                        }
                      },
                      child: const Text(
                        'Send Reset Link',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  if (sent)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Password reset link sent!',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
