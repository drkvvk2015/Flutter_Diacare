import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_profile_screen.dart';
import 'appointment_screen.dart';
import 'patient_list_screen.dart';
import 'video_call_screen.dart';
import 'chat_screen.dart';
import 'prescription_screen.dart';
import 'call_history_screen.dart';
import 'doctor_payments_screen.dart';
import 'records_screen.dart';
import 'health_analytics_screen.dart';
import 'health_service_demo_screen.dart';
import 'state_management_demo_screen.dart';
import 'performance_monitor_screen.dart';
import 'analytics_monitor_screen.dart';
import 'security_settings_screen.dart';
import '../widgets/glassmorphic_card.dart';
import '../services/analytics_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    // Track dashboard screen view
    _analyticsService.logScreenView(
      'dashboard_screen',
      screenClass: 'DashboardScreen',
    );

    // Log user action
    _analyticsService.logUserAction('dashboard_opened');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userId = user?.uid ?? '';
    final List<_DashboardCard> cards = [
      _DashboardCard(
        icon: Icons.account_circle,
        iconColor: Colors.indigo,
        title: 'Doctor Profile',
        subtitle: 'View and edit your profile.',
        onTap: () {
          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorProfileScreen(userId: user.uid),
              ),
            );
          }
        },
      ),
      _DashboardCard(
        icon: Icons.calendar_month,
        iconColor: Colors.deepPurple,
        title: 'Appointments',
        subtitle: 'View and manage your scheduled appointments.',
        onTap: () async {
          final navigator = Navigator.of(context);
          String userRole = 'doctor';
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
            if (doc.exists) {
              userRole = doc.data()?['role'] ?? 'doctor';
            }
          } catch (e) {
            debugPrint('Error fetching user role: $e');
          }
          if (context.mounted) {
            navigator.push(
              MaterialPageRoute(
                builder: (_) =>
                    AppointmentScreen(userRole: userRole, userId: userId),
              ),
            );
          }
        },
      ),
      _DashboardCard(
        icon: Icons.people,
        iconColor: Colors.teal,
        title: 'Patient List',
        subtitle: 'View and manage your patients.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientListScreen()),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.video_call,
        iconColor: Colors.blue,
        title: 'Video Consultation',
        subtitle: 'Start or join a video call with a patient.',
        onTap: () {
          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    VideoCallScreen(userId: user.uid, userRole: 'doctor'),
              ),
            );
          }
        },
      ),
      _DashboardCard(
        icon: Icons.chat,
        iconColor: Colors.green,
        title: 'Chat',
        subtitle: 'Communicate securely with patients.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.receipt_long,
        iconColor: Colors.deepOrange,
        title: 'E-Prescription',
        subtitle:
            'Create, print, and share prescriptions with diet, exercise advice, and AI insights.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrescriptionScreen()),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.history,
        iconColor: Colors.purple,
        title: 'Call History',
        subtitle: 'View your previous video consultations.',
        onTap: () async {
          final navigator = Navigator.of(context);
          String userRole = 'doctor';
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
            if (doc.exists) {
              userRole = doc.data()?['role'] ?? 'doctor';
            }
          } catch (e) {
            debugPrint('Error fetching user role: $e');
          }
          if (context.mounted) {
            navigator.push(
              MaterialPageRoute(
                builder: (_) =>
                    CallHistoryScreen(userRole: userRole, userId: userId),
              ),
            );
          }
        },
      ),
      _DashboardCard(
        icon: Icons.payments,
        iconColor: Colors.amber,
        title: 'Payment Received Details',
        subtitle: 'View all payments received for consultations.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorPaymentsScreen(doctorId: userId),
            ),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.folder_copy,
        iconColor: Colors.blueGrey,
        title: 'Digital Health Records',
        subtitle: 'Access and manage digital health records.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordsScreen()),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.analytics,
        iconColor: Colors.cyan,
        title: 'Health Analytics',
        subtitle: 'View comprehensive health insights and trends.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HealthAnalyticsScreen()),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.science,
        iconColor: Colors.deepPurple,
        title: 'Health Demo',
        subtitle: 'Interactive demo of health service features.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HealthServiceDemoScreen()),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.account_tree,
        iconColor: Colors.indigo,
        title: 'State Management',
        subtitle: 'Comprehensive provider state management demo.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StateManagementDemoScreen(),
            ),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.speed,
        iconColor: Colors.orange,
        title: 'Performance Monitor',
        subtitle: 'Monitor app performance and manage caching.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PerformanceMonitorScreen()),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.analytics,
        iconColor: Colors.deepOrange,
        title: 'Analytics Monitor',
        subtitle: 'Monitor Firebase Analytics, Crashlytics, and Performance.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnalyticsMonitorScreen()),
          );
        },
      ),
      _DashboardCard(
        icon: Icons.security,
        iconColor: Colors.red,
        title: 'Security Settings',
        subtitle: 'Manage biometric auth, encryption, and security audit.',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Hero(
          tag: 'dashboard-title',
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: const Text(
              'Doctor Dashboard',
              style: TextStyle(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  navigator.pushNamedAndRemoveUntil('/', (route) => false);
                }
              } catch (e) {
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: const Text('Logout Error'),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: Duration(milliseconds: 400 + i * 80),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Hero(
                    tag: 'dashboard-card-$i',
                    child: GlassmorphicCard(child: cards[i]),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.teal.withValues(alpha: 0.08)),
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: ListTile(
        leading: Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [iconColor.withValues(alpha: 0.7), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
        onTap: onTap,
      ),
    );
  }
}
