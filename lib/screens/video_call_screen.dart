import 'package:flutter/material.dart';
import 'prescription_screen.dart';
import '../models/patient.dart';

class VideoCallScreen extends StatefulWidget {
  final String userId;
  final String userRole; // 'doctor' or 'patient'
  final String? participantName;
  final String? participantRole;
  const VideoCallScreen({
    super.key,
    required this.userId,
    required this.userRole,
    this.participantName,
    this.participantRole,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Future<void> joinJitsiMeeting() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Mock video call functionality - would integrate with actual video service
      setState(() {
        connecting = true;
      });

      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        connecting = false;
        inCall = true;
        callStart = DateTime.now();
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Video call feature will be available soon'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        connecting = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to join video call: $e')),
      );
    }
  }

  // This should be set when the call is started, e.g. from appointment or passed as argument
  Patient? currentPatient;

  void _openPrescription({bool viewOnly = false}) {
    if (currentPatient == null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('No patient selected for prescription.')),
      );
      return;
    }
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute(
        builder: (_) => PrescriptionScreen(),
        settings: RouteSettings(
          arguments: {'patient': currentPatient!, 'viewOnly': viewOnly},
        ),
      ),
    );
  }

  bool inCall = false;
  bool connecting = false;
  bool callEnded = false;
  bool muted = false;
  bool cameraOn = true;
  DateTime? callStart;
  Duration callDuration = Duration.zero;
  late final String selfRole;
  late final String otherRole;
  late final String otherName;
  late final String selfName;
  late final bool isDoctor;
  late final bool isPatient;
  late final String waitingMsg;

  @override
  void initState() {
    super.initState();
    selfRole = widget.userRole;
    isDoctor = selfRole == 'doctor';
    isPatient = selfRole == 'patient';
    otherRole = widget.participantRole ?? (isDoctor ? 'patient' : 'doctor');
    otherName = widget.participantName ?? (isDoctor ? 'Patient' : 'Doctor');
    selfName = isDoctor ? 'Doctor' : 'Patient';
    waitingMsg = isDoctor
        ? 'Waiting for patient to join...'
        : 'Waiting for doctor to start the call...';
  }

  void joinCall() {
    joinJitsiMeeting();
  }

  void leaveCall() {
    setState(() {
      inCall = false;
      callEnded = true;
      callDuration = callStart != null
          ? DateTime.now().difference(callStart!)
          : Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telemedicine (Video Call)')),
      body: Center(
        child: connecting
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Connecting as $selfRole...'),
                ],
              )
            : inCall
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cameraOn ? Icons.videocam : Icons.videocam_off,
                    size: 80,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'In Call with $otherName ($otherRole)',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Call Duration: ${callDuration.inMinutes.toString().padLeft(2, '0')}:${(callDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          muted ? Icons.mic_off : Icons.mic,
                          color: muted ? Colors.red : Colors.teal,
                        ),
                        tooltip: muted ? 'Unmute' : 'Mute',
                        onPressed: () => setState(() => muted = !muted),
                      ),
                      IconButton(
                        icon: Icon(
                          cameraOn ? Icons.videocam : Icons.videocam_off,
                          color: cameraOn ? Colors.teal : Colors.red,
                        ),
                        tooltip: cameraOn
                            ? 'Turn Camera Off'
                            : 'Turn Camera On',
                        onPressed: () => setState(() => cameraOn = !cameraOn),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call_end),
                        color: Colors.red,
                        tooltip: 'End Call',
                        onPressed: leaveCall,
                      ),
                    ],
                  ),
                  if (isDoctor)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Create Prescription'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                        ),
                        onPressed: _openPrescription,
                      ),
                    ),
                ],
              )
            : callEnded
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.call_end, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Call Ended. Duration: ${callDuration.inMinutes.toString().padLeft(2, '0')}:${(callDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View Prescription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                    onPressed: () => _openPrescription(viewOnly: true),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Start New Call'),
                    onPressed: joinCall,
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDoctor ? Icons.person : Icons.person_outline,
                    size: 80,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  Text(waitingMsg, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  if (isDoctor)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.video_call),
                      label: const Text('Start Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: joinCall,
                    )
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.video_call),
                      label: const Text('Join Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: joinCall,
                    ),
                ],
              ),
      ),
    );
  }
}
