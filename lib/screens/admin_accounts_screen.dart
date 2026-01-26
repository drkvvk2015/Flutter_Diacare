import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../features/payments/payment_service.dart';

/// Admin Accounts Management Screen
/// 
/// Features:
/// - View all payments received
/// - Track pending settlements per doctor
/// - Settle payments to doctors
/// - View settlement history
class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.payments), text: 'All Payments'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending Settlements'),
            Tab(icon: Icon(Icons.history), text: 'Settlement History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllPaymentsTab(),
          _buildPendingSettlementsTab(),
          _buildSettlementHistoryTab(),
        ],
      ),
    );
  }

  /// Tab 1: All Payments
  Widget _buildAllPaymentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: PaymentService.getAllPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No payments yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final payments = snapshot.data!.docs;
        double totalRevenue = 0;
        double totalCommission = 0;

        for (final doc in payments) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data?['status'] == 'success') {
            totalRevenue += (data?['amount'] as num?)?.toDouble() ?? 0;
            totalCommission += (data?['adminCommission'] as num?)?.toDouble() ?? 0;
          }
        }

        return Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withAlpha(25),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Revenue',
                      currencyFormat.format(totalRevenue),
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Platform Fee (10%)',
                      currencyFormat.format(totalCommission),
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            // Payments List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index].data() as Map<String, dynamic>?;
                  return _buildPaymentCard(payment, payments[index].id);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic>? payment, String paymentId) {
    if (payment == null) return const SizedBox.shrink();

    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final status = payment['status'] as String? ?? 'unknown';
    final settlementStatus = payment['settlementStatus'] as String? ?? 'pending';
    final timestamp = payment['timestamp'] as String?;
    final doctorId = payment['doctorId'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: status == 'success' ? Colors.green : Colors.red,
          child: Icon(
            status == 'success' ? Icons.check : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(currencyFormat.format(amount)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment ID: $paymentId'),
            if (timestamp != null)
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(timestamp)),
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: _buildSettlementBadge(settlementStatus),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Doctor ID', doctorId ?? 'N/A'),
                _buildDetailRow('Doctor Amount', currencyFormat.format(payment['doctorAmount'] ?? 0)),
                _buildDetailRow('Platform Fee', currencyFormat.format(payment['adminCommission'] ?? 0)),
                _buildDetailRow('Payment Method', (payment['method'] as String?) ?? 'N/A'),
                _buildDetailRow('Status', status.toUpperCase()),
                _buildDetailRow('Settlement', settlementStatus.toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSettlementBadge(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'processing':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10),
      ),
      backgroundColor: color.withAlpha(30),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Tab 2: Pending Settlements grouped by doctor
  Widget _buildPendingSettlementsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('status', isEqualTo: 'success')
          .where('settlementStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('All settlements complete!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Group by doctor
        final payments = snapshot.data!.docs;
        final Map<String, List<QueryDocumentSnapshot>> doctorPayments = {};
        
        for (final payment in payments) {
          final data = payment.data() as Map<String, dynamic>?;
          final doctorId = data?['doctorId'] as String? ?? 'unknown';
          doctorPayments.putIfAbsent(doctorId, () => []).add(payment);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: doctorPayments.length,
          itemBuilder: (context, index) {
            final doctorId = doctorPayments.keys.elementAt(index);
            final doctorPaymentsList = doctorPayments[doctorId]!;
            return _buildDoctorSettlementCard(doctorId, doctorPaymentsList);
          },
        );
      },
    );
  }

  Widget _buildDoctorSettlementCard(String doctorId, List<QueryDocumentSnapshot> payments) {
    double totalAmount = 0;
    for (final payment in payments) {
      final data = payment.data() as Map<String, dynamic>?;
      totalAmount += (data?['doctorAmount'] as num?)?.toDouble() ?? 0;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(doctorId).get(),
              builder: (context, snapshot) {
                final name = snapshot.data?.get('name') as String? ?? 'Doctor';
                return Text('Dr. $name');
              },
            ),
            subtitle: Text('${payments.length} payments pending'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const Text('To Settle', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                    onPressed: () => _showPaymentDetails(doctorId, payments),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Settle Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _settlePayments(doctorId, payments, totalAmount),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(String doctorId, List<QueryDocumentSnapshot> payments) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Payment Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final data = payments[index].data() as Map<String, dynamic>?;
                  return ListTile(
                    title: Text(currencyFormat.format(data?['doctorAmount'] ?? 0)),
                    subtitle: Text(
                      data?['timestamp'] != null
                          ? DateFormat('dd MMM yyyy').format(DateTime.parse(data!['timestamp'] as String))
                          : 'Unknown date',
                    ),
                    trailing: Text((data?['method'] as String?) ?? 'N/A'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _settlePayments(
    String doctorId,
    List<QueryDocumentSnapshot> payments,
    double totalAmount,
  ) async {
    final TextEditingController referenceController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Settlement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${currencyFormat.format(totalAmount)}'),
            Text('Payments: ${payments.length}'),
            const SizedBox(height: 16),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Transaction Reference (Optional)',
                hintText: 'e.g., Bank transfer ID, UPI ref',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm Settlement'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      await PaymentService.batchSettleForDoctor(
        doctorId: doctorId,
        settledBy: user?.uid ?? 'admin',
        paymentIds: payments.map((p) => p.id).toList(),
        transactionReference: referenceController.text.trim().isNotEmpty
            ? referenceController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully settled ${currencyFormat.format(totalAmount)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settlement failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Tab 3: Settlement History
  Widget _buildSettlementHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: PaymentService.getSettlementHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No settlement history', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final settlements = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: settlements.length,
          itemBuilder: (context, index) {
            final settlement = settlements[index].data() as Map<String, dynamic>?;
            return _buildSettlementHistoryCard(settlement);
          },
        );
      },
    );
  }

  Widget _buildSettlementHistoryCard(Map<String, dynamic>? settlement) {
    if (settlement == null) return const SizedBox.shrink();

    final doctorId = settlement['doctorId'] as String?;
    final paymentCount = settlement['paymentCount'] as int? ?? 0;
    final settledAt = settlement['settledAt'] as String?;
    final reference = settlement['transactionReference'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(doctorId).get(),
          builder: (context, snapshot) {
            final name = snapshot.data?.get('name') as String? ?? 'Doctor';
            return Text('Dr. $name');
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$paymentCount payments settled'),
            if (settledAt != null)
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(settledAt)),
                style: const TextStyle(fontSize: 12),
              ),
            if (reference != null && reference.isNotEmpty)
              Text('Ref: $reference', style: const TextStyle(fontSize: 12)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
