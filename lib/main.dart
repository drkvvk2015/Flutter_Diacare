import 'package:flutter/material.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(DiacareApp());
}

class DiacareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Prescription App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // Use named routes for navigation
      routes: {
        '/': (context) => LoginScreen(),
        '/dashboard': (context) => HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctor Dashboard')),
      body: Center(child: Text('Welcome to the Doctor Prescription App!')),
    );
  }
}
