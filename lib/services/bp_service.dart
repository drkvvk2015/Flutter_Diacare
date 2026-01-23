import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';

class BPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<BPReading>> getBPHistory(String patientId) async {
    final snapshot = await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('bp')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BPReading(
        systolic: (data['systolic'] ?? 0) as int,
        diastolic: (data['diastolic'] ?? 0) as int,
        pulse: (data['pulse'] ?? 0) as int,
        date: DateTime.parse(data['date'] as String? ?? DateTime.now().toIso8601String()),
      );
    }).toList();
  }
}
