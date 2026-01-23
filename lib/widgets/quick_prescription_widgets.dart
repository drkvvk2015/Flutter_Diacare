import 'package:flutter/material.dart';

/// Quick prescription data for common diabetic medications
class QuickPrescriptionData {
  // Common doses for quick selection
  static const List<String> commonDoses = [
    '250mg',
    '500mg',
    '850mg',
    '1000mg',
    '1g',
    '2mg',
    '5mg',
    '10mg',
    '15mg',
    '20mg',
    '25mg',
    '50mg',
    '100mg',
    '5ml',
    '10ml',
    '15ml',
    '1 unit',
    '2 units',
    '5 units',
    '10 units',
    '20 units',
  ];

  // Common frequencies
  static const List<String> commonFrequencies = [
    'OD (Once Daily)',
    'BD (Twice Daily)',
    'TDS (Thrice Daily)',
    'QID (4 times)',
    'HS (At Bedtime)',
    'SOS (When Required)',
    'Stat (Immediately)',
    'Weekly',
    'Alternate Days',
    'Before Breakfast',
    'Before Lunch',
    'Before Dinner',
  ];

  // Common routes
  static const List<String> commonRoutes = [
    'Oral',
    'Subcutaneous',
    'Intramuscular',
    'Intravenous',
    'Topical',
    'Sublingual',
    'Inhalation',
  ];

  // Common durations
  static const List<String> commonDurations = [
    '3 days',
    '5 days',
    '7 days',
    '10 days',
    '14 days',
    '1 month',
    '2 months',
    '3 months',
    '6 months',
    'Continuous',
    'As Directed',
  ];

  // Common instructions
  static const List<String> commonInstructions = [
    'Take with water',
    'Take with meals',
    'Avoid alcohol',
    'Store in cool place',
    'Shake well before use',
    'Monitor blood sugar',
    'Report if hypoglycemia',
    'Do not crush',
    'Swallow whole',
    'Keep away from sunlight',
  ];

  // Quick prescription templates (most common diabetic prescriptions)
  static const List<Map<String, String>> quickTemplates = [
    {
      'name': 'Metformin 500mg BD',
      'generic': 'METFORMIN',
      'brand': 'Glyciphage',
      'type': 'Tablet',
      'dose': '500mg',
      'route': 'Oral',
      'freq': 'BD (Twice Daily)',
      'food': 'After Food',
      'instructions': 'Take with meals',
      'duration': '1 month',
    },
    {
      'name': 'Metformin 850mg BD',
      'generic': 'METFORMIN',
      'brand': 'Glyciphage',
      'type': 'Tablet',
      'dose': '850mg',
      'route': 'Oral',
      'freq': 'BD (Twice Daily)',
      'food': 'After Food',
      'instructions': 'Take with meals',
      'duration': '1 month',
    },
    {
      'name': 'Metformin 1000mg BD',
      'generic': 'METFORMIN',
      'brand': 'Glyciphage',
      'type': 'Tablet',
      'dose': '1000mg',
      'route': 'Oral',
      'freq': 'BD (Twice Daily)',
      'food': 'After Food',
      'instructions': 'Take with meals',
      'duration': '1 month',
    },
    {
      'name': 'Glimepiride 1mg OD',
      'generic': 'GLIMEPIRIDE',
      'brand': 'Amaryl',
      'type': 'Tablet',
      'dose': '1mg',
      'route': 'Oral',
      'freq': 'OD (Once Daily)',
      'food': 'Before Food',
      'instructions': 'Take before breakfast',
      'duration': '1 month',
    },
    {
      'name': 'Glimepiride 2mg OD',
      'generic': 'GLIMEPIRIDE',
      'brand': 'Amaryl',
      'type': 'Tablet',
      'dose': '2mg',
      'route': 'Oral',
      'freq': 'OD (Once Daily)',
      'food': 'Before Food',
      'instructions': 'Take before breakfast',
      'duration': '1 month',
    },
    {
      'name': 'Sitagliptin 100mg OD',
      'generic': 'SITAGLIPTIN',
      'brand': 'Januvia',
      'type': 'Tablet',
      'dose': '100mg',
      'route': 'Oral',
      'freq': 'OD (Once Daily)',
      'food': 'After Food',
      'instructions': 'Take with water',
      'duration': '1 month',
    },
    {
      'name': 'Teneligliptin 20mg OD',
      'generic': 'TENELIGLIPTIN',
      'brand': 'Tenglyn',
      'type': 'Tablet',
      'dose': '20mg',
      'route': 'Oral',
      'freq': 'OD (Once Daily)',
      'food': 'After Food',
      'instructions': 'Take with water',
      'duration': '1 month',
    },
    {
      'name': 'Dapagliflozin 10mg OD',
      'generic': 'DAPAGLIFLOZIN',
      'brand': 'Forxiga',
      'type': 'Tablet',
      'dose': '10mg',
      'route': 'Oral',
      'freq': 'OD (Once Daily)',
      'food': 'After Food',
      'instructions': 'Take in morning',
      'duration': '1 month',
    },
    {
      'name': 'Empagliflozin 10mg OD',
      'generic': 'EMPAGLIFLOZIN',
      'brand': 'Jardiance',
      'type': 'Tablet',
      'dose': '10mg',
      'route': 'Oral',
      'freq': 'OD (Once Daily)',
      'food': 'After Food',
      'instructions': 'Take in morning',
      'duration': '1 month',
    },
    {
      'name': 'Insulin Glargine 10U HS',
      'generic': 'GLARGINE',
      'brand': 'Lantus',
      'type': 'Injection',
      'dose': '10 units',
      'route': 'Subcutaneous',
      'freq': 'HS (At Bedtime)',
      'food': 'Before Food',
      'instructions': 'Inject in abdomen/thigh',
      'duration': '1 month',
    },
    {
      'name': 'Vildagliptin 50mg BD',
      'generic': 'VILDAGLIPTIN',
      'brand': 'Galvus',
      'type': 'Tablet',
      'dose': '50mg',
      'route': 'Oral',
      'freq': 'BD (Twice Daily)',
      'food': 'After Food',
      'instructions': 'Take with meals',
      'duration': '1 month',
    },
    {
      'name': 'Pioglitazone 15mg OD',
      'generic': 'PIOGLITAZONE',
      'brand': 'Pioglit',
      'type': 'Tablet',
      'dose': '15mg',
      'route': 'Oral',
      'freq': 'OD (Once Daily)',
      'food': 'After Food',
      'instructions': 'Take with water',
      'duration': '1 month',
    },
  ];
}

/// Widget for quick selection chips
class QuickSelectChips extends StatelessWidget {
  const QuickSelectChips({
    required this.options,
    required this.onSelected,
    this.selectedValue,
    this.label,
    super.key,
  });

  final List<String> options;
  final void Function(String) onSelected;
  final String? selectedValue;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return ActionChip(
              label: Text(
                option,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              backgroundColor: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[200],
              onPressed: () => onSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Quick template card widget
class QuickTemplateCard extends StatelessWidget {
  const QuickTemplateCard({
    required this.template,
    required this.onTap,
    super.key,
  });

  final Map<String, String> template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template['name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${template['generic']} (${template['brand']})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.medication, size: 14, color: Colors.blue[400]),
                  const SizedBox(width: 4),
                  Text(
                    template['type'] ?? '',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.schedule, size: 14, color: Colors.green[400]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      template['freq'] ?? '',
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
