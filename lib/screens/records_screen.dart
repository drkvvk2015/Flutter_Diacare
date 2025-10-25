import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import '../models/patient.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../widgets/glassmorphic_card.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Widget> _buildRecordWidgets() {
    List<Widget> widgets = [];
    // --- Smart Alerts Section ---
    List<Widget> alerts = [];
    if (bpHistory.isNotEmpty && (bpHistory.last['systolic'] ?? 0) > 140) {
      alerts.add(
        Container(
          color: Colors.red[100],
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 6),
          child: Semantics(
            label: 'High Blood Pressure detected',
            child: const Text(
              'High Blood Pressure detected!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
    if (smbgHistory.isNotEmpty && (smbgHistory.last['fasting'] ?? 0) > 180) {
      alerts.add(
        Container(
          color: Colors.red[100],
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 6),
          child: Semantics(
            label: 'High Fasting Glucose detected',
            child: const Text(
              'High Fasting Glucose detected!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
    if (anthropometryHistory.isNotEmpty &&
        (anthropometryHistory.last['bmi'] ?? 0) > 30) {
      alerts.add(
        Container(
          color: Colors.orange[100],
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 6),
          child: Semantics(
            label: 'Obesity risk: High BMI detected',
            child: const Text(
              'Obesity risk: High BMI detected!',
              style: TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
    if (labReports.isNotEmpty) {
      final lastLab = labReports.last;
      final lastLabDate =
          DateTime.tryParse(lastLab['date'] ?? '') ?? DateTime.now();
      if (DateTime.now().difference(lastLabDate).inDays > 90) {
        alerts.add(
          Container(
            color: Colors.yellow[100],
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 6),
            child: Semantics(
              label: 'Reminder: It has been over 3 months since last lab test.',
              child: const Text(
                'Reminder: It has been over 3 months since last lab test.',
                style: TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }
    if (alerts.isEmpty) {
      alerts.add(
        Semantics(
          label: 'No smart alerts. All values normal.',
          child: const Text(
            'No smart alerts. All values normal.',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    widgets.add(
      Semantics(
        label: 'Smart Alerts Section',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Smart Alerts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...alerts,
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    // --- Pending Patient Entries ---
    if (pendingEntries.isNotEmpty &&
        (userRole == 'doctor' || userRole == 'admin')) {
      widgets.add(
        Semantics(
          label: 'Pending Patient Entries Section',
          child: Card(
            color: Colors.yellow[50],
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Patient Entries',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...pendingEntries.map(
                    (entry) => ListTile(
                      title: Text('${entry['type']}: ${entry['value']}'),
                      subtitle: Text(
                        'Date: ${entry['date']?.toString().substring(0, 16) ?? ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: 'Approve Entry',
                            child: IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              tooltip: 'Approve',
                              onPressed: () async {
                                final args =
                                    ModalRoute.of(context)?.settings.arguments
                                        as Map<String, dynamic>?;
                                final pid = args?['patient']?.id ?? '';
                                await approvePendingEntry(entry, pid);
                                await fetchData(pid);
                              },
                            ),
                          ),
                          Semantics(
                            label: 'Reject Entry',
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Reject',
                              onPressed: () async {
                                final args =
                                    ModalRoute.of(context)?.settings.arguments
                                        as Map<String, dynamic>?;
                                final pid = args?['patient']?.id ?? '';
                                await rejectPendingEntry(entry, pid);
                                await fetchData(pid);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    // --- Timeline Section ---
    List<Map<String, dynamic>> eventList = [];
    for (var a in anthropometryHistory) {
      eventList.add({
        'date': a['date'] ?? '',
        'widget': ListTile(
          leading: const Icon(Icons.accessibility_new, color: Colors.orange),
          title: Text(
            'Anthropometry: BMI ${a['bmi']?.toStringAsFixed(1) ?? ''}',
          ),
          subtitle: Text(
            'Date: ${a['date']?.toString().substring(0, 10) ?? ''}',
          ),
        ),
      });
    }
    for (var bp in bpHistory) {
      eventList.add({
        'date': bp['date'] ?? '',
        'widget': ListTile(
          leading: const Icon(Icons.favorite, color: Colors.red),
          title: Text('BP: ${bp['systolic']}/${bp['diastolic']}'),
          subtitle: Text(
            'Date: ${bp['date']?.toString().substring(0, 10) ?? ''}',
          ),
        ),
      });
    }
    for (var s in smbgHistory) {
      eventList.add({
        'date': s['date'] ?? '',
        'widget': ListTile(
          leading: const Icon(Icons.bloodtype, color: Colors.blue),
          title: Text('Glucose: ${s['fasting']} mg/dL'),
          subtitle: Text(
            'Date: ${s['date']?.toString().substring(0, 10) ?? ''}',
          ),
        ),
      });
    }
    for (var lab in labReports) {
      eventList.add({
        'date': lab['date'] ?? '',
        'widget': ListTile(
          leading: const Icon(Icons.science, color: Colors.green),
          title: Text('${lab['test']}: ${lab['value']}'),
          subtitle: Text('Date: ${lab['date'].toString().substring(0, 10)}'),
        ),
      });
    }
    eventList.sort(
      (a, b) =>
          (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()),
    );
    widgets.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...eventList.map((e) => e['widget'] as Widget),
          const SizedBox(height: 16),
        ],
      ),
    );

    // --- Charts Section ---
    widgets.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Charts', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (bpHistory.isNotEmpty)
            RepaintBoundary(
              key: bpChartKey,
              child: buildLineChart(
                values: bpHistory
                    .map((e) => (e['systolic'] ?? 0).toDouble())
                    .toList()
                    .cast<double>(),
                title: 'Systolic BP',
                yLabel: 'mmHg',
              ),
            ),
          if (smbgHistory.isNotEmpty)
            RepaintBoundary(
              key: glucoseChartKey,
              child: buildLineChart(
                values: smbgHistory
                    .map((e) => (e['fasting'] ?? 0).toDouble())
                    .toList()
                    .cast<double>(),
                title: 'Fasting Glucose',
                yLabel: 'mg/dL',
              ),
            ),
          if (labReports.any((e) => e['test'] == 'HbA1c'))
            RepaintBoundary(
              key: hba1cChartKey,
              child: buildLineChart(
                values: labReports
                    .where((e) => e['test'] == 'HbA1c')
                    .map((e) => (e['value'] ?? 0).toDouble())
                    .toList()
                    .cast<double>(),
                title: 'HbA1c',
                yLabel: '%',
              ),
            ),
          if (showMultiChart)
            RepaintBoundary(
              key: multiChartKey,
              child: buildLineChart(
                values: bpHistory
                    .map((e) => (e['systolic'] ?? 0).toDouble())
                    .toList()
                    .cast<double>(),
                title: 'Multi-metric Chart (Systolic BP)',
                yLabel: 'mmHg',
              ),
            ),
          if (anthropometryHistory.isNotEmpty)
            RepaintBoundary(
              child: buildLineChart(
                values: anthropometryHistory
                    .map((e) => (e['weight'] ?? 0).toDouble())
                    .toList()
                    .cast<double>(),
                title: 'Weight Trend',
                yLabel: 'kg',
              ),
            ),
          if (anthropometryHistory.isNotEmpty)
            RepaintBoundary(
              child: buildLineChart(
                values: anthropometryHistory
                    .map((e) => (e['bmi'] ?? 0).toDouble())
                    .toList()
                    .cast<double>(),
                title: 'BMI Trend',
                yLabel: '',
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );

    // --- Doctor Notes Section ---
    widgets.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doctor Notes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (doctorNotes.isEmpty) const Text('No notes.'),
          ...doctorNotes.map(
            (note) => ListTile(
              leading: const Icon(Icons.note),
              title: Text(note['note'] ?? ''),
              subtitle: Text(
                'Date: ${note['date']?.toString().substring(0, 16) ?? ''}',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    // --- Attachments Section ---
    widgets.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attachments',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (attachments.isEmpty) const Text('No attachments.'),
          ...attachments.map(
            (a) => ListTile(
              leading: const Icon(Icons.attachment),
              title: Text(a['name'] ?? ''),
              subtitle: Text(
                'Date: ${a['date']?.toString().substring(0, 16) ?? ''}',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    // --- Lab Reports Section ---
    widgets.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lab Reports',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (labReports.isEmpty) const Text('No lab reports.'),
          ...labReports.map(
            (lab) => ListTile(
              leading: const Icon(Icons.science),
              title: Text('${lab['test']}: ${lab['value']}'),
              subtitle: Text(
                'Date: ${lab['date']?.toString().substring(0, 16) ?? ''}',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    return widgets;
  }

  // Timeline filter
  String timelineFilter = 'All';
  final List<String> timelineTypes = [
    'All',
    'Anthropometry',
    'BP',
    'Glucose',
    'Lab',
  ];
  // Multi-metric chart data
  bool showMultiChart = false;
  String? userRole;

  // GlobalKeys for chart RepaintBoundaries
  final GlobalKey bpChartKey = GlobalKey();
  final GlobalKey glucoseChartKey = GlobalKey();
  final GlobalKey hba1cChartKey = GlobalKey();
  final GlobalKey multiChartKey = GlobalKey();

  Future<void> fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() {
        userRole = doc.data()?['role'] ?? 'doctor';
      });
    }
  }

  List<Map<String, dynamic>> pendingEntries = [];

  Future<void> fetchPendingEntries(String patientId) async {
    final query = await FirebaseFirestore.instance
        .collection('pending_entries')
        .where('patientId', isEqualTo: patientId)
        .get();
    if (!mounted) return;
    setState(() {
      pendingEntries = query.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
    });
  }

  Future<void> approvePendingEntry(
    Map<String, dynamic> entry,
    String patientId,
  ) async {
    // Move entry to appropriate section
    if (entry['type'] == 'BP') {
      bpHistory.add({
        'systolic': int.tryParse(entry['value'].split('/')[0]) ?? 0,
        'diastolic': int.tryParse(entry['value'].split('/')[1]) ?? 0,
        'date': entry['date'],
      });
      await FirebaseFirestore.instance
          .collection('health_records')
          .doc(patientId)
          .set({'bpHistory': bpHistory}, SetOptions(merge: true));
    } else if (entry['type'] == 'Glucose') {
      smbgHistory.add({
        'fasting': double.tryParse(entry['value']) ?? 0,
        'date': entry['date'],
      });
      await FirebaseFirestore.instance
          .collection('health_records')
          .doc(patientId)
          .set({'smbgHistory': smbgHistory}, SetOptions(merge: true));
    } else if (entry['type'] == 'Weight') {
      anthropometryHistory.add({
        'weight': double.tryParse(entry['value']) ?? 0,
        'date': entry['date'],
      });
      await FirebaseFirestore.instance
          .collection('health_records')
          .doc(patientId)
          .set({
            'anthropometryHistory': anthropometryHistory,
          }, SetOptions(merge: true));
    } else if (entry['type'] == 'Lab') {
      labReports.add({
        'test': 'Patient Lab',
        'value': double.tryParse(entry['value']) ?? 0,
        'date': entry['date'],
      });
      await FirebaseFirestore.instance
          .collection('health_records')
          .doc(patientId)
          .set({'labReports': labReports}, SetOptions(merge: true));
    }
    // Remove from pending
    await FirebaseFirestore.instance
        .collection('pending_entries')
        .doc(entry['id'])
        .delete();
    await fetchPendingEntries(patientId);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> rejectPendingEntry(
    Map<String, dynamic> entry,
    String patientId,
  ) async {
    await FirebaseFirestore.instance
        .collection('pending_entries')
        .doc(entry['id'])
        .delete();
    await fetchPendingEntries(patientId);
    if (!mounted) return;
    setState(() {});
  }

  // Calculate a simple risk score based on available data
  int getRiskScore() {
    int score = 0;
    if (bpHistory.isNotEmpty && (bpHistory.last['systolic'] ?? 0) > 140) {
      score++;
    }
    if (smbgHistory.isNotEmpty && (smbgHistory.last['fasting'] ?? 0) > 180) {
      score++;
    }
    if (anthropometryHistory.isNotEmpty &&
        (anthropometryHistory.last['bmi'] ?? 0) > 30) {
      score++;
    }
    if (labReports.any(
      (lab) => lab['test'] == 'HbA1c' && (lab['value'] ?? 0) > 8,
    )) {
      score++;
    }
    return score;
  }

  String getRiskAdvice(int score) {
    if (score == 0) return 'Low risk. Keep up the good work!';
    if (score == 1) return 'Mild risk. Monitor regularly.';
    if (score == 2) return 'Moderate risk. Consider lifestyle changes.';
    return 'High risk. Consult your doctor for advice.';
  }

  Map<String, dynamic> clinicalHistory = {};
  List<Map<String, dynamic>> labReports = [];
  List<dynamic> anthropometryHistory = [];
  List<dynamic> bpHistory = [];
  List<dynamic> smbgHistory = [];
  List<Map<String, dynamic>> doctorNotes = [];
  List<Map<String, dynamic>> attachments = [];
  bool loading = true;

  final TextEditingController labTestController = TextEditingController();
  final TextEditingController labValueController = TextEditingController();

  @override
  void dispose() {
    labTestController.dispose();
    labValueController.dispose();
    super.dispose();
  }

  Future<void> fetchData(String patientId) async {
    if (mounted) setState(() => loading = true);
    final doc = await FirebaseFirestore.instance
        .collection('health_records')
        .doc(patientId)
        .get();
    if (!mounted) return;
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      setState(() {
        clinicalHistory = data['clinicalHistory'] ?? {};
        labReports = List<Map<String, dynamic>>.from(data['labReports'] ?? []);
        anthropometryHistory = List.from(data['anthropometryHistory'] ?? []);
        bpHistory = List.from(data['bpHistory'] ?? []);
        smbgHistory = List.from(data['smbgHistory'] ?? []);
        doctorNotes = List<Map<String, dynamic>>.from(
          data['doctorNotes'] ?? [],
        );
        attachments = List<Map<String, dynamic>>.from(
          data['attachments'] ?? [],
        );
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> saveLabReport(String patientId) async {
    labReports.add({
      'test': labTestController.text,
      'value': double.tryParse(labValueController.text) ?? 0,
      'date': DateTime.now().toIso8601String(),
    });
    await FirebaseFirestore.instance
        .collection('health_records')
        .doc(patientId)
        .set({'labReports': labReports}, SetOptions(merge: true));
    labTestController.clear();
    labValueController.clear();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> saveDoctorNote(String patientId, String note) async {
    doctorNotes.add({'note': note, 'date': DateTime.now().toIso8601String()});
    await FirebaseFirestore.instance
        .collection('health_records')
        .doc(patientId)
        .set({'doctorNotes': doctorNotes}, SetOptions(merge: true));
    if (!mounted) return;
    setState(() {});
  }

  Future<void> uploadAttachment(String patientId) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      // For demo: just store file name and path. In production, upload to Firebase Storage and store the URL.
      attachments.add({
        'name': result.files.single.name,
        'path': file.path,
        'date': DateTime.now().toIso8601String(),
      });
      await FirebaseFirestore.instance
          .collection('health_records')
          .doc(patientId)
          .set({'attachments': attachments}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {});
    }
  }

  Color? getAlertColor(String type, num? value) {
    if (type == 'bp' && value != null && value > 140) return Colors.red[100];
    if (type == 'glucose' && value != null && value > 180) {
      return Colors.red[100];
    }
    if (type == 'bmi' && value != null && (value < 18.5 || value > 30)) {
      return Colors.orange[100];
    }
    return null;
  }

  String getAnthropometryAI(List history) {
    if (history.length < 2) return 'Add more data for insights.';
    final last = history.last;
    final prev = history[history.length - 2];
    if ((last['bmi'] ?? 0) > (prev['bmi'] ?? 0)) {
      return 'BMI is increasing. Advise weight management.';
    }
    if ((last['bmi'] ?? 0) < (prev['bmi'] ?? 0)) {
      return 'BMI is improving. Keep it up!';
    }
    return 'BMI is stable.';
  }

  String getLabAI(List<Map<String, dynamic>> labs) {
    if (labs.isEmpty) return 'No lab data.';
    final fbs = labs.lastWhere(
      (e) => e['test'] == 'FBS',
      orElse: () => <String, dynamic>{},
    );
    if (fbs.isNotEmpty && fbs['value'] != null && fbs['value'] > 126) {
      return 'FBS is high. Review glycemic control.';
    }
    return 'Labs within normal limits.';
  }

  Widget buildTimeline() {
    List<Map<String, dynamic>> eventList = [];
    for (var a in anthropometryHistory) {
      eventList.add({
        'date': a['date'] ?? '',
        'widget': ListTile(
          leading: const Icon(Icons.accessibility_new, color: Colors.orange),
          title: Text(
            'Anthropometry: BMI ${a['bmi']?.toStringAsFixed(1) ?? ''}',
          ),
          subtitle: Text(
            'Date: ${a['date']?.toString().substring(0, 10) ?? ''}',
          ),
        ),
      });
    }
    for (var bp in bpHistory) {
      eventList.add({
        'date': bp['date'] ?? '',
        'widget': ListTile(
          leading: const Icon(Icons.favorite, color: Colors.red),
          title: Text('BP: ${bp['systolic']}/${bp['diastolic']}'),
          subtitle: Text(
            'Date: ${bp['date']?.toString().substring(0, 10) ?? ''}',
          ),
        ),
      });
    }
    for (var s in smbgHistory) {
      eventList.add({
        'date': s['date'] ?? '',
        'widget': ListTile(
          leading: const Icon(Icons.bloodtype, color: Colors.blue),
          title: Text('Glucose: ${s['fasting']} mg/dL'),
          subtitle: Text(
            'Date: ${s['date']?.toString().substring(0, 10) ?? ''}',
          ),
        ),
      });
    }
    for (var lab in labReports) {
      eventList.add({
        'date': lab['date'] ?? '',
        'widget': ListTile(
          leading: const Icon(Icons.science, color: Colors.green),
          title: Text('${lab['test']}: ${lab['value']}'),
          subtitle: Text('Date: ${lab['date'].toString().substring(0, 10)}'),
        ),
      });
    }
    eventList.sort(
      (a, b) =>
          (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...eventList.map((e) => e['widget'] as Widget),
      ],
    );
  }

  Widget buildLineChart({
    required List<double> values,
    required String title,
    String? yLabel,
  }) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i]),
                  ],
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        if (yLabel != null) Text(yLabel, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Patient? patient = args?['patient'];
    final patientId = patient?.id;
    if (userRole == null) {
      fetchUserRole();
    }
    if (patientId != null && loading) {
      fetchData(patientId);
      fetchPendingEntries(patientId);
    }
    final gradient = LinearGradient(
      colors: [
        Colors.teal.shade400,
        Colors.blue.shade200,
        Colors.purple.shade200,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Hero(
          tag: 'records-appbar',
          child: Material(
            color: Colors.transparent,
            child: Text(
              'Digital Health Records',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (patient != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export as PDF',
              onPressed: () async {
                // ...existing code for PDF export...
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(gradient: gradient),
          ),
          patient == null
              ? const Center(child: Text('No patient selected.'))
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildRecordWidgets()
                                .map(
                                  (w) => GlassmorphicCard(
                                    borderRadius: 20,
                                    padding: const EdgeInsets.all(12),
                                    child: w,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
        ],
      ),
    );
  }
}
