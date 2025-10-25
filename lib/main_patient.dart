import 'package:flutter/material.dart';
import 'main.dart' show SimpleLoginScreen; // Reuse existing screens

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiaCarePatientApp());
}

class DiaCarePatientApp extends StatelessWidget {
  const DiaCarePatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaCare Patient',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SimpleLoginScreen(role: 'patient'),
    );
  }
}
