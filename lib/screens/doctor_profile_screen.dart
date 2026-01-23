import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ignore: avoid_web_libraries_in_flutter
// Only import dart:html on web
// ignore: uri_does_not_exist
import 'doctor_profile_web_stub.dart'
    if (dart.library.html) 'doctor_profile_web_html.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({required this.userId, super.key});
  final String userId;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic>? profile;
  bool loading = true;
  String? errorMsg;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController regNumberController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  String? photoUrl;
  Map<String, List<Map<String, String>>>? availability;
  double? fee;
  ImagePicker? _picker;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _picker = ImagePicker();
    }
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);
      final doc = await docRef.get();
      if (!mounted) return; // ensure safe before setState
      final Map<String, dynamic> data = doc.data() ?? {};
      final Map<String, Object> requiredFields = {
        'name': '',
        'degree': '',
        'specialty': '',
        'contact': '',
        'about': '',
        'photoUrl': '',
        'fee': 0.0,
        'availability': <String, dynamic>{},
        'registrationNumber': '',
        'hospitalOrClinic': '',
        'role': 'doctor',
      };
      bool needsUpdate = false;
      requiredFields.forEach((key, value) {
        if (!data.containsKey(key)) {
          data[key] = value;
          needsUpdate = true;
        }
      });
      if (data['fee'] is! num) {
        data['fee'] = 0.0;
        needsUpdate = true;
      }
      if (data['availability'] is! Map) {
        data['availability'] = <String, dynamic>{};
        needsUpdate = true;
      }
      if (needsUpdate) {
        await docRef.set(data, SetOptions(merge: true));
        if (!mounted) return;
      }
      profile = data;
      if (!mounted) return;
      setState(() {
        nameController.text = profile?['name'] as String? ?? '';
        degreeController.text = profile?['degree'] as String? ?? '';
        specialtyController.text = profile?['specialty'] as String? ?? '';
        contactController.text = profile?['contact'] as String? ?? '';
        aboutController.text = profile?['about'] as String? ?? '';
        photoUrl = profile?['photoUrl'] as String?;
        feeController.text = profile?['fee'] != null
            ? (profile?['fee']).toString()
            : '';
        regNumberController.text = profile?['registrationNumber'] as String? ?? '';
        hospitalController.text = profile?['hospitalOrClinic'] as String? ?? '';
        Map<String, dynamic>? availRaw;
        try {
          availRaw = profile?['availability'] as Map<String, dynamic>?;
        } catch (_) {
          availRaw = {};
        }
        if (availRaw != null) {
          availability = availRaw.map(
            (day, slots) => MapEntry(
              day,
              (slots as List<dynamic>).map((slot) {
                if (slot is Map &&
                    slot.containsKey('from') &&
                    slot.containsKey('to')) {
                  return {
                    'from': slot['from'] as String,
                    'to': slot['to'] as String,
                  };
                } else if (slot is String) {
                  return {'from': slot, 'to': slot};
                }
                return {'from': '09:00', 'to': '10:00'};
              }).toList(),
            ),
          );
        } else {
          availability = {};
        }
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        profile = {};
        nameController.text = '';
        specialtyController.text = '';
        contactController.text = '';
        aboutController.text = '';
        photoUrl = null;
        feeController.text = '';
        availability = {};
        fee = null;
        loading = false;
        errorMsg = 'Failed to load profile. Please try again.';
      });
    }
  }

  Future<void> _saveProfile() async {
    // Show loading indicator
    setState(() {
      loading = true;
      errorMsg = null;
    });
    
    try {
      final data = {
        'name': nameController.text.trim(),
        'displayName': nameController.text.trim(), // Also update displayName
        'degree': degreeController.text.trim(),
        'specialty': specialtyController.text.trim(),
        'contact': contactController.text.trim(),
        'about': aboutController.text.trim(),
        'photoUrl': photoUrl ?? '',
        'availability': availability ?? {},
        'fee': double.tryParse(feeController.text.trim()) ?? 0.0,
        'registrationNumber': regNumberController.text.trim(),
        'hospitalOrClinic': hospitalController.text.trim(),
        'role': 'doctor',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (data['fee'] is String || data['fee'] == '') data['fee'] = 0.0;
      if (data['availability'] is! Map) data['availability'] = {};
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set(data, SetOptions(merge: true));
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      _fetch();
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save profile: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      setState(() {
        errorMsg = 'Failed to save profile: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (kIsWeb) {
      await pickAndUploadPhotoWeb(widget.userId, (url) async {
        if (!mounted) return;
        setState(() {
          photoUrl = url;
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .set({'photoUrl': url}, SetOptions(merge: true));
        if (mounted) _fetch();
      });
    } else {
      final picked = await _picker?.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;
      final file = await picked.readAsBytes();
      final ref = FirebaseStorage.instance.ref().child(
        'profile_photos/${widget.userId}.jpg',
      );
      await ref.putData(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        photoUrl = url;
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({'photoUrl': url}, SetOptions(merge: true));
      if (mounted) _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Replace with your actual UI. Placeholder for now.
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage:
                                photoUrl != null && photoUrl!.isNotEmpty
                                ? NetworkImage(photoUrl!)
                                : null,
                            child: (photoUrl == null || photoUrl!.isEmpty)
                                ? const Icon(Icons.person, size: 48)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: _pickAndUploadPhoto,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: degreeController,
                      decoration: const InputDecoration(labelText: 'Degree'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: specialtyController,
                      decoration: const InputDecoration(labelText: 'Specialty'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: regNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: hospitalController,
                      decoration: const InputDecoration(
                        labelText: 'Hospital/Clinic',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: contactController,
                      decoration: const InputDecoration(labelText: 'Contact'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: aboutController,
                      decoration: const InputDecoration(labelText: 'About'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: feeController,
                      decoration: const InputDecoration(
                        labelText: 'Consultation Fee',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Availability',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    AvailabilityPicker(
                      initial: availability ?? {},
                      onChanged: (val) => setState(() => availability = val),
                    ),
                    const SizedBox(height: 24),
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          errorMsg!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _saveProfile();
                          }
                        },
                        child: loading 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class AvailabilityPicker extends StatefulWidget {
  const AvailabilityPicker({
    required this.initial,
    required this.onChanged,
    super.key,
  });
  final Map<String, List<Map<String, String>>> initial;
  final void Function(Map<String, List<Map<String, String>>> avail) onChanged;

  @override
  State<AvailabilityPicker> createState() => _AvailabilityPickerState();
}

class _AvailabilityPickerState extends State<AvailabilityPicker> {
  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  late Map<String, List<Map<String, String>>> avail;

  @override
  void initState() {
    super.initState();
    avail = {};
    for (final d in days) {
      final slots = widget.initial[d] ?? [];
      avail[d] = [
        for (final slot in slots)
          if (slot.containsKey('from') && slot.containsKey('to'))
            {'from': slot['from']!, 'to': slot['to']!},
      ];
    }
  }

  Future<void> addSlot(String day) async {
    // Capture a local reference to context to satisfy lint about using
    // BuildContext synchronously after awaits.
    final ctx = context;
    final from = await showTimePicker(
      context: ctx,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Select start time (9 AM - 10 PM)',
    );
    if (from == null || !mounted) return;

    // Validate start time is within 9 AM - 10 PM
    if (from.hour < 9 || from.hour >= 22) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Start time must be between 9 AM and 10 PM'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate end time - default to 1 hour later, max 10 PM
    final endHour = (from.hour + 1).clamp(9, 22);
    final to = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: endHour, minute: from.minute),
      helpText: 'Select end time (9 AM - 10 PM)',
    );
    if (to == null) return;

    // Validate end time is within 9 AM - 10 PM
    if (to.hour < 9 || to.hour > 22 || (to.hour == 22 && to.minute > 0)) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('End time must be between 9 AM and 10 PM'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate end time is after start time
    if (to.hour < from.hour || (to.hour == from.hour && to.minute <= from.minute)) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      avail[day]!.add({'from': from.format(ctx), 'to': to.format(ctx)});
      widget.onChanged(avail);
    });
  }

  void removeSlot(String day, int idx) {
    setState(() {
      avail[day]!.removeAt(idx);
      widget.onChanged(avail);
    });
  }

  /// Adds a quick preset time slot
  void addQuickSlot(String day, String from, String to) {
    // Check if slot already exists
    final exists = avail[day]!.any(
      (slot) => slot['from'] == from && slot['to'] == to,
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time slot is already added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      avail[day]!.add({'from': from, 'to': to});
      widget.onChanged(avail);
    });
  }

  /// Shows quick slot selection dialog
  void showQuickSlotDialog(String day) {
    final quickSlots = <Map<String, String>>[
      // Morning slots
      {'from': '9:00 AM', 'to': '10:00 AM', 'label': 'Morning Early'},
      {'from': '10:00 AM', 'to': '11:00 AM', 'label': 'Morning Mid'},
      {'from': '11:00 AM', 'to': '12:00 PM', 'label': 'Morning Late'},
      // Afternoon slots
      {'from': '12:00 PM', 'to': '1:00 PM', 'label': 'Noon'},
      {'from': '1:00 PM', 'to': '2:00 PM', 'label': 'Early Afternoon'},
      {'from': '2:00 PM', 'to': '3:00 PM', 'label': 'Mid Afternoon'},
      {'from': '3:00 PM', 'to': '4:00 PM', 'label': 'Late Afternoon'},
      {'from': '4:00 PM', 'to': '5:00 PM', 'label': 'Evening Start'},
      // Evening slots
      {'from': '5:00 PM', 'to': '6:00 PM', 'label': 'Early Evening'},
      {'from': '6:00 PM', 'to': '7:00 PM', 'label': 'Evening'},
      {'from': '7:00 PM', 'to': '8:00 PM', 'label': 'Late Evening'},
      {'from': '8:00 PM', 'to': '9:00 PM', 'label': 'Night Early'},
      {'from': '9:00 PM', 'to': '10:00 PM', 'label': 'Night'},
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Quick Add Slots for $day'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select preferred time slots:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                // Morning section
                _buildSlotSection(
                  'Morning (9 AM - 12 PM)',
                  Colors.orange,
                  quickSlots.where((s) => 
                    s['from']!.contains('9:00 AM') || 
                    s['from']!.contains('10:00 AM') || 
                    s['from']!.contains('11:00 AM'),
                  ).toList(),
                  day,
                  ctx,
                ),
                const SizedBox(height: 12),
                // Afternoon section
                _buildSlotSection(
                  'Afternoon (12 PM - 5 PM)',
                  Colors.blue,
                  quickSlots.where((s) => 
                    s['from']!.contains('12:00 PM') || 
                    s['from']!.contains('1:00 PM') || 
                    s['from']!.contains('2:00 PM') ||
                    s['from']!.contains('3:00 PM') ||
                    s['from']!.contains('4:00 PM'),
                  ).toList(),
                  day,
                  ctx,
                ),
                const SizedBox(height: 12),
                // Evening section
                _buildSlotSection(
                  'Evening (5 PM - 10 PM)',
                  Colors.purple,
                  quickSlots.where((s) => 
                    s['from']!.contains('5:00 PM') || 
                    s['from']!.contains('6:00 PM') || 
                    s['from']!.contains('7:00 PM') ||
                    s['from']!.contains('8:00 PM') ||
                    s['from']!.contains('9:00 PM'),
                  ).toList(),
                  day,
                  ctx,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSection(
    String title,
    Color color,
    List<Map<String, String>> slots,
    String day,
    BuildContext dialogContext,
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
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isAdded = avail[day]!.any(
              (s) => s['from'] == slot['from'] && s['to'] == slot['to'],
            );
            return InkWell(
              onTap: isAdded
                  ? null
                  : () {
                      addQuickSlot(day, slot['from']!, slot['to']!);
                      Navigator.pop(dialogContext);
                      showQuickSlotDialog(day); // Reopen to show updated state
                    },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isAdded
                      ? Colors.green.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAdded ? Colors.green : color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAdded)
                      const Icon(Icons.check, size: 16, color: Colors.green)
                    else
                      Icon(Icons.add, size: 16, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${slot['from']} - ${slot['to']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAdded ? Colors.green : color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick preset buttons
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.teal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Quick Presets',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.wb_sunny, size: 16),
                    label: const Text('Morning Only'),
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    onPressed: () => _applyPreset('morning'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.wb_cloudy, size: 16),
                    label: const Text('Afternoon Only'),
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    onPressed: () => _applyPreset('afternoon'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.nights_stay, size: 16),
                    label: const Text('Evening Only'),
                    backgroundColor: Colors.purple.withValues(alpha: 0.2),
                    onPressed: () => _applyPreset('evening'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.all_inclusive, size: 16),
                    label: const Text('Full Day'),
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                    onPressed: () => _applyPreset('fullday'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.work, size: 16),
                    label: const Text('Weekdays Only'),
                    backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                    onPressed: () => _applyPreset('weekdays'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Day-wise availability
        for (final day in days)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: avail[day]!.isNotEmpty,
                    onChanged: (val) {
                      setState(() {
                        if ((val ?? false) && avail[day]!.isEmpty) {
                          avail[day]!.add({'from': '9:00 AM', 'to': '10:00 AM'});
                        } else if (val == false) {
                          avail[day] = [];
                        }
                        widget.onChanged(avail);
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              day,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (avail[day]!.isNotEmpty)
                              Text(
                                '${avail[day]!.length} slot(s)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                        if (avail[day]!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (int i = 0; i < avail[day]!.length; i++)
                                Chip(
                                  label: Text(
                                    '${avail[day]![i]['from']} - ${avail[day]![i]['to']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => removeSlot(day, i),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ActionChip(
                                label: const Text('Quick Add'),
                                avatar: const Icon(Icons.flash_on, size: 16),
                                backgroundColor: Colors.teal.withValues(alpha: 0.1),
                                onPressed: () => showQuickSlotDialog(day),
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                label: const Text('Custom'),
                                avatar: const Icon(Icons.access_time, size: 16),
                                onPressed: () => addSlot(day),
                              ),
                            ],
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Not available',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _applyPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'morning':
          for (final day in days) {
            avail[day] = [
              {'from': '9:00 AM', 'to': '10:00 AM'},
              {'from': '10:00 AM', 'to': '11:00 AM'},
              {'from': '11:00 AM', 'to': '12:00 PM'},
            ];
          }
        case 'afternoon':
          for (final day in days) {
            avail[day] = [
              {'from': '12:00 PM', 'to': '1:00 PM'},
              {'from': '2:00 PM', 'to': '3:00 PM'},
              {'from': '3:00 PM', 'to': '4:00 PM'},
              {'from': '4:00 PM', 'to': '5:00 PM'},
            ];
          }
        case 'evening':
          for (final day in days) {
            avail[day] = [
              {'from': '5:00 PM', 'to': '6:00 PM'},
              {'from': '6:00 PM', 'to': '7:00 PM'},
              {'from': '7:00 PM', 'to': '8:00 PM'},
              {'from': '8:00 PM', 'to': '9:00 PM'},
              {'from': '9:00 PM', 'to': '10:00 PM'},
            ];
          }
        case 'fullday':
          for (final day in days) {
            avail[day] = [
              {'from': '9:00 AM', 'to': '12:00 PM'},
              {'from': '2:00 PM', 'to': '5:00 PM'},
              {'from': '6:00 PM', 'to': '9:00 PM'},
            ];
          }
        case 'weekdays':
          for (final day in days) {
            if (day != 'Saturday' && day != 'Sunday') {
              avail[day] = [
                {'from': '9:00 AM', 'to': '12:00 PM'},
                {'from': '2:00 PM', 'to': '5:00 PM'},
              ];
            } else {
              avail[day] = [];
            }
          }
      }
      widget.onChanged(avail);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${preset.replaceAll('_', ' ')} preset'),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
