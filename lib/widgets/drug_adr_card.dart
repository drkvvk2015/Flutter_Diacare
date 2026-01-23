import 'package:flutter/material.dart';

import '../services/adverse_drug_reaction_service.dart';

/// Widget to display adverse drug reaction information for a single drug
/// 
/// Role-based visibility:
/// - [showContraindications]: Only visible to healthcare professionals (doctors/pharmacists)
/// - ADRs and Allergy warnings: Visible to all users including patients
class DrugADRCard extends StatefulWidget {
  const DrugADRCard({
    required this.drugName,
    this.patientConditions,
    this.showFullDetails = false,
    this.showContraindications = true,
    this.onTap,
    super.key,
  });

  final String drugName;
  final PatientConditions? patientConditions;
  final bool showFullDetails;
  /// Whether to show contraindications (only for healthcare professionals)
  final bool showContraindications;
  final VoidCallback? onTap;

  @override
  State<DrugADRCard> createState() => _DrugADRCardState();
}

class _DrugADRCardState extends State<DrugADRCard> {
  final AdverseDrugReactionService _adrService = AdverseDrugReactionService();
  DrugAdverseReactionInfo? _adrInfo;
  List<PatientSpecificWarning> _patientWarnings = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadADRInfo();
  }

  @override
  void didUpdateWidget(DrugADRCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drugName != widget.drugName) {
      _loadADRInfo();
    }
  }

  Future<void> _loadADRInfo() async {
    setState(() => _isLoading = true);

    try {
      final info = await _adrService.getAdverseReactions(widget.drugName);

      List<PatientSpecificWarning> patientWarnings = [];
      if (widget.patientConditions != null) {
        patientWarnings = _adrService.checkPatientContraindications(
          drugName: widget.drugName,
          conditions: widget.patientConditions!,
        );
      }

      if (mounted) {
        setState(() {
          _adrInfo = info;
          _patientWarnings = patientWarnings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('Loading ADR info for ${widget.drugName}...'),
            ],
          ),
        ),
      );
    }

    if (_adrInfo == null) {
      return const SizedBox.shrink();
    }

    final hasWarnings = _adrInfo!.hasBlackBoxWarning ||
        _patientWarnings.isNotEmpty ||
        _adrInfo!.commonAdverseReactions.any((r) => r.isSerious);

    return Card(
      elevation: hasWarnings ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _adrInfo!.hasBlackBoxWarning
              ? Colors.black
              : _patientWarnings.any(
                      (w) => w.severity == WarningSeverity.contraindicated,
                    )
                  ? Colors.red
                  : hasWarnings
                      ? Colors.orange
                      : Colors.grey.shade300,
          width: _adrInfo!.hasBlackBoxWarning ? 3 : 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap ??
            () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _adrInfo!.hasBlackBoxWarning
                        ? Icons.warning
                        : Icons.medication,
                    color: _adrInfo!.hasBlackBoxWarning
                        ? Colors.black
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.drugName.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasWarnings)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _adrInfo!.hasBlackBoxWarning
                            ? Colors.black
                            : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _adrInfo!.hasBlackBoxWarning
                            ? 'BLACK BOX'
                            : 'WARNINGS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),

              // Black Box Warning (always visible if present)
              if (_adrInfo!.hasBlackBoxWarning) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'BLACK BOX WARNING',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _adrInfo!.blackBoxWarning!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Patient-specific warnings (always visible if present)
              if (_patientWarnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._patientWarnings.map(
                  (warning) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(warning.severity.colorValue)
                          .withValues(alpha: 0.1),
                      border: Border.all(
                        color: Color(warning.severity.colorValue),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              warning.severity == WarningSeverity.contraindicated
                                  ? Icons.block
                                  : Icons.warning_amber,
                              color: Color(warning.severity.colorValue),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                warning.message,
                                style: TextStyle(
                                  color: Color(warning.severity.colorValue),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (warning.recommendation != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '→ ${warning.recommendation}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Expandable details
              if (_isExpanded || widget.showFullDetails) ...[
                const SizedBox(height: 12),
                const Divider(),

                // Contraindications - Only for healthcare professionals
                if (widget.showContraindications &&
                    _adrInfo!.parsedContraindications.isNotEmpty) ...[
                  _buildSection(
                    'Contraindications',
                    Icons.block,
                    Colors.red,
                    _adrInfo!.parsedContraindications
                        .map((c) => '• $c')
                        .join('\n'),
                  ),
                ],

                // Common Adverse Reactions - Visible to ALL users
                if (_adrInfo!.commonAdverseReactions.isNotEmpty) ...[
                  _buildADRSection(),
                ],

                // Special Warnings - Only for healthcare professionals
                if (widget.showContraindications &&
                    _adrInfo!.specialWarnings.isNotEmpty) ...[
                  _buildSection(
                    'Special Warnings',
                    Icons.warning_amber,
                    Colors.orange,
                    _adrInfo!.specialWarnings.map((w) => '• $w').join('\n'),
                  ),
                ],

                // Monitoring Requirements - Visible to ALL users (patients should know what to monitor)
                if (_adrInfo!.monitoringRequirements.isNotEmpty) ...[
                  _buildSection(
                    'Monitoring Required',
                    Icons.monitor_heart,
                    Colors.blue,
                    _adrInfo!.monitoringRequirements
                        .map((m) => '• $m')
                        .join('\n'),
                  ),
                ],

                // Patient-friendly summary - Only for patients
                if (!widget.showContraindications) ...[
                  _buildPatientFriendlySection(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    String content,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildADRSection() {
    final serious = _adrInfo!.commonAdverseReactions
        .where((r) => r.isSerious)
        .toList();
    final nonSerious = _adrInfo!.commonAdverseReactions
        .where((r) => !r.isSerious)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety, size: 18, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Adverse Reactions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Serious ADRs
          if (serious.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ SERIOUS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: serious
                        .map((r) => _buildADRChip(r, isSerious: true))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],

          // Common ADRs
          if (nonSerious.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: nonSerious
                  .map((r) => _buildADRChip(r, isSerious: false))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildADRChip(AdverseReaction reaction, {required bool isSerious}) {
    return Tooltip(
      message: reaction.frequency.displayName,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSerious
              ? Colors.red.shade100
              : Color(reaction.frequency.colorValue).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSerious
                ? Colors.red
                : Color(reaction.frequency.colorValue),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSerious) ...[
              const Icon(Icons.warning, size: 12, color: Colors.red),
              const SizedBox(width: 4),
            ],
            Text(
              reaction.reaction,
              style: TextStyle(
                fontSize: 12,
                color: isSerious
                    ? Colors.red.shade800
                    : Color(reaction.frequency.colorValue),
                fontWeight: isSerious ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build patient-friendly information section
  Widget _buildPatientFriendlySection() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Important Information for You',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildPatientTip(
              Icons.medical_services,
              'Take as directed',
              'Follow your doctor\'s instructions for dosing and timing.',
            ),
            const SizedBox(height: 8),
            _buildPatientTip(
              Icons.warning_amber,
              'Watch for side effects',
              'Contact your doctor if you experience any unusual symptoms.',
            ),
            const SizedBox(height: 8),
            _buildPatientTip(
              Icons.no_food,
              'Allergies',
              'Inform your doctor of any allergies before taking this medication.',
            ),
            const SizedBox(height: 8),
            _buildPatientTip(
              Icons.phone,
              'Emergency',
              'Seek immediate help if you have difficulty breathing or severe reactions.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTip(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.blue.shade800,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dialog to show comprehensive ADR information
class DrugADRDialog extends StatelessWidget {
  const DrugADRDialog({
    required this.drugName,
    this.patientConditions,
    super.key,
  });

  final String drugName;
  final PatientConditions? patientConditions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drugName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          'Adverse Drug Reaction Profile',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DrugADRCard(
                  drugName: drugName,
                  patientConditions: patientConditions,
                  showFullDetails: true,
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show ADR dialog for a drug
Future<void> showDrugADRDialog(
  BuildContext context,
  String drugName, {
  PatientConditions? patientConditions,
}) {
  return showDialog(
    context: context,
    builder: (context) => DrugADRDialog(
      drugName: drugName,
      patientConditions: patientConditions,
    ),
  );
}
