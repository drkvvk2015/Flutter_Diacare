/// Health Data Validators
/// 
/// Specialized validators for health-related measurements.
/// Ensures medical data falls within acceptable ranges.
library;

import '../constants/app_constants.dart';

/// Health data validators
class HealthValidators {
  HealthValidators._(); // Private constructor

  /// Blood pressure systolic validator
  static String? bloodPressureSystolic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Systolic BP is required';
    }

    final systolic = int.tryParse(value);
    if (systolic == null) {
      return 'Please enter a valid number';
    }

    if (systolic < AppConstants.minBPSystolic || 
        systolic > AppConstants.maxBPSystolic) {
      return 'Systolic BP must be between ${AppConstants.minBPSystolic} and ${AppConstants.maxBPSystolic}';
    }

    return null;
  }

  /// Blood pressure diastolic validator
  static String? bloodPressureDiastolic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Diastolic BP is required';
    }

    final diastolic = int.tryParse(value);
    if (diastolic == null) {
      return 'Please enter a valid number';
    }

    if (diastolic < AppConstants.minBPDiastolic || 
        diastolic > AppConstants.maxBPDiastolic) {
      return 'Diastolic BP must be between ${AppConstants.minBPDiastolic} and ${AppConstants.maxBPDiastolic}';
    }

    return null;
  }

  /// Heart rate validator
  static String? heartRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Heart rate is required';
    }

    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Please enter a valid number';
    }

    if (rate < AppConstants.minHeartRate || 
        rate > AppConstants.maxHeartRate) {
      return 'Heart rate must be between ${AppConstants.minHeartRate} and ${AppConstants.maxHeartRate} bpm';
    }

    return null;
  }

  /// Blood glucose validator
  static String? bloodGlucose(String? value) {
    if (value == null || value.isEmpty) {
      return 'Blood glucose is required';
    }

    final glucose = double.tryParse(value);
    if (glucose == null) {
      return 'Please enter a valid number';
    }

    if (glucose < AppConstants.minBloodGlucose || 
        glucose > AppConstants.maxBloodGlucose) {
      return 'Blood glucose must be between ${AppConstants.minBloodGlucose} and ${AppConstants.maxBloodGlucose} mg/dL';
    }

    return null;
  }

  /// Weight validator
  static String? weight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid number';
    }

    if (weight < AppConstants.minWeight || weight > AppConstants.maxWeight) {
      return 'Weight must be between ${AppConstants.minWeight} and ${AppConstants.maxWeight} kg';
    }

    return null;
  }

  /// Height validator
  static String? height(String? value) {
    if (value == null || value.isEmpty) {
      return 'Height is required';
    }

    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter a valid number';
    }

    if (height < AppConstants.minHeight || height > AppConstants.maxHeight) {
      return 'Height must be between ${AppConstants.minHeight} and ${AppConstants.maxHeight} cm';
    }

    return null;
  }

  /// Temperature validator (Celsius)
  static String? temperature(String? value) {
    if (value == null || value.isEmpty) {
      return 'Temperature is required';
    }

    final temp = double.tryParse(value);
    if (temp == null) {
      return 'Please enter a valid number';
    }

    if (temp < 30.0 || temp > 45.0) {
      return 'Temperature must be between 30°C and 45°C';
    }

    return null;
  }

  /// SpO2 (blood oxygen) validator
  static String? spo2(String? value) {
    if (value == null || value.isEmpty) {
      return 'SpO2 is required';
    }

    final spo2 = double.tryParse(value);
    if (spo2 == null) {
      return 'Please enter a valid number';
    }

    if (spo2 < 0 || spo2 > 100) {
      return 'SpO2 must be between 0 and 100%';
    }

    return null;
  }

  /// Steps validator
  static String? steps(String? value) {
    if (value == null || value.isEmpty) {
      return 'Steps are required';
    }

    final steps = int.tryParse(value);
    if (steps == null) {
      return 'Please enter a valid number';
    }

    if (steps < 0 || steps > 100000) {
      return 'Steps must be between 0 and 100,000';
    }

    return null;
  }

  /// Waist circumference validator
  static String? waistCircumference(String? value) {
    if (value == null || value.isEmpty) {
      return 'Waist circumference is required';
    }

    final waist = double.tryParse(value);
    if (waist == null) {
      return 'Please enter a valid number';
    }

    if (waist < 40 || waist > 200) {
      return 'Waist must be between 40 and 200 cm';
    }

    return null;
  }

  /// Hip circumference validator
  static String? hipCircumference(String? value) {
    if (value == null || value.isEmpty) {
      return 'Hip circumference is required';
    }

    final hip = double.tryParse(value);
    if (hip == null) {
      return 'Please enter a valid number';
    }

    if (hip < 50 || hip > 200) {
      return 'Hip must be between 50 and 200 cm';
    }

    return null;
  }
}
