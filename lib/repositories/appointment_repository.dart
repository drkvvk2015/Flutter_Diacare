/// Appointment Repository
/// 
/// Handles all appointment-related data operations.
/// Manages appointment scheduling, updates, and queries.
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// Repository for appointment data management
class AppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get appointments for a user (doctor or patient)
  Future<List<Map<String, dynamic>>> getAppointmentsByUser(
    String userId,
    String userRole,
  ) async {
    try {
      final field = userRole == 'doctor' ? 'doctorId' : 'patientId';
      
      final snapshot = await _firestore
          .collection('appointments')
          .where(field, isEqualTo: userId)
          .orderBy('dateTime', descending: false)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      },).toList();
    } catch (e) {
      logError('Error fetching appointments', e);
      rethrow;
    }
  }

  /// Get appointment by ID
  Future<Map<String, dynamic>?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!doc.exists) {
        logInfo('Appointment not found: $appointmentId');
        return null;
      }

      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      logError('Error fetching appointment', e);
      rethrow;
    }
  }

  /// Create new appointment
  Future<String> createAppointment(Map<String, dynamic> appointmentData) async {
    try {
      logInfo('Creating new appointment');

      appointmentData['createdAt'] = FieldValue.serverTimestamp();
      appointmentData['updatedAt'] = FieldValue.serverTimestamp();
      appointmentData['status'] = appointmentData['status'] ?? 'scheduled';

      final docRef = await _firestore
          .collection('appointments')
          .add(appointmentData);

      logInfo('Appointment created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logError('Error creating appointment', e);
      rethrow;
    }
  }

  /// Update appointment
  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      logInfo('Updating appointment: $appointmentId');

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update(updates);

      logInfo('Appointment updated successfully');
    } catch (e) {
      logError('Error updating appointment', e);
      rethrow;
    }
  }

  /// Cancel appointment
  Future<void> cancelAppointment(
    String appointmentId,
    String reason,
  ) async {
    try {
      logInfo('Cancelling appointment: $appointmentId');

      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logInfo('Appointment cancelled successfully');
    } catch (e) {
      logError('Error cancelling appointment', e);
      rethrow;
    }
  }

  /// Get upcoming appointments
  Future<List<Map<String, dynamic>>> getUpcomingAppointments(
    String userId,
    String userRole,
  ) async {
    try {
      final field = userRole == 'doctor' ? 'doctorId' : 'patientId';
      final now = Timestamp.now();

      final snapshot = await _firestore
          .collection('appointments')
          .where(field, isEqualTo: userId)
          .where('dateTime', isGreaterThan: now)
          .where('status', isEqualTo: 'scheduled')
          .orderBy('dateTime', descending: false)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      },).toList();
    } catch (e) {
      logError('Error fetching upcoming appointments', e);
      rethrow;
    }
  }

  /// Get past appointments
  Future<List<Map<String, dynamic>>> getPastAppointments(
    String userId,
    String userRole, {
    int limit = 20,
  }) async {
    try {
      final field = userRole == 'doctor' ? 'doctorId' : 'patientId';
      final now = Timestamp.now();

      final snapshot = await _firestore
          .collection('appointments')
          .where(field, isEqualTo: userId)
          .where('dateTime', isLessThan: now)
          .orderBy('dateTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      },).toList();
    } catch (e) {
      logError('Error fetching past appointments', e);
      rethrow;
    }
  }

  /// Get appointments for a specific date
  Future<List<Map<String, dynamic>>> getAppointmentsByDate(
    String userId,
    String userRole,
    DateTime date,
  ) async {
    try {
      final field = userRole == 'doctor' ? 'doctorId' : 'patientId';
      
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('appointments')
          .where(field, isEqualTo: userId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('dateTime', descending: false)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      },).toList();
    } catch (e) {
      logError('Error fetching appointments by date', e);
      rethrow;
    }
  }

  /// Complete appointment
  Future<void> completeAppointment(
    String appointmentId,
    Map<String, dynamic>? notes,
  ) async {
    try {
      logInfo('Completing appointment: $appointmentId');

      final updates = {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updates['completionNotes'] = notes;
      }

      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update(updates);

      logInfo('Appointment completed successfully');
    } catch (e) {
      logError('Error completing appointment', e);
      rethrow;
    }
  }
}
