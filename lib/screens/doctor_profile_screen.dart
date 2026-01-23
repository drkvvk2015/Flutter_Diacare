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
    required this.initial, required this.onChanged, super.key,
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
    );
    if (from == null || !mounted) return;
    final to = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (from.hour + 1) % 24, minute: from.minute),
    );
    if (to == null) return;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day in days)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: avail[day]!.isNotEmpty,
                onChanged: (val) {
                  setState(() {
                    if ((val ?? false) && avail[day]!.isEmpty) {
                      avail[day]!.add({'from': '09:00', 'to': '10:00'});
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
                    Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (avail[day]!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: [
                          for (int i = 0; i < avail[day]!.length; i++)
                            Chip(
                              label: Text(
                                '${avail[day]![i]['from']} - ${avail[day]![i]['to']}',
                              ),
                              onDeleted: () => removeSlot(day, i),
                            ),
                          ActionChip(
                            label: const Text('Add Time Slot'),
                            avatar: const Icon(Icons.add, size: 18),
                            onPressed: () => addSlot(day),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
