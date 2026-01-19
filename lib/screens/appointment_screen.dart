import '../features/telemedicine/appointment_notifications.dart';
import 'video_call_screen.dart';
import '../features/payments/payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../features/telemedicine/appointment_model.dart';
import '../features/telemedicine/appointment_service.dart';
import '../widgets/glassmorphic_card.dart';
import '../utils/logger.dart';

class AppointmentScreen extends StatefulWidget {
  final String userRole;
  final String userId;
  const AppointmentScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  Appointment? _nextAppointment;
  bool _showReminder = false;
  final AppointmentService _service = AppointmentService();
  List<Appointment> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppointmentNotifications.init();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      if (mounted) setState(() => _loading = true);
      logInfo(
        'Fetching appointments for user: ${widget.userId}, role: ${widget.userRole}',
      );
      final appts = await _service.getAppointmentsForUser(
        widget.userId,
        widget.userRole,
      );
      if (!mounted) return; // widget disposed mid-fetch

      logInfo('Found ${appts.length} appointments');

      if (mounted) {
        setState(() {
          _appointments = appts;
          _loading = false;
          final now = DateTime.now();
          final upcoming = appts
              .where(
                (a) =>
                    a.status == 'scheduled' &&
                    a.time.isAfter(now) &&
                    a.time.isBefore(now.add(const Duration(hours: 1))),
              )
              .toList();
          _nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;
          _showReminder = _nextAppointment != null;
        });
      }

      // Schedule notifications for all future appointments
      for (final appt in appts.where(
        (a) => a.status == 'scheduled' && a.time.isAfter(DateTime.now()),
      )) {
        await AppointmentNotifications.scheduleReminder(appt);
      }
    } catch (e) {
      logError('Error fetching appointments: $e');
      if (!mounted) return; // disposed
      if (mounted) {
        setState(() {
          _appointments = [];
          _loading = false;
          _showReminder = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _bookDialog() async {
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String? doctorId;
    String? doctorName; // Track doctor name for debugging
    String? notes;
    double? fee;
    List<Map<String, dynamic>> doctors = [];

    // Show loading dialog while fetching doctors
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading doctors...'),
            ],
          ),
        ),
      );
    }

    // Fetch doctors from Firestore
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      logInfo('Found ${snapshot.docs.length} doctors');

      doctors = snapshot.docs.map((doc) {
        final data = doc.data();
        final doctor = {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Doctor',
          'specialty': data['specialty'] ?? 'General',
          'availability': data['availability'] ?? 'Available',
          'fee': data['fee'] ?? 500.0, // Default fee if not specified
        };
        logInfo(
          'Doctor: ${doctor['name']}, ID: ${doctor['id']}, Specialty: ${doctor['specialty']}',
        );
        return doctor;
      }).toList();

      if (doctors.isEmpty) {
        logWarn('No doctors found in the database');
        // Add a dummy doctor for testing if none are found
        doctors = [
          {
            'id': 'dummy-doctor-id',
            'name': 'Test Doctor (No doctors in database)',
            'specialty': 'General',
            'availability': 'Always Available',
            'fee': 500.0,
          },
        ];
      }
    } catch (e) {
      logError('Error fetching doctors: $e');
      // Add a fallback doctor in case of error
      doctors = [
        {
          'id': 'error-doctor-id',
          'name': 'Doctor (Error loading doctors)',
          'specialty': 'General',
          'availability': 'Error',
          'fee': 500.0,
        },
      ];
    } finally {
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Book Appointment'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.userRole == 'patient')
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: const InputDecoration(
                        labelText: 'Select Doctor',
                      ),
                      items: doctors
                          .map(
                            (doc) => DropdownMenuItem(
                              value: doc,
                              child: Text(
                                '${doc['name']} | ${doc['specialty']} | ₹${doc['fee']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          doctorId = v?['id'];
                          doctorName = v?['name'];
                          fee = v?['fee'] != null
                              ? (v?['fee'] as num).toDouble()
                              : null;
                        });
                        logInfo(
                          'Selected doctor ID: $doctorId, Name: $doctorName',
                        );
                      },
                      validator: (v) => v == null ? 'Select a doctor' : null,
                    ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      selectedDate == null
                          ? 'Select Date'
                          : 'Date: ${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => selectedDate = d);
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(
                      selectedTime == null
                          ? 'Select Time'
                          : 'Time: ${selectedTime?.format(context)}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (t != null) setState(() => selectedTime = t);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (widget.userRole == 'doctor')
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Consultation Fee (₹)',
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => fee = double.tryParse(v ?? ''),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                    onSaved: (v) => notes = v,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a date'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a time'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                formKey.currentState!.save();

                final dt = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );

                // Ensure doctorId is not null
                final finalDoctorId =
                    doctorId ??
                    (widget.userRole == 'doctor'
                        ? widget.userId
                        : doctors.isNotEmpty
                        ? doctors.first['id']
                        : null);

                if (finalDoctorId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Could not determine doctor ID'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Debug info
                logInfo(
                  '📋 BOOKING APPOINTMENT:'
                  '\n  Patient ID: ${widget.userRole == 'patient' ? widget.userId : ''}'
                  '\n  Doctor ID: $finalDoctorId (${doctorName ?? "unknown"})'
                  '\n  User role: ${widget.userRole}'
                  '\n  Date/time: $dt'
                  '\n  Fee: $fee'
                  '\n  Notes: $notes',
                );

                // Show loading indicator
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Booking appointment...'),
                      ],
                    ),
                  ),
                );

                final appt = Appointment(
                  id: '', // Will be set by Firestore
                  patientId: widget.userRole == 'patient' ? widget.userId : '',
                  doctorId: finalDoctorId,
                  time: dt,
                  status: 'scheduled',
                  notes: notes,
                  fee: fee,
                );

                String? appointmentId;
                try {
                  appointmentId = await _service.bookAppointment(appt);
                  if (!mounted) return;
                  if (navigator.canPop()) {
                    navigator.pop();
                  } // close loading
                  if (appointmentId == null) {
                    throw Exception('Failed to get appointment ID');
                  }
                  logInfo(
                    'Appointment booked successfully with ID: $appointmentId',
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Appointment booked successfully! ID: $appointmentId',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  if (navigator.canPop()) {
                    navigator.pop(); // close booking dialog
                  }
                  _fetch();
                } catch (e) {
                  if (mounted && navigator.canPop()) {
                    navigator.pop(); // ensure dialog closed
                  }
                  logError('Error in booking dialog: $e');
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to book appointment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }

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

    return DefaultTabController(
      length: 2, // Always have 2 tabs regardless of role
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Hero(
            tag: 'appointments-appbar',
            child: Material(
              color: Colors.transparent,
              child: Text(
                'Appointments',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (widget.userRole == 'patient' || widget.userRole == 'doctor')
              IconButton(icon: const Icon(Icons.add), onPressed: _bookDialog),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Finished'),
            ],
          ),
        ),
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              decoration: BoxDecoration(gradient: gradient),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        if (_showReminder && _nextAppointment != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GlassmorphicCard(
                              color: Colors.yellow[100]?.withValues(alpha: 0.7),
                              borderRadius: 20,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You have an appointment at ${_nextAppointment!.time.toString().substring(0, 16)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _showReminder = false);
                                    },
                                    child: const Text('Dismiss'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final navigator = Navigator.of(context);
                                      if (widget.userRole == 'patient' &&
                                          _nextAppointment != null &&
                                          _nextAppointment!.fee != null) {
                                        final paymentSnap =
                                            await FirebaseFirestore.instance
                                                .collection('payments')
                                                .doc(_nextAppointment!.id)
                                                .get();
                                        if (!paymentSnap.exists ||
                                            paymentSnap.data()?['status'] !=
                                                'success') {
                                          final paid = await navigator.push(
                                            MaterialPageRoute(
                                              builder: (_) => PaymentScreen(
                                                appointmentId:
                                                    _nextAppointment!.id,
                                                amount: _nextAppointment!.fee!,
                                                doctorId:
                                                    _nextAppointment!.doctorId,
                                              ),
                                            ),
                                          );
                                          if (paid != true) {
                                            return;
                                          }
                                        }
                                      }
                                      if (!mounted) return;
                                      await navigator.push(
                                        MaterialPageRoute(
                                          builder: (_) => VideoCallScreen(
                                            userId: widget.userId,
                                            userRole: widget.userRole,
                                            participantName:
                                                widget.userRole == 'doctor'
                                                ? 'Patient'
                                                : 'Doctor',
                                            participantRole:
                                                widget.userRole == 'doctor'
                                                ? 'patient'
                                                : 'doctor',
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Join Call'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Pending appointments tab
                              Builder(
                                builder: (context) {
                                  final pendingAppointments = _appointments
                                      .where((a) => a.status == 'scheduled')
                                      .toList();

                                  if (pendingAppointments.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'No pending appointments.',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(height: 24),
                                          if (widget.userRole == 'patient')
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.add),
                                              label: const Text(
                                                'Book Appointment',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.teal,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 28,
                                                      vertical: 16,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              onPressed: _bookDialog,
                                            ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: pendingAppointments.length,
                                    itemBuilder: (ctx, i) {
                                      final a = pendingAppointments[i];
                                      return _buildAppointmentCard(a);
                                    },
                                  );
                                },
                              ),

                              // Finished appointments tab
                              Builder(
                                builder: (context) {
                                  final finishedAppointments = _appointments
                                      .where((a) => a.status != 'scheduled')
                                      .toList();

                                  if (finishedAppointments.isEmpty) {
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'No finished appointments.',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: finishedAppointments.length,
                                    itemBuilder: (ctx, i) {
                                      final a = finishedAppointments[i];
                                      return _buildAppointmentCard(a);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment a) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: GlassmorphicCard(
        borderRadius: 20,
        child: FutureBuilder<DocumentSnapshot>(
          future:
              (a.fee != null &&
                  a.status == 'scheduled' &&
                  widget.userRole == 'patient')
              ? FirebaseFirestore.instance
                    .collection('payments')
                    .doc(a.id)
                    .get()
              : FirebaseFirestore.instance
                    .collection('payments')
                    .doc('_dummy')
                    .get(),
          builder: (context, snapshot) {
            final paymentDoc = snapshot.data;
            final isPaid =
                paymentDoc != null &&
                paymentDoc.exists &&
                paymentDoc.data() != null &&
                (paymentDoc.data() as Map<String, dynamic>)['status'] ==
                    'success';

            Color statusColor;
            String statusLabel;
            switch (a.status) {
              case 'scheduled':
                statusColor = Colors.blue;
                statusLabel = 'Pending';
                break;
              case 'completed':
                statusColor = Colors.green;
                statusLabel = 'Finished';
                break;
              case 'cancelled':
                statusColor = Colors.red;
                statusLabel = 'Cancelled';
                break;
              default:
                statusColor = Colors.grey;
                statusLabel = a.status;
            }

            return ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(a.time.toString().substring(0, 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userRole == 'doctor'
                        ? 'Patient: ${a.patientId}'
                        : 'Doctor: ${a.doctorId}',
                  ),
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (a.notes != null && a.notes!.isNotEmpty)
                    Text('Notes: ${a.notes}'),
                  if (a.fee != null) Text('Fee: ₹${a.fee}'),
                  if (isPaid)
                    const Text(
                      'Payment: Paid',
                      style: TextStyle(color: Colors.green),
                    ),
                  if (!isPaid && a.fee != null)
                    const Text(
                      'Payment: Unpaid',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (a.status == 'scheduled' &&
                      a.fee != null &&
                      widget.userRole == 'patient' &&
                      !isPaid)
                    IconButton(
                      icon: const Icon(Icons.payment, color: Colors.orange),
                      tooltip: 'Pay Now',
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final paid = await navigator.push(
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              appointmentId: a.id,
                              amount: a.fee!,
                              doctorId: a.doctorId,
                            ),
                          ),
                        );
                        if (paid == true && mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  if (a.status == 'scheduled')
                    IconButton(
                      icon: const Icon(Icons.video_call, color: Colors.teal),
                      tooltip: 'Join Video Call',
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        if (widget.userRole == 'patient' &&
                            a.fee != null &&
                            !isPaid) {
                          final paid = await navigator.push(
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                appointmentId: a.id,
                                amount: a.fee!,
                                doctorId: a.doctorId,
                              ),
                            ),
                          );
                          if (paid != true) {
                            return;
                          }
                        }
                        if (!mounted) return;
                        await navigator.push(
                          MaterialPageRoute(
                            builder: (_) => VideoCallScreen(
                              userId: widget.userId,
                              userRole: widget.userRole,
                              participantName: widget.userRole == 'doctor'
                                  ? 'Patient'
                                  : 'Doctor',
                              participantRole: widget.userRole == 'doctor'
                                  ? 'patient'
                                  : 'doctor',
                            ),
                          ),
                        );
                      },
                    ),
                  if (a.status == 'scheduled')
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () async {
                        await _service.updateStatus(a.id, 'cancelled');
                        if (mounted) {
                          _fetch();
                        }
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
