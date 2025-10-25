// Place the Patient, Anthropometry, BPReading, and SMBGReading classes here.
class Anthropometry {
  final double height; // cm
  final double weight; // kg
  final double bmi;
  final double waist;
  final double hip;
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

class BPReading {
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime date;

  const BPReading({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.date,
  });
}

class SMBGReading {
  final double fasting;
  final double preLunch;
  final double preDinner;
  final double postMeal;
  final DateTime date;

  const SMBGReading({
    required this.fasting,
    required this.preLunch,
    required this.preDinner,
    required this.postMeal,
    required this.date,
  });
}

class Patient {
  final String id;
  final String uhid;
  final String name;
  final List<Anthropometry> anthropometryHistory;
  final List<BPReading> bpHistory;
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
