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
  // Dynamic lists with duration tracking
  List<Map<String, String>> _comorbiditiesList = [];
  List<Map<String, String>> _allergiesList = [];
  List<Map<String, String>> _surgeriesList = [];
  
  // Controllers for adding new entries
  final TextEditingController comorbidityNameController =
      TextEditingController();
  final TextEditingController comorbidityDurationController =
      TextEditingController();
  final TextEditingController allergyNameController = TextEditingController();
  final TextEditingController allergyDurationController = TextEditingController();
  final TextEditingController surgeryNameController = TextEditingController();
  final TextEditingController surgeryYearController = TextEditingController();
  
  // Basic profile fields
  Map<String, dynamic>? profile;
  bool loading = true;
  String? photoUrl;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String? uhid;
  
  // New demographic fields
  String? _selectedSex;
  DateTime? _dateOfBirth;
  int? _calculatedAge;
  
  // Sex options
  static const List<String> _sexOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  
  // Legacy controllers (for backward compatibility)
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController surgeriesController = TextEditingController();
  
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

  /// Calculate age from date of birth
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _fetch() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);
      final doc = await docRef.get();
      if (!mounted) return;
      final Map<String, dynamic> data = doc.data() ?? {};
      // Patient required fields - expanded
      final Map<String, Object> requiredFields = {
        'name': '',
        'uhid': '',
        'sex': '',
        'dateOfBirth': '',
        'address': '',
        'comorbidities': <dynamic>[],
        'allergies': <dynamic>[],
        'surgeries': <dynamic>[],
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
        addressController.text = profile?['address'] as String? ?? '';
        photoUrl = profile?['photoUrl'] as String?;
        uhid = profile?['uhid'] as String?;
        
        // Load sex
        _selectedSex = profile?['sex'] as String?;
        if (_selectedSex != null && _selectedSex!.isEmpty) {
          _selectedSex = null;
        }
        
        // Load date of birth
        final dobString = profile?['dateOfBirth'] as String?;
        if (dobString != null && dobString.isNotEmpty) {
          try {
            _dateOfBirth = DateTime.parse(dobString);
            _calculatedAge = _calculateAge(_dateOfBirth!);
          } catch (_) {
            _dateOfBirth = null;
          }
        }
        
        // Load comorbidities
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
        
        // Load allergies (support both old string and new list format)
        final allergiesData = profile?['allergies'];
        if (allergiesData is List) {
          _allergiesList = allergiesData.map<Map<String, String>>((item) {
            if (item is Map) {
              return {
                'name': item['name'] as String? ?? '',
                'duration': item['duration'] as String? ?? '',
              };
            }
            return {'name': item.toString(), 'duration': ''};
          }).toList();
        } else if (allergiesData is String && allergiesData.isNotEmpty) {
          // Convert old string format to new list format
          _allergiesList = allergiesData.split(',').map((a) => 
            {'name': a.trim(), 'duration': ''},).toList();
        }
        
        // Load surgeries (support both old string and new list format)
        final surgeriesData = profile?['surgeries'];
        if (surgeriesData is List) {
          _surgeriesList = surgeriesData.map<Map<String, String>>((item) {
            if (item is Map) {
              return {
                'name': item['name'] as String? ?? '',
                'year': item['year'] as String? ?? '',
              };
            }
            return {'name': item.toString(), 'year': ''};
          }).toList();
        } else if (surgeriesData is String && surgeriesData.isNotEmpty) {
          // Convert old string format to new list format
          _surgeriesList = surgeriesData.split(',').map((s) => 
            {'name': s.trim(), 'year': ''},).toList();
        }
        
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        profile = {};
        nameController.text = '';
        contactController.text = '';
        aboutController.text = '';
        addressController.text = '';
        photoUrl = null;
        uhid = '';
        _selectedSex = null;
        _dateOfBirth = null;
        _calculatedAge = null;
        _comorbiditiesList = [];
        _allergiesList = [];
        _surgeriesList = [];
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
                        
                        // --- Personal Information Section ---
                        const Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.indigo,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28, thickness: 1.2),
                        
                        // Name Field
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Sex and DOB Row
                        Row(
                          children: [
                            // Sex Dropdown
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedSex,
                                decoration: const InputDecoration(
                                  labelText: 'Sex',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.wc),
                                ),
                                items: _sexOptions.map((sex) {
                                  return DropdownMenuItem(
                                    value: sex,
                                    child: Text(sex),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSex = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Date of Birth
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _dateOfBirth ?? DateTime(2000),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    helpText: 'Select Date of Birth',
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _dateOfBirth = picked;
                                      _calculatedAge = _calculateAge(picked);
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date of Birth',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.cake),
                                  ),
                                  child: Text(
                                    _dateOfBirth != null
                                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                        : 'Select DOB',
                                    style: TextStyle(
                                      color: _dateOfBirth == null
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Age Display
                        if (_calculatedAge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.hourglass_bottom,
                                  color: Colors.indigo,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Age: $_calculatedAge years',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        
                        // Contact Field
                        TextFormField(
                          controller: contactController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        
                        // Address Field
                        TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                            helperText: 'Full address including city, state, PIN',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        
                        // About Field
                        TextFormField(
                          controller: aboutController,
                          decoration: const InputDecoration(
                            labelText: 'About / Notes',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          maxLines: 2,
                        ),
                        
                        const SizedBox(height: 32),
                        
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
                        
                        // --- Pre-existing Diseases (Comorbidities) ---
                        const Row(
                          children: [
                            Icon(
                              Icons.coronavirus,
                              color: Colors.teal,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pre-existing Diseases',
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
                                  labelText: 'Disease Name',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g. Hypertension, Diabetes',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: comorbidityDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Duration',
                                  border: OutlineInputBorder(),
                                  helperText: 'Years',
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Add disease',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.teal,
                                  size: 32,
                                ),
                                onPressed: () {
                                  final name = comorbidityNameController.text.trim();
                                  final duration = comorbidityDurationController.text.trim();
                                  if (name.isNotEmpty) {
                                    setState(() {
                                      _comorbiditiesList.add({
                                        'name': name,
                                        'duration': duration.isEmpty ? '0' : duration,
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
                        if (_comorbiditiesList.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildListWithDuration(
                            _comorbiditiesList,
                            'disease',
                            Colors.teal,
                            (idx) => setState(() => _comorbiditiesList.removeAt(idx)),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // --- Allergies with Duration ---
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
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: allergyNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Allergy',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g. Penicillin, Peanuts',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: allergyDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Duration',
                                  border: OutlineInputBorder(),
                                  helperText: 'Years',
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Add allergy',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.orange,
                                  size: 32,
                                ),
                                onPressed: () {
                                  final name = allergyNameController.text.trim();
                                  final duration = allergyDurationController.text.trim();
                                  if (name.isNotEmpty) {
                                    setState(() {
                                      _allergiesList.add({
                                        'name': name,
                                        'duration': duration.isEmpty ? '0' : duration,
                                      });
                                      allergyNameController.clear();
                                      allergyDurationController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_allergiesList.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildListWithDuration(
                            _allergiesList,
                            'allergy',
                            Colors.orange,
                            (idx) => setState(() => _allergiesList.removeAt(idx)),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // --- Surgeries with Year ---
                        const Row(
                          children: [
                            Icon(
                              Icons.healing,
                              color: Colors.purple,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Surgeries / Procedures',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: surgeryNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Surgery/Procedure',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g. Appendectomy, CABG',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: surgeryYearController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Year',
                                  border: OutlineInputBorder(),
                                  helperText: 'e.g. 2020',
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Add surgery',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.purple,
                                  size: 32,
                                ),
                                onPressed: () {
                                  final name = surgeryNameController.text.trim();
                                  final year = surgeryYearController.text.trim();
                                  if (name.isNotEmpty) {
                                    setState(() {
                                      _surgeriesList.add({
                                        'name': name,
                                        'year': year,
                                      });
                                      surgeryNameController.clear();
                                      surgeryYearController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_surgeriesList.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildSurgeriesList(),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // --- Save Button ---
                        const Divider(height: 32, thickness: 1),
                        Tooltip(
                          message: 'Save all profile information',
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
                              'Save Profile',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _saveProfile,
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

  /// Builds a list widget for items with duration (diseases, allergies)
  Widget _buildListWithDuration(
    List<Map<String, String>> items,
    String itemType,
    Color color,
    void Function(int) onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < items.length - 1 ? 8 : 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      itemType == 'disease' ? Icons.coronavirus : Icons.warning_amber,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i]['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Duration: ${items[i]['duration']} years',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                    onPressed: () => onRemove(i),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the surgeries list with year
  Widget _buildSurgeriesList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _surgeriesList.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < _surgeriesList.length - 1 ? 8 : 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.healing,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _surgeriesList[i]['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (_surgeriesList[i]['year']?.isNotEmpty ?? false)
                          Text(
                            'Year: ${_surgeriesList[i]['year']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                    onPressed: () => setState(() => _surgeriesList.removeAt(i)),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Saves the complete patient profile
  Future<void> _saveProfile() async {
    final messenger = ScaffoldMessenger.of(context);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);

    final data = {
      'name': nameController.text.trim(),
      'displayName': nameController.text.trim(),
      'sex': _selectedSex ?? '',
      'dateOfBirth': _dateOfBirth?.toIso8601String() ?? '',
      'age': _calculatedAge,
      'contact': contactController.text.trim(),
      'address': addressController.text.trim(),
      'about': aboutController.text.trim(),
      'photoUrl': photoUrl ?? '',
      'role': 'patient',
      'comorbidities': _comorbiditiesList,
      'allergies': _allergiesList,
      'surgeries': _surgeriesList,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await docRef.set(data, SetOptions(merge: true));
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

