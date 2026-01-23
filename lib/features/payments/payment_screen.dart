import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'payment_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    required this.appointmentId, required this.amount, required this.doctorId, super.key,
  });
  final String appointmentId;
  final double amount;
  final String doctorId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isPaying = false;
  bool _paid = false;
  String? _paymentStatus;

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('payments')
        .doc(widget.appointmentId)
        .get();
    if (doc.exists && doc.data()?['status'] == 'success') {
      setState(() {
        _paid = true;
        _paymentStatus = 'success';
      });
    }
  }

  Future<void> _startPayment() async {
    setState(() => _isPaying = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // In production, generate orderId from backend
    final orderId = widget.appointmentId;
    PaymentService().openCheckout(
      orderId: orderId,
      amount: widget.amount,
      name: user.displayName ?? 'Patient',
      email: user.email ?? '',
      contact: user.phoneNumber ?? '',
      context: context,
    );
    // Listen for payment result (should be improved for real app)
    // For demo, mark as paid after a delay
    await Future<void>.delayed(const Duration(seconds: 5));
    await PaymentService.savePaymentStatus(
      userId: user.uid,
      appointmentId: widget.appointmentId,
      status: 'success',
      amount: widget.amount,
      paymentId: orderId,
      method: 'Razorpay',
    );
    setState(() {
      _isPaying = false;
      _paid = true;
      _paymentStatus = 'success';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultation Payment')),
      body: Center(
        child: _paid
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.video_call),
                    label: const Text('Join Video Call'),
                    onPressed: () {
                      Navigator.pop(context, true); // Return success
                    },
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Consultation Fee: ₹${widget.amount}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  if (_isPaying) const CircularProgressIndicator() else ElevatedButton.icon(
                          icon: const Icon(Icons.payment),
                          label: const Text('Pay Now'),
                          onPressed: _startPayment,
                        ),
                  if (_paymentStatus == 'failed')
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Payment failed. Please try again.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

