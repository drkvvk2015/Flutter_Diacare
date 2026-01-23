import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Comprehensive Adverse Drug Reaction (ADR) Service
/// Provides warnings for known side effects, black box warnings,
/// contraindications, and patient-specific alerts
class AdverseDrugReactionService {
  factory AdverseDrugReactionService() => _instance;
  AdverseDrugReactionService._internal();
  static final AdverseDrugReactionService _instance =
      AdverseDrugReactionService._internal();

  // OpenFDA API
  static const String _openFdaBaseUrl = 'https://api.fda.gov/drug';

  // Cache
  final Map<String, dynamic> _cache = {};
  final Duration _cacheDuration = const Duration(hours: 24);
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Get adverse reactions from OpenFDA for a drug
  Future<DrugAdverseReactionInfo> getAdverseReactions(String drugName) async {
    final cacheKey = 'adr_$drugName';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as DrugAdverseReactionInfo;
    }

    final info = DrugAdverseReactionInfo(drugName: drugName);

    try {
      final encodedName = Uri.encodeComponent(drugName);
      final url =
          '$_openFdaBaseUrl/label.json?search=openfda.generic_name:"$encodedName"&limit=1';

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          final result = results[0] as Map<String, dynamic>;

          // Black Box Warning (most critical)
          final boxedWarning = result['boxed_warning'] as List?;
          if (boxedWarning != null && boxedWarning.isNotEmpty) {
            info.blackBoxWarning = boxedWarning[0] as String;
            info.hasBlackBoxWarning = true;
          }

          // Warnings and Precautions
          final warningsAndPrecautions =
              result['warnings_and_precautions'] as List?;
          if (warningsAndPrecautions != null &&
              warningsAndPrecautions.isNotEmpty) {
            info.warningsAndPrecautions = warningsAndPrecautions[0] as String;
          }

          // Contraindications
          final contraindications = result['contraindications'] as List?;
          if (contraindications != null && contraindications.isNotEmpty) {
            info.contraindications = contraindications[0] as String;
            info.parsedContraindications =
                _parseContraindications(contraindications[0] as String);
          }

          // Adverse Reactions
          final adverseReactions = result['adverse_reactions'] as List?;
          if (adverseReactions != null && adverseReactions.isNotEmpty) {
            info.adverseReactionsText = adverseReactions[0] as String;
            info.commonAdverseReactions =
                _parseAdverseReactions(adverseReactions[0] as String);
          }

          // Pregnancy Warning
          final pregnancy = result['pregnancy'] as List?;
          if (pregnancy != null && pregnancy.isNotEmpty) {
            info.pregnancyWarning = pregnancy[0] as String;
          }

          // Nursing Mothers
          final nursing = result['nursing_mothers'] as List?;
          if (nursing != null && nursing.isNotEmpty) {
            info.nursingWarning = nursing[0] as String;
          }

          // Pediatric Use
          final pediatric = result['pediatric_use'] as List?;
          if (pediatric != null && pediatric.isNotEmpty) {
            info.pediatricWarning = pediatric[0] as String;
          }

          // Geriatric Use
          final geriatric = result['geriatric_use'] as List?;
          if (geriatric != null && geriatric.isNotEmpty) {
            info.geriatricWarning = geriatric[0] as String;
          }

          // Overdosage
          final overdosage = result['overdosage'] as List?;
          if (overdosage != null && overdosage.isNotEmpty) {
            info.overdosageInfo = overdosage[0] as String;
          }
        }
      }
    } catch (e) {
      debugPrint('OpenFDA ADR API error: $e');
    }

    // Add local database info
    _addLocalDatabaseInfo(info);

    _setCache(cacheKey, info);
    return info;
  }

  /// Parse contraindications text to extract key conditions
  List<String> _parseContraindications(String text) {
    final List<String> conditions = [];

    final keywords = {
      'hypersensitivity': 'Hypersensitivity/Allergy to drug',
      'renal impairment': 'Renal Impairment',
      'hepatic impairment': 'Hepatic Impairment',
      'heart failure': 'Heart Failure',
      'ketoacidosis': 'Diabetic Ketoacidosis',
      'type 1 diabetes': 'Type 1 Diabetes',
      'pregnancy': 'Pregnancy',
      'lactic acidosis': 'Risk of Lactic Acidosis',
      'bladder cancer': 'History of Bladder Cancer',
      'pancreatitis': 'History of Pancreatitis',
      'medullary thyroid': 'Medullary Thyroid Carcinoma',
      'men 2': 'MEN 2 Syndrome',
    };

    for (final entry in keywords.entries) {
      if (text.toLowerCase().contains(entry.key)) {
        conditions.add(entry.value);
      }
    }

    return conditions;
  }

  /// Parse adverse reactions text to extract common side effects
  List<AdverseReaction> _parseAdverseReactions(String text) {
    final List<AdverseReaction> reactions = [];

    // Common diabetic drug side effects with frequency estimates
    final sideEffects = {
      // GI effects
      'nausea': ADRFrequency.common,
      'vomiting': ADRFrequency.common,
      'diarrhea': ADRFrequency.veryCommon,
      'abdominal pain': ADRFrequency.common,
      'constipation': ADRFrequency.common,
      'dyspepsia': ADRFrequency.common,
      'flatulence': ADRFrequency.common,

      // Metabolic
      'hypoglycemia': ADRFrequency.veryCommon,
      'weight gain': ADRFrequency.common,
      'weight loss': ADRFrequency.common,
      'lactic acidosis': ADRFrequency.rare,
      'ketoacidosis': ADRFrequency.uncommon,

      // Cardiovascular
      'edema': ADRFrequency.common,
      'peripheral edema': ADRFrequency.common,
      'heart failure': ADRFrequency.uncommon,
      'hypotension': ADRFrequency.uncommon,

      // Genitourinary
      'urinary tract infection': ADRFrequency.common,
      'genital infection': ADRFrequency.common,
      'polyuria': ADRFrequency.common,

      // Dermatologic
      'rash': ADRFrequency.uncommon,
      'pruritus': ADRFrequency.uncommon,
      'urticaria': ADRFrequency.rare,

      // Musculoskeletal
      'arthralgia': ADRFrequency.common,
      'back pain': ADRFrequency.common,
      'fracture': ADRFrequency.uncommon,

      // Neurologic
      'headache': ADRFrequency.common,
      'dizziness': ADRFrequency.common,

      // Serious
      'pancreatitis': ADRFrequency.rare,
      'anaphylaxis': ADRFrequency.veryRare,
      "fournier's gangrene": ADRFrequency.veryRare,
      'amputation': ADRFrequency.rare,
    };

    for (final entry in sideEffects.entries) {
      if (text.toLowerCase().contains(entry.key)) {
        reactions.add(AdverseReaction(
          reaction: _capitalize(entry.key),
          frequency: entry.value,
          isSerious: _isSerious(entry.key),
        ),);
      }
    }

    // Sort by severity (serious first) then frequency
    reactions.sort((a, b) {
      if (a.isSerious != b.isSerious) {
        return a.isSerious ? -1 : 1;
      }
      return a.frequency.index.compareTo(b.frequency.index);
    });

    return reactions;
  }

  bool _isSerious(String reaction) {
    final serious = [
      'lactic acidosis',
      'ketoacidosis',
      'heart failure',
      'pancreatitis',
      'anaphylaxis',
      "fournier's gangrene",
      'amputation',
    ];
    return serious.contains(reaction.toLowerCase());
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Add local database information for diabetic drugs
  void _addLocalDatabaseInfo(DrugAdverseReactionInfo info) {
    final localData = _localDrugDatabase[info.drugName.toUpperCase()];
    if (localData != null) {
      // Merge local data with API data
      if (info.blackBoxWarning == null && localData.blackBoxWarning != null) {
        info.blackBoxWarning = localData.blackBoxWarning;
        info.hasBlackBoxWarning = true;
      }

      // Add local contraindications
      for (final contra in localData.contraindications) {
        if (!info.parsedContraindications.contains(contra)) {
          info.parsedContraindications.add(contra);
        }
      }

      // Add local ADRs
      for (final adr in localData.commonADRs) {
        if (!info.commonAdverseReactions
            .any((r) => r.reaction.toLowerCase() == adr.reaction.toLowerCase())) {
          info.commonAdverseReactions.add(adr);
        }
      }

      // Add special warnings
      info.specialWarnings.addAll(localData.specialWarnings);

      // Add monitoring requirements
      info.monitoringRequirements.addAll(localData.monitoringRequirements);
    }
  }

  /// Local database for diabetic drugs with critical ADR info
  final Map<String, LocalDrugADRData> _localDrugDatabase = {
    'METFORMIN': LocalDrugADRData(
      blackBoxWarning:
          'LACTIC ACIDOSIS: Metformin can cause lactic acidosis, a rare but serious complication. '
          'Risk increases with renal impairment, sepsis, dehydration, excess alcohol, hepatic impairment, '
          'and acute heart failure. Discontinue if conditions occur.',
      contraindications: [
        'Severe renal impairment (eGFR <30)',
        'Metabolic acidosis including DKA',
        'Iodinated contrast procedures',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Diarrhea', frequency: ADRFrequency.veryCommon, isSerious: false),
        AdverseReaction(reaction: 'Nausea', frequency: ADRFrequency.veryCommon, isSerious: false),
        AdverseReaction(reaction: 'Vitamin B12 deficiency', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Lactic acidosis', frequency: ADRFrequency.rare, isSerious: true),
      ],
      specialWarnings: [
        'Hold before and 48h after iodinated contrast',
        'Check renal function before initiation and periodically',
        'Monitor Vitamin B12 levels with long-term use',
      ],
      monitoringRequirements: [
        'Renal function (eGFR): Baseline and annually',
        'Vitamin B12: Every 2-3 years',
        'HbA1c: Every 3-6 months',
      ],
    ),
    'GLIMEPIRIDE': LocalDrugADRData(
      contraindications: [
        'Type 1 Diabetes',
        'Diabetic ketoacidosis',
        'Sulfonamide allergy',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Hypoglycemia', frequency: ADRFrequency.veryCommon, isSerious: true),
        AdverseReaction(reaction: 'Weight gain', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Dizziness', frequency: ADRFrequency.common, isSerious: false),
      ],
      specialWarnings: [
        'HIGH HYPOGLYCEMIA RISK - especially in elderly, malnourished, or renal impairment',
        'Increased cardiovascular mortality (historical sulfonylurea warning)',
        'May cause hemolytic anemia in G6PD deficiency',
      ],
      monitoringRequirements: [
        'Blood glucose: Frequent self-monitoring',
        'HbA1c: Every 3 months initially',
        'Signs of hypoglycemia',
      ],
    ),
    'GLIPIZIDE': LocalDrugADRData(
      contraindications: [
        'Type 1 Diabetes',
        'Diabetic ketoacidosis',
        'Sulfonamide allergy',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Hypoglycemia', frequency: ADRFrequency.veryCommon, isSerious: true),
        AdverseReaction(reaction: 'Weight gain', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'GI upset', frequency: ADRFrequency.common, isSerious: false),
      ],
      specialWarnings: [
        'HIGH HYPOGLYCEMIA RISK',
        'Use with caution in hepatic/renal impairment',
        'Avoid in elderly >65 years if possible',
      ],
      monitoringRequirements: [
        'Blood glucose: Regular monitoring',
        'HbA1c: Every 3-6 months',
        'Renal and hepatic function',
      ],
    ),
    'PIOGLITAZONE': LocalDrugADRData(
      blackBoxWarning:
          'HEART FAILURE: Thiazolidinediones cause fluid retention that can exacerbate or lead to '
          'heart failure. Contraindicated in NYHA Class III-IV heart failure. Monitor for signs of '
          'heart failure after initiation and dose increases.',
      contraindications: [
        'NYHA Class III-IV Heart Failure',
        'Active bladder cancer',
        'History of bladder cancer',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Edema', frequency: ADRFrequency.veryCommon, isSerious: false),
        AdverseReaction(reaction: 'Weight gain', frequency: ADRFrequency.veryCommon, isSerious: false),
        AdverseReaction(reaction: 'Fractures', frequency: ADRFrequency.common, isSerious: true),
        AdverseReaction(reaction: 'Heart failure', frequency: ADRFrequency.uncommon, isSerious: true),
        AdverseReaction(reaction: 'Bladder cancer', frequency: ADRFrequency.rare, isSerious: true),
        AdverseReaction(reaction: 'Macular edema', frequency: ADRFrequency.rare, isSerious: true),
      ],
      specialWarnings: [
        'BLACK BOX: Heart failure risk',
        'Increased fracture risk in women',
        'Possible increased bladder cancer risk',
        'May cause or worsen macular edema',
      ],
      monitoringRequirements: [
        'Signs of heart failure',
        'Weight and edema',
        'Liver function tests',
        'Bone health in women',
      ],
    ),
    'DAPAGLIFLOZIN': LocalDrugADRData(
      contraindications: [
        'Severe renal impairment (eGFR <25 for diabetes)',
        'Dialysis patients',
        'Type 1 Diabetes (not approved)',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Genital mycotic infections', frequency: ADRFrequency.veryCommon, isSerious: false),
        AdverseReaction(reaction: 'Urinary tract infections', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Volume depletion', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Diabetic ketoacidosis', frequency: ADRFrequency.uncommon, isSerious: true),
        AdverseReaction(reaction: "Fournier's gangrene", frequency: ADRFrequency.veryRare, isSerious: true),
      ],
      specialWarnings: [
        "RARE BUT SERIOUS: Fournier's gangrene (necrotizing fasciitis of perineum)",
        'Euglycemic DKA - may occur with normal glucose',
        'Hold before major surgery',
        'Increased risk of lower limb amputation (class effect)',
      ],
      monitoringRequirements: [
        'Renal function: Baseline and periodically',
        'Volume status, especially in elderly',
        'Signs of ketoacidosis',
        'Genital/perineal symptoms',
      ],
    ),
    'EMPAGLIFLOZIN': LocalDrugADRData(
      contraindications: [
        'Severe renal impairment (eGFR <20 for HFrEF)',
        'Dialysis patients',
        'Type 1 Diabetes',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Genital infections', frequency: ADRFrequency.veryCommon, isSerious: false),
        AdverseReaction(reaction: 'UTI', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Polyuria', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Euglycemic DKA', frequency: ADRFrequency.uncommon, isSerious: true),
        AdverseReaction(reaction: "Fournier's gangrene", frequency: ADRFrequency.veryRare, isSerious: true),
      ],
      specialWarnings: [
        "WARNING: Fournier's gangrene risk",
        'Euglycemic DKA - can occur with normal blood glucose',
        'Volume depletion - caution with diuretics',
        'Temporary discontinuation before surgery',
      ],
      monitoringRequirements: [
        'eGFR: Before and during treatment',
        'Blood pressure and volume status',
        'Ketones if ill or symptomatic',
        'Foot health',
      ],
    ),
    'SITAGLIPTIN': LocalDrugADRData(
      contraindications: [
        'History of serious hypersensitivity to sitagliptin',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Nasopharyngitis', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Upper respiratory infection', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Headache', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Pancreatitis', frequency: ADRFrequency.rare, isSerious: true),
        AdverseReaction(reaction: 'Severe joint pain', frequency: ADRFrequency.rare, isSerious: true),
        AdverseReaction(reaction: 'Bullous pemphigoid', frequency: ADRFrequency.rare, isSerious: true),
      ],
      specialWarnings: [
        'PANCREATITIS: Discontinue if pancreatitis suspected',
        'Severe and disabling arthralgia reported',
        'Bullous pemphigoid - discontinue if blisters develop',
        'Reduce dose in renal impairment',
      ],
      monitoringRequirements: [
        'Signs of pancreatitis (severe abdominal pain)',
        'Joint symptoms',
        'Renal function for dose adjustment',
        'Skin for bullous lesions',
      ],
    ),
    'LIRAGLUTIDE': LocalDrugADRData(
      blackBoxWarning:
          'THYROID C-CELL TUMORS: Liraglutide causes thyroid C-cell tumors in rodents. '
          'Contraindicated in patients with personal or family history of medullary thyroid carcinoma (MTC) '
          'or Multiple Endocrine Neoplasia syndrome type 2 (MEN 2).',
      contraindications: [
        'Personal/family history of MTC',
        'MEN 2 syndrome',
        'History of pancreatitis',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Nausea', frequency: ADRFrequency.veryCommon, isSerious: false),
        AdverseReaction(reaction: 'Vomiting', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Diarrhea', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Injection site reactions', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Pancreatitis', frequency: ADRFrequency.rare, isSerious: true),
        AdverseReaction(reaction: 'Acute kidney injury', frequency: ADRFrequency.rare, isSerious: true),
        AdverseReaction(reaction: 'Gallbladder disease', frequency: ADRFrequency.uncommon, isSerious: true),
      ],
      specialWarnings: [
        'BLACK BOX: Thyroid C-cell tumor risk',
        'Pancreatitis - discontinue if suspected',
        'Acute kidney injury with dehydration from GI effects',
        'Increased heart rate',
      ],
      monitoringRequirements: [
        'Thyroid nodules/symptoms',
        'Signs of pancreatitis',
        'Renal function if GI symptoms severe',
        'Heart rate',
      ],
    ),
    'SEMAGLUTIDE': LocalDrugADRData(
      blackBoxWarning:
          'THYROID C-CELL TUMORS: Semaglutide causes thyroid C-cell tumors in rodents. '
          'Contraindicated in patients with personal or family history of medullary thyroid carcinoma (MTC) '
          'or Multiple Endocrine Neoplasia syndrome type 2 (MEN 2).',
      contraindications: [
        'Personal/family history of MTC',
        'MEN 2 syndrome',
        'History of pancreatitis',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Nausea', frequency: ADRFrequency.veryCommon, isSerious: false),
        AdverseReaction(reaction: 'Vomiting', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Diarrhea', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Abdominal pain', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Constipation', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Pancreatitis', frequency: ADRFrequency.rare, isSerious: true),
        AdverseReaction(reaction: 'Diabetic retinopathy complications', frequency: ADRFrequency.uncommon, isSerious: true),
      ],
      specialWarnings: [
        'BLACK BOX: Thyroid C-cell tumor risk',
        'Pancreatitis risk',
        'May worsen diabetic retinopathy with rapid glucose improvement',
        'Acute gallbladder disease',
      ],
      monitoringRequirements: [
        'Thyroid examination',
        'Retinal examination if history of retinopathy',
        'Signs of pancreatitis',
        'Gallbladder symptoms',
      ],
    ),
    'INSULIN': LocalDrugADRData(
      contraindications: [
        'During hypoglycemia episodes',
      ],
      commonADRs: [
        AdverseReaction(reaction: 'Hypoglycemia', frequency: ADRFrequency.veryCommon, isSerious: true),
        AdverseReaction(reaction: 'Weight gain', frequency: ADRFrequency.veryCommon, isSerious: false),
        AdverseReaction(reaction: 'Injection site reactions', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Lipodystrophy', frequency: ADRFrequency.common, isSerious: false),
        AdverseReaction(reaction: 'Hypokalemia', frequency: ADRFrequency.uncommon, isSerious: true),
        AdverseReaction(reaction: 'Severe hypoglycemia', frequency: ADRFrequency.uncommon, isSerious: true),
      ],
      specialWarnings: [
        'HYPOGLYCEMIA: Most common serious adverse effect',
        'Never share insulin pens between patients',
        'Rotate injection sites to prevent lipodystrophy',
        'Dose adjustment needed with renal/hepatic impairment',
      ],
      monitoringRequirements: [
        'Blood glucose: Multiple times daily',
        'HbA1c: Every 3 months',
        'Injection sites for lipodystrophy',
        'Symptoms of hypoglycemia',
        'Potassium levels with high doses',
      ],
    ),
  };

  /// Check patient-specific contraindications
  List<PatientSpecificWarning> checkPatientContraindications({
    required String drugName,
    required PatientConditions conditions,
  }) {
    final warnings = <PatientSpecificWarning>[];
    final drugUpper = drugName.toUpperCase();

    // Renal impairment checks
    if (conditions.hasRenalImpairment) {
      if (drugUpper == 'METFORMIN' && (conditions.eGFR ?? 100) < 30) {
        warnings.add(PatientSpecificWarning(
          severity: WarningSeverity.contraindicated,
          message: 'CONTRAINDICATED: Metformin with eGFR <30 mL/min/1.73m²',
          recommendation: 'Do not use. Consider alternative agents.',
        ),);
      } else if (drugUpper == 'METFORMIN' && (conditions.eGFR ?? 100) < 45) {
        warnings.add(PatientSpecificWarning(
          severity: WarningSeverity.caution,
          message: 'CAUTION: Metformin dose reduction needed with eGFR 30-45',
          recommendation: 'Maximum dose 1000mg/day. Monitor renal function.',
        ),);
      }
      
      if (['DAPAGLIFLOZIN', 'EMPAGLIFLOZIN'].contains(drugUpper) &&
          (conditions.eGFR ?? 100) < 25) {
        warnings.add(PatientSpecificWarning(
          severity: WarningSeverity.contraindicated,
          message: 'CONTRAINDICATED: SGLT2 inhibitor with eGFR <25',
          recommendation: 'Do not initiate. Discontinue if already on therapy.',
        ),);
      }
    }

    // Heart failure checks
    if (conditions.hasHeartFailure) {
      if (drugUpper == 'PIOGLITAZONE') {
        if (conditions.nyhcClass != null && conditions.nyhcClass! >= 3) {
          warnings.add(PatientSpecificWarning(
            severity: WarningSeverity.contraindicated,
            message: 'CONTRAINDICATED: Pioglitazone in NYHA Class III-IV heart failure',
            recommendation: 'Do not use. High risk of fluid retention and worsening HF.',
          ),);
        } else {
          warnings.add(PatientSpecificWarning(
            severity: WarningSeverity.caution,
            message: 'CAUTION: Pioglitazone may worsen heart failure',
            recommendation: 'Monitor closely for weight gain, edema, dyspnea.',
          ),);
        }
      }
    }

    // Pregnancy checks
    if (conditions.isPregnant) {
      final contraindicatedInPregnancy = [
        'GLIMEPIRIDE', 'GLIPIZIDE', 'GLIBENCLAMIDE',
        'PIOGLITAZONE', 'ROSIGLITAZONE',
        'DAPAGLIFLOZIN', 'EMPAGLIFLOZIN', 'CANAGLIFLOZIN',
        'SITAGLIPTIN', 'LINAGLIPTIN', 'SAXAGLIPTIN',
        'LIRAGLUTIDE', 'SEMAGLUTIDE', 'DULAGLUTIDE',
      ];
      if (contraindicatedInPregnancy.contains(drugUpper)) {
        warnings.add(PatientSpecificWarning(
          severity: WarningSeverity.contraindicated,
          message: 'CONTRAINDICATED IN PREGNANCY: $drugName',
          recommendation: 'Use insulin for glycemic control during pregnancy.',
        ),);
      }
    }

    // Allergy checks
    if (conditions.allergies.isNotEmpty) {
      // Sulfonamide cross-reactivity
      if (conditions.allergies.any(
        (a) => a.toLowerCase().contains('sulfa') ||
            a.toLowerCase().contains('sulfonamide'),
      )) {
        if (['GLIMEPIRIDE', 'GLIPIZIDE', 'GLIBENCLAMIDE', 'GLYBURIDE'].contains(drugUpper)) {
          warnings.add(PatientSpecificWarning(
            severity: WarningSeverity.caution,
            message: 'ALLERGY ALERT: Patient has sulfonamide allergy - sulfonylureas may cross-react',
            recommendation: 'Consider alternative. If used, monitor closely for allergic reactions.',
          ),);
        }
      }
      
      // Direct drug allergy
      if (conditions.allergies.any(
        (a) => a.toUpperCase().contains(drugUpper),
      )) {
        warnings.add(PatientSpecificWarning(
          severity: WarningSeverity.contraindicated,
          message: 'ALLERGY: Patient allergic to $drugName',
          recommendation: 'Do not prescribe. Use alternative agent.',
        ),);
      }
    }

    // Elderly checks
    if (conditions.age != null && conditions.age! >= 65) {
      if (['GLIMEPIRIDE', 'GLIPIZIDE', 'GLIBENCLAMIDE'].contains(drugUpper)) {
        warnings.add(PatientSpecificWarning(
          severity: WarningSeverity.caution,
          message: 'CAUTION: Elderly patient - increased hypoglycemia risk with sulfonylureas',
          recommendation: 'Start low, go slow. Consider alternatives like DPP-4 inhibitors.',
        ),);
      }
    }

    // History of pancreatitis
    if (conditions.hasPancreatitisHistory) {
      if (['SITAGLIPTIN', 'LINAGLIPTIN', 'SAXAGLIPTIN', 'LIRAGLUTIDE', 'SEMAGLUTIDE', 'DULAGLUTIDE', 'EXENATIDE'].contains(drugUpper)) {
        warnings.add(PatientSpecificWarning(
          severity: WarningSeverity.contraindicated,
          message: 'CONTRAINDICATED: GLP-1 RA/DPP-4i with history of pancreatitis',
          recommendation: 'Do not use. Choose alternative drug class.',
        ),);
      }
    }

    // History of bladder cancer
    if (conditions.hasBladderCancerHistory) {
      if (drugUpper == 'PIOGLITAZONE') {
        warnings.add(PatientSpecificWarning(
          severity: WarningSeverity.contraindicated,
          message: 'CONTRAINDICATED: Pioglitazone with bladder cancer history',
          recommendation: 'Do not use due to possible bladder cancer association.',
        ),);
      }
    }

    // MTC/MEN2 history
    if (conditions.hasMTCHistory || conditions.hasMEN2) {
      if (['LIRAGLUTIDE', 'SEMAGLUTIDE', 'DULAGLUTIDE', 'EXENATIDE'].contains(drugUpper)) {
        warnings.add(PatientSpecificWarning(
          severity: WarningSeverity.contraindicated,
          message: 'CONTRAINDICATED: GLP-1 RA with MTC/MEN2 history',
          recommendation: 'BLACK BOX WARNING - Do not use.',
        ),);
      }
    }

    return warnings;
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}

/// Frequency of adverse reactions
enum ADRFrequency {
  veryCommon, // ≥1/10
  common, // ≥1/100 to <1/10
  uncommon, // ≥1/1,000 to <1/100
  rare, // ≥1/10,000 to <1/1,000
  veryRare, // <1/10,000
}

extension ADRFrequencyExtension on ADRFrequency {
  String get displayName {
    switch (this) {
      case ADRFrequency.veryCommon:
        return 'Very Common (≥10%)';
      case ADRFrequency.common:
        return 'Common (1-10%)';
      case ADRFrequency.uncommon:
        return 'Uncommon (0.1-1%)';
      case ADRFrequency.rare:
        return 'Rare (0.01-0.1%)';
      case ADRFrequency.veryRare:
        return 'Very Rare (<0.01%)';
    }
  }

  int get colorValue {
    switch (this) {
      case ADRFrequency.veryCommon:
        return 0xFFE65100; // Deep orange
      case ADRFrequency.common:
        return 0xFFFF9800; // Orange
      case ADRFrequency.uncommon:
        return 0xFFFFC107; // Amber
      case ADRFrequency.rare:
        return 0xFF8BC34A; // Light green
      case ADRFrequency.veryRare:
        return 0xFF4CAF50; // Green
    }
  }
}

/// Adverse reaction data model
class AdverseReaction {
  AdverseReaction({
    required this.reaction,
    required this.frequency,
    required this.isSerious,
  });

  final String reaction;
  final ADRFrequency frequency;
  final bool isSerious;
}

/// Complete drug ADR information
class DrugAdverseReactionInfo {
  DrugAdverseReactionInfo({required this.drugName});

  final String drugName;
  bool hasBlackBoxWarning = false;
  String? blackBoxWarning;
  String? warningsAndPrecautions;
  String? contraindications;
  List<String> parsedContraindications = [];
  String? adverseReactionsText;
  List<AdverseReaction> commonAdverseReactions = [];
  String? pregnancyWarning;
  String? nursingWarning;
  String? pediatricWarning;
  String? geriatricWarning;
  String? overdosageInfo;
  List<String> specialWarnings = [];
  List<String> monitoringRequirements = [];
}

/// Local drug ADR data structure
class LocalDrugADRData {
  LocalDrugADRData({
    this.blackBoxWarning,
    this.contraindications = const [],
    this.commonADRs = const [],
    this.specialWarnings = const [],
    this.monitoringRequirements = const [],
  });

  final String? blackBoxWarning;
  final List<String> contraindications;
  final List<AdverseReaction> commonADRs;
  final List<String> specialWarnings;
  final List<String> monitoringRequirements;
}

/// Patient conditions for personalized warnings
class PatientConditions {
  PatientConditions({
    this.age,
    this.eGFR,
    this.hasRenalImpairment = false,
    this.hasHeartFailure = false,
    this.nyhcClass,
    this.hasLiverDisease = false,
    this.isPregnant = false,
    this.isNursing = false,
    this.hasPancreatitisHistory = false,
    this.hasBladderCancerHistory = false,
    this.hasMTCHistory = false,
    this.hasMEN2 = false,
    this.allergies = const [],
  });

  final int? age;
  final double? eGFR;
  final bool hasRenalImpairment;
  final bool hasHeartFailure;
  final int? nyhcClass;
  final bool hasLiverDisease;
  final bool isPregnant;
  final bool isNursing;
  final bool hasPancreatitisHistory;
  final bool hasBladderCancerHistory;
  final bool hasMTCHistory;
  final bool hasMEN2;
  final List<String> allergies;
}

/// Warning severity levels
enum WarningSeverity {
  contraindicated, // Do not use
  warning, // Serious caution
  caution, // Monitor closely
  info, // Be aware
}

extension WarningSeverityExtension on WarningSeverity {
  String get displayName {
    switch (this) {
      case WarningSeverity.contraindicated:
        return 'CONTRAINDICATED';
      case WarningSeverity.warning:
        return 'WARNING';
      case WarningSeverity.caution:
        return 'CAUTION';
      case WarningSeverity.info:
        return 'INFO';
    }
  }

  int get colorValue {
    switch (this) {
      case WarningSeverity.contraindicated:
        return 0xFFD32F2F; // Red
      case WarningSeverity.warning:
        return 0xFFFF5722; // Deep orange
      case WarningSeverity.caution:
        return 0xFFFFA000; // Amber
      case WarningSeverity.info:
        return 0xFF2196F3; // Blue
    }
  }
}

/// Patient-specific warning
class PatientSpecificWarning {
  PatientSpecificWarning({
    required this.severity,
    required this.message,
    this.recommendation,
  });

  final WarningSeverity severity;
  final String message;
  final String? recommendation;
}
