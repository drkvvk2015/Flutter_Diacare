import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/payments/payment_screen.dart';
import '../features/telemedicine/appointment_model.dart';
import '../features/telemedicine/appointment_service.dart';
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

    // Store values in local non-nullable variables after validation
    final doctorId = _selectedDoctorId!;
    final doctorName = _selectedDoctorName ?? 'Doctor';
    final fee = _fee ?? 500;

    setState(() {
      _isLoading = true;
      _status = 'Creating appointment...';
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
        'Creating appointment: patient=${user.uid} doctor=$doctorId time=$appointmentTime fee=$fee',
      );

      final appointment = Appointment(
        id: '', // Will be assigned by Firestore
        patientId: user.uid,
        doctorId: doctorId,
        time: appointmentTime,
        status: 'pending_payment', // Changed: Set initial status to pending_payment
        notes: _notes,
        fee: fee,
        paymentStatus: 'pending', // Added: Track payment status
      );

      final appointmentIdResult = await _service.bookAppointment(appointment);
      
      if (appointmentIdResult == null) {
        _showError('Failed to create appointment');
        setState(() {
          _isLoading = false;
          _status = '❌ Failed to create appointment';
        });
        return;
      }
      
      final appointmentId = appointmentIdResult;

      setState(() {
        _isLoading = false;
        _status = 'Appointment created. Proceeding to payment...';
      });

      // Navigate to payment screen
      if (mounted) {
        final paymentResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => PaymentScreen(
              appointmentId: appointmentId,
              amount: fee,
              doctorId: doctorId,
            ),
          ),
        );

        // Check if payment was successful
        if (paymentResult ?? false) {
          // Update appointment status to scheduled after payment
          await _service.updateStatus(appointmentId, 'scheduled');
          
          setState(() {
            _status = '✅ Success! Appointment booked and payment completed.';
          });

          // Show success dialog
          if (mounted) {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Appointment Confirmed'),
                content: Text(
                  'Your appointment with $doctorName has been confirmed for ${appointmentTime.toString().substring(0, 16)}.\n\nPayment received successfully!\n\nAppointment ID: $appointmentId',
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
        } else {
          // Payment was cancelled or failed
          setState(() {
            _status = '⚠️ Payment not completed. Appointment is pending.';
          });
          
          if (mounted) {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Payment Pending'),
                content: Text(
                  'Your appointment has been created but payment is pending.\n\nPlease complete the payment to confirm your appointment with $doctorName.\n\nAppointment ID: $appointmentId',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: const Text('Later'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Retry payment
                      final retryResult = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute<bool>(
                          builder: (_) => PaymentScreen(
                            appointmentId: appointmentId,
                            amount: fee,
                            doctorId: doctorId,
                          ),
                        ),
                      );
                      if (retryResult ?? false) {
                        await _service.updateStatus(appointmentId, 'scheduled');
                        setState(() {
                          _status = '✅ Payment completed! Appointment confirmed.';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Pay Now'),
                  ),
                ],
              ),
            );
          }
        }
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

  /// Generates available time slots from 9 AM to 10 PM
  List<TimeOfDay> _generateTimeSlots() {
    final slots = <TimeOfDay>[];
    // Generate slots from 9 AM to 9:30 PM (last slot at 9:30 PM for 30-min appointment)
    for (var hour = 9; hour < 22; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      slots.add(TimeOfDay(hour: hour, minute: 30));
    }
    return slots;
  }

  /// Builds quick time slot selection grid
  Widget _buildQuickTimeSlots() {
    final timeSlots = _generateTimeSlots();
    final theme = Theme.of(context);
    
    // Group slots by time period
    final morningSlots = timeSlots.where((t) => t.hour >= 9 && t.hour < 12).toList();
    final afternoonSlots = timeSlots.where((t) => t.hour >= 12 && t.hour < 17).toList();
    final eveningSlots = timeSlots.where((t) => t.hour >= 17 && t.hour < 22).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Morning slots
        _buildTimeSlotSection(
          'Morning (9 AM - 12 PM)',
          morningSlots,
          Colors.orange,
          theme,
        ),
        const SizedBox(height: 12),
        
        // Afternoon slots
        _buildTimeSlotSection(
          'Afternoon (12 PM - 5 PM)',
          afternoonSlots,
          Colors.blue,
          theme,
        ),
        const SizedBox(height: 12),
        
        // Evening slots
        _buildTimeSlotSection(
          'Evening (5 PM - 10 PM)',
          eveningSlots,
          Colors.purple,
          theme,
        ),
      ],
    );
  }

  Widget _buildTimeSlotSection(
    String title,
    List<TimeOfDay> slots,
    Color accentColor,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((time) {
            final isSelected = _selectedTime != null &&
                _selectedTime!.hour == time.hour &&
                _selectedTime!.minute == time.minute;
            
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedTime = time;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : accentColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
                            
                            // Quick Time Slot Selection
                            const Text(
                              'Preferred Time Slots',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildQuickTimeSlots(),
                            
                            const SizedBox(height: 12),
                            const Center(
                              child: Text(
                                '— OR select custom time —',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            InkWell(
                              onTap: () async {
                                // Determine initial time - default to 9 AM if current time is outside range
                                final now = TimeOfDay.now();
                                TimeOfDay initialTime;
                                if (now.hour < 9) {
                                  initialTime = const TimeOfDay(hour: 9, minute: 0);
                                } else if (now.hour >= 22) {
                                  initialTime = const TimeOfDay(hour: 21, minute: 0);
                                } else {
                                  initialTime = now;
                                }

                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: initialTime,
                                  helpText: 'Select time (9 AM - 10 PM)',
                                );
                                if (time != null) {
                                  // Validate time is within 9 AM - 10 PM
                                  if (time.hour < 9 || time.hour >= 22) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please select a time between 9 AM and 10 PM',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _selectedTime = time;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Custom Time (9 AM - 10 PM)',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.access_time),
                                  suffixIcon: _selectedTime != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _selectedTime = null;
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                child: Text(
                                  _selectedTime == null
                                      ? 'Tap to select custom time'
                                      : _selectedTime!.format(context),
                                  style: TextStyle(
                                    color: _selectedTime == null
                                        ? Colors.grey
                                        : null,
                                  ),
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


