import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.time,
    required this.status,
    this.notes,
    this.fee,
    this.paymentStatus,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      time: (data['time'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'scheduled',
      notes: data['notes'] as String?,
      fee: (data['fee'] != null) ? (data['fee'] as num).toDouble() : null,
      paymentStatus: data['paymentStatus'] as String?,
    );
  }
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime time;
  final String status; // pending_payment, scheduled, completed, cancelled
  final String? notes;
  final double? fee;
  final String? paymentStatus; // pending, success, failed

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'time': Timestamp.fromDate(time),
      'status': status,
      'notes': notes,
      if (fee != null) 'fee': fee,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
    };
  }
}
