import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
                          color: Colors.teal.withValues(alpha: 0.3),
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
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: RouteSettings(arguments: {'role': role}),
            ),
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
}
