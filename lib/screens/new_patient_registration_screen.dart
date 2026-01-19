import 'dart:ui'; // Added for ImageFilter
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Futuristic animations
// import 'package:flutter/services.dart'; // Unused
import 'patient_dashboard_screen.dart';

class NewPatientRegistrationScreen extends StatefulWidget {
  const NewPatientRegistrationScreen({super.key});

  @override
  State<NewPatientRegistrationScreen> createState() =>
      _NewPatientRegistrationScreenState();
}

class _NewPatientRegistrationScreenState
    extends State<NewPatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController uhidController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageDobController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipController = TextEditingController();
  final TextEditingController bpController = TextEditingController();
  final TextEditingController pulseController = TextEditingController();
  final TextEditingController importController = TextEditingController();
  final TextEditingController historyController = TextEditingController();
  bool loading = false;
  String? error;

  void _registerPatient() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // Save patient data to Firestore
      await FirebaseFirestore.instance.collection('patients').add({
        'uhid': uhidController.text.trim(),
        'name': nameController.text.trim(),
        'ageDob': ageDobController.text.trim(),
        'anthropometry': {
          'height': heightController.text.trim(),
          'weight': weightController.text.trim(),
          'waist': waistController.text.trim(),
          'hip': hipController.text.trim(),
        },
        'vitals': {
          'bp': bpController.text.trim(),
          'pulse': pulseController.text.trim(),
        },
        'history': historyController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientDashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('New Patient Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      body: Stack(
        children: [
          // Futuristic Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027), // Deep Space Blue
                  Color(0xFF203A43), // Cyber Teal
                  Color(0xFF2C5364), // Horizon Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Ambient Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Patient Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
                            const SizedBox(height: 24),
                            _buildFuturisticTextField(
                              controller: uhidController,
                              label: 'UHID',
                              icon: Icons.badge_outlined,
                              delay: 100,
                            ),
                            const SizedBox(height: 16),
                            _buildFuturisticTextField(
                              controller: nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              delay: 200,
                            ),
                            const SizedBox(height: 16),
                            _buildFuturisticTextField(
                              controller: ageDobController,
                              label: 'Age / DOB',
                              icon: Icons.calendar_today_outlined,
                              delay: 300,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Anthropometry',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFuturisticTextField(
                                    controller: heightController,
                                    label: 'Height (cm)',
                                    isNumber: true,
                                    delay: 500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFuturisticTextField(
                                    controller: weightController,
                                    label: 'Weight (kg)',
                                    isNumber: true,
                                    delay: 600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFuturisticTextField(
                                    controller: waistController,
                                    label: 'Waist (cm)',
                                    isNumber: true,
                                    delay: 700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFuturisticTextField(
                                    controller: hipController,
                                    label: 'Hip (cm)',
                                    isNumber: true,
                                    delay: 800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.paste, color: Colors.cyanAccent),
                              label: const Text('Paste Data'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.cyanAccent,
                                side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final data = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF203A43),
                                    title: const Text('Paste Anthropometry', style: TextStyle(color: Colors.white)),
                                    content: TextField(
                                      controller: importController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Paste comma-separated data',
                                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text('Import', style: TextStyle(color: Colors.cyanAccent)),
                                        onPressed: () => Navigator.pop(ctx, importController.text),
                                      ),
                                    ],
                                  ),
                                );
                                if (data != null && data.isNotEmpty) {
                                  final parts = data.split(',');
                                  if (parts.length >= 4) {
                                    heightController.text = parts[0].trim();
                                    weightController.text = parts[1].trim();
                                    waistController.text = parts[2].trim();
                                    hipController.text = parts[3].trim();
                                  }
                                }
                              },
                            ).animate().fadeIn(delay: 900.ms),
                            const SizedBox(height: 24),
                            const Text(
                              'Vitals & History',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate().fadeIn(delay: 1000.ms),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFuturisticTextField(
                                    controller: bpController,
                                    label: 'BP (mmHg)',
                                    delay: 1100,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFuturisticTextField(
                                    controller: pulseController,
                                    label: 'Pulse (bpm)',
                                    isNumber: true,
                                    delay: 1200,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFuturisticTextField(
                              controller: historyController,
                              label: 'Clinical History',
                              maxLines: 3,
                              icon: Icons.history_edu,
                              delay: 1300,
                            ),
                            const SizedBox(height: 32),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(error!, style: const TextStyle(color: Colors.redAccent)),
                              ),
                            loading
                                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                                : ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        _registerPatient();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.cyanAccent,
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      shadowColor: Colors.cyanAccent.withValues(alpha: 0.4),
                                    ),
                                    child: const Text(
                                      'REGISTER PATIENT',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ).animate().scale(delay: 1400.ms, duration: 400.ms, curve: Curves.elasticOut),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool isNumber = false,
    int maxLines = 1,
    required int delay,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIcon: icon != null ? Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.8)) : null,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
