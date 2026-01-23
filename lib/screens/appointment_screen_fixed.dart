import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../features/payments/payment_screen.dart';
import '../features/telemedicine/appointment_model.dart';
import '../features/telemedicine/appointment_notifications.dart';
import '../features/telemedicine/appointment_service.dart';
import '../utils/logger.dart';
import '../widgets/glassmorphic_card.dart';
import 'video_call_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({
    required this.userRole, required this.userId, super.key,
  });
  final String userRole;
  final String userId;

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
    if (!mounted) return; // defensive
    setState(() => _loading = true);
    final appts = await _service.getAppointmentsForUser(
      widget.userId,
      widget.userRole,
    );
    logInfo('Fetched ${appts.length} appointments (fixed screen)');
    if (!mounted) return; // widget may have been disposed during await
    setState(() {
      _appointments = appts;
      _loading = false;
      // Find next upcoming appointment within 1 hour
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
    // Schedule notifications for all future appointments (does not use context)
    for (final appt in appts.where(
      (a) => a.status == 'scheduled' && a.time.isAfter(DateTime.now()),
    )) {
      await AppointmentNotifications.scheduleReminder(appt);
    }
  }

  Future<void> _bookDialog() async {
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String? doctorId;
    String? notes;
    double? fee;
    List<Map<String, dynamic>> doctors = [];

    // Fetch doctors from Firestore
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();
      doctors = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'availability': data['availability'] ?? '',
          'fee': data['fee'],
        };
      }).toList();
    } catch (e) {
      logError('Failed to fetch doctors: $e');
    }

    if (!mounted) return;
    final navigator = Navigator.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Book Appointment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.userRole == 'patient')
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(labelText: 'Select Doctor'),
                  items: doctors
                      .map(
                        (doc) => DropdownMenuItem(
                          value: doc,
                          child: Text(
                            '${doc['name']}  |  ${doc['availability']}  |  ₹${doc['fee'] ?? ''}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    doctorId = v?['id'] as String?;
                    fee = v?['fee'] != null
                        ? (v?['fee'] as num).toDouble()
                        : null;
                  },
                  validator: (v) => v == null ? 'Select a doctor' : null,
                ),
              ListTile(
                title: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : selectedDate.toString().substring(0, 10),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null && mounted) setState(() => selectedDate = d);
                },
              ),
              ListTile(
                title: Text(
                  selectedTime == null
                      ? 'Select Time (9 AM - 10 PM)'
                      : selectedTime?.format(context) ?? '',
                ),
                trailing: const Icon(Icons.access_time),
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

                  final t = await showTimePicker(
                    context: context,
                    initialTime: initialTime,
                    helpText: 'Select time (9 AM - 10 PM)',
                  );
                  if (t != null && mounted) {
                    // Validate time is within 9 AM - 10 PM
                    if (t.hour < 9 || t.hour >= 22) {
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
                    setState(() => selectedTime = t);
                  }
                },
              ),
              if (widget.userRole == 'doctor')
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Consultation Fee (₹)',
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => fee = double.tryParse(v ?? ''),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                onSaved: (v) => notes = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: navigator.pop,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() &&
                  selectedDate != null &&
                  selectedTime != null) {
                formKey.currentState!.save();
                final dt = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );
                final appt = Appointment(
                  id: '',
                  patientId: widget.userRole == 'patient' ? widget.userId : '',
                  doctorId:
                      doctorId ??
                      (widget.userRole == 'doctor' ? widget.userId : ''),
                  time: dt,
                  status: 'scheduled',
                  notes: notes,
                  fee: fee,
                );
                try {
                  await _service.bookAppointment(appt);
                  logInfo('Booked new appointment at $dt');
                } catch (e) {
                  logError('Failed to book appointment: $e');
                }
                if (!mounted) return; // still on screen?
                navigator.pop();
                _fetch();
              }
            },
            child: const Text('Book'),
          ),
        ],
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: GlassmorphicCard(
                              borderRadius: 20,
                              color: Colors.yellow[100]?.withValues(alpha: 0.7),
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
                                        final paid = await navigator.push(
                                          MaterialPageRoute<bool>(
                              builder: (_) => PaymentScreen(
                                              appointmentId:
                                                  _nextAppointment!.id,
                                              amount: _nextAppointment!.fee!,
                                              doctorId:
                                                  _nextAppointment!.doctorId,
                                            ),
                                          ),
                                        );
                                        if (!mounted || paid != true) return;
                                      }
                                      if (!mounted) return;
                                      await navigator.push(
                                        MaterialPageRoute<void>(
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
            final paymentDoc =
                snapshot.data; // paymentDoc used below to compute isPaid
            final isPaid =
                paymentDoc != null &&
                paymentDoc.exists &&
                paymentDoc.data() != null &&
                (paymentDoc.data()! as Map<String, dynamic>)['status'] ==
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
                  if (a.status == 'scheduled')
                    IconButton(
                      icon: const Icon(Icons.video_call, color: Colors.teal),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        if (widget.userRole == 'patient' &&
                            a.fee != null &&
                            !isPaid) {
                          final paid = await navigator.push(
                            MaterialPageRoute<bool>(
                              builder: (_) => PaymentScreen(
                                appointmentId: a.id,
                                amount: a.fee!,
                                doctorId: a.doctorId,
                              ),
                            ),
                          );
                          if (!mounted || paid != true) return;
                        }
                        if (!mounted) return;
                        await navigator.push(
                          MaterialPageRoute<void>(
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
                        if (!mounted) return;
                        _fetch();
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



