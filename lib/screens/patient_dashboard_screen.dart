import 'patient_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_screen.dart';
import '../services/pedometer_service.dart';
import '../services/health_service.dart';
import 'quick_book_appointment_screen.dart';
import '../utils/logger.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late final PedometerService _pedometerService;
  late final HealthService _healthService;
  bool _healthAuthorized = false;

  // Ensure Firestore user document exists with all required fields
  Future<void> _ensureUserDocument(User user) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        String generateUHID() {
          return 'UHID-${user.uid.substring(0, 8).toUpperCase()}';
        }

        await docRef.set({
          'name': user.displayName ?? '',
          'uhid': generateUHID(),
          'diagnosis': '',
          'comorbidities': '',
          'allergies': '',
          'surgeries': '',
          'contact': user.phoneNumber ?? '',
          'about': '',
          'photoUrl': user.photoURL ?? '',
          'role': 'patient',
        });
        logInfo('Created patient document for user ${user.uid}');
      }
    } catch (e) {
      logError('Failed ensuring patient document: $e');
    }
  }

  // Ensure Firestore doctor document exists with all required fields
  Future<void> _ensureDoctorDocument(User user) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'name': user.displayName ?? '',
          'specialty': '',
          'contact': user.phoneNumber ?? '',
          'about': '',
          'photoUrl': user.photoURL ?? '',
          'role': 'doctor',
        });
        logInfo('Created doctor document for user ${user.uid}');
      }
    } catch (e) {
      logError('Failed ensuring doctor document: $e');
    }
  }

  // Open doctor profile screen
  void _openDoctorProfile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final navigator = Navigator.of(context);
      navigator.pushNamed('/doctorProfile', arguments: {'userId': user.uid});
    }
  }

  @override
  void initState() {
    super.initState();
    _pedometerService = PedometerService();
    _pedometerService.startListening();
    _healthService = HealthService();
    _initHealth();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((doc) {
            final role = doc.data()?['role'] ?? 'patient';
            if (role == 'doctor') {
              _ensureDoctorDocument(user);
            } else {
              _ensureUserDocument(user);
            }
          })
          .catchError((e) {
            logWarn('Role fetch failed: $e');
            return null; // explicit null to satisfy FutureOr<Null>
          });
    }
  }

  Future<void> _initHealth() async {
    final authorized = await _healthService.requestAuthorization();
    if (!mounted) return;
    setState(() => _healthAuthorized = authorized);
    if (authorized) {
      try {
        await _healthService.fetchTodayData();
      } catch (e) {
        logWarn('Fetching health data failed: $e');
      }
      if (mounted) {
        _healthService.addListener(_onHealthUpdate);
      }
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

  void _openDeviceManagement(BuildContext context) {
    Navigator.of(context).pushNamed('/deviceManagement');
  }

  void _openProfile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final navigator = Navigator.of(context);
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PatientProfileScreen(userId: user.uid),
        ),
      );
    }
  }

  void _openQuickBookAppointment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuickBookAppointmentScreen()),
    );
  }

  void _openDiagnostics(BuildContext context) {
    Navigator.of(context).pushNamed('/diagnostics');
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final doc = await docRef.get();
      Map<String, dynamic> data = doc.data() ?? {};
      final requiredFields = {
        'name': '',
        'uhid': '',
        'diagnosis': '',
        'comorbidities': '',
        'allergies': '',
        'surgeries': '',
        'contact': '',
        'about': '',
        'photoUrl': '',
        'role': 'patient',
      };
      bool needsUpdate = false;
      requiredFields.forEach((key, value) {
        if (!data.containsKey(key)) {
          data[key] = value;
          needsUpdate = true;
        }
      });
      if (needsUpdate) {
        await docRef.set(data, SetOptions(merge: true));
      }
      return data;
    } catch (e) {
      logError('Failed to fetch profile for $userId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _openQuickBookAppointment(context),
            label: const Text('Quick Book'),
            icon: const Icon(Icons.add_circle),
            backgroundColor: Colors.teal[700],
            tooltip: 'Quick Book Appointment',
            heroTag: 'quickBook',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _openDiagnostics(context),
            backgroundColor: Colors.orange,
            tooltip: 'Diagnostics',
            heroTag: 'diagnostics',
            child: const Icon(Icons.bug_report),
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        actions: [
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: user != null
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get()
                : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  user == null) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data?.data();
              final role = data?['role'] ?? 'patient';
              if (role == 'doctor') {
                return Semantics(
                  label: 'Open doctor profile',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.account_circle),
                    tooltip: 'Doctor Profile',
                    onPressed: () => _openDoctorProfile(context),
                  ),
                );
              } else {
                return Semantics(
                  label: 'Open profile',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.account_circle),
                    tooltip: 'Profile',
                    onPressed: () => _openProfile(context),
                  ),
                );
              }
            },
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
                Semantics(
                  header: true,
                  child: Text(
                    'Welcome, Patient!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                ),
                SizedBox(height: cardSpacing),
                if (user != null)
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchProfile(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final profile = snapshot.data;
                      if (profile == null) {
                        return const Text('Profile not found.');
                      }
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundImage:
                                        profile['photoUrl'] != null &&
                                            (profile['photoUrl'] as String)
                                                .isNotEmpty
                                        ? NetworkImage(profile['photoUrl'])
                                        : null,
                                    child:
                                        (profile['photoUrl'] == null ||
                                            (profile['photoUrl'] as String)
                                                .isEmpty)
                                        ? const Icon(Icons.person, size: 32)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                        if (profile['uhid'] != null &&
                                            (profile['uhid'] as String)
                                                .isNotEmpty)
                                          Text(
                                            'UHID: ${profile['uhid']}',
                                            style: const TextStyle(
                                              color: Colors.teal,
                                            ),
                                          ),
                                        if (profile['contact'] != null &&
                                            (profile['contact'] as String)
                                                .isNotEmpty)
                                          Text(
                                            'Contact: ${profile['contact']}',
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit Profile',
                                    onPressed: () => _openProfile(context),
                                  ),
                                ],
                              ),
                              if (profile['about'] != null &&
                                  (profile['about'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    profile['about'],
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              const Divider(height: 24),
                              Text(
                                'Clinical History',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (profile['diagnosis'] != null &&
                                  (profile['diagnosis'] as String).isNotEmpty)
                                Text('Diagnosis: ${profile['diagnosis']}'),
                              // --- Comorbidities Section ---
                              if (profile['comorbidities'] != null &&
                                  (profile['comorbidities'] is List &&
                                      (profile['comorbidities'] as List)
                                          .isNotEmpty)) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Comorbidities:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount:
                                      (profile['comorbidities'] as List).length,
                                  itemBuilder: (context, idx) {
                                    final c =
                                        (profile['comorbidities'] as List)[idx];
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('${c['name'] ?? ''}'),
                                      subtitle: Text(
                                        'Duration: ${c['duration'] ?? ''} years',
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Simple comparison chart
                                SizedBox(
                                  height: 120,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: (profile['comorbidities'] as List)
                                        .map<Widget>((c) {
                                          final duration =
                                              int.tryParse(
                                                c['duration'] ?? '0',
                                              ) ??
                                              0;
                                          return Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                  height: (duration * 10)
                                                      .toDouble()
                                                      .clamp(0, 100),
                                                  width: 18,
                                                  color: Colors.teal,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  c['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                Text(
                                                  '${c['duration']}y',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              ],
                              if (profile['allergies'] != null &&
                                  (profile['allergies'] as String).isNotEmpty)
                                Text('Allergies: ${profile['allergies']}'),
                              if (profile['surgeries'] != null &&
                                  (profile['surgeries'] as String).isNotEmpty)
                                Text('Surgeries: ${profile['surgeries']}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                // Step Counter Card
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_walk,
                              size: 32,
                              color: Colors.deepOrange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _healthAuthorized
                                  ? 'Steps Today: ${_healthService.steps}'
                                  : 'Steps Today: --',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 28,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _healthAuthorized
                                  ? 'Calories: ${_healthService.calories.toStringAsFixed(1)} kcal'
                                  : 'Calories: --',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 28,
                              color: Colors.pink,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _healthAuthorized &&
                                      _healthService.heartRate != null
                                  ? 'Heart Rate: ${_healthService.heartRate!.toStringAsFixed(0)} bpm'
                                  : 'Heart Rate: --',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.bloodtype,
                              size: 28,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _healthAuthorized && _healthService.spo2 != null
                                  ? 'SpO₂: ${_healthService.spo2!.toStringAsFixed(1)}%'
                                  : 'SpO₂: --',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.thermostat,
                              size: 28,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _healthAuthorized &&
                                      _healthService.temperature != null
                                  ? 'Temperature: ${_healthService.temperature!.toStringAsFixed(1)} °C'
                                  : 'Temperature: --',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.monitor_heart,
                              size: 28,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _healthAuthorized &&
                                      _healthService.bpSystolic != null &&
                                      _healthService.bpDiastolic != null
                                  ? 'BP: ${_healthService.bpSystolic!.toStringAsFixed(0)}/${_healthService.bpDiastolic!.toStringAsFixed(0)} mmHg'
                                  : 'BP: --',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const Text(
                          'Trends',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Daily, weekly, and monthly step/calorie/vitals trends coming soon!',
                        ),
                        if (!_healthAuthorized)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Health data not authorized. Tap to grant permission.',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        if (!_healthAuthorized)
                          TextButton.icon(
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Grant Health Permission'),
                            onPressed: _initHealth,
                          ),
                      ],
                    ),
                  ),
                ),
                Wrap(
                  spacing: cardSpacing,
                  runSpacing: cardSpacing,
                  children: [
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: Semantics(
                        label:
                            'Extended Anthropometry & AI Insights. View detailed health metrics and comparison charts.',
                        button: true,
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.analytics,
                              color: Colors.deepOrange,
                              size: 32,
                            ),
                            title: const Text(
                              'Extended Anthropometry & AI Insights',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Detailed view, trends, and comparison charts for all vitals.',
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.teal,
                            ),
                            onTap: () {
                              Navigator.pushNamed(context, '/anthropometry');
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: Semantics(
                        label:
                            'Device Management. Pair and manage health devices.',
                        button: true,
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.devices,
                              color: Colors.blueGrey,
                              size: 32,
                            ),
                            title: const Text(
                              'Device Management',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Pair Bluetooth/WiFi devices for automatic vitals.',
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.teal[700],
                            ),
                            onTap: () => _openDeviceManagement(context),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: Semantics(
                        label: 'Appointments. View and book appointments.',
                        button: true,
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.calendar_today,
                              color: Colors.blue,
                              size: 32,
                            ),
                            title: const Text(
                              'Appointments',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('View and book appointments.'),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.teal[700],
                            ),
                            onTap: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                // In the patient dashboard, we explicitly set the role to 'patient'
                                // regardless of what's in Firestore, since this is the patient view
                                const String userRole = 'patient';
                                logInfo(
                                  'Navigating to AppointmentScreen userRole=$userRole userId=${user.uid}',
                                );
                                if (!mounted) return;
                                final navigator = Navigator.of(context);
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => AppointmentScreen(
                                      userRole: userRole,
                                      userId: user.uid,
                                    ),
                                  ),
                                );
                              } else {
                                // Show error if user is null
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Error: User not logged in. Please log in again.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: Semantics(
                        label:
                            'E-Prescription. View your latest e-prescription.',
                        button: true,
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.medical_services,
                              color: Colors.deepPurple,
                              size: 32,
                            ),
                            title: const Text(
                              'E-Prescription',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'View your latest e-prescription.',
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.teal[700],
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/prescription',
                                arguments: {'viewOnly': true},
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: Semantics(
                        label: 'Chat with Doctor. Get advice and support.',
                        button: true,
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.chat,
                              color: Colors.green,
                              size: 32,
                            ),
                            title: const Text(
                              'Chat with Doctor',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('Get advice and support.'),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.teal[700],
                            ),
                            onTap: () {},
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 340 : double.infinity,
                      child: Semantics(
                        label:
                            'Quick Book Appointment. Book an appointment quickly.',
                        button: true,
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.book_online,
                              color: Colors.orange,
                              size: 32,
                            ),
                            title: const Text(
                              'Quick Book Appointment',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Book an appointment quickly with default settings.',
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.teal[700],
                            ),
                            onTap: () => _openQuickBookAppointment(context),
                          ),
                        ),
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
}
