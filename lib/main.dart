import 'package:flutter/material.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(const DiacareApp());
}

class DiacareApp extends StatelessWidget {
  const DiacareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaCare - Doctor Prescription App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // Use named routes for navigation
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DoctorDashboard(),
        '/patient-dashboard': (context) => const PatientDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Welcome, Doctor!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Doctor Prescription App Dashboard'),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureCard(
                  icon: Icons.person_add,
                  title: 'Patients',
                  description: 'Manage Patients',
                  color: Colors.green,
                ),
                _buildFeatureCard(
                  icon: Icons.description,
                  title: 'Prescriptions',
                  description: 'Create Prescriptions',
                  color: Colors.orange,
                ),
                _buildFeatureCard(
                  icon: Icons.calendar_today,
                  title: 'Appointments',
                  description: 'View Schedule',
                  color: Colors.purple,
                ),
                _buildFeatureCard(
                  icon: Icons.video_call,
                  title: 'Video Calls',
                  description: 'Telemedicine',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Welcome, Patient!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Your Health Dashboard'),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                DoctorDashboard._buildFeatureCard(
                  icon: Icons.medication,
                  title: 'Prescriptions',
                  description: 'View History',
                  color: Colors.blue,
                ),
                DoctorDashboard._buildFeatureCard(
                  icon: Icons.calendar_month,
                  title: 'Appointments',
                  description: 'Book/View',
                  color: Colors.purple,
                ),
                DoctorDashboard._buildFeatureCard(
                  icon: Icons.monitor_heart,
                  title: 'Health Data',
                  description: 'Track Vitals',
                  color: Colors.red,
                ),
                DoctorDashboard._buildFeatureCard(
                  icon: Icons.video_call,
                  title: 'Consultations',
                  description: 'Video Calls',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 100, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Welcome, Admin!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('System Administration'),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                DoctorDashboard._buildFeatureCard(
                  icon: Icons.people,
                  title: 'Users',
                  description: 'Manage Users',
                  color: Colors.blue,
                ),
                DoctorDashboard._buildFeatureCard(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  description: 'View Reports',
                  color: Colors.green,
                ),
                DoctorDashboard._buildFeatureCard(
                  icon: Icons.settings,
                  title: 'Settings',
                  description: 'System Config',
                  color: Colors.orange,
                ),
                DoctorDashboard._buildFeatureCard(
                  icon: Icons.security,
                  title: 'Security',
                  description: 'Access Control',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
