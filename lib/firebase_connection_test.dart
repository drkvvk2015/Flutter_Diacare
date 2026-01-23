import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'utils/logger.dart';

class FirebaseConnectionTest extends StatefulWidget {
  const FirebaseConnectionTest({super.key});

  @override
  State<FirebaseConnectionTest> createState() => _FirebaseConnectionTestState();
}

class _FirebaseConnectionTestState extends State<FirebaseConnectionTest> {
  String _status = 'Testing Firebase connection...';
  bool _isLoading = true;
  bool _isConnected = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Test Firestore connection (initial read)
      await FirebaseFirestore.instance
          .collection('_connection_test')
          .doc('test')
          .get();

      // Write a test document
      await FirebaseFirestore.instance
          .collection('_connection_test')
          .doc('test')
          .set({'timestamp': FieldValue.serverTimestamp(), 'test': true});

      // Read the test document back
      final verifyDoc = await FirebaseFirestore.instance
          .collection('_connection_test')
          .doc('test')
          .get();

      if (verifyDoc.exists && verifyDoc.data()?['test'] == true) {
        setState(() {
          _status = 'Firebase connection successful!';
          _isLoading = false;
          _isConnected = true;
        });
      } else {
        setState(() {
          _status = 'Firebase connection issue: Could not verify data';
          _isLoading = false;
          _errorMessage =
              'Document exists: ${verifyDoc.exists}, Data: ${verifyDoc.data()}';
        });
      }

      // Clean up test document
      await FirebaseFirestore.instance
          .collection('_connection_test')
          .doc('test')
          .delete();
    } catch (e) {
      setState(() {
        _status = 'Firebase connection failed';
        _isLoading = false;
        _errorMessage = e.toString();
      });
      logError('Firebase connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.teal),
              const SizedBox(height: 20),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _status = 'Testing Firebase connection...';
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _testFirebaseConnection();
                },
                child: const Text('Test Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
