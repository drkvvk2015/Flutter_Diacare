import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Only import dart:html on web
// ignore: uri_does_not_exist
import 'patient_profile_web_stub.dart'
    if (dart.library.html) 'patient_profile_web_html.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({required this.userId, super.key});
  final String userId;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  // Dynamic comorbidities list and controllers
  List<Map<String, String>> _comorbiditiesList = [];
  final TextEditingController comorbidityNameController =
      TextEditingController();
  final TextEditingController comorbidityDurationController =
      TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController surgeriesController = TextEditingController();
  Map<String, dynamic>? profile;
  bool loading = true;
  String? photoUrl;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  String? uhid;
  // Only initialize on mobile
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
      if (!mounted) return;
      final Map<String, dynamic> data = doc.data() ?? {};
      // Patient required fields
      final Map<String, Object> requiredFields = {
        'name': '',
        'uhid': '',
        'comorbidities': <dynamic>[],
        'allergies': '',
        'surgeries': '',
        'contact': '',
        'about': '',
        'photoUrl': '',
        'role': 'patient',
      };
      bool needsUpdate = false;
      requiredFields.forEach((key, value) {
        if (!data.containsKey(key) || data[key] == null) {
          data[key] = value;
          needsUpdate = true;
        }
      });
      if (needsUpdate) {
        await docRef.set(data, SetOptions(merge: true));
      }
      if (!mounted) return;
      profile = data;
      setState(() {
        nameController.text = profile?['name'] as String? ?? '';
        contactController.text = profile?['contact'] as String? ?? '';
        aboutController.text = profile?['about'] as String? ?? '';
        photoUrl = profile?['photoUrl'] as String?;
        uhid = profile?['uhid'] as String?;
        final List<dynamic> comorbiditiesRaw =
            (profile?['comorbidities'] ?? <dynamic>[]) as List<dynamic>;
        _comorbiditiesList = comorbiditiesRaw
            .map<Map<String, String>>(
              (item) => {
                'name': (item as Map)['name'] as String? ?? '',
                'duration': item['duration'] as String? ?? '',
              },
            )
            .toList();
        allergiesController.text = profile?['allergies'] as String? ?? '';
        surgeriesController.text = profile?['surgeries'] as String? ?? '';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        profile = {};
        nameController.text = '';
        contactController.text = '';
        aboutController.text = '';
        photoUrl = null;
        uhid = '';
        allergiesController.text = '';
        surgeriesController.text = '';
        loading = false;
      });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main widget tree
    final gradient = LinearGradient(
      colors: [
        Colors.teal.shade400,
        Colors.blue.shade200,
        Colors.purple.shade200,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Hero(
          tag: 'patient-profile-appbar',
          child: Material(
            color: Colors.transparent,
            child: Text(
              'Patient Profile',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(gradient: gradient),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // --- Clinical History Section ---
                        const Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              color: Colors.teal,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Clinical History',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28, thickness: 1.2),
                        // --- Comorbidities ---
                        const Row(
                          children: [
                            Icon(
                              Icons.coronavirus,
                              color: Colors.teal,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Comorbidities',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: comorbidityNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Comorbidity',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g. Hypertension',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: comorbidityDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Years',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g. 5',
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Add comorbidity',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.teal,
                                ),
                                onPressed: () {
                                  final name = comorbidityNameController.text
                                      .trim();
                                  final duration = comorbidityDurationController
                                      .text
                                      .trim();
                                  if (name.isNotEmpty && duration.isNotEmpty) {
                                    setState(() {
                                      _comorbiditiesList.add({
                                        'name': name,
                                        'duration': duration,
                                      });
                                      comorbidityNameController.clear();
                                      comorbidityDurationController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_comorbiditiesList.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.list_alt,
                                    color: Colors.teal,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Added Comorbidities:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _comorbiditiesList.length,
                                separatorBuilder: (context, idx) =>
                                    Divider(height: 1, color: Colors.grey[200]),
                                itemBuilder: (context, idx) {
                                  final c = _comorbiditiesList[idx];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.bubble_chart,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                    title: Text(
                                      '${c['name']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Duration: ${c['duration']} years',
                                    ),
                                    trailing: Tooltip(
                                      message: 'Remove',
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _comorbiditiesList.removeAt(idx);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              // Simple comparison chart
                              Card(
                                color: Colors.teal[50],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  child: SizedBox(
                                    height: 120,
                                    child: _comorbiditiesList.isNotEmpty
                                        ? Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: _comorbiditiesList.map((
                                              c,
                                            ) {
                                              final duration =
                                                  int.tryParse(
                                                    c['duration'] ?? '0',
                                                  ) ??
                                                  0;
                                              return Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Container(
                                                      height: (duration * 10)
                                                          .toDouble()
                                                          .clamp(0, 100),
                                                      width: 18,
                                                      decoration: BoxDecoration(
                                                        color: Colors.teal,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      c['name'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${c['duration']}y',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          )
                                        : const Center(child: Text('No data')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        // --- Allergies Entry ---
                        const Divider(height: 32, thickness: 1),
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Allergies',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: allergiesController,
                          decoration: const InputDecoration(
                            labelText: 'Allergies',
                            border: OutlineInputBorder(),
                            helperText: 'e.g. Penicillin, Peanuts',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        // --- Surgeries Entry ---
                        const Row(
                          children: [
                            Icon(Icons.healing, color: Colors.purple, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Surgeries',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: surgeriesController,
                          decoration: const InputDecoration(
                            labelText: 'Surgeries',
                            border: OutlineInputBorder(),
                            helperText: 'e.g. Appendectomy, Cataract',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 32),
                        // --- Save Button ---
                        const Divider(height: 32, thickness: 1),
                        Tooltip(
                          message: 'Save all changes to your clinical history',
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            icon: const Icon(Icons.save_alt, size: 22),
                            label: const Text(
                              'Save Clinical History',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final docRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.userId);
                              final data = {
                                'name': nameController.text.trim(),
                                'contact': contactController.text.trim(),
                                'about': aboutController.text.trim(),
                                'photoUrl': photoUrl ?? '',
                                'role': 'patient',
                                'comorbidities': _comorbiditiesList,
                                'allergies': allergiesController.text.trim(),
                                'surgeries': surgeriesController.text.trim(),
                              };
                              try {
                                await docRef.set(data, SetOptions(merge: true));
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Clinical history saved!'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed to save: $e')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: MediaQuery.of(context).size.width / 2 - 54,
            child: GestureDetector(
              onTap: _pickAndUploadPhoto,
              child: CircleAvatar(
                radius: 54,
                backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null || photoUrl!.isEmpty
                    ? const Icon(Icons.person, size: 54)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

