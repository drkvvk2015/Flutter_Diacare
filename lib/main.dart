import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple session model and AuthService using SharedPreferences
class Session {
  final String role;
  final String userName;
  final String loginMethod;

  const Session({
    required this.role,
    required this.userName,
    required this.loginMethod,
  });
}

class AuthService {
  static const _kRole = 'session_role';
  static const _kUserName = 'session_user_name';
  static const _kLoginMethod = 'session_login_method';

  Future<void> saveSession(Session s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, s.role);
    await prefs.setString(_kUserName, s.userName);
    await prefs.setString(_kLoginMethod, s.loginMethod);
  }

  Future<Session?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_kRole);
    final name = prefs.getString(_kUserName);
    final method = prefs.getString(_kLoginMethod);
    if (role != null && name != null && method != null) {
      return Session(role: role, userName: name, loginMethod: method);
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRole);
    await prefs.remove(_kUserName);
    await prefs.remove(_kLoginMethod);
  }
}

final _auth = AuthService();

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // small delay for splash feel
    await Future.delayed(const Duration(milliseconds: 600));
    final session = await _auth.restoreSession();
    if (!mounted) return;
    if (session != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SimpleDashboardScreen(
            role: session.role,
            userName: session.userName,
            loginMethod: session.loginMethod,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SimpleRoleSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading DiaCare...'),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // Loads .env file
  // Example usage: print(dotenv.env['API_URL']);
  runApp(const DiaCareApp());
}

class DiaCareApp extends StatelessWidget {
  const DiaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaCare',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SimpleRoleSelectionScreen extends StatelessWidget {
  const SimpleRoleSelectionScreen({super.key});

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
    required String role,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SimpleLoginScreen(role: role)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: color[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color[700]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color[700], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo and Title
              Column(
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.teal[700],
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DiaCare',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A5D5D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete Diabetes Care Platform',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Role Selection Cards
              const Text(
                'Select Your Role',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A5D5D),
                ),
              ),
              const SizedBox(height: 32),

              // Doctor Card
              _buildRoleCard(
                context: context,
                icon: Icons.medical_services,
                title: 'Doctor',
                subtitle: 'Manage patients and consultations',
                color: Colors.blue,
                role: 'doctor',
              ),
              const SizedBox(height: 16),

              // Patient Card
              _buildRoleCard(
                context: context,
                icon: Icons.person,
                title: 'Patient',
                subtitle: 'Track health and book appointments',
                color: Colors.green,
                role: 'patient',
              ),
              const SizedBox(height: 16),

              // Admin Card
              _buildRoleCard(
                context: context,
                icon: Icons.admin_panel_settings,
                title: 'Administrator',
                subtitle: 'System management and oversight',
                color: Colors.orange,
                role: 'admin',
              ),
              const SizedBox(height: 16),

              // Pharmacy Card
              _buildRoleCard(
                context: context,
                icon: Icons.local_pharmacy,
                title: 'Pharmacy',
                subtitle: 'Manage prescriptions and inventory',
                color: Colors.purple,
                role: 'pharmacy',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key, required this.role});

  final String role;

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _error;
  bool _loading = false;
  bool _socialLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Basic validation
      if (emailController.text.trim().isEmpty ||
          passwordController.text.trim().isEmpty) {
        throw Exception('Please enter both email and password');
      }

      if (!emailController.text.contains('@')) {
        throw Exception('Please enter a valid email address');
      }

      // Simulate authentication delay
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate to dashboard
      final name = emailController.text.split('@')[0];
      await _auth.saveSession(
        Session(role: widget.role, userName: name, loginMethod: 'Email'),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SimpleDashboardScreen(
            role: widget.role,
            userName: name,
            loginMethod: 'Email',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _socialLoading = true;
      _error = null;
    });

    try {
      // Simulate Google Sign-In process
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate to dashboard with Google user info
      await _auth.saveSession(
        const Session(
          role: '', // will be set to actual below
          userName: 'Google User',
          loginMethod: 'Google',
        ),
      );
      // Overwrite with correct role; constructing directly to avoid double write complexity.
      await _auth.saveSession(
        Session(
          role: widget.role,
          userName: 'Google User',
          loginMethod: 'Google',
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SimpleDashboardScreen(
            role: widget.role,
            userName: 'Google User',
            loginMethod: 'Google',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Google Sign-In failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _socialLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _socialLoading = true;
      _error = null;
    });

    try {
      // Simulate Facebook Sign-In process
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate to dashboard with Facebook user info
      await _auth.saveSession(
        Session(
          role: widget.role,
          userName: 'Facebook User',
          loginMethod: 'Facebook',
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SimpleDashboardScreen(
            role: widget.role,
            userName: 'Facebook User',
            loginMethod: 'Facebook',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Facebook Sign-In failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _socialLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _socialLoading = true;
      _error = null;
    });

    try {
      // Simulate Apple Sign-In process
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate to dashboard with Apple user info
      await _auth.saveSession(
        Session(
          role: widget.role,
          userName: 'Apple User',
          loginMethod: 'Apple',
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SimpleDashboardScreen(
            role: widget.role,
            userName: 'Apple User',
            loginMethod: 'Apple',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Apple Sign-In failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _socialLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.role.toUpperCase()} LOGIN',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185A9D),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Social Media Login Buttons
                    const Text(
                      'Quick Login with Social Media',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF185A9D),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                        ),
                        onPressed: _socialLoading ? null : _signInWithGoogle,
                        icon: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://developers.google.com/identity/images/g-logo.png',
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        label: const Text('Continue with Google'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Facebook Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _socialLoading ? null : _signInWithFacebook,
                        icon: const Icon(Icons.facebook, size: 20),
                        label: const Text('Continue with Facebook'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Apple Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _socialLoading ? null : _signInWithApple,
                        icon: const Icon(Icons.apple, size: 20),
                        label: const Text('Continue with Apple'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Email/Password Login
                    const Text(
                      'Login with Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF185A9D),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185A9D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _loading ? null : _signIn,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('LOGIN WITH EMAIL'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Registration Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'New to DiaCare? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RegistrationScreen(role: widget.role),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF185A9D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_socialLoading) ...[
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Authenticating...'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleDashboardScreen extends StatelessWidget {
  const SimpleDashboardScreen({
    super.key,
    required this.role,
    this.userName,
    this.loginMethod,
  });

  final String? loginMethod;
  final String role;
  final String? userName;

  Widget _buildRoleSpecificContent(BuildContext context) {
    switch (role.toLowerCase().trim()) {
      case 'doctor':
        return _buildDoctorDashboard(context);
      case 'patient':
        return _buildPatientDashboard(context);
      case 'admin':
      case 'administrator':
        return _buildAdminDashboard(context);
      case 'pharmacy':
        return _buildPharmacyDashboard(context);
      default:
        return _buildDefaultDashboard(context);
    }
  }

  Widget _buildDoctorDashboard(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildFeatureCard(
          icon: Icons.people,
          title: 'My Patients',
          subtitle: '24 Active',
          color: Colors.blue,
          onTap: () => _showFeature(context, 'Patient Management'),
        ),
        _buildFeatureCard(
          icon: Icons.calendar_today,
          title: 'Appointments',
          subtitle: '8 Today',
          color: Colors.green,
          onTap: () => _showFeature(context, 'Appointment Schedule'),
        ),
        _buildFeatureCard(
          icon: Icons.video_call,
          title: 'Telemedicine',
          subtitle: '3 Pending',
          color: Colors.orange,
          onTap: () => _showFeature(context, 'Video Consultations'),
        ),
        _buildFeatureCard(
          icon: Icons.assignment,
          title: 'Prescriptions',
          subtitle: 'Write New',
          color: Colors.purple,
          onTap: () => _showFeature(context, 'Digital Prescriptions'),
        ),
        _buildFeatureCard(
          icon: Icons.analytics,
          title: 'Analytics',
          subtitle: 'View Reports',
          color: Colors.indigo,
          onTap: () => _showFeature(context, 'Patient Analytics'),
        ),
        _buildFeatureCard(
          icon: Icons.medical_services,
          title: 'Diagnostics',
          subtitle: '12 Results',
          color: Colors.teal,
          onTap: () => _showFeature(context, 'Lab Results'),
        ),
      ],
    );
  }

  Widget _buildPatientDashboard(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildFeatureCard(
          icon: Icons.favorite,
          title: 'Health Stats',
          subtitle: 'View Progress',
          color: Colors.red,
          onTap: () => _showFeature(context, 'Health Monitoring'),
        ),
        _buildFeatureCard(
          icon: Icons.calendar_today,
          title: 'Book Appointment',
          subtitle: 'Find Doctors',
          color: Colors.blue,
          onTap: () => _showFeature(context, 'Appointment Booking'),
        ),
        _buildFeatureCard(
          icon: Icons.folder,
          title: 'Medical Records',
          subtitle: 'View History',
          color: Colors.green,
          onTap: () => _showFeature(context, 'Medical History'),
        ),
        _buildFeatureCard(
          icon: Icons.local_pharmacy,
          title: 'Medications',
          subtitle: '3 Active',
          color: Colors.purple,
          onTap: () => _showFeature(context, 'Medication Tracker'),
        ),
        _buildFeatureCard(
          icon: Icons.fitness_center,
          title: 'Exercise Plan',
          subtitle: 'Stay Fit',
          color: Colors.orange,
          onTap: () => _showFeature(context, 'Fitness Tracking'),
        ),
        _buildFeatureCard(
          icon: Icons.chat,
          title: 'Ask Doctor',
          subtitle: 'Quick Chat',
          color: Colors.teal,
          onTap: () => _showFeature(context, 'Chat with Doctor'),
        ),
      ],
    );
  }

  Widget _buildAdminDashboard(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildFeatureCard(
          icon: Icons.dashboard,
          title: 'System Monitor',
          subtitle: 'All Systems OK',
          color: Colors.indigo,
          onTap: () => _showFeature(context, 'System Monitoring'),
        ),
        _buildFeatureCard(
          icon: Icons.people,
          title: 'User Management',
          subtitle: '1,245 Users',
          color: Colors.blue,
          onTap: () => _showFeature(context, 'User Administration'),
        ),
        _buildFeatureCard(
          icon: Icons.security,
          title: 'Security Center',
          subtitle: 'No Threats',
          color: Colors.red,
          onTap: () => _showFeature(context, 'Security Management'),
        ),
        _buildFeatureCard(
          icon: Icons.bar_chart,
          title: 'Analytics',
          subtitle: 'View Reports',
          color: Colors.green,
          onTap: () => _showFeature(context, 'System Analytics'),
        ),
        _buildFeatureCard(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'Configure System',
          color: Colors.grey,
          onTap: () => _showFeature(context, 'System Settings'),
        ),
        _buildFeatureCard(
          icon: Icons.backup,
          title: 'Backups',
          subtitle: 'Last: 2 hrs ago',
          color: Colors.orange,
          onTap: () => _showFeature(context, 'Data Backup'),
        ),
      ],
    );
  }

  Widget _buildPharmacyDashboard(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildFeatureCard(
          icon: Icons.inventory,
          title: 'Inventory',
          subtitle: '1,240 Items',
          color: Colors.blue,
          onTap: () => _showFeature(context, 'Medicine Inventory'),
        ),
        _buildFeatureCard(
          icon: Icons.receipt,
          title: 'New Orders',
          subtitle: '15 Pending',
          color: Colors.green,
          onTap: () => _showFeature(context, 'Order Management'),
        ),
        _buildFeatureCard(
          icon: Icons.payment,
          title: 'Payments',
          subtitle: 'Process Bills',
          color: Colors.orange,
          onTap: () => _showFeature(context, 'Payment Processing'),
        ),
        _buildFeatureCard(
          icon: Icons.local_shipping,
          title: 'Deliveries',
          subtitle: '8 In Transit',
          color: Colors.purple,
          onTap: () => _showFeature(context, 'Delivery Tracking'),
        ),
        _buildFeatureCard(
          icon: Icons.qr_code_scanner,
          title: 'Scan Prescription',
          subtitle: 'Quick Process',
          color: Colors.teal,
          onTap: () => _showFeature(context, 'Prescription Scanner'),
        ),
        _buildFeatureCard(
          icon: Icons.trending_up,
          title: 'Sales Report',
          subtitle: 'View Trends',
          color: Colors.indigo,
          onTap: () => _showFeature(context, 'Sales Analytics'),
        ),
      ],
    );
  }

  Widget _buildDefaultDashboard(BuildContext context) {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'Welcome to DiaCare',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your role is not recognized (received: \"$role\").\nPlease return and select a role again.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SimpleRoleSelectionScreen(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to role selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeature(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text(
          'This feature will be available in the next update.\n\nCurrent capabilities:\n• User authentication ✅\n• Social media login ✅\n• Role-based access ✅\n• Dashboard navigation ✅',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'doctor':
        return Icons.medical_services;
      case 'patient':
        return Icons.person;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'pharmacy':
        return Icons.local_pharmacy;
      default:
        return Icons.help;
    }
  }

  Color _getLoginMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'google':
        return const Color(0xFF4285F4);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'apple':
        return Colors.black;
      case 'email':
        return const Color(0xFF185A9D);
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${role.toUpperCase()} DASHBOARD'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _auth.clearSession();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const SimpleRoleSelectionScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[50]!, Colors.teal[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.teal[700],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      _getRoleIcon(role),
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName != null
                              ? 'Hello, ${userName!}'
                              : 'Welcome to DiaCare!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${role.toUpperCase()} DASHBOARD',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.teal[600],
                              ),
                            ),
                            if (loginMethod != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getLoginMethodColor(loginMethod!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  loginMethod!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Role-specific dashboard content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildRoleSpecificContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.role});

  final String role;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _error;
  bool _loading = false;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Validation
      if (fullNameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          passwordController.text.trim().isEmpty ||
          confirmPasswordController.text.trim().isEmpty) {
        throw Exception('Please fill in all required fields');
      }

      if (!emailController.text.contains('@')) {
        throw Exception('Please enter a valid email address');
      }

      if (passwordController.text.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      if (passwordController.text != confirmPasswordController.text) {
        throw Exception('Passwords do not match');
      }

      if (widget.role == 'doctor' && licenseController.text.trim().isEmpty) {
        throw Exception('Medical license number is required for doctors');
      }

      // Simulate registration delay
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Auto-login: save session and navigate to dashboard
      final name = (fullNameController.text.trim().isNotEmpty)
          ? fullNameController.text.trim()
          : emailController.text.split('@')[0];
      await _auth.saveSession(
        Session(role: widget.role, userName: name, loginMethod: 'Email'),
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SimpleDashboardScreen(
            role: widget.role,
            userName: name,
            loginMethod: 'Email',
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'doctor':
        return Icons.medical_services;
      case 'patient':
        return Icons.person;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'pharmacy':
        return Icons.local_pharmacy;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role.toUpperCase()} REGISTRATION'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(widget.role),
                      size: 64,
                      color: Colors.teal[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join DiaCare as ${widget.role.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF185A9D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (widget.role == 'doctor') ...[
                      TextFormField(
                        controller: licenseController,
                        decoration: InputDecoration(
                          labelText: 'Medical License Number',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password (min 6 characters)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185A9D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('CREATE ACCOUNT'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Color(0xFF185A9D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
