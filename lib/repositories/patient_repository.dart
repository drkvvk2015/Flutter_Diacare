/// Patient Repository
/// 
/// Handles all patient-related data operations.
/// Manages patient records, health history, and medical data.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/patient.dart';
import '../utils/logger.dart';

/// Repository for patient data management
class PatientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiClient _apiClient = ApiClient();

  /// Get all patients
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    try {
      final snapshot = await _firestore.collection('patients').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      logError('Error fetching patients', e);
      rethrow;
    }
  }

  /// Get patient by ID
  Future<Map<String, dynamic>?> getPatientById(String patientId) async {
    try {
      final doc = await _firestore.collection('patients').doc(patientId).get();
      
      if (!doc.exists) {
        logWarning('Patient not found: $patientId');
        return null;
      }

      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      logError('Error fetching patient', e);
      rethrow;
    }
  }

  /// Create new patient
  Future<String> createPatient(Map<String, dynamic> patientData) async {
    try {
      logInfo('Creating new patient');

      patientData['createdAt'] = FieldValue.serverTimestamp();
      patientData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('patients').add(patientData);
      
      logInfo('Patient created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logError('Error creating patient', e);
      rethrow;
    }
  }

  /// Update patient information
  Future<void> updatePatient(
    String patientId,
    Map<String, dynamic> updates,
  ) async {
    try {
      logInfo('Updating patient: $patientId');

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('patients').doc(patientId).update(updates);
      
      logInfo('Patient updated successfully');
    } catch (e) {
      logError('Error updating patient', e);
      rethrow;
    }
  }

  /// Delete patient
  Future<void> deletePatient(String patientId) async {
    try {
      logInfo('Deleting patient: $patientId');
      await _firestore.collection('patients').doc(patientId).delete();
      logInfo('Patient deleted successfully');
    } catch (e) {
      logError('Error deleting patient', e);
      rethrow;
    }
  }

  /// Add anthropometry reading
  Future<void> addAnthropometryReading(
    String patientId,
    Anthropometry reading,
  ) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('anthropometry')
          .add({
        'height': reading.height,
        'weight': reading.weight,
        'bmi': reading.bmi,
        'waist': reading.waist,
        'hip': reading.hip,
        'date': Timestamp.fromDate(reading.date),
        'createdAt': FieldValue.serverTimestamp(),
      });

      logInfo('Anthropometry reading added for patient: $patientId');
    } catch (e) {
      logError('Error adding anthropometry reading', e);
      rethrow;
    }
  }

  /// Add blood pressure reading
  Future<void> addBPReading(String patientId, BPReading reading) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('bloodPressure')
          .add({
        'systolic': reading.systolic,
        'diastolic': reading.diastolic,
        'pulse': reading.pulse,
        'date': Timestamp.fromDate(reading.date),
        'createdAt': FieldValue.serverTimestamp(),
      });

      logInfo('BP reading added for patient: $patientId');
    } catch (e) {
      logError('Error adding BP reading', e);
      rethrow;
    }
  }

  /// Add blood glucose reading
  Future<void> addSMBGReading(String patientId, SMBGReading reading) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('bloodGlucose')
          .add({
        'fasting': reading.fasting,
        'preLunch': reading.preLunch,
        'preDinner': reading.preDinner,
        'postMeal': reading.postMeal,
        'date': Timestamp.fromDate(reading.date),
        'createdAt': FieldValue.serverTimestamp(),
      });

      logInfo('Blood glucose reading added for patient: $patientId');
    } catch (e) {
      logError('Error adding blood glucose reading', e);
      rethrow;
    }
  }

  /// Get patient's anthropometry history
  Future<List<Anthropometry>> getAnthropometryHistory(
    String patientId, {
    int limit = 30,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('anthropometry')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Anthropometry(
          height: (data['height'] as num).toDouble(),
          weight: (data['weight'] as num).toDouble(),
          bmi: (data['bmi'] as num).toDouble(),
          waist: (data['waist'] as num).toDouble(),
          hip: (data['hip'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      logError('Error fetching anthropometry history', e);
      rethrow;
    }
  }

  /// Get patient's blood pressure history
  Future<List<BPReading>> getBPHistory(
    String patientId, {
    int limit = 30,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('bloodPressure')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BPReading(
          systolic: data['systolic'] as int,
          diastolic: data['diastolic'] as int,
          pulse: data['pulse'] as int,
          date: (data['date'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      logError('Error fetching BP history', e);
      rethrow;
    }
  }

  /// Get patient's blood glucose history
  Future<List<SMBGReading>> getSMBGHistory(
    String patientId, {
    int limit = 30,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('bloodGlucose')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SMBGReading(
          fasting: (data['fasting'] as num).toDouble(),
          preLunch: (data['preLunch'] as num).toDouble(),
          preDinner: (data['preDinner'] as num).toDouble(),
          postMeal: (data['postMeal'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      logError('Error fetching blood glucose history', e);
      rethrow;
    }
  }

  /// Search patients by name or UHID
  Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    try {
      // Search by name
      final nameSnapshot = await _firestore
          .collection('patients')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query\uf8ff')
          .get();

      // Search by UHID
      final uhidSnapshot = await _firestore
          .collection('patients')
          .where('uhid', isEqualTo: query)
          .get();

      final results = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      for (final doc in [...nameSnapshot.docs, ...uhidSnapshot.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      logError('Error searching patients', e);
      rethrow;
    }
  }
}
