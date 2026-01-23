import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appointment_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/glassmorphic_card.dart';

/// Comprehensive state management demo screen
class StateManagementDemoScreen extends StatefulWidget {
  const StateManagementDemoScreen({super.key});

  @override
  State<StateManagementDemoScreen> createState() =>
      _StateManagementDemoScreenState();
}

class _StateManagementDemoScreenState extends State<StateManagementDemoScreen> {
  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('State Management Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _showNotificationsDialog(context),
                  ),
                  if (notificationProvider.hasUnread)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFFf093fb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildUserProviderDemo(),
                const SizedBox(height: 16),
                _buildThemeProviderDemo(),
                const SizedBox(height: 16),
                _buildNotificationProviderDemo(),
                const SizedBox(height: 16),
                _buildAppointmentProviderDemo(),
                const SizedBox(height: 16),
                _buildProviderStatistics(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProviderDemo() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'User Provider',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (userProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _buildInfoRow(
                    'Authenticated',
                    userProvider.isAuthenticated ? 'Yes' : 'No',
                  ),
                  _buildInfoRow('Display Name', userProvider.displayName),
                  _buildInfoRow('Email', userProvider.email),
                  _buildInfoRow('User Role', userProvider.userRole.displayName),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _simulateUserLogin(userProvider),
                          child: const Text('Simulate Login'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: userProvider.isAuthenticated
                              ? () => userProvider.signOut()
                              : null,
                          child: const Text('Sign Out'),
                        ),
                      ),
                    ],
                  ),
                  if (userProvider.isAuthenticated) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => userProvider.switchRole(
                              userProvider.isDoctor
                                  ? UserRole.patient
                                  : UserRole.doctor,
                            ),
                            child: Text(
                              'Switch to ${userProvider.isDoctor ? "Patient" : "Doctor"}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                if (userProvider.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error: ${userProvider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeProviderDemo() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette, color: Colors.purple[700], size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Theme Provider',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Theme Mode', themeProvider.themeMode.name),
                _buildInfoRow(
                  'Material 3',
                  themeProvider.useMaterial3 ? 'Enabled' : 'Disabled',
                ),
                _buildInfoRow(
                  'System Colors',
                  themeProvider.useSystemColors ? 'Yes' : 'No',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Theme Colors:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ThemeProvider.predefinedColors.map((color) {
                    final isSelected =
                        color == themeProvider.seedColor;
                    return GestureDetector(
                      onTap: () => themeProvider.setSeedColor(color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withAlpha(128),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto, size: 16),
                          ),
                        ],
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: (Set<ThemeMode> selection) {
                          themeProvider.setThemeMode(selection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationProviderDemo() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Notification Provider',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (notificationProvider.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Total Notifications',
                  notificationProvider.notifications.length.toString(),
                ),
                _buildInfoRow(
                  'Unread Count',
                  notificationProvider.unreadCount.toString(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => notificationProvider.showSuccess(
                        'Operation completed successfully!',
                      ),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Success'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => notificationProvider.showError(
                        'Something went wrong!',
                      ),
                      icon: const Icon(Icons.error, size: 16),
                      label: const Text('Error'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => notificationProvider.showWarning(
                        'Please check your settings.',
                      ),
                      icon: const Icon(Icons.warning, size: 16),
                      label: const Text('Warning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          notificationProvider.showAppointmentNotification(
                            title: 'Appointment Reminder',
                            message: 'You have an appointment in 30 minutes.',
                            appointmentTime: DateTime.now().add(
                              const Duration(minutes: 30),
                            ),
                          ),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Appointment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (notificationProvider.notifications.isNotEmpty)
                  TextButton(
                    onPressed: () => notificationProvider.clearAll(),
                    child: const Text('Clear All Notifications'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentProviderDemo() {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        return GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Colors.green[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Appointment Provider',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (appointmentProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _buildInfoRow(
                    'Total Appointments',
                    appointmentProvider.totalAppointments.toString(),
                  ),
                  _buildInfoRow(
                    'Today\'s Appointments',
                    appointmentProvider.todaysCount.toString(),
                  ),
                  _buildInfoRow(
                    'Upcoming',
                    appointmentProvider.upcomingCount.toString(),
                  ),
                  _buildInfoRow(
                    'Current Filter',
                    appointmentProvider.currentFilter.displayName,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppointmentFilter.values.map((filter) {
                        final isSelected =
                            appointmentProvider.currentFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter.displayName),
                            selected: isSelected,
                            onSelected: (_) =>
                                appointmentProvider.setFilter(filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        _createSampleAppointment(appointmentProvider),
                    child: const Text('Create Sample Appointment'),
                  ),
                ],
                if (appointmentProvider.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error: ${appointmentProvider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProviderStatistics() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.indigo[700], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Provider Statistics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer4<
              UserProvider,
              AppointmentProvider,
              NotificationProvider,
              ThemeProvider
            >(
              builder:
                  (
                    context,
                    userProvider,
                    appointmentProvider,
                    notificationProvider,
                    themeProvider,
                    _,
                  ) {
                    return Column(
                      children: [
                        _buildStatCard(
                          'Active Providers',
                          '4',
                          Icons.layers,
                          Colors.purple,
                        ),
                        const SizedBox(height: 8),
                        _buildStatCard(
                          'User Authenticated',
                          userProvider.isAuthenticated ? '✓' : '✗',
                          Icons.verified_user,
                          userProvider.isAuthenticated
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _buildStatCard(
                          'Total Appointments',
                          appointmentProvider.totalAppointments.toString(),
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        _buildStatCard(
                          'Unread Notifications',
                          notificationProvider.unreadCount.toString(),
                          Icons.notifications_active,
                          Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        _buildStatCard(
                          'Current Theme',
                          themeProvider.themeMode.name,
                          Icons.palette,
                          Colors.deepPurple,
                        ),
                      ],
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateUserLogin(UserProvider userProvider) async {
    // Simulate creating a sample user for demo purposes
    await userProvider.updateProfile(
      displayName: 'Demo User',
      additionalData: {
        'role': 'doctor',
        'phone': '+1234567890',
        'specialization': 'General Medicine',
      },
    );
  }

  void _createSampleAppointment(AppointmentProvider appointmentProvider) {
    final appointment = AppointmentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: 'demo_patient_id',
      doctorId: 'demo_doctor_id',
      patientName: 'John Doe',
      doctorName: 'Dr. Smith',
      dateTime: DateTime.now().add(const Duration(hours: 2)),
    );

    appointmentProvider.createAppointment(appointment);
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Consumer<NotificationProvider>(
        builder: (context, notificationProvider, _) {
          return AlertDialog(
            title: Text(
              'Notifications (${notificationProvider.unreadCount} unread)',
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: notificationProvider.notifications.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : ListView.builder(
                      itemCount: notificationProvider.notifications.length,
                      itemBuilder: (context, index) {
                        final notification =
                            notificationProvider.notifications[index];
                        return ListTile(
                          leading: Icon(
                            notification.icon,
                            color: notification.color,
                          ),
                          title: Text(notification.title),
                          subtitle: Text(notification.message),
                          trailing: Text(notification.formattedTime),
                          tileColor: notification.isRead
                              ? null
                              : notification.color.withAlpha(26),
                          onTap: () {
                            notificationProvider.markAsRead(notification.id);
                            notification.onTap?.call();
                          },
                        );
                      },
                    ),
            ),
            actions: [
              if (notificationProvider.hasUnread)
                TextButton(
                  onPressed: () => notificationProvider.markAllAsRead(),
                  child: const Text('Mark All Read'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}

