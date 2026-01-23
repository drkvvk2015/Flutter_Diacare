import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';

class SMBGService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SMBGReading>> getSMBGHistory(String patientId) async {
    final snapshot = await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('smbg')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SMBGReading(
        fasting: ((data['fasting'] as num?) ?? 0).toDouble(),
        preLunch: ((data['preLunch'] as num?) ?? 0).toDouble(),
        preDinner: ((data['preDinner'] as num?) ?? 0).toDouble(),
        postMeal: ((data['postMeal'] as num?) ?? 0).toDouble(),
        date: DateTime.parse(data['date'] as String? ?? DateTime.now().toIso8601String()),
      );
    }).toList();
  }
}
