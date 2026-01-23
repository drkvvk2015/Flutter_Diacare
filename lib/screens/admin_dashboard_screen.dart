import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/dashboard_card.dart';
import 'appointment_screen.dart';
import 'patient_list_screen.dart';
import 'pharmacy_dashboard_screen.dart';
import 'records_screen.dart';

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
                if (isWide) Row(
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
                      ) else Column(
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
                if (isWide) Row(
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
                              label: r'Revenue Today: $1,240',
                              child: _buildStatCard(
                                'Revenue Today',
                                r'$1,240',
                                Icons.attach_money,
                                Colors.purple,
                                key: const Key(
                                  'admin_dashboard_stat_revenue_today',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ) else Column(
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
                            label: r'Revenue Today: $1,240',
                            child: _buildStatCard(
                              'Revenue Today',
                              r'$1,240',
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
                          MaterialPageRoute<void>(
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
                          final String userId = user?.uid ?? '';
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
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
                          MaterialPageRoute<void>(
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
                          MaterialPageRoute<void>(
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
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: DashboardCard(
                        key: const Key('admin_dashboard_card_user_management'),
                        icon: Icons.manage_accounts,
                        iconColor: Colors.deepOrange,
                        title: 'User Management',
                        subtitle: 'View, edit, and manage all users.',
                        onTap: () => _showUserManagement(context),
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
        padding: const EdgeInsets.all(16),
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
    showDialog<void>(
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

    showDialog<void>(
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
    showDialog<void>(
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
                  final data = doc.data()! as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['name'] as String? ?? data['displayName'] as String? ?? 'Unknown'),
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics & Reports'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('Daily Reports'),
              subtitle: Text('View daily activity reports'),
            ),
            ListTile(
              leading: Icon(Icons.pie_chart),
              title: Text('Monthly Analytics'),
              subtitle: Text('View monthly system analytics'),
            ),
            ListTile(
              leading: Icon(Icons.trending_up),
              title: Text('Revenue Reports'),
              subtitle: Text('View revenue and financial reports'),
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Security Settings'),
              subtitle: Text('Configure system security'),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notification Settings'),
              subtitle: Text('Configure system notifications'),
            ),
            ListTile(
              leading: Icon(Icons.backup),
              title: Text('Backup Settings'),
              subtitle: Text('Configure data backup'),
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
    showDialog<void>(
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

  /// Shows the user management dialog with options to view all users,
  /// filter by role, and manage individual users.
  void _showUserManagement(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people, color: Colors.blue),
              title: const Text('View All Users'),
              subtitle: const Text('See all registered users'),
              onTap: () {
                Navigator.pop(context);
                _showAllUsers(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.green),
              title: const Text('Doctors'),
              subtitle: const Text('Manage doctor accounts'),
              onTap: () {
                Navigator.pop(context);
                _showUsersByRole(context, 'doctor');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.orange),
              title: const Text('Patients'),
              subtitle: const Text('Manage patient accounts'),
              onTap: () {
                Navigator.pop(context);
                _showUsersByRole(context, 'patient');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_pharmacy, color: Colors.purple),
              title: const Text('Pharmacy'),
              subtitle: const Text('Manage pharmacy accounts'),
              onTap: () {
                Navigator.pop(context);
                _showUsersByRole(context, 'pharmacy');
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

  /// Displays all users from Firestore with options to edit or delete.
  void _showAllUsers(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Users'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found'));
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data()! as Map<String, dynamic>;
                  return _buildUserTile(context, doc.id, data);
                },
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

  /// Displays users filtered by role.
  void _showUsersByRole(BuildContext context, String role) {
    final roleTitle = role[0].toUpperCase() + role.substring(1);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$roleTitle Users'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: role)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No $role users found'));
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data()! as Map<String, dynamic>;
                  return _buildUserTile(context, doc.id, data);
                },
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

  /// Builds a user list tile with edit and delete options.
  Widget _buildUserTile(
      BuildContext context, String docId, Map<String, dynamic> data,) {
    final name = data['displayName'] as String? ?? data['name'] as String? ?? 'Unknown';
    final email = data['email'] as String? ?? 'No email';
    final role = data['role'] as String? ?? 'user';
    final isActive = data['isActive'] as bool? ?? true;

    Color roleColor;
    switch (role) {
      case 'doctor':
        roleColor = Colors.blue;
        break;
      case 'patient':
        roleColor = Colors.green;
        break;
      case 'pharmacy':
        roleColor = Colors.purple;
        break;
      case 'admin':
        roleColor = Colors.orange;
        break;
      default:
        roleColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.2),
          child: Icon(
            _getRoleIcon(role),
            color: roleColor,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: isActive ? Colors.green : Colors.red,
                ),
                Text(
                  isActive ? ' Active' : ' Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditUserDialog(context, docId, data);
                break;
              case 'toggle':
                _toggleUserStatus(context, docId, isActive);
                break;
              case 'delete':
                _confirmDeleteUser(context, docId, name);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(
                  isActive ? Icons.block : Icons.check_circle,
                  size: 20,
                ),
                title: Text(isActive ? 'Deactivate' : 'Activate'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, size: 20, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the appropriate icon for a user role.
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'doctor':
        return Icons.medical_services;
      case 'patient':
        return Icons.person;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person_outline;
    }
  }

  /// Shows dialog to edit user details.
  void _showEditUserDialog(
      BuildContext context, String docId, Map<String, dynamic> data,) {
    final nameController =
        TextEditingController(text: data['displayName'] as String? ?? data['name'] as String? ?? '');
    final emailController =
        TextEditingController(text: data['email'] as String? ?? '');
    String selectedRole = data['role'] as String? ?? 'patient';

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                enabled: false, // Email cannot be changed
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                  DropdownMenuItem(value: 'patient', child: Text('Patient')),
                  DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRole = value);
                  }
                },
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
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .update({
                  'displayName': nameController.text.trim(),
                  'name': nameController.text.trim(),
                  'role': selectedRole,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggles user active status.
  Future<void> _toggleUserStatus(
      BuildContext context, String docId, bool currentStatus,) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'isActive': !currentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus ? 'User deactivated' : 'User activated',
          ),
        ),
      );
    }
  }

  /// Confirms and deletes a user.
  void _confirmDeleteUser(BuildContext context, String docId, String userName) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "$userName"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}


