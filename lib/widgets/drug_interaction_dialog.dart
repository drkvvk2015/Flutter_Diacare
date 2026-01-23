import 'package:flutter/material.dart';

import '../services/drug_interaction_service.dart';

/// A comprehensive dialog to display drug interaction warnings
class DrugInteractionDialog extends StatelessWidget {
  const DrugInteractionDialog({
    required this.report,
    this.onProceed,
    this.onCancel,
    super.key,
  });

  final DrugInteractionReport report;
  final VoidCallback? onProceed;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary
                    _buildSummary(theme),
                    const SizedBox(height: 16),
                    
                    // Interactions List
                    ..._buildInteractionsList(theme),
                    
                    // Sources
                    const SizedBox(height: 16),
                    _buildSources(theme),
                  ],
                ),
              ),
            ),
            
            // Actions
            _buildActions(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final headerColor = report.hasSevereInteractions
        ? Colors.red
        : report.hasHighInteractions
            ? Colors.deepOrange
            : Colors.amber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            report.hasSevereInteractions
                ? Icons.dangerous
                : report.hasHighInteractions
                    ? Icons.warning_amber
                    : Icons.info_outline,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.hasSevereInteractions
                      ? 'SEVERE DRUG INTERACTIONS DETECTED'
                      : report.hasHighInteractions
                          ? 'HIGH RISK INTERACTIONS DETECTED'
                          : 'DRUG INTERACTIONS DETECTED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${report.interactions.length} interaction(s) found',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interaction Summary',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Severe',
                  report.severeCount,
                  InteractionSeverity.severe.colorValue,
                ),
                _buildSummaryItem(
                  'High',
                  report.highCount,
                  InteractionSeverity.high.colorValue,
                ),
                _buildSummaryItem(
                  'Moderate',
                  report.moderateCount,
                  InteractionSeverity.moderate.colorValue,
                ),
                _buildSummaryItem(
                  'Low',
                  report.lowCount,
                  InteractionSeverity.low.colorValue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, int colorValue) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(colorValue).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(colorValue)),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Color(colorValue),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(colorValue),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildInteractionsList(ThemeData theme) {
    final widgets = <Widget>[];

    // Group by severity
    final severityOrder = [
      InteractionSeverity.severe,
      InteractionSeverity.high,
      InteractionSeverity.moderate,
      InteractionSeverity.low,
      InteractionSeverity.unknown,
    ];

    for (final severity in severityOrder) {
      final interactions = report.interactions
          .where((i) => i.severity == severity)
          .toList();

      if (interactions.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(severity.colorValue),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  severity.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(color: Color(severity.colorValue)),
              ),
            ],
          ),
        ),
      );

      for (final interaction in interactions) {
        widgets.add(_buildInteractionCard(interaction, theme));
      }
    }

    return widgets;
  }

  Widget _buildInteractionCard(DrugInteraction interaction, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Color(interaction.severity.colorValue).withValues(alpha: 0.5),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(
          _getSeverityIcon(interaction.severity),
          color: Color(interaction.severity.colorValue),
        ),
        title: Text(
          '${interaction.sourceDrugName ?? 'Drug'} ↔ ${interaction.interactingDrugName}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          interaction.source,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              interaction.description,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          
          // Clinical Effect
          if (interaction.clinicalEffect != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              theme,
              Icons.medical_information,
              'Clinical Effect',
              interaction.clinicalEffect!,
            ),
          ],
          
          // Management
          if (interaction.management != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              theme,
              Icons.health_and_safety,
              'Management',
              interaction.management!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getSeverityIcon(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.severe:
        return Icons.dangerous;
      case InteractionSeverity.high:
        return Icons.warning_amber;
      case InteractionSeverity.moderate:
        return Icons.info_outline;
      case InteractionSeverity.low:
        return Icons.check_circle_outline;
      case InteractionSeverity.unknown:
        return Icons.help_outline;
    }
  }

  Widget _buildSources(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sources: ${report.sources.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (report.hasSevereInteractions)
            Expanded(
              child: Text(
                '⚠️ Proceeding with severe interactions is not recommended',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onProceed ?? () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: report.hasSevereInteractions
                  ? Colors.red
                  : theme.colorScheme.primary,
            ),
            child: Text(
              report.hasSevereInteractions
                  ? 'Proceed Anyway'
                  : 'Acknowledge & Proceed',
            ),
          ),
        ],
      ),
    );
  }
}

/// Show the drug interaction dialog
Future<bool> showDrugInteractionDialog(
  BuildContext context,
  DrugInteractionReport report,
) async {
  if (!report.hasInteractions) return true;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DrugInteractionDialog(report: report),
  );

  return result ?? false;
}
