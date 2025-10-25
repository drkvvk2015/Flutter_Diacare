import 'package:cloud_firestore/cloud_firestore.dart';
import 'call_history_model.dart';

class CallHistoryService {
  final _calls = FirebaseFirestore.instance.collection('call_history');

  Future<List<CallHistory>> getCallHistoryForUser(
    String userId,
    String role,
  ) async {
    QuerySnapshot snapshot;
    if (role == 'doctor') {
      snapshot = await _calls
          .where('doctorId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();
    } else {
      snapshot = await _calls
          .where('patientId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();
    }
    return snapshot.docs.map((doc) => CallHistory.fromFirestore(doc)).toList();
  }

  Future<void> addCall(CallHistory call) async {
    await _calls.add(call.toMap());
  }

  Future<void> addNotes(String id, String notes) async {
    await _calls.doc(id).update({'notes': notes});
  }
}
