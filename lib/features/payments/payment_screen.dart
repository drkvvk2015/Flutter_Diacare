import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'payment_service.dart';

/// Enum for payment methods
enum PaymentMethod {
  gpay,
  card,
  netBanking,
  upi,
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    required this.appointmentId,
    required this.amount,
    required this.doctorId,
    super.key,
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
  PaymentMethod? _selectedMethod;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
    _initPaymentListeners();
  }

  void _initPaymentListeners() {
    _paymentService.initListeners(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(dynamic response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await PaymentService.savePaymentStatus(
      userId: user.uid,
      appointmentId: widget.appointmentId,
      status: 'success',
      amount: widget.amount,
      paymentId: response.paymentId?.toString() ?? widget.appointmentId,
      method: _getMethodName(_selectedMethod),
    );

    if (mounted) {
      setState(() {
        _isPaying = false;
        _paid = true;
        _paymentStatus = 'success';
      });
    }
  }

  void _handlePaymentError(dynamic response) {
    if (mounted) {
      setState(() {
        _isPaying = false;
        _paymentStatus = 'failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(dynamic response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName}'),
      ),
    );
  }

  String _getMethodName(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.gpay:
        return 'Google Pay';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.upi:
        return 'UPI';
      case null:
        return 'Razorpay';
    }
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
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPaying = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isPaying = false);
      return;
    }

    final orderId = widget.appointmentId;
    _paymentService.openCheckout(
      orderId: orderId,
      amount: widget.amount,
      name: user.displayName ?? 'Patient',
      email: user.email ?? '',
      contact: user.phoneNumber ?? '',
      context: context,
      preferredMethod: _selectedMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Payment'),
        elevation: 0,
      ),
      body: _paid ? _buildSuccessView() : _buildPaymentView(theme),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${widget.amount.toStringAsFixed(0)} paid',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_call),
              label: const Text('Join Video Call'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Consultation Fee',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Methods Section
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Google Pay
          _buildPaymentMethodCard(
            method: PaymentMethod.gpay,
            icon: Icons.g_mobiledata,
            iconColor: Colors.blue,
            title: 'Google Pay',
            subtitle: 'Pay using GPay UPI',
          ),

          // Card Payment
          _buildPaymentMethodCard(
            method: PaymentMethod.card,
            icon: Icons.credit_card,
            iconColor: Colors.purple,
            title: 'Credit / Debit Card',
            subtitle: 'Visa, Mastercard, RuPay',
          ),

          // Net Banking
          _buildPaymentMethodCard(
            method: PaymentMethod.netBanking,
            icon: Icons.account_balance,
            iconColor: Colors.teal,
            title: 'Net Banking',
            subtitle: 'All major banks supported',
          ),

          // UPI
          _buildPaymentMethodCard(
            method: PaymentMethod.upi,
            icon: Icons.qr_code,
            iconColor: Colors.orange,
            title: 'UPI',
            subtitle: 'PhonePe, Paytm, BHIM & more',
          ),

          const SizedBox(height: 24),

          // Pay Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isPaying ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isPaying
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Pay ₹${widget.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (_paymentStatus == 'failed')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payment failed. Please try again.',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Security Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your payment is secured with 256-bit SSL encryption',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required PaymentMethod method,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == method;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? theme.primaryColor.withValues(alpha: 0.05)
                : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? theme.primaryColor : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.primaryColor : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

