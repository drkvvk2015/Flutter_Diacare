import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../models/patient_hive.dart';
import 'patient_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _patients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final user = FirebaseAuth.instance.currentUser;
    final doctorId = user?.uid;
    if (doctorId == null) {
      setState(() {
        _error = 'Not logged in';
        _loading = false;
      });
      return;
    }
    try {
      // Try Firestore first
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final patients = snapshot.docs.map((doc) {
          final data = doc.data();
          return Patient(
            id: doc.id,
            uhid: data['uhid'] ?? '',
            name: data['name'] ?? '',
          );
        }).toList();
        setState(() {
          _patients = patients;
          _loading = false;
        });
        // Cache in Hive
        final box = Hive.box<PatientHive>('patients');
        await box.clear();
        for (final p in patients) {
          box.put(p.id, PatientHive(id: p.id, uhid: p.uhid, name: p.name));
        }
        return;
      }
    } catch (e) {
      // Firestore failed, try Hive
      debugPrint('Firestore error: $e');
    }
    // Load from Hive
    try {
      final box = Hive.box<PatientHive>('patients');
      final patients = box.values
          .map((h) => Patient(id: h.id, uhid: h.uhid, name: h.name))
          .toList();
      setState(() {
        _patients = patients;
        _loading = false;
        if (patients.isEmpty) {
          _error = 'No patients found.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'No patients found.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Management')),
        body: Center(child: Text(_error!)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Management')),
      body: _patients.isEmpty
          ? const Center(child: Text('No patients found.'))
          : ListView.builder(
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(patient.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.green),
                          tooltip: 'Chat',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: {'patient': patient},
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.medical_services,
                            color: Colors.deepPurple,
                          ),
                          tooltip: 'Edit E-Prescription',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/prescription',
                              arguments: {
                                'patient': patient,
                                'viewOnly': false,
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.folder_copy,
                            color: Colors.blue,
                          ),
                          tooltip: 'Digital Health Record',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/records',
                              arguments: {'patient': patient},
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.teal),
                          tooltip: 'Print E-Prescription',
                          onPressed: () {
                            // Implement print logic or navigation here
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientDetailScreen(patient: patient),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
