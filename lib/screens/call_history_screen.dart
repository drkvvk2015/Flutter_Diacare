import 'package:flutter/material.dart';
import '../features/telemedicine/call_history_model.dart';
import '../features/telemedicine/call_history_service.dart';

class CallHistoryScreen extends StatefulWidget {
  final String userRole;
  final String userId;
  const CallHistoryScreen({
    super.key,
    required this.userRole,
    required this.userId,
  });

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final CallHistoryService _service = CallHistoryService();
  List<CallHistory> _calls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final calls = await _service.getCallHistoryForUser(
      widget.userId,
      widget.userRole,
    );
    if (!mounted) return;
    setState(() {
      _calls = calls;
      _loading = false;
    });
  }

  void _addNotesDialog(CallHistory call) async {
    final controller = TextEditingController(text: call.notes ?? '');
    final navigator = Navigator.of(context);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Call Notes'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.addNotes(call.id, controller.text);
              if (navigator.mounted) navigator.pop();
              _fetch();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _calls.length,
              itemBuilder: (ctx, i) {
                final c = _calls[i];
                final duration = c.endTime.difference(c.startTime);
                return ListTile(
                  leading: const Icon(Icons.video_call, color: Colors.teal),
                  title: Text(c.startTime.toString().substring(0, 16)),
                  subtitle: Text(
                    'Duration: ${duration.inMinutes} min${c.notes != null && c.notes!.isNotEmpty ? '\nNotes: ${c.notes}' : ''}',
                  ),
                  trailing: widget.userRole == 'doctor'
                      ? IconButton(
                          icon: const Icon(Icons.note_add),
                          tooltip: 'Add Notes',
                          onPressed: () => _addNotesDialog(c),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
