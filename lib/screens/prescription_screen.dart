import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';
import '../services/drug_interaction_service.dart';
import '../widgets/drug_adr_card.dart';
import '../widgets/drug_interaction_dialog.dart';
import '../widgets/quick_prescription_widgets.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  // Mock price comparison data for demo
  Future<List<Map<String, dynamic>>> fetchPharmacyPrices(String drug) async {
    // In production, call real APIs for each pharmacy
    await Future<void>.delayed(const Duration(milliseconds: 500));
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

  Future<void> _showPharmacyComparison(BuildContext context, String drug) async {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
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
                      final url = Uri.parse(p['url'] as String);
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
                              child: pw.Text(cell),
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
            ...doctorNotes.map((n) => pw.Bullet(text: n['note'] as String? ?? '')),
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
          doc.data()!['doctorNotes'] as List? ?? [],
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
          doc.data()!['attachments'] as List? ?? [],
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
  Map<String, dynamic>? _selectedDrug;
  bool _showQuickTemplates = true;

  // Comprehensive drug interaction service
  final DrugInteractionService _interactionService = DrugInteractionService();
  DrugInteractionReport? _interactionReport;
  bool _isCheckingInteractions = false;

  /// Check interactions using comprehensive API service
  Future<void> _checkComprehensiveInteractions() async {
    if (prescriptions.isEmpty) {
      setState(() {
        _interactionReport = null;
      });
      return;
    }

    final drugNames = prescriptions
        .map((p) => p['generic'] ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    if (drugNames.length < 2) {
      setState(() {
        _interactionReport = null;
      });
      return;
    }

    setState(() {
      _isCheckingInteractions = true;
    });

    try {
      final report = await _interactionService.checkInteractionsForPrescription(drugNames);
      if (mounted) {
        setState(() {
          _interactionReport = report;
          _isCheckingInteractions = false;
        });
      }
    } catch (e) {
      debugPrint('Interaction check error: $e');
      if (mounted) {
        setState(() {
          _isCheckingInteractions = false;
        });
      }
    }
  }

  /// Show detailed interaction report dialog
  Future<bool> _showInteractionReportDialog() async {
    if (_interactionReport == null || !_interactionReport!.hasInteractions) {
      return true;
    }
    return showDrugInteractionDialog(context, _interactionReport!);
  }

  /// Build the comprehensive drug interaction display widget
  Widget _buildInteractionWidget() {
    // Show local (fast) interactions first
    final localWarnings = checkInteractions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick local check results
        if (localWarnings.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Check (Local)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...localWarnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            w,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Comprehensive API check results
        if (_isCheckingInteractions)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Checking RxNav + OpenFDA + DrugBank for interactions...',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          )
        else if (_interactionReport != null && _interactionReport!.hasInteractions)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _interactionReport!.hasSevereInteractions
                  ? Colors.red.shade50
                  : _interactionReport!.hasHighInteractions
                      ? Colors.orange.shade50
                      : Colors.amber.shade50,
              border: Border.all(
                color: _interactionReport!.hasSevereInteractions
                    ? Colors.red
                    : _interactionReport!.hasHighInteractions
                        ? Colors.deepOrange
                        : Colors.amber,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _interactionReport!.hasSevereInteractions
                          ? Icons.dangerous
                          : Icons.warning_amber,
                      color: _interactionReport!.hasSevereInteractions
                          ? Colors.red
                          : Colors.deepOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Comprehensive Interaction Report',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _interactionReport!.hasSevereInteractions
                              ? Colors.red.shade700
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showInteractionReportDialog,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View Details'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Summary chips
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (_interactionReport!.severeCount > 0)
                      _buildSeverityChip(
                        'Severe: ${_interactionReport!.severeCount}',
                        Colors.red,
                      ),
                    if (_interactionReport!.highCount > 0)
                      _buildSeverityChip(
                        'High: ${_interactionReport!.highCount}',
                        Colors.deepOrange,
                      ),
                    if (_interactionReport!.moderateCount > 0)
                      _buildSeverityChip(
                        'Moderate: ${_interactionReport!.moderateCount}',
                        Colors.amber.shade700,
                      ),
                    if (_interactionReport!.lowCount > 0)
                      _buildSeverityChip(
                        'Low: ${_interactionReport!.lowCount}',
                        Colors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sources: ${_interactionReport!.sources.join(', ')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else if (prescriptions.length >= 2)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'No significant drug interactions detected',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                TextButton(
                  onPressed: _checkComprehensiveInteractions,
                  child: const Text('Re-check'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSeverityChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Build ADR summary section for all prescribed drugs
  /// [showContraindications] - Only true for healthcare professionals
  Widget _buildADRSummarySection({bool showContraindications = true}) {
    final drugNames = prescriptions
        .map((p) => p['generic'] ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (drugNames.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.health_and_safety, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              showContraindications
                  ? 'Adverse Drug Reactions & Contraindications'
                  : 'Drug Side Effects & Allergy Alerts',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                // Show all ADRs in a modal
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (ctx) => DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (ctx, scrollController) => Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.health_and_safety, color: Colors.purple),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  showContraindications
                                      ? 'Complete ADR Profile'
                                      : 'Drug Safety Information',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: drugNames.length,
                            itemBuilder: (ctx, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DrugADRCard(
                                drugName: drugNames[index],
                                showFullDetails: true,
                                showContraindications: showContraindications,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Show compact ADR cards for each drug
        ...drugNames.map(
          (drug) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DrugADRCard(
              drugName: drug,
              showContraindications: showContraindications,
            ),
          ),
        ),
      ],
    );
  }

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
      'interactions': <String>[],
    },
    {
      'generic': 'VILDAGLIPTIN',
      'brands': ['Galvus', 'Vysov'],
      'interactions': <String>[],
    },
    {
      'generic': 'TENELIGLIPTIN',
      'brands': ['Teneligliptin', 'Teneza', 'Tenglyn'],
      'interactions': <String>[],
    },
    {
      'generic': 'DAPAGLIFLOZIN',
      'brands': ['Forxiga', 'Dapafloz', 'Dapaglyn'],
      'interactions': <String>[],
    },
    {
      'generic': 'EMPAGLIFLOZIN',
      'brands': ['Jardiance', 'Empaone', 'Glyxambi'],
      'interactions': <String>[],
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
      'interactions': <String>[],
    },
    {
      'generic': 'DEGLUDEC',
      'brands': ['Tresiba'],
      'interactions': <String>[],
    },
    {
      'generic': 'LIRAGLUTIDE',
      'brands': ['Victoza', 'Lira'],
      'interactions': <String>[],
    },
    {
      'generic': 'GLUCAGON',
      'brands': ['Glucagen', 'Glucagon'],
      'interactions': <String>[],
    },
    // Add more as needed
  ];

  // Returns a list of drugs matching the query
  List<Map<String, dynamic>> searchDrugs(String query) {
    return drugDatabase
        .where(
          (drug) =>
              (drug['generic'] as String? ?? '').contains(query.toUpperCase()) ||
              (drug['brands'] as List? ?? []).any(
                (b) => (b as String).toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .toList();
  }

  // Checks for interactions among selected drugs
  List<String> checkInteractions() {
    final List<String> warnings = [];
    final selectedGenerics = prescriptions
        .map((p) => p['generic'] ?? '')
        .toSet();
    for (final drug in drugDatabase) {
      if (selectedGenerics.contains(drug['generic'] as String? ?? '')) {
        for (final interact in (drug['interactions'] as List? ?? [])) {
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
          'generic': drug['generic'] as String? ?? '',
          'brand': (drug['brands'] as List?)?.isNotEmpty ?? false ? (drug['brands'] as List)[0] as String : '',
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
        _selectedDrug = null;
      });
      // Trigger comprehensive interaction check
      _checkComprehensiveInteractions();
    }
  }

  /// Add prescription from quick template
  void addFromTemplate(Map<String, String> template) {
    setState(() {
      prescriptions.add({
        'type': template['type'] ?? 'Tablet',
        'generic': template['generic'] ?? '',
        'brand': template['brand'] ?? '',
        'dose': template['dose'] ?? '',
        'route': template['route'] ?? 'Oral',
        'freq': template['freq'] ?? '',
        'food': template['food'] ?? 'After Food',
        'instructions': template['instructions'] ?? '',
        'duration': template['duration'] ?? '',
      });
    });
    // Trigger comprehensive interaction check
    _checkComprehensiveInteractions();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added: ${template['name']}'),
        duration: const Duration(seconds: 1),
      ),
    );
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
      final items = List<Map<String, dynamic>>.from(data['items'] as List? ?? []);
      setState(() {
        prescriptions.clear();
        prescriptions.addAll(items.map((e) => Map<String, String>.from(e as Map? ?? {})));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool viewOnly = args?['viewOnly'] as bool? ?? false;
    final patient = args?['patient'];
    final patientId = patient?.id;
    final user = FirebaseAuth.instance.currentUser;
    final doctorId = user?.uid;

    // Get user role for conditional display
    final userProvider = context.watch<UserProvider>();
    final isHealthcareProfessional = userProvider.isHealthcareProfessional;

    // Toggle for general prescription
    final bool isGeneral = args?['general'] == true;
    final String? generalDocId = doctorId != null ? '${doctorId}_general' : null;

    // Load prescription on open
    if (prescriptions.isEmpty) {
      if (isGeneral && generalDocId != null) {
        loadPrescriptionFromFirestore(generalDocId);
        loadDoctorNotes(generalDocId);
        loadAttachments(generalDocId);
      } else if (patientId != null) {
        loadPrescriptionFromFirestore(patientId as String);
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
                  await savePrescriptionToFirestore(docId as String);
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
                await _downloadPrescriptionPdf(patient.name as String? ?? 'Patient');
              },
            ),
          if (viewOnly && prescriptions.isNotEmpty && patient != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download PDF',
              onPressed: () async {
                await _downloadPrescriptionPdf(patient.name as String? ?? 'Patient');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  // Quick Templates Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '⚡ Quick Add (One-Click)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          _showQuickTemplates
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        label: Text(_showQuickTemplates ? 'Hide' : 'Show'),
                        onPressed: () {
                          setState(() {
                            _showQuickTemplates = !_showQuickTemplates;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showQuickTemplates) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: QuickPrescriptionData.quickTemplates.length,
                        itemBuilder: (context, index) {
                          final template =
                              QuickPrescriptionData.quickTemplates[index];
                          return SizedBox(
                            width: 180,
                            child: QuickTemplateCard(
                              template: template,
                              onTap: () => addFromTemplate(template),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Custom Drug',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Drug Type and Search
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
                        width: 250,
                        child: TypeAheadField<Map<String, dynamic>>(
                          suggestionsCallback: searchDrugs,
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(
                                suggestion['generic'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Brands: ${((suggestion['brands'] as List?) ?? []).join(', ')}',
                              ),
                            );
                          },
                          onSelected: (suggestion) {
                            setState(() {
                              _selectedDrug = suggestion;
                              medicineController.text =
                                  suggestion['generic'] as String;
                            });
                          },
                          controller: medicineController,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Search Drug (Generic/Brand)',
                                prefixIcon: Icon(Icons.search),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick Select Dose
                  QuickSelectChips(
                    label: '💊 Quick Dose',
                    options: QuickPrescriptionData.commonDoses.take(10).toList(),
                    selectedValue: doseController.text.isNotEmpty
                        ? doseController.text
                        : null,
                    onSelected: (value) {
                      setState(() {
                        doseController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: doseController,
                      decoration: const InputDecoration(
                        labelText: 'Dose (or type custom)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick Select Route
                  QuickSelectChips(
                    label: '💉 Quick Route',
                    options: QuickPrescriptionData.commonRoutes,
                    selectedValue: routeController.text.isNotEmpty
                        ? routeController.text
                        : null,
                    onSelected: (value) {
                      setState(() {
                        routeController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: routeController,
                      decoration: const InputDecoration(
                        labelText: 'Route (or type custom)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick Select Frequency
                  QuickSelectChips(
                    label: '⏰ Quick Frequency',
                    options: QuickPrescriptionData.commonFrequencies,
                    selectedValue: freqController.text.isNotEmpty
                        ? freqController.text
                        : null,
                    onSelected: (value) {
                      setState(() {
                        freqController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: freqController,
                      decoration: const InputDecoration(
                        labelText: 'Frequency (or type custom)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Food Relation
                  const Text(
                    '🍽️ Food Relation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: foodRelations.map((food) {
                      final isSelected = selectedFoodRelation == food;
                      return ActionChip(
                        label: Text(
                          food,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        onPressed: () {
                          setState(() {
                            selectedFoodRelation = food;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Quick Select Duration
                  QuickSelectChips(
                    label: '📅 Quick Duration',
                    options: QuickPrescriptionData.commonDurations,
                    selectedValue: durationController.text.isNotEmpty
                        ? durationController.text
                        : null,
                    onSelected: (value) {
                      setState(() {
                        durationController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (or type custom)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick Select Instructions
                  QuickSelectChips(
                    label: '📝 Quick Instructions',
                    options: QuickPrescriptionData.commonInstructions,
                    selectedValue: instructionsController.text.isNotEmpty
                        ? instructionsController.text
                        : null,
                    onSelected: (value) {
                      setState(() {
                        instructionsController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions (or type custom)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add Drug Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Prescription'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      if (_selectedDrug != null ||
                          medicineController.text.isNotEmpty) {
                        final drug = _selectedDrug ??
                            {
                              'generic': medicineController.text,
                              'brands': <String>[],
                            };
                        if (doseController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a dose'),
                            ),
                          );
                          return;
                        }
                        addPrescription(drug);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added: ${drug['generic']} ${doseController.text}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select or enter a drug'),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Comprehensive Drug Interaction Widget
                  // Only visible to healthcare professionals (doctors & pharmacists)
                  if (isHealthcareProfessional) _buildInteractionWidget(),
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
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: prescriptions
                        .asMap()
                        .entries
                        .map(
                          (entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return DataRow(
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ADR Info Button
                                    IconButton(
                                      icon: const Icon(Icons.health_and_safety, color: Colors.purple),
                                      tooltip: 'View Adverse Reactions',
                                      onPressed: () => showDrugADRDialog(
                                        context,
                                        item['generic'] ?? '',
                                      ),
                                    ),
                                    if (viewOnly)
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.shopping_cart, size: 16),
                                        label: const Text('Buy'),
                                        onPressed: () =>
                                            _showPharmacyComparison(
                                              context,
                                              item['generic'] ?? '',
                                            ),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Remove',
                                        onPressed: () {
                                          setState(() {
                                            prescriptions.removeAt(index);
                                          });
                                          // Re-check interactions after removal
                                          _checkComprehensiveInteractions();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Drug removed from prescription'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                          },
                        )
                        .toList(),
                  ),
                ),

                // ADR Summary Section - Visible to ALL users (doctors, pharmacists, patients)
                // Shows Adverse Drug Reactions and Allergy alerts for every drug
                if (prescriptions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildADRSummarySection(
                    showContraindications: isHealthcareProfessional,
                  ),
                ],

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
                              patientId as String,
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
                    title: Text(note['note'] as String? ?? ''),
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
                      await uploadAttachment(patientId as String);
                    },
                  ),
                ...attachments.reversed.map(
                  (att) => ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(att['name'] as String? ?? ''),
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



