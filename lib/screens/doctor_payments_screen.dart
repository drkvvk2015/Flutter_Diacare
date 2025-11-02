import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorPaymentsScreen extends StatelessWidget {
  final String doctorId;
  const DoctorPaymentsScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments Received')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No payments received yet.'));
          }
          final payments = snapshot.data!.docs;
          return ListView.separated(
            itemCount: payments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, i) {
              final p = payments[i].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.payment, color: Colors.green),
                title: Text('₹${p['amount'] ?? ''} - ${p['status'] ?? ''}'),
                subtitle: Text(
                  'Patient: ${p['userId'] ?? ''}\nMethod: ${p['method'] ?? ''}\nDate: ${p['timestamp'] ?? ''}',
                ),
                trailing: p['receiptUrl'] != null
                    ? IconButton(
                        icon: const Icon(Icons.receipt_long),
                        onPressed: () {
                          // Open/download receipt
                        },
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
