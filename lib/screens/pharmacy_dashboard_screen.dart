import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/dashboard_card.dart';
import '../widgets/glassmorphic_card.dart';
import 'prescription_screen.dart';
import 'records_screen.dart';

/// Debug widget to print a message when built
class DebugPrintWidget extends StatelessWidget {
  const DebugPrintWidget(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print(message);
    return const SizedBox.shrink();
  }
}

class PharmacyDashboardScreen extends StatelessWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        Colors.teal.shade400,
        Colors.blue.shade200,
        Colors.purple.shade200,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Hero(
          tag: 'pharmacy-dashboard-appbar',
          child: Material(
            color: Colors.transparent,
            child: Text(
              'Pharmacy Dashboard',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Semantics(
            label: 'Logout',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final cardSpacing = isWide ? 24.0 : 12.0;
          final padding = isWide ? 48.0 : 16.0;
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                decoration: BoxDecoration(gradient: gradient),
              ),
              ListView(
                padding: EdgeInsets.all(padding),
                children: [
                  // Stat cards
                  if (isWide) Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                label: 'Pending Orders: 8',
                                child: GlassmorphicCard(
                                  key: const Key(
                                    'pharmacy_pending_orders_card',
                                  ),
                                  borderRadius: 20,
                                  child: _buildStatCard(
                                    'Pending Orders',
                                    '8',
                                    Icons.pending,
                                    Colors.orange,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: cardSpacing),
                            Expanded(
                              child: Semantics(
                                label: 'Completed Today: 23',
                                child: GlassmorphicCard(
                                  key: const Key(
                                    'pharmacy_completed_today_card',
                                  ),
                                  borderRadius: 20,
                                  child: _buildStatCard(
                                    'Completed Today',
                                    '23',
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ) else Column(
                          children: [
                            Semantics(
                              label: 'Pending Orders: 8',
                              child: GlassmorphicCard(
                                key: const Key('pharmacy_pending_orders_card'),
                                borderRadius: 20,
                                child: _buildStatCard(
                                  'Pending Orders',
                                  '8',
                                  Icons.pending,
                                  Colors.orange,
                                ),
                              ),
                            ),
                            SizedBox(height: cardSpacing),
                            Semantics(
                              label: 'Completed Today: 23',
                              child: GlassmorphicCard(
                                key: const Key('pharmacy_completed_today_card'),
                                borderRadius: 20,
                                child: _buildStatCard(
                                  'Completed Today',
                                  '23',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                  const DebugPrintWidget('Built stat cards'),
                  SizedBox(height: cardSpacing),
                  if (isWide) Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                label: r'Revenue Today: $850',
                                child: GlassmorphicCard(
                                  key: const Key('pharmacy_revenue_today_card'),
                                  borderRadius: 20,
                                  child: _buildStatCard(
                                    'Revenue Today',
                                    r'$850',
                                    Icons.attach_money,
                                    Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: cardSpacing),
                            Expanded(
                              child: Semantics(
                                label: 'Low Stock Items: 4',
                                child: GlassmorphicCard(
                                  key: const Key(
                                    'pharmacy_low_stock_items_card',
                                  ),
                                  borderRadius: 20,
                                  child: _buildStatCard(
                                    'Low Stock Items',
                                    '4',
                                    Icons.warning,
                                    Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ) else Column(
                          children: [
                            Semantics(
                              label: r'Revenue Today: $850',
                              child: GlassmorphicCard(
                                key: const Key('pharmacy_revenue_today_card'),
                                borderRadius: 20,
                                child: _buildStatCard(
                                  'Revenue Today',
                                  r'$850',
                                  Icons.attach_money,
                                  Colors.blue,
                                ),
                              ),
                            ),
                            SizedBox(height: cardSpacing),
                            Semantics(
                              label: 'Low Stock Items: 4',
                              child: GlassmorphicCard(
                                key: const Key('pharmacy_low_stock_items_card'),
                                borderRadius: 20,
                                child: _buildStatCard(
                                  'Low Stock Items',
                                  '4',
                                  Icons.warning,
                                  Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                  const DebugPrintWidget('Built revenue/low stock cards'),
                  const DebugPrintWidget('Built prescription orders card'),
                  const DebugPrintWidget('Built inventory management card'),
                  const DebugPrintWidget('Built order management card'),
                  SizedBox(height: cardSpacing * 2),
                  // Management and navigation cards
                  Wrap(
                    spacing: cardSpacing,
                    runSpacing: cardSpacing,
                    children: [
                      SizedBox(
                        width: isWide ? 340 : double.infinity,
                        child: DashboardCard(
                          key: const Key('pharmacy_prescription_orders_card'),
                          icon: Icons.receipt,
                          iconColor: Colors.blue,
                          title: 'Prescription Orders',
                          subtitle: 'View and process prescription orders.',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PrescriptionScreen(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 340 : double.infinity,
                        child: DashboardCard(
                          key: const Key('pharmacy_inventory_management_card'),
                          icon: Icons.inventory,
                          iconColor: Colors.green,
                          title: 'Inventory Management',
                          subtitle: 'Manage medicine stock and inventory.',
                          onTap: () => _showInventoryManagement(context),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 340 : double.infinity,
                        child: DashboardCard(
                          key: const Key('pharmacy_order_management_card'),
                          icon: Icons.shopping_cart,
                          iconColor: Colors.orange,
                          title: 'Order Management',
                          subtitle: 'Track and manage all orders.',
                          onTap: () => _showOrderManagement(context),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 340 : double.infinity,
                        child: DashboardCard(
                          key: const Key('pharmacy_delivery_management_card'),
                          icon: Icons.local_shipping,
                          iconColor: Colors.purple,
                          title: 'Delivery Management',
                          subtitle: 'Manage deliveries and shipments.',
                          onTap: () => _showDeliveryManagement(context),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 340 : double.infinity,
                        child: DashboardCard(
                          key: const Key('pharmacy_customer_management_card'),
                          icon: Icons.people,
                          iconColor: Colors.indigo,
                          title: 'Customer Management',
                          subtitle: 'View and manage customer information.',
                          onTap: () => _showCustomerManagement(context),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 340 : double.infinity,
                        child: DashboardCard(
                          key: const Key('pharmacy_sales_reports_card'),
                          icon: Icons.analytics,
                          iconColor: Colors.teal,
                          title: 'Sales Reports',
                          subtitle: 'View sales analytics and reports.',
                          onTap: () => _showSalesReports(context),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 340 : double.infinity,
                        child: DashboardCard(
                          key: const Key('pharmacy_prescription_records_card'),
                          icon: Icons.folder,
                          iconColor: Colors.brown,
                          title: 'Prescription Records',
                          subtitle: 'Access prescription records.',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const RecordsScreen(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 340 : double.infinity,
                        child: DashboardCard(
                          key: const Key('pharmacy_help_feedback_card'),
                          icon: Icons.help_outline,
                          iconColor: Colors.deepPurple,
                          title: 'Help & Feedback',
                          subtitle: 'Contact support or send feedback.',
                          onTap: () => _showHelpFeedbackDialog(context),
                        ),
                      ),
                    ], // end of children for Wrap
                  ), // end of Wrap
                ],
              ), // end of ListView
            ],
          ); // end of Stack
        },
      ),
    );
  }

  void _showHelpFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe your issue or feedback:'),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type your message here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    Key? key,
  }) {
    return Card(
      key: key,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showInventoryManagement(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inventory Management'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add New Medicine'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMedicineDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('View All Medicines'),
                onTap: () {
                  Navigator.pop(context);
                  _showMedicinesList(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Low Stock Alerts'),
                subtitle: const Text('4 medicines are running low'),
                onTap: () {
                  Navigator.pop(context);
                  _showLowStockAlert(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'Stock Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('medicines').add({
                'name': nameController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'stock': int.tryParse(stockController.text) ?? 0,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medicine added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showMedicinesList(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Medicines'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('medicines')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data()! as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['name'] as String? ?? data['displayName'] as String? ?? 'Unknown'),
                    subtitle: Text(
                      'Price: \$${data['price']} - Stock: ${data['stock']}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // ...existing code...
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLowStockAlert(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low Stock Alert'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('Paracetamol'),
              subtitle: Text('Only 5 units left'),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('Metformin'),
              subtitle: Text('Only 3 units left'),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('Insulin'),
              subtitle: Text('Only 2 units left'),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('Aspirin'),
              subtitle: Text('Only 1 unit left'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Reorder All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOrderManagement(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Management'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.pending, color: Colors.orange),
                title: Text('Pending Orders'),
                subtitle: Text('8 orders waiting for processing'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Completed Orders'),
                subtitle: Text('23 orders completed today'),
              ),
              ListTile(
                leading: Icon(Icons.local_shipping, color: Colors.blue),
                title: Text('Shipped Orders'),
                subtitle: Text('15 orders shipped today'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeliveryManagement(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Management'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.local_shipping, color: Colors.blue),
                title: Text('Out for Delivery'),
                subtitle: Text('5 orders out for delivery'),
              ),
              ListTile(
                leading: Icon(Icons.done_all, color: Colors.green),
                title: Text('Delivered Today'),
                subtitle: Text('18 orders delivered successfully'),
              ),
              ListTile(
                leading: Icon(Icons.error, color: Colors.red),
                title: Text('Failed Deliveries'),
                subtitle: Text('2 delivery attempts failed'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCustomerManagement(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Management'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.person_add, color: Colors.green),
                title: Text('New Customers'),
                subtitle: Text('5 new customers this week'),
              ),
              ListTile(
                leading: Icon(Icons.people, color: Colors.blue),
                title: Text('Total Customers'),
                subtitle: Text('142 registered customers'),
              ),
              ListTile(
                leading: Icon(Icons.star, color: Colors.orange),
                title: Text('VIP Customers'),
                subtitle: Text('23 VIP customers'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSalesReports(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sales Reports'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.today, color: Colors.green),
                title: Text('Today\'s Sales'),
                subtitle: Text(r'$850 - 23 orders'),
              ),
              ListTile(
                leading: Icon(Icons.view_week, color: Colors.blue),
                title: Text('This Week\'s Sales'),
                subtitle: Text(r'$4,250 - 125 orders'),
              ),
              ListTile(
                leading: Icon(Icons.calendar_month, color: Colors.purple),
                title: Text('This Month\'s Sales'),
                subtitle: Text(r'$18,500 - 450 orders'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


