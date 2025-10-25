import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';

class AnthropometryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Anthropometry>> getAnthropometryHistory(String patientId) async {
    final snapshot = await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('anthropometry')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Anthropometry(
        height: (data['height'] ?? 0).toDouble(),
        weight: (data['weight'] ?? 0).toDouble(),
        bmi: (data['bmi'] ?? 0).toDouble(),
        waist: (data['waist'] ?? 0).toDouble(),
        hip: (data['hip'] ?? 0).toDouble(),
        date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      );
    }).toList();
  }

  // Add similar methods for BP and SMBG if needed
}
