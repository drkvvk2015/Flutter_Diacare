/// Patient Data Models
/// 
/// Defines data structures for patient information and health measurements.
/// Includes anthropometry, blood pressure, and blood glucose tracking.
/// 
/// Models:
/// - Patient: Core patient information with health history
/// - Anthropometry: Body measurements (height, weight, BMI, etc.)
/// - BPReading: Blood pressure measurements
/// - SMBGReading: Self-Monitoring Blood Glucose readings

/// Anthropometry measurement model
/// 
/// Stores body measurements taken at a specific date.
/// Used for tracking patient's physical health over time.
class Anthropometry {
  /// Height in centimeters
  final double height;
  
  /// Weight in kilograms
  final double weight;
  
  /// Body Mass Index (calculated)
  final double bmi;
  
  /// Waist circumference in centimeters
  final double waist;
  
  /// Hip circumference in centimeters
  final double hip;
  
  /// Date of measurement
  final DateTime date;

  const Anthropometry({
    required this.height,
    required this.weight,
    required this.bmi,
    required this.waist,
    required this.hip,
    required this.date,
  });
}

/// Blood Pressure Reading model
/// 
/// Stores blood pressure measurements with pulse rate.
/// Tracks cardiovascular health over time.
class BPReading {
  /// Systolic blood pressure (mmHg)
  final int systolic;
  
  /// Diastolic blood pressure (mmHg)
  final int diastolic;
  
  /// Heart rate (beats per minute)
  final int pulse;
  
  /// Date and time of measurement
  final DateTime date;

  const BPReading({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.date,
  });
}

/// Self-Monitoring Blood Glucose Reading model
/// 
/// Stores multiple blood glucose measurements throughout the day.
/// Essential for diabetes management and insulin dosing decisions.
class SMBGReading {
  /// Fasting blood glucose (mg/dL)
  final double fasting;
  
  /// Pre-lunch blood glucose (mg/dL)
  final double preLunch;
  
  /// Pre-dinner blood glucose (mg/dL)
  final double preDinner;
  
  /// Post-meal blood glucose (mg/dL)
  final double postMeal;
  
  /// Date of readings
  final DateTime date;

  const SMBGReading({
    required this.fasting,
    required this.preLunch,
    required this.preDinner,
    required this.postMeal,
    required this.date,
  });
}

/// Patient model
/// 
/// Core patient information with complete health history.
/// Aggregates all health measurements and identifiers.
class Patient {
  /// Unique patient identifier
  final String id;
  
  /// Universal Health Identifier (hospital ID)
  final String uhid;
  
  /// Patient's full name
  final String name;
  
  /// Historical anthropometry measurements
  final List<Anthropometry> anthropometryHistory;
  
  /// Historical blood pressure readings
  final List<BPReading> bpHistory;
  
  /// Historical blood glucose readings
  final List<SMBGReading> smbgHistory;

  const Patient({
    required this.id,
    required this.uhid,
    required this.name,
    this.anthropometryHistory = const [],
    this.bpHistory = const [],
    this.smbgHistory = const [],
  });
}
