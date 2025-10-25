import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  // Mock price comparison data for demo
  Future<List<Map<String, dynamic>>> fetchPharmacyPrices(String drug) async {
    // In production, call real APIs for each pharmacy
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'pharmacy': '1mg',
        'price': 120,
        'url': 'https://www.1mg.com/search/all?name=$drug',
      },
      {
        'pharmacy': 'Netmeds',
        'price': 125,
        'url': 'https://www.netmeds.com/catalogsearch/result?q=$drug',
      },
      {
        'pharmacy': 'PharmEasy',
        'price': 118,
        'url': 'https://pharmeasy.in/search/all?name=$drug',
      },
    ];
  }

  void _showPharmacyComparison(BuildContext context, String drug) async {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPharmacyPrices(drug),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final prices = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Buy "$drug" Online',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ...prices.map(
                (p) => ListTile(
                  leading: const Icon(Icons.local_pharmacy, color: Colors.teal),
                  title: Text('${p['pharmacy']}'),
                  subtitle: Text('₹${p['price']} (approximate)'),
                  trailing: ElevatedButton(
                    child: const Text('Buy'),
                    onPressed: () async {
                      final url = Uri.parse(p['url']);
                      try {
                        final can = await canLaunchUrl(url);
                        if (!can) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Could not open $url')),
                          );
                          return;
                        }
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Launch failed: $e')),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadPrescriptionPdf(String patientName) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'E-Prescription',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Patient: $patientName'),
          pw.SizedBox(height: 8),
          pw.Text('Date: ${DateTime.now().toString().substring(0, 16)}'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Medications:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children:
                    [
                          'Type',
                          'Drug',
                          'Dose',
                          'Route',
                          'Freq',
                          'Food',
                          'Instructions',
                          'Duration',
                        ]
                        .map(
                          (header) => pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              header,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              ...prescriptions.map(
                (item) => pw.TableRow(
                  children:
                      [
                            item['type'] ?? '',
                            '${item['generic'] ?? ''} - ${item['brand'] ?? ''}',
                            item['dose'] ?? '',
                            item['route'] ?? '',
                            item['freq'] ?? '',
                            item['food'] ?? '',
                            item['instructions'] ?? '',
                            item['duration'] ?? '',
                          ]
                          .map(
                            (cell) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(cell.toString()),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          if (doctorNotes.isNotEmpty) ...[
            pw.Text(
              'Doctor Notes:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...doctorNotes.map((n) => pw.Bullet(text: n['note'] ?? '')),
          ],
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  List<Map<String, dynamic>> doctorNotes = [];
  List<Map<String, dynamic>> attachments = [];
  final TextEditingController doctorNoteController = TextEditingController();

  @override
  void dispose() {
    doctorNoteController.dispose();
    super.dispose();
  }

  Future<void> saveDoctorNote(String patientId, String note) async {
    doctorNotes.add({'note': note, 'date': DateTime.now().toIso8601String()});
    await FirebaseFirestore.instance
        .collection('prescriptions')
        .doc(patientId)
        .set({'doctorNotes': doctorNotes}, SetOptions(merge: true));
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadDoctorNotes(String patientId) async {
    final doc = await FirebaseFirestore.instance
        .collection('prescriptions')
        .doc(patientId)
        .get();
    if (!mounted) return;
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!['doctorNotes'] != null) {
      setState(() {
        doctorNotes = List<Map<String, dynamic>>.from(
          doc.data()!['doctorNotes'],
        );
      });
    }
  }

  Future<void> uploadAttachment(String patientId) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      attachments.add({
        'name': file.name,
        'path': file.path,
        'date': DateTime.now().toIso8601String(),
      });
      await FirebaseFirestore.instance
          .collection('prescriptions')
          .doc(patientId)
          .set({'attachments': attachments}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> loadAttachments(String patientId) async {
    final doc = await FirebaseFirestore.instance
        .collection('prescriptions')
        .doc(patientId)
        .get();
    if (!mounted) return;
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!['attachments'] != null) {
      setState(() {
        attachments = List<Map<String, dynamic>>.from(
          doc.data()!['attachments'],
        );
      });
    }
  }

  Color? getSmartAlertColor(Map<String, String> item) {
    // Example: alert for high dose or risky combinations
    if (item['dose'] != null && double.tryParse(item['dose']!) != null) {
      final dose = double.parse(item['dose']!);
      if (dose > 2000) return Colors.red[100]; // Arbitrary high dose
    }
    return null;
  }

  final List<Map<String, String>> prescriptions = [];
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  final TextEditingController freqController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  String selectedDrugType = 'Tablet';
  String selectedFoodRelation = 'After Food';

  final List<String> drugTypes = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Lotion',
    'Cream',
    'Ointment',
    'Powder',
    'Drops',
    'Spray',
    'Gel',
    'Patch',
    'Suppository',
    'Other',
  ];
  final List<String> foodRelations = [
    'After Food',
    'Before Food',
    'In Empty Stomach',
    '1 hr Before Food',
    '2 hrs After Food',
    'Along with First Bite of Meal',
  ];

  // Indian diabetic drug database (expand as needed)
  final List<Map<String, dynamic>> drugDatabase = [
    {
      'generic': 'METFORMIN',
      'brands': [
        'Glyciphage',
        'Glucophage',
        'Obimet',
        'Bigomet',
        'Cetapin',
        'Xmet',
      ],
      'interactions': ['GLIBENCLAMIDE', 'PIOGLITAZONE'],
    },
    {
      'generic': 'GLIMEPIRIDE',
      'brands': ['Amaryl', 'Glimy', 'Glypride', 'Glimestar', 'Glyree'],
      'interactions': ['INSULIN', 'GLIPIZIDE'],
    },
    {
      'generic': 'GLIPIZIDE',
      'brands': ['Glynase', 'Minidiab', 'Glizid', 'Glytop'],
      'interactions': ['INSULIN', 'GLIMEPIRIDE'],
    },
    {
      'generic': 'GLIBENCLAMIDE',
      'brands': ['Daonil', 'Euglucon', 'Glyburide'],
      'interactions': ['METFORMIN'],
    },
    {
      'generic': 'GLIPIZIDE+METFORMIN',
      'brands': ['Glizid-M', 'Glynase-MF', 'Glytop-M'],
      'interactions': ['INSULIN'],
    },
    {
      'generic': 'PIOGLITAZONE',
      'brands': ['Pioglit', 'Pioz', 'Glizone'],
      'interactions': ['INSULIN', 'METFORMIN'],
    },
    {
      'generic': 'SITAGLIPTIN',
      'brands': ['Januvia', 'Istavel', 'Zita'],
      'interactions': [],
    },
    {
      'generic': 'VILDAGLIPTIN',
      'brands': ['Galvus', 'Vysov'],
      'interactions': [],
    },
    {
      'generic': 'TENELIGLIPTIN',
      'brands': ['Teneligliptin', 'Teneza', 'Tenglyn'],
      'interactions': [],
    },
    {
      'generic': 'DAPAGLIFLOZIN',
      'brands': ['Forxiga', 'Dapafloz', 'Dapaglyn'],
      'interactions': [],
    },
    {
      'generic': 'EMPAGLIFLOZIN',
      'brands': ['Jardiance', 'Empaone', 'Glyxambi'],
      'interactions': [],
    },
    {
      'generic': 'INSULIN',
      'brands': [
        'Huminsulin',
        'Novolin',
        'Wosulin',
        'Actrapid',
        'Mixtard',
        'Lantus',
        'Tresiba',
        'Humalog',
        'Novorapid',
      ],
      'interactions': [
        'GLIMEPIRIDE',
        'GLIPIZIDE',
        'PIOGLITAZONE',
        'GLIPIZIDE+METFORMIN',
      ],
    },
    {
      'generic': 'GLARGINE',
      'brands': ['Lantus', 'Basalog', 'Glaritus'],
      'interactions': [],
    },
    {
      'generic': 'DEGLUDEC',
      'brands': ['Tresiba'],
      'interactions': [],
    },
    {
      'generic': 'LIRAGLUTIDE',
      'brands': ['Victoza', 'Lira'],
      'interactions': [],
    },
    {
      'generic': 'GLUCAGON',
      'brands': ['Glucagen', 'Glucagon'],
      'interactions': [],
    },
    // Add more as needed
  ];

  // Returns a list of drugs matching the query
  List<Map<String, dynamic>> searchDrugs(String query) {
    return drugDatabase
        .where(
          (drug) =>
              drug['generic'].contains(query.toUpperCase()) ||
              drug['brands'].any(
                (b) => b.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .toList();
  }

  // Checks for interactions among selected drugs
  List<String> checkInteractions() {
    List<String> warnings = [];
    final selectedGenerics = prescriptions
        .map((p) => p['generic'] ?? '')
        .toSet();
    for (final drug in drugDatabase) {
      if (selectedGenerics.contains(drug['generic'])) {
        for (final interact in drug['interactions']) {
          if (selectedGenerics.contains(interact)) {
            warnings.add('Interaction: ${drug['generic']} ↔ $interact');
          }
        }
      }
    }
    return warnings;
  }

  void addPrescription(Map<String, dynamic> drug) {
    if (drug['generic'] != null && doseController.text.isNotEmpty) {
      setState(() {
        prescriptions.add({
          'type': selectedDrugType,
          'generic': drug['generic'],
          'brand': drug['brands'].isNotEmpty ? drug['brands'][0] : '',
          'dose': doseController.text,
          'route': routeController.text,
          'freq': freqController.text,
          'food': selectedFoodRelation,
          'instructions': instructionsController.text,
          'duration': durationController.text,
        });
        medicineController.clear();
        doseController.clear();
        freqController.clear();
        routeController.clear();
        instructionsController.clear();
        durationController.clear();
        selectedDrugType = 'Tablet';
        selectedFoodRelation = 'After Food';
      });
    }
  }

  // Firestore integration
  Future<void> savePrescriptionToFirestore(String patientId) async {
    await FirebaseFirestore.instance
        .collection('prescriptions')
        .doc(patientId)
        .set({'items': prescriptions});
  }

  Future<void> loadPrescriptionFromFirestore(String patientId) async {
    final doc = await FirebaseFirestore.instance
        .collection('prescriptions')
        .doc(patientId)
        .get();
    if (!mounted) return;
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      setState(() {
        prescriptions.clear();
        prescriptions.addAll(items.map((e) => Map<String, String>.from(e)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool viewOnly = args?['viewOnly'] ?? false;
    final patient = args?['patient'];
    final patientId = patient?.id;
    final user = FirebaseAuth.instance.currentUser;
    final doctorId = user?.uid;

    // Toggle for general prescription
    bool isGeneral = args?['general'] == true;
    String? generalDocId = doctorId != null ? '${doctorId}_general' : null;

    // Load prescription on open
    if (prescriptions.isEmpty) {
      if (isGeneral && generalDocId != null) {
        loadPrescriptionFromFirestore(generalDocId);
        loadDoctorNotes(generalDocId);
        loadAttachments(generalDocId);
      } else if (patientId != null) {
        loadPrescriptionFromFirestore(patientId);
        loadDoctorNotes(patientId);
        loadAttachments(patientId);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Prescription'),
        actions: [
          if (!viewOnly)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: () async {
                final docId = isGeneral && generalDocId != null
                    ? generalDocId
                    : patientId;
                if (docId != null) {
                  final messenger = ScaffoldMessenger.of(context);
                  await savePrescriptionToFirestore(docId);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Prescription saved to cloud!'),
                    ),
                  );
                }
              },
            ),
          if (!viewOnly && patient != null)
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print',
              onPressed: () async {
                await _downloadPrescriptionPdf(patient.name ?? 'Patient');
              },
            ),
          if (viewOnly && prescriptions.isNotEmpty && patient != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download PDF',
              onPressed: () async {
                await _downloadPrescriptionPdf(patient.name ?? 'Patient');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!viewOnly) ...[
                  Row(
                    children: [
                      const Text(
                        'Prescription Type: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      StatefulBuilder(
                        builder: (context, setStateSB) => SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Patient'),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('General'),
                            ),
                          ],
                          selected: {isGeneral},
                          onSelectionChanged: (Set<bool> selection) {
                            final newValue = selection.first;
                            if (!newValue && patientId != null) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/prescription',
                                arguments: {
                                  'patient': patient,
                                  'viewOnly': false,
                                },
                              );
                            } else if (newValue && generalDocId != null) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/prescription',
                                arguments: {'general': true, 'viewOnly': false},
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Diabetic Drug',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DropdownButton<String>(
                        value: selectedDrugType,
                        items: drugTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedDrugType = v ?? 'Tablet'),
                      ),
                      SizedBox(
                        width: 220,
                        child: TypeAheadField<Map<String, dynamic>>(
                          suggestionsCallback: (pattern) =>
                              searchDrugs(pattern),
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(
                                suggestion['generic'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Brands: ${(suggestion['brands'] as List).join(', ')}',
                              ),
                            );
                          },
                          onSelected: (suggestion) {
                            setState(() {
                              medicineController.text = suggestion['generic'];
                            });
                            addPrescription(suggestion);
                          },
                          controller: medicineController,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Search Drug (Generic/Brand)',
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: doseController,
                          decoration: const InputDecoration(labelText: 'Dose'),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: routeController,
                          decoration: const InputDecoration(labelText: 'Route'),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: freqController,
                          decoration: const InputDecoration(
                            labelText: 'Frequency',
                          ),
                        ),
                      ),
                      DropdownButton<String>(
                        value: selectedFoodRelation,
                        items: foodRelations
                            .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)),
                            )
                            .toList(),
                        onChanged: (v) => setState(
                          () => selectedFoodRelation = v ?? 'After Food',
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: instructionsController,
                          decoration: const InputDecoration(
                            labelText: 'Instructions',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final warnings = checkInteractions();
                      if (warnings.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: warnings
                              .map(
                                (w) => Text(
                                  w,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Prescription Table',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Drug Name')),
                      DataColumn(label: Text('Dose')),
                      DataColumn(label: Text('Route')),
                      DataColumn(label: Text('Frequency')),
                      DataColumn(label: Text('Food Relation')),
                      DataColumn(label: Text('Instructions')),
                      DataColumn(label: Text('Duration')),
                      DataColumn(label: Text('Buy')), // New column
                    ],
                    rows: prescriptions
                        .map(
                          (item) => DataRow(
                            color: getSmartAlertColor(item) != null
                                ? WidgetStateProperty.all(
                                    getSmartAlertColor(item),
                                  )
                                : null,
                            cells: [
                              DataCell(Text(item['type'] ?? '')),
                              DataCell(
                                Text(
                                  '${item['generic'] ?? ''} - ${item['brand'] ?? ''}',
                                ),
                              ),
                              DataCell(Text(item['dose'] ?? '')),
                              DataCell(Text(item['route'] ?? '')),
                              DataCell(Text(item['freq'] ?? '')),
                              DataCell(Text(item['food'] ?? '')),
                              DataCell(Text(item['instructions'] ?? '')),
                              DataCell(Text(item['duration'] ?? '')),
                              DataCell(
                                viewOnly
                                    ? ElevatedButton.icon(
                                        icon: const Icon(Icons.shopping_cart),
                                        label: const Text('Buy'),
                                        onPressed: () =>
                                            _showPharmacyComparison(
                                              context,
                                              item['generic'] ?? '',
                                            ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                // Doctor Notes Section
                const Text(
                  'Doctor Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!viewOnly && patientId != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: doctorNoteController,
                          decoration: const InputDecoration(
                            labelText: 'Add a note',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          if (doctorNoteController.text.trim().isNotEmpty) {
                            await saveDoctorNote(
                              patientId,
                              doctorNoteController.text.trim(),
                            );
                            doctorNoteController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
                ...doctorNotes.reversed.map(
                  (note) => ListTile(
                    leading: const Icon(Icons.note),
                    title: Text(note['note'] ?? ''),
                    subtitle: Text(
                      note['date'] != null
                          ? note['date'].toString().substring(0, 16)
                          : '',
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                // Attachments Section
                const Text(
                  'Attachments',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!viewOnly && patientId != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Upload Attachment'),
                    onPressed: () async {
                      await uploadAttachment(patientId);
                    },
                  ),
                ...attachments.reversed.map(
                  (att) => ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(att['name'] ?? ''),
                    subtitle: Text(
                      att['date'] != null
                          ? att['date'].toString().substring(0, 16)
                          : '',
                    ),
                    trailing: att['path'] != null
                        ? IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () {
                              // For demo: open file locally if possible
                              // In production: open/download from Firebase Storage
                              // You can use url_launcher or similar
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ), // <-- closes Column
          ), // <-- closes SingleChildScrollView
        ), // <-- closes Padding
      ), // <-- closes SafeArea
    ); // <-- closes Scaffold
  }
}
