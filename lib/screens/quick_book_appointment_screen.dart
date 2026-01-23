import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/telemedicine/appointment_model.dart';
import '../features/telemedicine/appointment_service.dart';
// Removed unused direct cloud_firestore import (service handles it)
import '../utils/logger.dart';
import 'appointment_screen.dart';
import 'patient_dashboard_screen.dart';

class QuickBookAppointmentScreen extends StatefulWidget {
  const QuickBookAppointmentScreen({super.key});

  @override
  State<QuickBookAppointmentScreen> createState() =>
      _QuickBookAppointmentScreenState();
}

class _QuickBookAppointmentScreenState
    extends State<QuickBookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentService _service = AppointmentService();
  bool _isLoading = false;
  String _status = '';

  // Form data
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _notes;
  double? _fee = 500;
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading doctors...';
    });

    try {
      // Use the service's getDoctors method for better error handling
      final doctors = await _service.getDoctors();

      logInfo('Loaded ${doctors.length} doctors in UI');

      if (doctors.isEmpty) {
        logWarn('No doctors found - adding a test doctor for UI');
        // Add a test doctor if none exist
        doctors.add({
          'id': 'test-doctor-id',
          'name': 'Test Doctor',
          'specialty': 'General',
          'fee': 500.0,
        });
      }

      setState(() {
        _doctors = doctors;
        if (_doctors.isNotEmpty) {
          _selectedDoctorId = _doctors[0]['id'] as String?;
          _selectedDoctorName = _doctors[0]['name'] as String?;
          _fee = (_doctors[0]['fee'] as num).toDouble();
          _status = 'Found ${_doctors.length} doctors';
        } else {
          _status = 'No doctors available';
        }
      });
    } catch (e) {
      logError('Error fetching doctors in UI', e);
      setState(() {
        _status = 'ERROR LOADING DOCTORS: $e';

        // Add a fallback doctor for UI to prevent errors
        _doctors = [
          {
            'id': 'error-doctor-id',
            'name': 'Error Loading Doctors',
            'specialty': 'Please try again',
            'fee': 0.0,
          },
        ];
        _selectedDoctorId = _doctors[0]['id'] as String?;
        _selectedDoctorName = _doctors[0]['name'] as String?;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }

    if (_selectedTime == null) {
      _showError('Please select a time');
      return;
    }

    if (_selectedDoctorId == null) {
      _showError('Please select a doctor');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('You need to be logged in');
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _status = 'Booking appointment...';
    });

    try {
      final appointmentTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      logInfo(
        'Creating appointment: patient=${user.uid} doctor=$_selectedDoctorId time=$appointmentTime fee=$_fee',
      );

      final appointment = Appointment(
        id: '', // Will be assigned by Firestore
        patientId: user.uid,
        doctorId: _selectedDoctorId!,
        time: appointmentTime,
        status: 'scheduled',
        notes: _notes,
        fee: _fee,
      );

      final appointmentId = await _service.bookAppointment(appointment);

      setState(() {
        _isLoading = false;
        _status =
            '✅ Success! Appointment booked successfully. ID: $appointmentId';
      });

      // Show success dialog
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Appointment Booked'),
            content: Text(
              'Your appointment with $_selectedDoctorName has been successfully booked for ${appointmentTime.toString().substring(0, 16)}.\n\nAppointment ID: $appointmentId',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AppointmentScreen(
                        userRole: 'patient',
                        userId: user.uid,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('View All Appointments'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      logError('Error booking appointment', e);
      setState(() {
        _isLoading = false;
        _status = '❌ Error booking appointment: $e';
      });
      _showError('Failed to book appointment: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Book Appointment'),
        backgroundColor: Colors.teal,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade200, Colors.blue.shade100],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading && _doctors.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Book Appointment',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (_doctors.isNotEmpty)
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Doctor',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                initialValue: _selectedDoctorId,
                                items: _doctors.map((doctor) {
                                  return DropdownMenuItem<String>(
                                    value: doctor['id'] as String,
                                    child: Text(
                                      '${doctor['name']} (${doctor['specialty']})',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDoctorId = value;
                                    final selectedDoctor = _doctors.firstWhere(
                                      (doctor) => doctor['id'] == value,
                                      orElse: () => _doctors.first,
                                    );
                                    _selectedDoctorName =
                                        selectedDoctor['name'] as String;
                                    _fee = (selectedDoctor['fee'] as num)
                                        .toDouble();
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Please select a doctor'
                                    : null,
                              )
                            else
                              const Text(
                                'No doctors available',
                                style: TextStyle(color: Colors.red),
                              ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 30),
                                  ),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Appointment Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _selectedDate == null
                                      ? 'Select Date'
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setState(() {
                                    _selectedTime = time;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Appointment Time',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _selectedTime == null
                                      ? 'Select Time'
                                      : _selectedTime!.format(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Notes (Optional)',
                                hintText: 'Any specific concerns or requests',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                              ),
                              maxLines: 3,
                              onSaved: (value) {
                                _notes = value;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Consultation Fee: ₹${_fee?.toStringAsFixed(0) ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (_isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton(
                                onPressed: _doctors.isEmpty
                                    ? null
                                    : _bookAppointment,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.teal,
                                ),
                                child: const Text(
                                  'Book Appointment',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            const SizedBox(height: 16),
                            if (_status.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _status.startsWith('❌')
                                      ? Colors.red.shade50
                                      : _status.startsWith('✅')
                                      ? Colors.green.shade50
                                      : Colors.grey.shade100,
                                ),
                                child: Text(
                                  _status,
                                  style: TextStyle(
                                    color: _status.startsWith('❌')
                                        ? Colors.red
                                        : _status.startsWith('✅')
                                        ? Colors.green
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.teal,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PatientDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text(
                'Dashboard',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AppointmentScreen(
                        userRole: 'patient',
                        userId: user.uid,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: const Text(
                'All Appointments',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


