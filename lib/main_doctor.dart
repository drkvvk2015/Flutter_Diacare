import 'package:flutter/material.dart';
import 'main.dart' show SimpleLoginScreen; // Reuse existing screens

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiaCareDoctorApp());
}

class DiaCareDoctorApp extends StatelessWidget {
  const DiaCareDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaCare Doctor',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SimpleLoginScreen(role: 'doctor'),
    );
  }
}
