import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'patient_profile_screen.dart';
import '../services/pedometer_service.dart';
import '../services/health_service.dart';
import 'quick_book_appointment_screen.dart';
import '../utils/logger.dart';
import '../widgets/glassmorphic_card.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final PedometerService _pedometerService = PedometerService();
  final HealthService _healthService = HealthService();

  @override
  void initState() {
    super.initState();
    _pedometerService.startListening();
    _initHealth();
  }

  Future<void> _initHealth() async {
    try {
      final authorized = await _healthService.requestAuthorization();
      if (!mounted) return;
      if (authorized) {
        await _healthService.fetchTodayData();
      }
      _healthService.addListener(_onHealthUpdate);
    } catch (e) {
      logWarn('Health init failed: $e');
    }
  }

  @override
  void dispose() {
    _healthService.removeListener(_onHealthUpdate);
    super.dispose();
  }

  void _onHealthUpdate() {
    if (mounted) setState(() {});
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      Map<String, dynamic> data = doc.data() ?? {};
      data.putIfAbsent('name', () => '');
      data.putIfAbsent('uhid', () => '');
      data.putIfAbsent('photoUrl', () => '');
      data.putIfAbsent('role', () => 'patient');
      return data;
    } catch (e) {
      logError('Failed to fetch profile for $userId: $e');
      return null;
    }
  }

  void _openProfile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PatientProfileScreen(userId: user.uid),
      ));
    }
  }

  void _openDeviceManagement(BuildContext context) =>
      Navigator.of(context).pushNamed('/deviceManagement');
  void _openQuickBookAppointment(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const QuickBookAppointmentScreen()));
  void _openDiagnostics(BuildContext context) =>
      Navigator.of(context).pushNamed('/diagnostics');

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Theme-driven colors
    final Color cyan = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Futuristic Gradient Background using theme colors
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.primary
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Ambient glow (soft accent)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cyan.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: cyan.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  title: Text(
                    'Patient Dashboard',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  centerTitle: false,
                  actions: [
                    if (user != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: GlassmorphicCard(
                          borderRadius: 30,
                          padding: const EdgeInsets.all(4),
                          blur: 10,
                          color: Colors.white.withValues(alpha: 0.1),
                          child: IconButton(
                            icon: const Icon(Icons.person, color: Colors.white),
                            onPressed: () => _openProfile(context),
                            tooltip: 'Profile',
                          ),
                        ),
                      ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        'Welcome, ${user?.displayName?.split(' ').first ?? 'Patient'}',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                      const SizedBox(height: 8),
                      Text(
                        'Your Health Command Center',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: cyan,
                          letterSpacing: 1.2,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                      const SizedBox(height: 24),
                      if (user != null)
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _fetchProfile(user.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.cyan)),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final profile = snapshot.data!;
                            return GlassmorphicCard(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Hero(
                                        tag: 'profile-pic',
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundColor:
                                              cyan.withValues(alpha: 0.2),
                                          backgroundImage:
                                              profile['photoUrl'] != null &&
                                                      (profile['photoUrl']
                                                              as String)
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                      profile['photoUrl'])
                                                  : null,
                                          child: (profile['photoUrl'] == null ||
                                                  (profile['photoUrl']
                                                          as String)
                                                      .isEmpty)
                                              ? Icon(Icons.person, color: cyan)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile['name'] ?? 'User',
                                              style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (profile['uhid'] != null)
                                              Text('${profile['uhid']}',
                                                  style: TextStyle(
                                                      color: cyan,
                                                      fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildQuickInfo(
                                          Icons.bloodtype,
                                          'Type',
                                          profile['bloodGroup'] ?? '--',
                                          Colors.redAccent),
                                      _buildQuickInfo(
                                          Icons.calendar_today,
                                          'Age',
                                          profile['age']?.toString() ?? '--',
                                          Colors.orangeAccent),
                                      _buildQuickInfo(
                                          Icons.height,
                                          'Height',
                                          profile['height']?.toString() ?? '--',
                                          Colors.greenAccent),
                                    ],
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .scale(begin: const Offset(0.95, 0.95));
                          },
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'LIVE VITALS',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 12),
                      GlassmorphicCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildVitalRow(
                                Icons.directions_walk,
                                'Steps',
                                '${_healthService.steps}',
                                'steps',
                                Colors.orangeAccent),
                            const Divider(color: Colors.white12),
                            _buildVitalRow(
                                Icons.local_fire_department,
                                'Calories',
                                _healthService.calories.toStringAsFixed(0),
                                'kcal',
                                Colors.redAccent),
                            const Divider(color: Colors.white12),
                            _buildVitalRow(
                                Icons.favorite,
                                'Heart Rate',
                                _healthService.heartRate?.toStringAsFixed(0) ??
                                    '--',
                                'bpm',
                                Colors.pinkAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'QUICK ACTIONS',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 700.ms),
                      const SizedBox(height: 12),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildActionCard(
                          'Book Apt',
                          'Schedule visit',
                          Icons.calendar_month_rounded,
                          const Color(0xFF64FFDA),
                          () => _openQuickBookAppointment(context)),
                      _buildActionCard(
                          'Diagnostics',
                          'Lab results',
                          Icons.analytics_rounded,
                          const Color(0xFF18FFFF),
                          () => _openDiagnostics(context)),
                      _buildActionCard(
                          'Devices',
                          'Manage IoT',
                          Icons.watch_rounded,
                          const Color(0xFFFF80AB),
                          () => _openDeviceManagement(context)),
                      _buildActionCard(
                          'Chat AI',
                          'Get advice',
                          Icons.chat_bubble_rounded,
                          const Color(0xFFB388FF),
                          () => Navigator.pushNamed(context, '/chat')),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: GlassmorphicCard(
        borderRadius: 30,
        padding: EdgeInsets.zero,
        color: cyan.withValues(alpha: 0.8),
        child: FloatingActionButton(
          onPressed: () => _openQuickBookAppointment(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.black87),
        ),
      ).animate().scale(delay: 1000.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildQuickInfo(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label,
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
      ],
    );
  }

  Widget _buildVitalRow(
      IconData icon, String label, String value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 16))),
          Text(value,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(unit,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon,
      Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: accent, size: 24),
            ),
            const Spacer(),
            Text(title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(subtitle,
                style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
