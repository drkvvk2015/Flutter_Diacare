import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'payment_screen.dart';

/// Payment status constants
class PaymentStatus {
  static const String pending = 'pending';
  static const String success = 'success';
  static const String failed = 'failed';
}

/// Settlement status constants
class SettlementStatus {
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String completed = 'completed';
  static const String failed = 'failed';
}

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

  /// Opens Razorpay checkout - ALL payments go to Admin's Razorpay account
  void openCheckout({
    required String orderId,
    required double amount,
    required String name,
    required String email,
    required String contact,
    required BuildContext context,
    PaymentMethod? preferredMethod,
    String? doctorName,
  }) {
    // Build the options map - payments go to Admin's Razorpay account
    final options = <String, dynamic>{
      'key': 'YOUR_RAZORPAY_KEY', // Admin's Razorpay Key
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'DiaCare', // Platform name
      'order_id': orderId,
      'description': 'Consultation with Dr. ${doctorName ?? "Doctor"}',
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

      // For GPay, use intent-based flow
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

  /// Save payment record with doctor info for later settlement
  static Future<void> savePaymentStatus({
    required String userId,
    required String appointmentId,
    required String doctorId,
    required String status,
    required double amount,
    String? paymentId,
    String? method,
    String? receiptUrl,
  }) async {
    // Calculate admin commission (e.g., 10%)
    const double adminCommissionRate = 0.10;
    final double adminCommission = amount * adminCommissionRate;
    final double doctorAmount = amount - adminCommission;

    await FirebaseFirestore.instance
        .collection('payments')
        .doc(appointmentId)
        .set(
          {
            'userId': userId,
            'appointmentId': appointmentId,
            'doctorId': doctorId,
            'status': status,
            'amount': amount,
            'adminCommission': adminCommission,
            'doctorAmount': doctorAmount,
            'settlementStatus': SettlementStatus.pending,
            'paymentId': paymentId,
            'method': method,
            'receiptUrl': receiptUrl,
            'timestamp': DateTime.now().toIso8601String(),
            'settledAt': null,
          },
          SetOptions(merge: true),
        );
  }

  /// Get all payments for admin dashboard
  static Stream<QuerySnapshot> getAllPayments() {
    return FirebaseFirestore.instance
        .collection('payments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get payments pending settlement for a specific doctor
  static Stream<QuerySnapshot> getPendingSettlementsForDoctor(String doctorId) {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: PaymentStatus.success)
        .where('settlementStatus', isEqualTo: SettlementStatus.pending)
        .snapshots();
  }

  /// Get all pending settlements
  static Stream<QuerySnapshot> getAllPendingSettlements() {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('status', isEqualTo: PaymentStatus.success)
        .where('settlementStatus', isEqualTo: SettlementStatus.pending)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Mark payment as settled (admin action)
  static Future<void> settlePayment({
    required String paymentId,
    required String settledBy,
    String? transactionReference,
  }) async {
    await FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId)
        .update({
          'settlementStatus': SettlementStatus.completed,
          'settledAt': DateTime.now().toIso8601String(),
          'settledBy': settledBy,
          'settlementReference': transactionReference,
        });
  }

  /// Batch settle multiple payments for a doctor
  static Future<void> batchSettleForDoctor({
    required String doctorId,
    required String settledBy,
    required List<String> paymentIds,
    String? transactionReference,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now().toIso8601String();

    for (final paymentId in paymentIds) {
      final docRef = FirebaseFirestore.instance.collection('payments').doc(paymentId);
      batch.update(docRef, {
        'settlementStatus': SettlementStatus.completed,
        'settledAt': now,
        'settledBy': settledBy,
        'settlementReference': transactionReference,
      });
    }

    // Create settlement record
    final settlementRef = FirebaseFirestore.instance.collection('settlements').doc();
    batch.set(settlementRef, {
      'doctorId': doctorId,
      'paymentIds': paymentIds,
      'transactionReference': transactionReference,
      'settledBy': settledBy,
      'settledAt': now,
      'paymentCount': paymentIds.length,
    });

    await batch.commit();
  }

  /// Get settlement history for admin
  static Stream<QuerySnapshot> getSettlementHistory() {
    return FirebaseFirestore.instance
        .collection('settlements')
        .orderBy('settledAt', descending: true)
        .snapshots();
  }

  /// Get doctor's settlement summary
  static Future<Map<String, dynamic>> getDoctorSettlementSummary(String doctorId) async {
    final payments = await FirebaseFirestore.instance
        .collection('payments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: PaymentStatus.success)
        .get();

    double totalEarned = 0;
    double pendingSettlement = 0;
    double settledAmount = 0;
    int pendingCount = 0;
    int settledCount = 0;

    for (final doc in payments.docs) {
      final data = doc.data();
      final doctorAmount = (data['doctorAmount'] as num?)?.toDouble() ?? 0;
      final settlementStatus = data['settlementStatus'] as String? ?? SettlementStatus.pending;

      totalEarned += doctorAmount;

      if (settlementStatus == SettlementStatus.completed) {
        settledAmount += doctorAmount;
        settledCount++;
      } else {
        pendingSettlement += doctorAmount;
        pendingCount++;
      }
    }

    return {
      'totalEarned': totalEarned,
      'pendingSettlement': pendingSettlement,
      'settledAmount': settledAmount,
      'pendingCount': pendingCount,
      'settledCount': settledCount,
    };
  }

  /// Get payments for a specific doctor
  static Stream<QuerySnapshot> getPaymentsForDoctor(String doctorId) {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
