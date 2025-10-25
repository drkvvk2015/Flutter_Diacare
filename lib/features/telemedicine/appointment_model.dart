import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime time;
  final String status; // scheduled, completed, cancelled
  final String? notes;
  final double? fee;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.time,
    required this.status,
    this.notes,
    this.fee,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      time: (data['time'] as Timestamp).toDate(),
      status: data['status'] ?? 'scheduled',
      notes: data['notes'],
      fee: (data['fee'] != null) ? (data['fee'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'time': Timestamp.fromDate(time),
      'status': status,
      'notes': notes,
      if (fee != null) 'fee': fee,
    };
  }
}
