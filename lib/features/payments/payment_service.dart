import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'payment_screen.dart';

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
    PaymentMethod? preferredMethod,
  }) {
    // Build the options map with preferred method configuration
    final options = <String, dynamic>{
      'key': 'YOUR_RAZORPAY_KEY',
      'amount': (amount * 100).toInt(),
      'name': name,
      'order_id': orderId,
      'description': 'Video Consultation',
      'prefill': {'contact': contact, 'email': email},
      'theme': {'color': '#008080'},
    };

    // Configure preferred payment method
    if (preferredMethod != null) {
      final method = <String, bool>{
        'card': preferredMethod == PaymentMethod.card,
        'netbanking': preferredMethod == PaymentMethod.netBanking,
        'upi': preferredMethod == PaymentMethod.upi ||
            preferredMethod == PaymentMethod.gpay,
        'wallet': false,
      };
      options['method'] = method;

      // If GPay is selected, configure UPI with Google Pay preference
      if (preferredMethod == PaymentMethod.gpay) {
        options['upi'] = {
          'flow': 'intent',
        };
      }
    }

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
        .set(
          {
            'userId': userId,
            'appointmentId': appointmentId,
            'status': status,
            'amount': amount,
            'paymentId': paymentId,
            'method': method,
            'receiptUrl': receiptUrl,
            'timestamp': DateTime.now().toIso8601String(),
          },
          SetOptions(merge: true),
        );
  }

  static Stream<QuerySnapshot> getPaymentsForDoctor(String doctorId) {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }
}
