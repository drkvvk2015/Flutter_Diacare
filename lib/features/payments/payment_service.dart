import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  final Razorpay _razorpay = Razorpay();

  void initListeners({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    required void Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void openCheckout({
    required String orderId,
    required double amount,
    required String name,
    required String email,
    required String contact,
    required BuildContext context,
  }) {
    final options = {
      'key': 'YOUR_RAZORPAY_KEY',
      'amount': (amount * 100).toInt(),
      'name': name,
      'order_id': orderId,
      'description': 'Video Consultation',
      'prefill': {'contact': contact, 'email': email},
      'theme': {'color': '#008080'},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment error: $e')));
    }
  }

  static Future<void> savePaymentStatus({
    required String userId,
    required String appointmentId,
    required String status,
    required double amount,
    String? paymentId,
    String? method,
    String? receiptUrl,
  }) async {
    await FirebaseFirestore.instance
        .collection('payments')
        .doc(appointmentId)
        .set({
          'userId': userId,
          'appointmentId': appointmentId,
          'status': status,
          'amount': amount,
          'paymentId': paymentId,
          'method': method,
          'receiptUrl': receiptUrl,
          'timestamp': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true),);
  }

  static Stream<QuerySnapshot> getPaymentsForDoctor(String doctorId) {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }
}
