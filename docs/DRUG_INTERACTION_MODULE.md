# Comprehensive Drug Interaction Module

## Overview

DiaCare now includes a comprehensive drug-drug interaction (DDI) checking system that integrates multiple trusted pharmaceutical databases to provide accurate, real-time interaction warnings during prescription writing.

## Data Sources

### 1. RxNav (NIH/NLM)
- **API**: https://rxnav.nlm.nih.gov/REST
- **Features**:
  - RxCUI (RxNorm Concept Unique Identifier) lookup
  - Drug-drug interaction checking via `/interaction/interaction.json`
  - Pair-wise interaction queries
  - Severity classification
- **Coverage**: ~100,000+ drugs in RxNorm database

### 2. OpenFDA
- **API**: https://api.fda.gov/drug
- **Features**:
  - Drug label information including interaction sections
  - Warning sections with interaction data
  - Parsing of drug class interactions (MAOIs, CYP inhibitors, etc.)
- **Coverage**: FDA-approved drug labels

### 3. DiaCare Local Database
- **Purpose**: Fast, offline-capable checking for common diabetic medications
- **Features**:
  - Curated interactions for diabetes-specific drugs
  - Clinical effects and management recommendations
  - Immediate response without API latency
- **Coverage**: 20+ diabetic medications with detailed interaction profiles

## Severity Levels

| Level | Color | Description |
|-------|-------|-------------|
| **SEVERE** | Red | Contraindicated - Do not use together |
| **HIGH** | Deep Orange | Serious interaction - Use with extreme caution |
| **MODERATE** | Amber | Significant interaction - Monitor closely |
| **LOW** | Green | Minor interaction - Be aware |
| **UNKNOWN** | Grey | Severity could not be determined |

## Usage

### In Prescription Screen

1. **Automatic Checking**: Interactions are automatically checked when:
   - Adding a new drug to the prescription
   - Using a quick template
   - Loading an existing prescription

2. **Visual Indicators**:
   - Local check results appear immediately (orange box)
   - API check shows loading indicator while fetching
   - Results display with color-coded severity chips
   - "No interactions" message when safe

3. **Detailed Report**:
   - Click "View Details" to see full interaction report
   - Expandable cards with:
     - Drug pair identification
     - Description of interaction
     - Clinical effect
     - Management recommendations
     - Data source

### Programmatic Usage

```dart
import 'package:flutter_diacare/services/drug_interaction_service.dart';

final service = DrugInteractionService();

// Check interactions for a list of drugs
final report = await service.checkInteractionsForPrescription([
  'METFORMIN',
  'GLIBENCLAMIDE',
  'PIOGLITAZONE',
]);

if (report.hasInteractions) {
  print('Found ${report.interactions.length} interactions');
  
  if (report.hasSevereInteractions) {
    print('WARNING: Severe interactions detected!');
  }
  
  for (final interaction in report.interactions) {
    print('${interaction.sourceDrugName} ↔ ${interaction.interactingDrugName}');
    print('Severity: ${interaction.severity.displayName}');
    print('Description: ${interaction.description}');
    if (interaction.management != null) {
      print('Management: ${interaction.management}');
    }
  }
}
```

## Diabetic Drug Coverage

The local database includes detailed interactions for:

### Biguanides
- **Metformin**: Interactions with sulfonylureas, TZDs, alcohol, iodinated contrast

### Sulfonylureas
- **Glimepiride**, **Glipizide**, **Glibenclamide**: 
  - Cross-interactions (do not combine two sulfonylureas)
  - Interactions with insulin, warfarin, fluconazole

### Thiazolidinediones (TZDs)
- **Pioglitazone**, **Rosiglitazone**: 
  - CYP2C8 interactions (gemfibrozil, rifampin)
  - Insulin combination warnings
  - Heart failure considerations

### SGLT2 Inhibitors
- **Dapagliflozin**, **Empagliflozin**:
  - Diuretic interactions (volume depletion)
  - Insulin dose adjustment recommendations

### GLP-1 Receptor Agonists
- **Liraglutide**, **Semaglutide**, **Dulaglutide**:
  - Sulfonylurea/insulin dose reduction
  - Warfarin absorption effects

### DPP-4 Inhibitors
- **Sitagliptin**, **Vildagliptin**:
  - Digoxin level monitoring

### Insulins
- **All insulin types**:
  - Beta-blocker masking of hypoglycemia
  - ACE inhibitor enhanced sensitivity
  - Sulfonylurea combination warnings

## Caching

- API responses are cached for 24 hours to reduce network calls
- Cache can be cleared manually via `DrugInteractionService().clearCache()`

## Error Handling

- Network timeouts: 10-15 seconds per API call
- Graceful degradation: If APIs fail, local database still provides core checking
- Errors are logged via `debugPrint` for troubleshooting

## Future Enhancements

1. **DrugBank API Integration**: For even more comprehensive coverage
2. **Pharmacogenomics**: CYP450 enzyme interaction predictions
3. **Patient-specific Checking**: Consider age, weight, renal function
4. **Offline Mode**: Download interaction database for offline use
5. **Drug-Food Interactions**: Add food/alcohol interaction warnings
6. **Allergy Cross-reactivity**: Check for drug class allergies

## API Rate Limits

- **RxNav**: No authentication required, generous limits
- **OpenFDA**: 240 requests per minute per IP, 120,000 requests per day

## References

1. RxNav API Documentation: https://rxnav.nlm.nih.gov/RxNavAPIs.html
2. OpenFDA API: https://open.fda.gov/apis/drug/
3. DrugBank (future): https://go.drugbank.com/
