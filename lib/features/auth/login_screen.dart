import 'package:flutter/material.dart';

enum UserType { doctor, patient, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  UserType _selectedUserType = UserType.doctor;

  void _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    // Simulate authentication (replace with real auth logic)
    await Future.delayed(const Duration(seconds: 2));
    
    bool isValid = false;
    String route = '/dashboard';
    
    // Check credentials based on user type
    switch (_selectedUserType) {
      case UserType.doctor:
        if (_emailController.text == 'doctor@demo.com' &&
            _passwordController.text == 'password123') {
          isValid = true;
          route = '/dashboard';
        }
        break;
      case UserType.patient:
        if (_emailController.text == 'patient@demo.com' &&
            _passwordController.text == 'password123') {
          isValid = true;
          route = '/patient-dashboard';
        }
        break;
      case UserType.admin:
        if (_emailController.text == 'admin@demo.com' &&
            _passwordController.text == 'password123') {
          isValid = true;
          route = '/admin-dashboard';
        }
        break;
    }
    
    if (isValid) {
      if (!mounted) return; // avoid use_build_context_synchronously
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      setState(() {
        _error = 'Invalid credentials for ${_getUserTypeLabel()}';
        _isLoading = false;
      });
    }
  }

  String _getUserTypeLabel() {
    switch (_selectedUserType) {
      case UserType.doctor:
        return 'Doctor';
      case UserType.patient:
        return 'Patient';
      case UserType.admin:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_getUserTypeLabel()} Login')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.local_hospital, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'DiaCare',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // User Type Selector
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Select User Type',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<UserType>(
                        segments: const [
                          ButtonSegment<UserType>(
                            value: UserType.doctor,
                            label: Text('Doctor'),
                            icon: Icon(Icons.medical_services),
                          ),
                          ButtonSegment<UserType>(
                            value: UserType.patient,
                            label: Text('Patient'),
                            icon: Icon(Icons.person),
                          ),
                          ButtonSegment<UserType>(
                            value: UserType.admin,
                            label: Text('Admin'),
                            icon: Icon(Icons.admin_panel_settings),
                          ),
                        ],
                        selected: {_selectedUserType},
                        onSelectionChanged: (Set<UserType> newSelection) {
                          setState(() {
                            _selectedUserType = newSelection.first;
                            _error = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Login Form
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
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
                const SizedBox(height: 20),
              ],
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              
              // Demo credentials info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Demo Credentials:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDemoCredential('Doctor', 'doctor@demo.com'),
                    _buildDemoCredential('Patient', 'patient@demo.com'),
                    _buildDemoCredential('Admin', 'admin@demo.com'),
                    const SizedBox(height: 8),
                    const Text(
                      'Password: password123 (for all)',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredential(String type, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$type: $email',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
