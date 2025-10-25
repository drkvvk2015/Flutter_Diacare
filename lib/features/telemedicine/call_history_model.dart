import 'package:cloud_firestore/cloud_firestore.dart';

class CallHistory {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;

  CallHistory({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  factory CallHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallHistory(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'notes': notes,
    };
  }
}
