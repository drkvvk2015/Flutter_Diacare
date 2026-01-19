import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_model.dart';
import 'package:hive/hive.dart';
import '../../models/appointment_hive.dart';
import '../../utils/logger.dart';

class AppointmentService {
  final _appointments = FirebaseFirestore.instance.collection('appointments');
  final int _maxRetries = 3;

  // Get appointments with retry mechanism
  Future<List<Appointment>> getAppointmentsForUser(
    String userId,
    String role,
  ) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        logInfo(
          'Attempt ${attempts + 1}: Fetching appointments for $userId ($role)',
        );
        QuerySnapshot snapshot;
        if (role == 'doctor') {
          snapshot = await _appointments
              .where('doctorId', isEqualTo: userId)
              .orderBy('time')
              .get();
        } else {
          snapshot = await _appointments
              .where('patientId', isEqualTo: userId)
              .orderBy('time')
              .get();
        }
        final appts = snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList();

        logInfo('Found ${appts.length} appointments');

        // Debug: Print all appointments
        for (var i = 0; i < appts.length; i++) {
          logInfo(
            'Appointment ${i + 1}: ID=${appts[i].id} patient=${appts[i].patientId} doctor=${appts[i].doctorId} status=${appts[i].status} time=${appts[i].time}',
          );
        }

        // Cache in Hive
        try {
          final box = Hive.box<AppointmentHive>('appointments');
          await box.clear();
          for (final a in appts) {
            box.put(
              a.id,
              AppointmentHive(
                id: a.id,
                patientId: a.patientId,
                doctorId: a.doctorId,
                time: a.time,
                status: a.status,
                notes: a.notes,
                fee: a.fee,
              ),
            );
          }
          logInfo('Cached ${appts.length} appointments in Hive');
        } catch (hiveError) {
          logWarn('Failed to cache in Hive: $hiveError');
          // Continue even if caching fails
        }

        return appts;
      } catch (e) {
        attempts++;
        logError('Error fetching appointments (attempt $attempts)', e);

        if (attempts >= _maxRetries) {
          logWarn('All attempts failed, falling back to Hive cache');
          // All attempts failed, try Hive
          try {
            final box = Hive.box<AppointmentHive>('appointments');
            final List<Appointment> cachedAppts = box.values
                .map(
                  (h) => Appointment(
                    id: h.id,
                    patientId: h.patientId,
                    doctorId: h.doctorId,
                    time: h.time,
                    status: h.status,
                    notes: h.notes,
                    fee: h.fee,
                  ),
                )
                .toList();
            logInfo(
              'Retrieved ${cachedAppts.length} appointments from Hive cache',
            );
            return cachedAppts;
          } catch (hiveError) {
            logError('Hive cache retrieval failed', hiveError);
            rethrow; // Rethrow the original Firestore error
          }
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: 1 * attempts));
      }
    }

    // This should not be reached due to the structure of the while loop
    throw Exception('Failed to fetch appointments after $_maxRetries attempts');
  }

  // Book appointment with retry mechanism
  Future<String?> bookAppointment(Appointment appt) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        logInfo(
          'Attempt ${attempts + 1}: Book appt patient=${appt.patientId} doctor=${appt.doctorId} time=${appt.time} status=${appt.status}',
        );

        // Validate required fields
        if (appt.patientId.isEmpty) {
          throw Exception('Patient ID cannot be empty');
        }
        if (appt.doctorId.isEmpty) {
          throw Exception('Doctor ID cannot be empty');
        }

        // Add appointment to Firestore
        final docRef = await _appointments.add(appt.toMap());
        final appointmentId = docRef.id;
        logInfo('Appointment booked id=$appointmentId');

        // Also add to Hive cache
        try {
          final box = Hive.box<AppointmentHive>('appointments');
          box.put(
            appointmentId,
            AppointmentHive(
              id: appointmentId,
              patientId: appt.patientId,
              doctorId: appt.doctorId,
              time: appt.time,
              status: appt.status,
              notes: appt.notes,
              fee: appt.fee,
            ),
          );
          logInfo('Appointment cached in Hive');
        } catch (hiveError) {
          logWarn('Failed to cache in Hive: $hiveError');
          // Continue even if caching fails
        }

        return appointmentId;
      } catch (e) {
        attempts++;
        logError('Error booking appointment (attempt $attempts)', e);

        if (attempts >= _maxRetries) {
          logError('All booking attempts failed', e);
          throw Exception(
            'Failed to book appointment after $_maxRetries attempts: $e',
          );
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: 1 * attempts));
      }
    }

    return null;
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      logInfo('Update status id=$id -> $status');
      await _appointments.doc(id).update({'status': status});
      logInfo('Status updated');

      // Update Hive cache
      try {
        final box = Hive.box<AppointmentHive>('appointments');
        final hiveAppt = box.get(id);
        if (hiveAppt != null) {
          hiveAppt.status = status;
          await hiveAppt.save();
        }
      } catch (e) {
        logWarn('Failed to update Hive cache: $e');
      }
    } catch (e) {
      logError('Error updating appointment status', e);
      throw Exception('Failed to update appointment status: $e');
    }
  }

  Future<void> addNotes(String id, String notes) async {
    try {
      logInfo('Add notes id=$id');
      await _appointments.doc(id).update({'notes': notes});
      logInfo('Notes updated');

      // Update Hive cache
      try {
        final box = Hive.box<AppointmentHive>('appointments');
        final hiveAppt = box.get(id);
        if (hiveAppt != null) {
          hiveAppt.notes = notes;
          await hiveAppt.save();
        }
      } catch (e) {
        logWarn('Failed to update Hive cache: $e');
      }
    } catch (e) {
      logError('Error updating appointment notes', e);
      throw Exception('Failed to update appointment notes: $e');
    }
  } // Fetch doctors with retry mechanism

  Future<List<Map<String, dynamic>>> getDoctors() async {
    int attempts = 0;

    // Try to load cached doctors first
    try {
      final prefs = await Hive.openBox('app_settings');
      final cachedDoctors = prefs.get('cached_doctors');
      if (cachedDoctors != null && cachedDoctors is List) {
        logInfo('Using cached doctors list (${cachedDoctors.length} doctors)');
        return List<Map<String, dynamic>>.from(cachedDoctors);
      }
    } catch (e) {
      logWarn('Failed to load cached doctors: $e');
      // Continue with network fetch
    }

    while (attempts < _maxRetries) {
      try {
        logInfo('Attempt ${attempts + 1}: Fetching doctors');

        // Use a more reliable query with additional timeout
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .get()
            .timeout(const Duration(seconds: 15));

        logInfo('Found ${snapshot.docs.length} doctors');

        if (snapshot.docs.isEmpty) {
          logWarn('No doctors found in the database');
          // Return empty list but don't throw error
          return [];
        }

        final doctors = snapshot.docs.map((doc) {
          final data = doc.data();
          final doctor = {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Doctor',
            'specialty': data['specialty'] ?? 'General',
            'availability': data['availability'] ?? 'Available',
            'fee': data['fee'] ?? 500.0, // Default fee if not specified
            'photoUrl': data['photoUrl'],
            'rating': data['rating'] ?? 4.0,
          };
          logInfo(
            'Doctor: ${doctor['name']} id=${doctor['id']} spec=${doctor['specialty']}',
          );
          return doctor;
        }).toList(); // Cache the doctors list
        try {
          final prefs = await Hive.openBox('app_settings');
          await prefs.put('cached_doctors', doctors);
          await prefs.put(
            'doctors_last_updated',
            DateTime.now().millisecondsSinceEpoch,
          );
        } catch (cacheError) {
          logWarn('Failed to cache doctors list: $cacheError');
        }

        return doctors;
      } catch (e) {
        attempts++;
        logError('Error fetching doctors (attempt $attempts)', e);

        if (attempts >= _maxRetries) {
          logError('All attempts to fetch doctors failed', e);
          // Try to load any previously cached doctors as fallback
          try {
            final prefs = await Hive.openBox('app_settings');
            final cachedDoctors = prefs.get('cached_doctors');
            if (cachedDoctors != null && cachedDoctors is List) {
              logInfo('Using cached doctors as fallback after failed attempts');
              return List<Map<String, dynamic>>.from(cachedDoctors);
            }
          } catch (cacheError) {
            logWarn('Failed to load cached doctors as fallback: $cacheError');
          }

          // Return a fallback doctor only if no cached data available
          return [
            {
              'id': 'fallback-doctor-id',
              'name': 'Fallback Doctor (Error loading doctors)',
              'specialty': 'General',
              'availability': 'Error',
              'fee': 500.0,
            },
          ];
        }

        // Wait before retry with exponential backoff
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }

    // Should not reach here due to the loop structure
    return [];
  }
}
