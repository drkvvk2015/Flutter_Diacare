import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Removed unused firebase_connection_test import (navigation uses route)

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  String _userId = 'Not logged in';
  String _userEmail = 'No email';
  String _userRole = 'Unknown';
  String _firebaseStatus = 'Testing...';
  String _firestoreStatus = 'Testing...';
  final List<Map<String, dynamic>> _testResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;
        _userEmail = user.email ?? 'No email';

        // Check Firestore
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            _userRole = userDoc.data()?['role'] as String? ?? 'No role found';
            _firestoreStatus = 'User document exists in Firestore';
            _addTestResult(
              'User document',
              'Success',
              'Found user document with role: $_userRole',
            );
          } else {
            _firestoreStatus = 'User document not found in Firestore';
            _addTestResult(
              'User document',
              'Warning',
              'User exists in Auth but not in Firestore',
            );
          }
        } catch (e) {
          _firestoreStatus = 'Firestore error: $e';
          _addTestResult('Firestore connection', 'Error', e.toString());
        }

        _firebaseStatus = 'Authenticated';
        _addTestResult(
          'Authentication',
          'Success',
          'User authenticated with ID: ${_userId.substring(0, 8)}...',
        );
      } else {
        _firebaseStatus = 'Not authenticated';
        _addTestResult(
          'Authentication',
          'Warning',
          'No user currently logged in',
        );
      }

      // Test Firestore CRUD
      await _testFirestore();
    } catch (e) {
      _firebaseStatus = 'Error: $e';
      _addTestResult('General', 'Error', e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFirestore() async {
    try {
      // Create
      final docRef = await FirebaseFirestore.instance
          .collection('_diagnostics')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'test': true,
            'message': 'Diagnostic test',
          });

      _addTestResult(
        'Firestore write',
        'Success',
        'Created document with ID: ${docRef.id}',
      );

      // Read
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        _addTestResult(
          'Firestore read',
          'Success',
          'Read document successfully',
        );
      } else {
        _addTestResult(
          'Firestore read',
          'Error',
          'Document not found right after creation',
        );
      }

      // Update
      await docRef.update({
        'updated': true,
        'updateTime': FieldValue.serverTimestamp(),
      });
      _addTestResult(
        'Firestore update',
        'Success',
        'Updated document successfully',
      );

      // Delete
      await docRef.delete();
      _addTestResult(
        'Firestore delete',
        'Success',
        'Deleted document successfully',
      );

      // Query test
      final QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .limit(5)
          .get();

      _addTestResult(
        'Firestore query',
        'Success',
        'Query returned ${querySnap.docs.length} doctors',
      );
    } catch (e) {
      _addTestResult('Firestore CRUD', 'Error', e.toString());
    }
  }

  void _addTestResult(String test, String status, String details) {
    setState(() {
      _testResults.add({
        'test': test,
        'status': status,
        'details': details,
        'timestamp': DateTime.now(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diacare Diagnostics'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'User Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            Text('User ID: $_userId'),
                            Text('Email: $_userEmail'),
                            Text('Role: $_userRole'),
                            Text('Firebase status: $_firebaseStatus'),
                            Text('Firestore status: $_firestoreStatus'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Test results
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Diagnostic Test Results',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _checkAuth,
                                  tooltip: 'Run Tests Again',
                                ),
                              ],
                            ),
                            const Divider(),
                            ..._testResults.map((result) {
                              Color statusColor;
                              IconData statusIcon;

                              switch (result['status']) {
                                case 'Success':
                                  statusColor = Colors.green;
                                  statusIcon = Icons.check_circle;
                                  break;
                                case 'Warning':
                                  statusColor = Colors.orange;
                                  statusIcon = Icons.warning;
                                  break;
                                case 'Error':
                                  statusColor = Colors.red;
                                  statusIcon = Icons.error;
                                  break;
                                default:
                                  statusColor = Colors.grey;
                                  statusIcon = Icons.info;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(statusIcon, color: statusColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${result['test']}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${result['details']}",
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (_testResults.isEmpty)
                              const Text('No test results available'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20), // Test Buttons
                    Center(
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/firebaseTest');
                            },
                            icon: const Icon(Icons.shield),
                            label: const Text('Firebase Connection Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/quickBook');
                            },
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Quick Book Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
