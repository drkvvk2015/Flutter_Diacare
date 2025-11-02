import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/patient.dart';
import '../widgets/voice_text_field.dart';
import 'exercise_video_library_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/glassmorphic_card.dart';

// --- New Tabs moved to top-level below ---

class EPrescriptionTab extends StatelessWidget {
  final Patient patient;
  const EPrescriptionTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'eprescription-card',
            child: GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'E-Prescription Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Prescription'),
                            onPressed: () {
                              try {
                                Navigator.pushNamed(
                                  context,
                                  '/prescription',
                                  arguments: {
                                    'patient': patient,
                                    'viewOnly': false,
                                  },
                                );
                              } catch (e) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    title: const Text('Navigation Error'),
                                    content: Text(e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.history),
                            label: const Text('View History'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              try {
                                Navigator.pushNamed(
                                  context,
                                  '/prescription',
                                  arguments: {
                                    'patient': patient,
                                    'viewOnly': true,
                                  },
                                );
                              } catch (e) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    title: const Text('Navigation Error'),
                                    content: Text(e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent Prescriptions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Semantics(
              label: 'Recent Prescriptions List',
              child: GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: ListView(
                      key: const ValueKey('prescriptionList'),
                      children: [
                        _buildPrescriptionTile(
                          date: 'Dec 8, 2024',
                          medications: 'Metformin 500mg, Glipizide 5mg',
                          status: 'Active',
                        ),
                        _buildPrescriptionTile(
                          date: 'Nov 15, 2024',
                          medications: 'Insulin Aspart, Metformin 500mg',
                          status: 'Completed',
                        ),
                        _buildPrescriptionTile(
                          date: 'Oct 28, 2024',
                          medications: 'Glimepiride 2mg, Pioglitazone 15mg',
                          status: 'Completed',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionTile({
    required String date,
    required String medications,
    required String status,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: status == 'Active' ? Colors.green : Colors.grey,
        child: Icon(
          status == 'Active' ? Icons.medication : Icons.check,
          color: Colors.white,
        ),
      ),
      title: Text(date),
      subtitle: Text(medications),
      trailing: Chip(
        label: Text(status),
        backgroundColor:
            status == 'Active' ? Colors.green[100] : Colors.grey[200],
      ),
    );
  }
}

class DietAdviceTab extends StatefulWidget {
  final Patient patient;
  const DietAdviceTab({super.key, required this.patient});

  @override
  State<DietAdviceTab> createState() => _DietAdviceTabState();
}

class _DietAdviceTabState extends State<DietAdviceTab> {
  final TextEditingController _adviceController = TextEditingController();
  final List<Map<String, dynamic>> _dietPlans = [
    {
      'title': 'Low Carb Diet Plan',
      'description': 'Reduce carbohydrate intake to manage blood sugar',
      'calories': '1800-2000',
      'meals': [
        'Breakfast: Eggs with vegetables',
        'Lunch: Grilled chicken salad',
        'Dinner: Fish with steamed broccoli',
      ],
    },
    {
      'title': 'Mediterranean Diet',
      'description': 'Heart-healthy diet rich in omega-3 fatty acids',
      'calories': '2000-2200',
      'meals': [
        'Breakfast: Greek yogurt with nuts',
        'Lunch: Quinoa salad',
        'Dinner: Grilled salmon with vegetables',
      ],
    },
    {
      'title': 'DASH Diet',
      'description': 'Dietary approaches to stop hypertension',
      'calories': '1600-1800',
      'meals': [
        'Breakfast: Oatmeal with berries',
        'Lunch: Turkey sandwich on whole grain',
        'Dinner: Lean beef with sweet potato',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Diet Advice Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Diet Advice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adviceController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Diet recommendations for patient',
                      border: OutlineInputBorder(),
                      hintText: 'Enter specific diet advice...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Advice'),
                    onPressed: () {
                      if (_adviceController.text.trim().isNotEmpty) {
                        // TODO: Save to Firestore
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Diet advice saved!')),
                        );
                        _adviceController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pre-defined Diet Plans
          const Text(
            'Recommended Diet Plans',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: _dietPlans.length,
              itemBuilder: (context, index) {
                final plan = _dietPlans[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.green,
                    ),
                    title: Text(plan['title']),
                    subtitle: Text(
                      '${plan['calories']} cal/day • ${plan['description']}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sample Meals:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              plan['meals'].length,
                              (mealIndex) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• ${plan['meals'][mealIndex]}'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.assignment),
                              label: const Text('Assign to Patient'),
                              onPressed: () {
                                // TODO: Assign diet plan to patient in Firestore
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${plan['title']} assigned to ${widget.patient.name}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _adviceController.dispose();
    super.dispose();
  }
}

class ExerciseAdviceTab extends StatefulWidget {
  final Patient patient;
  const ExerciseAdviceTab({super.key, required this.patient});

  @override
  State<ExerciseAdviceTab> createState() => _ExerciseAdviceTabState();
}

class _ExerciseAdviceTabState extends State<ExerciseAdviceTab> {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _localNotifications.initialize(settings);
  }

  Future<void> _scheduleExerciseReminder(String planTitle) async {
    final now = DateTime.now();
    final scheduledTime = tz.TZDateTime.from(
      now.add(const Duration(hours: 1)),
      tz.local,
    );
    await _localNotifications.zonedSchedule(
      planTitle.hashCode,
      'Exercise Reminder',
      'Time for your exercise: $planTitle',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exercise_channel',
          'Exercise Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  final TextEditingController _exerciseController = TextEditingController();
  final List<Map<String, dynamic>> _exercisePlans = [
    {
      'title': 'Beginner Cardio Plan',
      'description': 'Low-impact exercises for diabetes management',
      'duration': '30 minutes',
      'frequency': '5 days/week',
      'exercises': [
        'Walking: 15 minutes',
        'Light stretching: 10 minutes',
        'Breathing exercises: 5 minutes',
      ],
    },
    {
      'title': 'Intermediate Strength Training',
      'description': 'Build muscle to improve insulin sensitivity',
      'duration': '45 minutes',
      'frequency': '3 days/week',
      'exercises': [
        'Bodyweight squats: 3 sets of 10',
        'Push-ups: 3 sets of 8',
        'Resistance band exercises: 20 minutes',
      ],
    },
    {
      'title': 'Advanced Fitness Routine',
      'description': 'Comprehensive exercise for optimal health',
      'duration': '60 minutes',
      'frequency': '6 days/week',
      'exercises': [
        'HIIT cardio: 20 minutes',
        'Weight training: 30 minutes',
        'Cool down stretching: 10 minutes',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Exercise Advice Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Exercise Advice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _exerciseController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Exercise recommendations for patient',
                      border: OutlineInputBorder(),
                      hintText: 'Enter specific exercise instructions...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save Advice'),
                        onPressed: () async {
                          if (_exerciseController.text.trim().isNotEmpty) {
                            final advice = _exerciseController.text.trim();
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('patients')
                                  .doc(widget.patient.id)
                                  .set({
                                'exerciseAdvice': advice,
                                'exerciseAdviceDate':
                                    DateTime.now().toIso8601String(),
                              }, SetOptions(merge: true));
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Exercise advice saved!'),
                                ),
                              );
                              _exerciseController.clear();
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text('Save failed: $e')),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.video_library),
                        label: const Text('Video Library'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExerciseVideoLibraryScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pre-defined Exercise Plans
          const Text(
            'Recommended Exercise Plans',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: _exercisePlans.length,
              itemBuilder: (context, index) {
                final plan = _exercisePlans[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.fitness_center,
                      color: Colors.blue,
                    ),
                    title: Text(plan['title']),
                    subtitle: Text(
                      '${plan['duration']} • ${plan['frequency']} • ${plan['description']}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Exercise Routine:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              plan['exercises'].length,
                              (exerciseIndex) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.play_arrow,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        plan['exercises'][exerciseIndex],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.assignment),
                                  label: const Text('Assign Plan'),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('patients')
                                          .doc(widget.patient.id)
                                          .set({
                                        'assignedExercisePlan': plan,
                                        'assignedExercisePlanDate':
                                            DateTime.now().toIso8601String(),
                                      }, SetOptions(merge: true));
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${plan['title']} assigned to ${widget.patient.name}',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Assignment failed: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.timer),
                                  label: const Text('Set Reminder'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    try {
                                      await _scheduleExerciseReminder(
                                        plan['title'],
                                      );
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Exercise reminder scheduled!',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Reminder scheduling failed: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }
}

class NextVisitTab extends StatefulWidget {
  final Patient patient;
  const NextVisitTab({super.key, required this.patient});

  @override
  State<NextVisitTab> createState() => _NextVisitTabState();
}

class _NextVisitTabState extends State<NextVisitTab> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _lastVisit;
  String? _lastReason;

  @override
  void initState() {
    super.initState();
    _loadNextVisit();
  }

  Future<void> _loadNextVisit() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient.id)
          .get();
      if (!mounted) return;
      if (doc.exists && doc.data()?['nextVisit'] != null) {
        setState(() {
          _lastVisit = doc.data()!['nextVisit'];
          _lastReason = doc.data()!['nextVisitReason'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    }
  }

  Future<void> _saveNextVisit() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient.id)
          .set({
        'nextVisit': _dateController.text,
        'nextVisitReason': _reasonController.text,
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _lastVisit = _dateController.text;
        _lastReason = _reasonController.text;
      });
      _dateController.clear();
      _reasonController.clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('Next visit saved!')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule Next Visit',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dateController,
            decoration: const InputDecoration(
              labelText: 'Next Visit Date (YYYY-MM-DD)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(labelText: 'Reason/Notes'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: _saveNextVisit,
          ),
          const SizedBox(height: 16),
          if (_lastVisit != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_available, color: Colors.teal),
                title: Text('Next Visit: $_lastVisit'),
                subtitle: Text(_lastReason ?? ''),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}

class NextVisitInvestigationTab extends StatefulWidget {
  final Patient patient;
  const NextVisitInvestigationTab({super.key, required this.patient});

  @override
  State<NextVisitInvestigationTab> createState() =>
      _NextVisitInvestigationTabState();
}

class _NextVisitInvestigationTabState extends State<NextVisitInvestigationTab> {
  final TextEditingController _investigationController =
      TextEditingController();
  List<String> _investigations = [];

  @override
  void initState() {
    super.initState();
    _loadInvestigations();
  }

  Future<void> _loadInvestigations() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient.id)
          .get();
      if (!mounted) return;
      if (doc.exists && doc.data()?['nextVisitInvestigations'] != null) {
        setState(() {
          _investigations = List<String>.from(
            doc.data()!['nextVisitInvestigations'],
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    }
  }

  Future<void> _saveInvestigation() async {
    if (_investigationController.text.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      _investigations.add(_investigationController.text.trim());
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient.id)
          .set({
        'nextVisitInvestigations': _investigations,
      }, SetOptions(merge: true));
      if (!mounted) return;
      _investigationController.clear();
      setState(() {});
      messenger.showSnackBar(
        const SnackBar(content: Text('Investigation saved!')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Visit Investigations',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _investigationController,
            decoration: const InputDecoration(labelText: 'Add Investigation'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: _saveInvestigation,
          ),
          const SizedBox(height: 16),
          ..._investigations.map(
            (inv) => Card(
              child: ListTile(
                leading: const Icon(Icons.science, color: Colors.deepPurple),
                title: Text(inv),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _investigationController.dispose();
    super.dispose();
  }
}

// Add this to your pubspec.yaml dependencies:
// flutter_blue_plus: ^1.16.4
// Then run: flutter pub get

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.patient.name} - Details'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Anthropometry'),
              Tab(text: 'BP'),
              Tab(text: 'SMBG'),
              Tab(text: 'E-Prescription'),
              Tab(text: 'Diet Advice'),
              Tab(text: 'Exercise Advice'),
              Tab(text: 'Next Visit'),
              Tab(text: 'Next Visit Investigation'),
            ],
          ),
        ),
        body: Column(
          children: [
            DeviceIntegrationSection(patient: widget.patient),
            Expanded(
              child: TabBarView(
                children: [
                  AnthropometryTab(patient: widget.patient),
                  BPHistoryTab(patient: widget.patient),
                  SMBGHistoryTab(patient: widget.patient),
                  EPrescriptionTab(patient: widget.patient),
                  DietAdviceTab(patient: widget.patient),
                  ExerciseAdviceTab(patient: widget.patient),
                  NextVisitTab(patient: widget.patient),
                  NextVisitInvestigationTab(patient: widget.patient),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- New Tabs moved to top-level below ---
}

class DeviceIntegrationSection extends StatefulWidget {
  final Patient patient;
  const DeviceIntegrationSection({super.key, required this.patient});

  @override
  State<DeviceIntegrationSection> createState() =>
      _DeviceIntegrationSectionState();
}

class _DeviceIntegrationSectionState extends State<DeviceIntegrationSection> {
  bool scanning = false;
  List<BluetoothDevice> foundDevices = [];

  void scanBluetoothDevices() async {
    setState(() {
      scanning = true;
      foundDevices.clear();
    });
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        foundDevices = results.map((r) => r.device).toList();
      });
    });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      }
    } finally {
      await subscription.cancel();
      if (mounted) {
        setState(() {
          scanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Automated Entry',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.bluetooth),
          label: Text(scanning ? 'Scanning...' : 'Scan Bluetooth Devices'),
          onPressed: scanning ? null : scanBluetoothDevices,
        ),
        if (foundDevices.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: foundDevices
                .map(
                  (d) => ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(
                      d.platformName.isNotEmpty
                          ? d.platformName
                          : d.remoteId.toString(),
                    ),
                    subtitle: Text(d.remoteId.toString()),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Connect and fetch data from \\${d.platformName.isNotEmpty ? d.platformName : d.remoteId} (not implemented)',
                          ),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.wifi),
          label: const Text('Connect WiFi Device'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('WiFi device integration coming soon!'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class AnthropometryTab extends StatefulWidget {
  final Patient patient;
  const AnthropometryTab({super.key, required this.patient});

  @override
  AnthropometryTabState createState() => AnthropometryTabState();
}

class AnthropometryTabState extends State<AnthropometryTab> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double? height;
  double? weight;
  double? waist;
  double? hip;
  DateTime? date;

  String getAIInsight(List<Anthropometry> history) {
    if (history.length < 2) return 'Add more data for insights.';
    final last = history.last;
    final prev = history[history.length - 2];
    if (last.bmi > prev.bmi) {
      return 'BMI is increasing. Advise weight management.';
    }
    if (last.bmi < prev.bmi) return 'BMI is improving. Keep it up!';
    return 'BMI is stable.';
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.patient.anthropometryHistory;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Anthropometry',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: VoiceTextFormField(
                    controller: _heightController,
                    labelText: 'Height (cm)',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => height = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VoiceTextFormField(
                    controller: _weightController,
                    labelText: 'Weight (kg)',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => weight = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VoiceTextFormField(
                    controller: _waistController,
                    labelText: 'Waist (cm)',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => waist = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VoiceTextFormField(
                    controller: _hipController,
                    labelText: 'Hip (cm)',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => hip = double.tryParse(v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        widget.patient.anthropometryHistory.add(
                          Anthropometry(
                            height: height ?? 0,
                            weight: weight ?? 0,
                            bmi: (weight ?? 0) /
                                (((height ?? 1) / 100) * ((height ?? 1) / 100)),
                            waist: waist ?? 0,
                            hip: hip ?? 0,
                            date: DateTime.now(),
                          ),
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, i) {
                final entry = history[i];
                return ListTile(
                  title: Text(
                    'Date: 	${entry.date.toLocal().toString().split(' ')[0]}',
                  ),
                  subtitle: Text(
                    'Height: 	${entry.height} cm, Weight: 	${entry.weight} kg, BMI: 	${entry.bmi.toStringAsFixed(1)}, Waist: 	${entry.waist} cm, Hip: 	${entry.hip} cm',
                  ),
                  trailing: i > 0
                      ? Text(
                          'ΔBMI: ${(entry.bmi - history[i - 1].bmi).toStringAsFixed(1)}',
                        )
                      : null,
                );
              },
            ),
          ),
          Text(
            'AI Insight: ${getAIInsight(history)}',
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

class BPHistoryTab extends StatefulWidget {
  final Patient patient;
  const BPHistoryTab({super.key, required this.patient});

  @override
  BPHistoryTabState createState() => BPHistoryTabState();
}

class BPHistoryTabState extends State<BPHistoryTab> {
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? systolic;
  int? diastolic;
  int? pulse;

  String getAIInsight(List<BPReading> history) {
    if (history.length < 2) return 'Add more data for insights.';
    final last = history.last;
    final prev = history[history.length - 2];
    if (last.systolic > prev.systolic) {
      return 'Systolic BP rising. Monitor closely.';
    }
    if (last.systolic < prev.systolic) return 'Systolic BP improving.';
    return 'Systolic BP stable.';
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.patient.bpHistory;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add BP Reading',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: VoiceTextFormField(
                    controller: _systolicController,
                    labelText: 'Systolic',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => systolic = int.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VoiceTextFormField(
                    controller: _diastolicController,
                    labelText: 'Diastolic',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => diastolic = int.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VoiceTextFormField(
                    controller: _pulseController,
                    labelText: 'Pulse',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => pulse = int.tryParse(v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        widget.patient.bpHistory.add(
                          BPReading(
                            systolic: systolic ?? 0,
                            diastolic: diastolic ?? 0,
                            pulse: pulse ?? 0,
                            date: DateTime.now(),
                          ),
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, i) {
                final entry = history[i];
                return ListTile(
                  title: Text(
                    'Date: ${entry.date.toLocal().toString().split(' ')[0]}',
                  ),
                  subtitle: Text(
                    'Systolic: ${entry.systolic}, Diastolic: ${entry.diastolic}, Pulse: ${entry.pulse}',
                  ),
                  trailing: i > 0
                      ? Text(
                          'ΔSys: ${(entry.systolic - history[i - 1].systolic)}, ΔDia: ${(entry.diastolic - history[i - 1].diastolic)}',
                        )
                      : null,
                );
              },
            ),
          ),
          Text(
            'AI Insight: ${getAIInsight(history)}',
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

class SMBGHistoryTab extends StatefulWidget {
  final Patient patient;
  const SMBGHistoryTab({super.key, required this.patient});

  @override
  SMBGHistoryTabState createState() => SMBGHistoryTabState();
}

class SMBGHistoryTabState extends State<SMBGHistoryTab> {
  final TextEditingController _fastingController = TextEditingController();
  final TextEditingController _preLunchController = TextEditingController();
  final TextEditingController _preDinnerController = TextEditingController();
  final TextEditingController _postMealController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double? fasting;
  double? preLunch;
  double? preDinner;
  double? postMeal;

  String getAIInsight(List<SMBGReading> history) {
    if (history.length < 2) return 'Add more data for insights.';
    final last = history.last;
    final prev = history[history.length - 2];
    if (last.fasting > prev.fasting) {
      return 'Fasting glucose rising. Review diet/meds.';
    }
    if (last.fasting < prev.fasting) return 'Fasting glucose improving.';
    return 'Fasting glucose stable.';
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.patient.smbgHistory;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add SMBG Reading',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: VoiceTextFormField(
                    controller: _fastingController,
                    labelText: 'Fasting',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => fasting = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VoiceTextFormField(
                    controller: _preLunchController,
                    labelText: 'Pre-Lunch',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => preLunch = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VoiceTextFormField(
                    controller: _preDinnerController,
                    labelText: 'Pre-Dinner',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => preDinner = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VoiceTextFormField(
                    controller: _postMealController,
                    labelText: 'Post-Meal',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => postMeal = double.tryParse(v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        widget.patient.smbgHistory.add(
                          SMBGReading(
                            fasting: fasting ?? 0,
                            preLunch: preLunch ?? 0,
                            preDinner: preDinner ?? 0,
                            postMeal: postMeal ?? 0,
                            date: DateTime.now(),
                          ),
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, i) {
                final entry = history[i];
                return ListTile(
                  title: Text(
                    'Date: ${entry.date.toLocal().toString().split(' ')[0]}',
                  ),
                  subtitle: Text(
                    'Fasting: ${entry.fasting}, Pre-Lunch: ${entry.preLunch}, Pre-Dinner: ${entry.preDinner}, Post-Meal: ${entry.postMeal}',
                  ),
                  trailing: i > 0
                      ? Text(
                          'ΔF: ${(entry.fasting - history[i - 1].fasting).toStringAsFixed(1)}',
                        )
                      : null,
                );
              },
            ),
          ),
          Text(
            'AI Insight: ${getAIInsight(history)}',
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
