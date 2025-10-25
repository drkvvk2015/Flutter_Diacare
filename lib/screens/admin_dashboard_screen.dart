import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_screen.dart';
import 'patient_list_screen.dart';
import 'records_screen.dart';
import '../widgets/dashboard_card.dart';
import 'pharmacy_dashboard_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.purple[700],
        elevation: 0,
        actions: [
          Semantics(
            label: 'Logout',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final cardSpacing = isWide ? 24.0 : 12.0;
          final padding = isWide ? 48.0 : 16.0;
          return Padding(
            padding: EdgeInsets.all(padding),
            child: ListView(
              children: [
                // Stat cards
                isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'Total Doctors: 24',
                              child: _buildStatCard(
                                'Total Doctors',
                                '24',
                                Icons.medical_services,
                                Colors.blue,
                                key: const Key(
                                  'admin_dashboard_stat_total_doctors',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: cardSpacing),
                          Expanded(
                            child: Semantics(
                              label: 'Total Patients: 156',
                              child: _buildStatCard(
                                'Total Patients',
                                '156',
                                Icons.people,
                                Colors.green,
                                key: const Key(
                                  'admin_dashboard_stat_total_patients',
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Semantics(
                            label: 'Total Doctors: 24',
                            child: _buildStatCard(
                              'Total Doctors',
                              '24',
                              Icons.medical_services,
                              Colors.blue,
                              key: const Key(
                                'admin_dashboard_stat_total_doctors',
                              ),
                            ),
                          ),
                          SizedBox(height: cardSpacing),
                          Semantics(
                            label: 'Total Patients: 156',
                            child: _buildStatCard(
                              'Total Patients',
                              '156',
                              Icons.people,
                              Colors.green,
                              key: const Key(
                                'admin_dashboard_stat_total_patients',
                              ),
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: cardSpacing),
                isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'Appointments Today: 12',
                              child: _buildStatCard(
                                'Appointments Today',
                                '12',
                                Icons.calendar_today,
                                Colors.orange,
                                key: const Key(
                                  'admin_dashboard_stat_appointments_today',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: cardSpacing),
                          Expanded(
                            child: Semantics(
                              label: 'Revenue Today: \$1,240',
                              child: _buildStatCard(
                                'Revenue Today',
                                '\$1,240',
                                Icons.attach_money,
                                Colors.purple,
                                key: const Key(
                                  'admin_dashboard_stat_revenue_today',
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Semantics(
                            label: 'Appointments Today: 12',
                            child: _buildStatCard(
                              'Appointments Today',
                              '12',
                              Icons.calendar_today,
                              Colors.orange,
                              key: const Key(
                                'admin_dashboard_stat_appointments_today',
                              ),
                            ),
                          ),
                          SizedBox(height: cardSpacing),
                          Semantics(
                            label: 'Revenue Today: \$1,240',
                            child: _buildStatCard(
                              'Revenue Today',
                              '\$1,240',
                              Icons.attach_money,
                              Colors.purple,
                              key: const Key(
                                'admin_dashboard_stat_revenue_today',
                              ),
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: cardSpacing * 2),
                // Management and navigation cards
                Wrap(
                  spacing: cardSpacing,
                  runSpacing: cardSpacing,
                  children: [
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: DashboardCard(
                        key: const Key(
                          'admin_dashboard_card_doctor_management',
                        ),
                        icon: Icons.medical_services,
                        iconColor: Colors.blue,
                        title: 'Doctor Management',
                        subtitle: 'Add, edit, and manage doctors.',
                        onTap: () => _showDoctorManagement(context),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: DashboardCard(
                        key: const Key(
                          'admin_dashboard_card_patient_management',
                        ),
                        icon: Icons.people,
                        iconColor: Colors.green,
                        title: 'Patient Management',
                        subtitle: 'View and manage all patients.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PatientListScreen(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: DashboardCard(
                        key: const Key(
                          'admin_dashboard_card_appointment_management',
                        ),
                        icon: Icons.calendar_month,
                        iconColor: Colors.orange,
                        title: 'Appointment Management',
                        subtitle: 'View and manage all appointments.',
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          String userId = user?.uid ?? '';
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppointmentScreen(
                                  userRole: 'admin',
                                  userId: userId,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: DashboardCard(
                        key: const Key(
                          'admin_dashboard_card_analytics_reports',
                        ),
                        icon: Icons.analytics,
                        iconColor: Colors.purple,
                        title: 'Analytics & Reports',
                        subtitle: 'View system analytics and reports.',
                        onTap: () => _showAnalytics(context),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: DashboardCard(
                        key: const Key('admin_dashboard_card_system_records'),
                        icon: Icons.folder,
                        iconColor: Colors.indigo,
                        title: 'System Records',
                        subtitle: 'Access all health records.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecordsScreen(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: DashboardCard(
                        key: const Key('admin_dashboard_card_system_settings'),
                        icon: Icons.settings,
                        iconColor: Colors.grey,
                        title: 'System Settings',
                        subtitle: 'Configure system settings.',
                        onTap: () => _showSystemSettings(context),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: DashboardCard(
                        key: const Key(
                          'admin_dashboard_card_pharmacy_dashboard',
                        ),
                        icon: Icons.local_pharmacy,
                        iconColor: Colors.purple,
                        title: 'Pharmacy Dashboard',
                        subtitle: 'Access pharmacy management and inventory.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PharmacyDashboardScreen(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: DashboardCard(
                        key: const Key('admin_dashboard_card_help_feedback'),
                        icon: Icons.help_outline,
                        iconColor: Colors.teal,
                        title: 'Help & Feedback',
                        subtitle: 'Contact support or send feedback.',
                        onTap: () => _showHelpFeedbackDialog(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    Key? key,
  }) {
    return Card(
      key: key,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showDoctorManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doctor Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add New Doctor'),
              onTap: () {
                Navigator.pop(context);
                _showAddDoctorDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('View All Doctors'),
              onTap: () {
                Navigator.pop(context);
                _showDoctorsList(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddDoctorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final specialtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Doctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Doctor Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: specialtyController,
              decoration: const InputDecoration(labelText: 'Specialty'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('doctors').add({
                'name': nameController.text,
                'email': emailController.text,
                'specialty': specialtyController.text,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Doctor added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDoctorsList(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Doctors'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['name'] ?? 'Unknown'),
                    subtitle: Text(
                      '${data['specialty'] ?? 'General'} - ${data['email'] ?? ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await doc.reference.delete();
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnalytics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics & Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Daily Reports'),
              subtitle: const Text('View daily activity reports'),
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('Monthly Analytics'),
              subtitle: const Text('View monthly system analytics'),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Revenue Reports'),
              subtitle: const Text('View revenue and financial reports'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSystemSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security Settings'),
              subtitle: const Text('Configure system security'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              subtitle: const Text('Configure system notifications'),
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup Settings'),
              subtitle: const Text('Configure data backup'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe your issue or feedback:'),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type your message here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you could send feedback to Firestore, email, etc.
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
