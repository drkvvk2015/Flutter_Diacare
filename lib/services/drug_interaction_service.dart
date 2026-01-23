import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Comprehensive Drug Interaction Service
/// Integrates with RxNav, OpenFDA, and local DrugBank-style database
/// for accurate drug-drug interaction checking
class DrugInteractionService {
  factory DrugInteractionService() => _instance;
  DrugInteractionService._internal();
  static final DrugInteractionService _instance = DrugInteractionService._internal();

  // API endpoints
  static const String _rxNavBaseUrl = 'https://rxnav.nlm.nih.gov/REST';
  static const String _openFdaBaseUrl = 'https://api.fda.gov/drug';
  
  // Cache for API responses to reduce calls
  final Map<String, dynamic> _cache = {};
  final Duration _cacheDuration = const Duration(hours: 24);
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Get RxCUI (RxNorm Concept Unique Identifier) for a drug name
  Future<String?> getRxCUI(String drugName) async {
    final cacheKey = 'rxcui_$drugName';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as String?;
    }

    try {
      final encodedName = Uri.encodeComponent(drugName);
      final url = '$_rxNavBaseUrl/rxcui.json?name=$encodedName';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final idGroup = data['idGroup'] as Map<String, dynamic>?;
        final rxnormId = idGroup?['rxnormId'] as List?;
        
        if (rxnormId != null && rxnormId.isNotEmpty) {
          final rxcui = rxnormId[0].toString();
          _setCache(cacheKey, rxcui);
          return rxcui;
        }
      }
    } catch (e) {
      debugPrint('RxNav API error: $e');
    }
    return null;
  }

  /// Get drug interactions from RxNav API
  Future<List<DrugInteraction>> getInteractionsFromRxNav(String rxcui) async {
    final cacheKey = 'rxnav_interactions_$rxcui';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<DrugInteraction>;
    }

    final List<DrugInteraction> interactions = [];

    try {
      final url = '$_rxNavBaseUrl/interaction/interaction.json?rxcui=$rxcui';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final interactionTypeGroup = data['interactionTypeGroup'] as List?;

        if (interactionTypeGroup != null) {
          for (final group in interactionTypeGroup) {
            final interactionType = (group as Map<String, dynamic>)['interactionType'] as List?;
            
            if (interactionType != null) {
              for (final type in interactionType) {
                final interactionPair = (type as Map<String, dynamic>)['interactionPair'] as List?;
                
                if (interactionPair != null) {
                  for (final pair in interactionPair) {
                    final pairData = pair as Map<String, dynamic>;
                    final description = pairData['description'] as String? ?? '';
                    final severity = pairData['severity'] as String? ?? 'N/A';
                    final interactionConcept = pairData['interactionConcept'] as List?;
                    
                    String? interactingDrug;
                    String? interactingRxcui;
                    
                    if (interactionConcept != null && interactionConcept.length > 1) {
                      final concept = interactionConcept[1] as Map<String, dynamic>;
                      final sourceConceptItem = concept['sourceConceptItem'] as Map<String, dynamic>?;
                      interactingDrug = sourceConceptItem?['name'] as String?;
                      interactingRxcui = sourceConceptItem?['id'] as String?;
                    }

                    interactions.add(DrugInteraction(
                      sourceDrugRxcui: rxcui,
                      interactingDrugName: interactingDrug ?? 'Unknown',
                      interactingDrugRxcui: interactingRxcui,
                      description: description,
                      severity: _mapSeverity(severity),
                      source: 'RxNav',
                    ),);
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('RxNav interaction API error: $e');
    }

    _setCache(cacheKey, interactions);
    return interactions;
  }

  /// Get drug interactions between two specific drugs from RxNav
  Future<List<DrugInteraction>> getInteractionsBetweenDrugs(
    String rxcui1,
    String rxcui2,
  ) async {
    final cacheKey = 'rxnav_pair_${rxcui1}_$rxcui2';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<DrugInteraction>;
    }

    final List<DrugInteraction> interactions = [];

    try {
      final url = '$_rxNavBaseUrl/interaction/interaction.json?rxcui=$rxcui1&rxcui=$rxcui2';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final fullInteractionTypeGroup = data['fullInteractionTypeGroup'] as List?;

        if (fullInteractionTypeGroup != null) {
          for (final group in fullInteractionTypeGroup) {
            final fullInteractionType = (group as Map<String, dynamic>)['fullInteractionType'] as List?;
            
            if (fullInteractionType != null) {
              for (final type in fullInteractionType) {
                final interactionPair = (type as Map<String, dynamic>)['interactionPair'] as List?;
                
                if (interactionPair != null) {
                  for (final pair in interactionPair) {
                    final pairData = pair as Map<String, dynamic>;
                    interactions.add(DrugInteraction(
                      sourceDrugRxcui: rxcui1,
                      interactingDrugName: '',
                      interactingDrugRxcui: rxcui2,
                      description: pairData['description'] as String? ?? '',
                      severity: _mapSeverity(pairData['severity'] as String? ?? 'N/A'),
                      source: 'RxNav',
                    ),);
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('RxNav pair interaction API error: $e');
    }

    _setCache(cacheKey, interactions);
    return interactions;
  }

  /// Get drug information and interactions from OpenFDA
  Future<List<DrugInteraction>> getInteractionsFromOpenFDA(String drugName) async {
    final cacheKey = 'openfda_$drugName';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<DrugInteraction>;
    }

    final List<DrugInteraction> interactions = [];

    try {
      final encodedName = Uri.encodeComponent(drugName);
      final url = '$_openFdaBaseUrl/label.json?search=openfda.generic_name:"$encodedName"&limit=1';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          final result = results[0] as Map<String, dynamic>;
          
          // Extract drug interactions section
          final drugInteractionsText = result['drug_interactions'] as List?;
          
          if (drugInteractionsText != null && drugInteractionsText.isNotEmpty) {
            final interactionText = drugInteractionsText[0] as String;
            
            // Parse the interaction text to extract individual interactions
            final parsedInteractions = _parseOpenFDAInteractions(
              drugName,
              interactionText,
            );
            interactions.addAll(parsedInteractions);
          }

          // Also check warnings section for interactions
          final warnings = result['warnings'] as List?;
          if (warnings != null && warnings.isNotEmpty) {
            final warningText = warnings[0] as String;
            if (warningText.toLowerCase().contains('interaction')) {
              interactions.add(DrugInteraction(
                sourceDrugRxcui: '',
                interactingDrugName: 'See FDA Label',
                description: _truncateText(warningText, 500),
                severity: InteractionSeverity.moderate,
                source: 'OpenFDA',
              ),);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('OpenFDA API error: $e');
    }

    _setCache(cacheKey, interactions);
    return interactions;
  }

  /// Parse OpenFDA interaction text to extract drug names
  List<DrugInteraction> _parseOpenFDAInteractions(
    String sourceDrug,
    String interactionText,
  ) {
    final List<DrugInteraction> interactions = [];
    
    // Common drug interaction keywords used for future enhancement
    // ignore: unused_local_variable
    const interactionKeywords = [
      'may interact with',
      'should not be used with',
      'contraindicated with',
      'avoid use with',
      'caution when used with',
      'concurrent use',
      'concomitant use',
      'co-administration',
    ];

    // Check for major drug classes that commonly interact
    final drugClasses = {
      'MAO inhibitors': InteractionSeverity.severe,
      'MAOI': InteractionSeverity.severe,
      'CYP3A4 inhibitors': InteractionSeverity.moderate,
      'CYP2D6 inhibitors': InteractionSeverity.moderate,
      'anticoagulants': InteractionSeverity.high,
      'warfarin': InteractionSeverity.high,
      'insulin': InteractionSeverity.moderate,
      'sulfonylureas': InteractionSeverity.moderate,
      'beta-blockers': InteractionSeverity.moderate,
      'ACE inhibitors': InteractionSeverity.moderate,
      'diuretics': InteractionSeverity.moderate,
      'NSAIDs': InteractionSeverity.moderate,
      'aspirin': InteractionSeverity.moderate,
      'alcohol': InteractionSeverity.moderate,
    };

    for (final entry in drugClasses.entries) {
      if (interactionText.toLowerCase().contains(entry.key.toLowerCase())) {
        interactions.add(DrugInteraction(
          sourceDrugRxcui: '',
          interactingDrugName: entry.key,
          description: _extractRelevantSentence(interactionText, entry.key),
          severity: entry.value,
          source: 'OpenFDA',
        ),);
      }
    }

    return interactions;
  }

  /// Extract relevant sentence containing the keyword
  String _extractRelevantSentence(String text, String keyword) {
    final sentences = text.split(RegExp('[.!?]'));
    for (final sentence in sentences) {
      if (sentence.toLowerCase().contains(keyword.toLowerCase())) {
        return sentence.trim();
      }
    }
    return 'Potential interaction with $keyword. See full prescribing information.';
  }

  /// Check interactions for a list of drugs
  Future<DrugInteractionReport> checkInteractionsForPrescription(
    List<String> drugNames,
  ) async {
    final List<DrugInteraction> allInteractions = [];
    final Map<String, String> rxcuiMap = {};
    final List<String> errors = [];

    // Step 1: Get RxCUI for each drug
    for (final drug in drugNames) {
      final rxcui = await getRxCUI(drug);
      if (rxcui != null) {
        rxcuiMap[drug] = rxcui;
      } else {
        // Try OpenFDA as fallback
        final fdaInteractions = await getInteractionsFromOpenFDA(drug);
        allInteractions.addAll(fdaInteractions);
      }
    }

    // Step 2: Check RxNav interactions for each drug pair
    final rxcuiList = rxcuiMap.values.toList();
    for (int i = 0; i < rxcuiList.length; i++) {
      // Get all interactions for this drug
      final interactions = await getInteractionsFromRxNav(rxcuiList[i]);
      
      // Filter to only include interactions with drugs in our list
      for (final interaction in interactions) {
        if (rxcuiList.contains(interaction.interactingDrugRxcui)) {
          allInteractions.add(interaction);
        }
      }

      // Also check pair-wise interactions
      for (int j = i + 1; j < rxcuiList.length; j++) {
        final pairInteractions = await getInteractionsBetweenDrugs(
          rxcuiList[i],
          rxcuiList[j],
        );
        allInteractions.addAll(pairInteractions);
      }
    }

    // Step 3: Check local database for additional interactions
    final localInteractions = _checkLocalDatabase(drugNames);
    allInteractions.addAll(localInteractions);

    // Remove duplicates and sort by severity
    final uniqueInteractions = _deduplicateInteractions(allInteractions);
    uniqueInteractions.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return DrugInteractionReport(
      drugNames: drugNames,
      interactions: uniqueInteractions,
      checkedAt: DateTime.now(),
      sources: ['RxNav', 'OpenFDA', 'Local Database'],
      errors: errors,
    );
  }

  /// Local database for common diabetic drug interactions
  List<DrugInteraction> _checkLocalDatabase(List<String> drugNames) {
    final List<DrugInteraction> interactions = [];
    final normalizedNames = drugNames.map((d) => d.toUpperCase()).toSet();

    // Comprehensive local interaction database for diabetic medications
    final localDatabase = <String, Map<String, LocalInteractionData>>{
      'METFORMIN': {
        'GLIBENCLAMIDE': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Increased risk of hypoglycemia when Metformin is combined with Glibenclamide. Monitor blood glucose closely.',
          clinicalEffect: 'Enhanced hypoglycemic effect',
          management: 'Monitor blood glucose. Adjust doses as needed.',
        ),
        'PIOGLITAZONE': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Pioglitazone may increase the risk of lactic acidosis when combined with Metformin, especially in patients with renal impairment.',
          clinicalEffect: 'Increased risk of lactic acidosis and fluid retention',
          management: 'Monitor renal function. Watch for signs of heart failure.',
        ),
        'ALCOHOL': LocalInteractionData(
          severity: InteractionSeverity.high,
          description: 'Alcohol significantly increases the risk of lactic acidosis with Metformin. Can also cause severe hypoglycemia.',
          clinicalEffect: 'Lactic acidosis, hypoglycemia',
          management: 'Advise patient to avoid or limit alcohol consumption.',
        ),
        'IODINATED CONTRAST': LocalInteractionData(
          severity: InteractionSeverity.severe,
          description: 'Metformin should be discontinued before IV iodinated contrast and withheld 48 hours after to prevent contrast-induced nephropathy and lactic acidosis.',
          clinicalEffect: 'Acute kidney injury, lactic acidosis',
          management: 'Stop Metformin before contrast. Resume 48h after if renal function stable.',
        ),
      },
      'INSULIN': {
        'GLIMEPIRIDE': LocalInteractionData(
          severity: InteractionSeverity.high,
          description: 'Concurrent use of Insulin and Glimepiride significantly increases hypoglycemia risk.',
          clinicalEffect: 'Severe hypoglycemia',
          management: 'Reduce sulfonylurea dose when adding insulin. Frequent glucose monitoring.',
        ),
        'GLIPIZIDE': LocalInteractionData(
          severity: InteractionSeverity.high,
          description: 'Concurrent use of Insulin and Glipizide significantly increases hypoglycemia risk.',
          clinicalEffect: 'Severe hypoglycemia',
          management: 'Reduce sulfonylurea dose when adding insulin. Frequent glucose monitoring.',
        ),
        'PIOGLITAZONE': LocalInteractionData(
          severity: InteractionSeverity.high,
          description: 'Combination increases risk of hypoglycemia and fluid retention/heart failure.',
          clinicalEffect: 'Hypoglycemia, edema, heart failure exacerbation',
          management: 'Reduce insulin dose. Monitor for signs of heart failure.',
        ),
        'BETA-BLOCKERS': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Beta-blockers can mask hypoglycemic symptoms and impair glycogenolysis.',
          clinicalEffect: 'Masked hypoglycemia symptoms, prolonged hypoglycemia',
          management: 'Prefer cardioselective beta-blockers. Educate patient on alternative hypoglycemia signs.',
        ),
        'ACE INHIBITORS': LocalInteractionData(
          severity: InteractionSeverity.low,
          description: 'ACE inhibitors may enhance insulin sensitivity and increase hypoglycemia risk.',
          clinicalEffect: 'Enhanced hypoglycemic effect',
          management: 'Monitor blood glucose when initiating ACE inhibitor.',
        ),
      },
      'GLIMEPIRIDE': {
        'GLIPIZIDE': LocalInteractionData(
          severity: InteractionSeverity.severe,
          description: 'Do not combine two sulfonylureas - significantly increased hypoglycemia risk with no additional benefit.',
          clinicalEffect: 'Severe hypoglycemia',
          management: 'Use only one sulfonylurea at a time.',
        ),
        'FLUCONAZOLE': LocalInteractionData(
          severity: InteractionSeverity.high,
          description: 'Fluconazole inhibits CYP2C9, increasing Glimepiride levels and hypoglycemia risk.',
          clinicalEffect: 'Increased Glimepiride exposure, hypoglycemia',
          management: 'Reduce Glimepiride dose. Monitor glucose closely.',
        ),
        'WARFARIN': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Sulfonylureas may enhance anticoagulant effect of Warfarin.',
          clinicalEffect: 'Increased bleeding risk',
          management: 'Monitor INR closely when adding or adjusting sulfonylurea.',
        ),
      },
      'DAPAGLIFLOZIN': {
        'FUROSEMIDE': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Combined diuretic effect may cause volume depletion and hypotension.',
          clinicalEffect: 'Dehydration, orthostatic hypotension',
          management: 'Monitor volume status. Consider reducing loop diuretic dose.',
        ),
        'INSULIN': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Increased hypoglycemia risk when SGLT2 inhibitor added to insulin.',
          clinicalEffect: 'Hypoglycemia',
          management: 'Consider reducing insulin dose by 10-20% when adding SGLT2i.',
        ),
      },
      'EMPAGLIFLOZIN': {
        'FUROSEMIDE': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Combined diuretic effect may cause volume depletion and hypotension.',
          clinicalEffect: 'Dehydration, orthostatic hypotension',
          management: 'Monitor volume status. Consider reducing loop diuretic dose.',
        ),
        'DIGOXIN': LocalInteractionData(
          severity: InteractionSeverity.low,
          description: 'SGLT2 inhibitors may increase digoxin exposure slightly.',
          clinicalEffect: 'Increased digoxin levels',
          management: 'Monitor digoxin levels if clinically indicated.',
        ),
      },
      'SITAGLIPTIN': {
        'DIGOXIN': LocalInteractionData(
          severity: InteractionSeverity.low,
          description: 'Sitagliptin may slightly increase digoxin exposure.',
          clinicalEffect: 'Minimal increase in digoxin levels',
          management: 'No dose adjustment typically needed. Monitor if concerned.',
        ),
      },
      'PIOGLITAZONE': {
        'GEMFIBROZIL': LocalInteractionData(
          severity: InteractionSeverity.high,
          description: 'Gemfibrozil inhibits CYP2C8, significantly increasing Pioglitazone exposure.',
          clinicalEffect: '3-fold increase in Pioglitazone AUC',
          management: 'Limit Pioglitazone to 15mg daily when used with Gemfibrozil.',
        ),
        'RIFAMPIN': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Rifampin induces CYP2C8, reducing Pioglitazone effectiveness.',
          clinicalEffect: '54% decrease in Pioglitazone AUC',
          management: 'May need to increase Pioglitazone dose. Monitor glucose.',
        ),
      },
      'LIRAGLUTIDE': {
        'INSULIN': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Combination increases hypoglycemia risk.',
          clinicalEffect: 'Hypoglycemia',
          management: 'Consider reducing insulin dose when adding GLP-1 RA.',
        ),
        'SULFONYLUREAS': LocalInteractionData(
          severity: InteractionSeverity.moderate,
          description: 'Increased hypoglycemia risk with sulfonylurea combination.',
          clinicalEffect: 'Hypoglycemia',
          management: 'Consider reducing sulfonylurea dose.',
        ),
        'WARFARIN': LocalInteractionData(
          severity: InteractionSeverity.low,
          description: 'GLP-1 RAs may delay gastric emptying, affecting Warfarin absorption initially.',
          clinicalEffect: 'Variable INR during initiation',
          management: 'Monitor INR more frequently when starting GLP-1 RA.',
        ),
      },
    };

    // Check for interactions
    for (final drug1 in normalizedNames) {
      final drugInteractions = localDatabase[drug1];
      if (drugInteractions != null) {
        for (final drug2 in normalizedNames) {
          if (drug1 != drug2 && drugInteractions.containsKey(drug2)) {
            final data = drugInteractions[drug2]!;
            interactions.add(DrugInteraction(
              sourceDrugRxcui: '',
              sourceDrugName: drug1,
              interactingDrugName: drug2,
              description: data.description,
              severity: data.severity,
              source: 'DiaCare Database',
              clinicalEffect: data.clinicalEffect,
              management: data.management,
            ),);
          }
        }
      }
    }

    return interactions;
  }

  /// Remove duplicate interactions
  List<DrugInteraction> _deduplicateInteractions(List<DrugInteraction> interactions) {
    final seen = <String>{};
    final unique = <DrugInteraction>[];

    for (final interaction in interactions) {
      final key = '${interaction.sourceDrugName ?? interaction.sourceDrugRxcui}_'
          '${interaction.interactingDrugName}_${interaction.source}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(interaction);
      }
    }

    return unique;
  }

  /// Map severity string to enum
  InteractionSeverity _mapSeverity(String severity) {
    final lower = severity.toLowerCase();
    if (lower.contains('severe') || lower.contains('contraindicated')) {
      return InteractionSeverity.severe;
    } else if (lower.contains('high') || lower.contains('serious')) {
      return InteractionSeverity.high;
    } else if (lower.contains('moderate')) {
      return InteractionSeverity.moderate;
    } else if (lower.contains('low') || lower.contains('minor')) {
      return InteractionSeverity.low;
    }
    return InteractionSeverity.unknown;
  }

  /// Truncate text to specified length
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Check if cache is valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  /// Set cache with timestamp
  void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}

/// Severity levels for drug interactions
enum InteractionSeverity {
  severe,   // Contraindicated - Do not use together
  high,     // Serious - Use with extreme caution
  moderate, // Significant - Monitor closely
  low,      // Minor - Be aware
  unknown,  // Unable to determine
}

/// Extension for severity display
extension InteractionSeverityExtension on InteractionSeverity {
  String get displayName {
    switch (this) {
      case InteractionSeverity.severe:
        return 'SEVERE';
      case InteractionSeverity.high:
        return 'HIGH';
      case InteractionSeverity.moderate:
        return 'MODERATE';
      case InteractionSeverity.low:
        return 'LOW';
      case InteractionSeverity.unknown:
        return 'UNKNOWN';
    }
  }

  String get description {
    switch (this) {
      case InteractionSeverity.severe:
        return 'Contraindicated - Do not use together';
      case InteractionSeverity.high:
        return 'Serious interaction - Use with extreme caution';
      case InteractionSeverity.moderate:
        return 'Significant interaction - Monitor closely';
      case InteractionSeverity.low:
        return 'Minor interaction - Be aware';
      case InteractionSeverity.unknown:
        return 'Severity could not be determined';
    }
  }

  int get colorValue {
    switch (this) {
      case InteractionSeverity.severe:
        return 0xFFD32F2F; // Red
      case InteractionSeverity.high:
        return 0xFFFF5722; // Deep Orange
      case InteractionSeverity.moderate:
        return 0xFFFFA000; // Amber
      case InteractionSeverity.low:
        return 0xFF4CAF50; // Green
      case InteractionSeverity.unknown:
        return 0xFF9E9E9E; // Grey
    }
  }
}

/// Drug interaction data model
class DrugInteraction {
  DrugInteraction({
    required this.sourceDrugRxcui,
    required this.interactingDrugName,
    required this.description,
    required this.severity,
    required this.source,
    this.sourceDrugName,
    this.interactingDrugRxcui,
    this.clinicalEffect,
    this.management,
  });

  final String sourceDrugRxcui;
  final String? sourceDrugName;
  final String interactingDrugName;
  final String? interactingDrugRxcui;
  final String description;
  final InteractionSeverity severity;
  final String source;
  final String? clinicalEffect;
  final String? management;

  Map<String, dynamic> toJson() => {
    'sourceDrugRxcui': sourceDrugRxcui,
    'sourceDrugName': sourceDrugName,
    'interactingDrugName': interactingDrugName,
    'interactingDrugRxcui': interactingDrugRxcui,
    'description': description,
    'severity': severity.displayName,
    'source': source,
    'clinicalEffect': clinicalEffect,
    'management': management,
  };
}

/// Local interaction data for database
class LocalInteractionData {
  LocalInteractionData({
    required this.severity,
    required this.description,
    this.clinicalEffect,
    this.management,
  });

  final InteractionSeverity severity;
  final String description;
  final String? clinicalEffect;
  final String? management;
}

/// Complete interaction report
class DrugInteractionReport {
  DrugInteractionReport({
    required this.drugNames,
    required this.interactions,
    required this.checkedAt,
    required this.sources,
    this.errors = const [],
  });

  final List<String> drugNames;
  final List<DrugInteraction> interactions;
  final DateTime checkedAt;
  final List<String> sources;
  final List<String> errors;

  bool get hasInteractions => interactions.isNotEmpty;
  bool get hasSevereInteractions =>
      interactions.any((i) => i.severity == InteractionSeverity.severe);
  bool get hasHighInteractions =>
      interactions.any((i) => i.severity == InteractionSeverity.high);

  int get severeCount =>
      interactions.where((i) => i.severity == InteractionSeverity.severe).length;
  int get highCount =>
      interactions.where((i) => i.severity == InteractionSeverity.high).length;
  int get moderateCount =>
      interactions.where((i) => i.severity == InteractionSeverity.moderate).length;
  int get lowCount =>
      interactions.where((i) => i.severity == InteractionSeverity.low).length;

  Map<String, dynamic> toJson() => {
    'drugNames': drugNames,
    'interactions': interactions.map((i) => i.toJson()).toList(),
    'checkedAt': checkedAt.toIso8601String(),
    'sources': sources,
    'errors': errors,
    'summary': {
      'total': interactions.length,
      'severe': severeCount,
      'high': highCount,
      'moderate': moderateCount,
      'low': lowCount,
    },
  };
}
