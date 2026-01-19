import 'package:health/health.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Modern enhanced HealthService with analytics and robust error handling
class HealthService with ChangeNotifier {
  final Health _health = Health();
  bool _isInitialized = false;
  bool _isFetching = false;
  String? _lastError;

  // Health data with null safety and proper typing
  int _steps = 0;
  double _calories = 0.0;
  double _distance = 0.0;
  double? _heartRate;
  double? _spo2;
  double? _temperature;
  double? _bpSystolic;
  double? _bpDiastolic;
  double? _weight;
  double? _height;
  DateTime? _lastFetch;

  // Analytics and trends
  List<HealthDataPoint> _historicalData = [];
  final Map<HealthDataType, List<double>> _trends = {};

  // Getters with proper documentation
  /// Current step count for today
  int get steps => _steps;

  /// Calories burned today (in kcal)
  double get calories => _calories;

  /// Distance walked/run today (in meters)
  double get distance => _distance;

  /// Latest heart rate reading (beats per minute)
  double? get heartRate => _heartRate;

  /// Latest blood oxygen saturation (percentage)
  double? get spo2 => _spo2;

  /// Latest body temperature (Celsius)
  double? get temperature => _temperature;

  /// Latest systolic blood pressure (mmHg)
  double? get bpSystolic => _bpSystolic;

  /// Latest diastolic blood pressure (mmHg)
  double? get bpDiastolic => _bpDiastolic;

  /// Latest weight measurement (kg)
  double? get weight => _weight;

  /// Latest height measurement (cm)
  double? get height => _height;

  /// Timestamp of last successful data fetch
  DateTime? get lastFetch => _lastFetch;

  /// Whether the service is currently fetching data
  bool get isFetching => _isFetching;

  /// Whether the service has been successfully initialized
  bool get isInitialized => _isInitialized;

  /// Last error message, if any
  String? get lastError => _lastError;

  /// Historical health data for analytics
  List<HealthDataPoint> get historicalData =>
      List.unmodifiable(_historicalData);

  /// Health data trends by type
  Map<HealthDataType, List<double>> get trends => Map.unmodifiable(_trends);

  /// All supported health data types for this service
  static const List<HealthDataType> supportedTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
  ];

  /// Request authorization for health data access
  /// Returns true if authorization was granted
  Future<bool> requestAuthorization() async {
    try {
      logInfo('Requesting health data authorization');
      final authorized = await _health.requestAuthorization(supportedTypes);
      _isInitialized = authorized;
      _lastError = null;

      if (authorized) {
        logInfo('Health data authorization granted');
      } else {
        logWarn('Health data authorization denied');
      }

      notifyListeners();
      return authorized;
    } catch (e, stack) {
      _lastError = 'Authorization failed: ${e.toString()}';
      logError('Health authorization error', e, stack);
      notifyListeners();
      return false;
    }
  }

  /// Fetch today's health data with enhanced error handling
  Future<bool> fetchTodayData() async {
    if (!_isInitialized) {
      _lastError =
          'Health service not initialized. Call requestAuthorization first.';
      logWarn(_lastError!);
      return false;
    }

    if (_isFetching) {
      logInfo('Health data fetch already in progress');
      return false;
    }

    _isFetching = true;
    _lastError = null;
    notifyListeners();

    try {
      logInfo('Fetching today\'s health data');
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: supportedTypes,
      );

      await _processHealthData(data);

      _lastFetch = now;
      logInfo('Successfully fetched ${data.length} health data points');
      return true;
    } catch (e, stack) {
      _lastError = 'Failed to fetch health data: ${e.toString()}';
      logError('Health data fetch error', e, stack);
      return false;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Fetch historical health data for analytics (last 7 days)
  Future<bool> fetchWeeklyData() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      logInfo('Fetching weekly health data for analytics');
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final data = await _health.getHealthDataFromTypes(
        startTime: weekAgo,
        endTime: now,
        types: supportedTypes,
      );

      _historicalData = data;
      _calculateTrends();

      logInfo('Successfully fetched ${data.length} weekly health data points');
      return true;
    } catch (e, stack) {
      _lastError = 'Failed to fetch weekly data: ${e.toString()}';
      logError('Weekly health data fetch error', e, stack);
      return false;
    }
  }

  /// Process and update health data with proper error handling
  Future<void> _processHealthData(List<HealthDataPoint> data) async {
    try {
      _steps = _sumInt(data, HealthDataType.STEPS);
      _calories = _sumDouble(data, HealthDataType.ACTIVE_ENERGY_BURNED);
      _distance = _sumDouble(data, HealthDataType.DISTANCE_WALKING_RUNNING);
      _heartRate = _latestDouble(data, HealthDataType.HEART_RATE);
      _spo2 = _latestDouble(data, HealthDataType.BLOOD_OXYGEN);
      _temperature = _latestDouble(data, HealthDataType.BODY_TEMPERATURE);
      _bpSystolic = _latestDouble(data, HealthDataType.BLOOD_PRESSURE_SYSTOLIC);
      _bpDiastolic = _latestDouble(
        data,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      );
      _weight = _latestDouble(data, HealthDataType.WEIGHT);
      _height = _latestDouble(data, HealthDataType.HEIGHT);

      logInfo(
        'Processed health data: $_steps steps, ${_calories.toStringAsFixed(1)} cal',
      );
    } catch (e, stack) {
      logError('Error processing health data', e, stack);
      rethrow;
    }
  }

  /// Calculate health data trends for analytics
  void _calculateTrends() {
    _trends.clear();

    for (final type in supportedTypes) {
      final typeData = _historicalData
          .where((point) => point.type == type)
          .map((point) => (point.value as num).toDouble())
          .toList();

      if (typeData.isNotEmpty) {
        _trends[type] = typeData;
      }
    }
  }

  /// Get health score based on current vitals (0-100)
  int calculateHealthScore() {
    int score = 50; // Base score

    // Steps contribution (up to +20 points)
    if (_steps >= 10000) {
      score += 20;
    } else if (_steps >= 8000) {
      score += 15;
    } else if (_steps >= 5000) {
      score += 10;
    }

    // Heart rate contribution (±10 points)
    if (_heartRate != null) {
      if (_heartRate! >= 60 && _heartRate! <= 100) {
        score += 10;
      } else if (_heartRate! >= 50 && _heartRate! <= 120) {
        score += 5;
      } else {
        score -= 5;
      }
    }

    // Blood oxygen contribution (±10 points)
    if (_spo2 != null) {
      if (_spo2! >= 95) {
        score += 10;
      } else if (_spo2! >= 90) {
        score += 5;
      } else {
        score -= 10;
      }
    }

    // Blood pressure contribution (±10 points)
    if (_bpSystolic != null && _bpDiastolic != null) {
      if (_bpSystolic! <= 120 && _bpDiastolic! <= 80) {
        score += 10;
      } else if (_bpSystolic! <= 140 && _bpDiastolic! <= 90) {
        score += 5;
      } else {
        score -= 10;
      }
    }

    return score.clamp(0, 100);
  }

  /// Get health insights based on current data
  List<String> getHealthInsights() {
    final insights = <String>[];

    if (_steps < 5000) {
      insights.add('Consider increasing daily activity - aim for 8,000+ steps');
    } else if (_steps >= 10000) {
      insights.add('Great job! You\'ve reached your daily step goal');
    }

    if (_heartRate != null) {
      if (_heartRate! > 100) {
        insights.add('Heart rate is elevated - consider relaxation techniques');
      } else if (_heartRate! >= 60 && _heartRate! <= 100) {
        insights.add('Heart rate is in healthy range');
      }
    }

    if (_spo2 != null && _spo2! < 95) {
      insights.add(
        'Blood oxygen is low - consult healthcare provider if persistent',
      );
    }

    if (_bpSystolic != null && _bpDiastolic != null) {
      if (_bpSystolic! > 140 || _bpDiastolic! > 90) {
        insights.add('Blood pressure is elevated - monitor regularly');
      }
    }

    return insights;
  }

  /// Reset all health data
  void resetData() {
    _steps = 0;
    _calories = 0.0;
    _distance = 0.0;
    _heartRate = null;
    _spo2 = null;
    _temperature = null;
    _bpSystolic = null;
    _bpDiastolic = null;
    _weight = null;
    _height = null;
    _lastFetch = null;
    _lastError = null;
    _historicalData.clear();
    _trends.clear();

    notifyListeners();
  }

  /// Test-friendly method to set health values for testing
  @visibleForTesting
  void setTestValues({
    double? heartRate,
    double? spo2,
    double? bpSystolic,
    double? bpDiastolic,
    double? temperature,
    int? steps,
    double? calories,
    double? distance,
  }) {
    if (heartRate != null) {
      _heartRate = heartRate;
    }
    if (spo2 != null) {
      _spo2 = spo2;
    }
    if (bpSystolic != null) {
      _bpSystolic = bpSystolic;
    }
    if (bpDiastolic != null) {
      _bpDiastolic = bpDiastolic;
    }
    if (temperature != null) {
      _temperature = temperature;
    }
    if (steps != null) {
      _steps = steps;
    }
    if (calories != null) {
      _calories = calories;
    }
    if (distance != null) {
      _distance = distance;
    }
    notifyListeners();
  }

  /// Demo method to simulate health data (for demo purposes only)
  void simulateHealthData({
    double? heartRate,
    double? spo2,
    double? bpSystolic,
    double? bpDiastolic,
    double? temperature,
    int? steps,
    double? calories,
    double? distance,
  }) {
    if (heartRate != null) {
      _heartRate = heartRate;
    }
    if (spo2 != null) {
      _spo2 = spo2;
    }
    if (bpSystolic != null) {
      _bpSystolic = bpSystolic;
    }
    if (bpDiastolic != null) {
      _bpDiastolic = bpDiastolic;
    }
    if (temperature != null) {
      _temperature = temperature;
    }
    if (steps != null) {
      _steps = steps;
    }
    if (calories != null) {
      _calories = calories;
    }
    if (distance != null) {
      _distance = distance;
    }
    notifyListeners();
  }

  // Enhanced helper methods with better error handling
  int _sumInt(List<HealthDataPoint> data, HealthDataType type) {
    try {
      return data
          .where((d) => d.type == type)
          .fold(0, (sum, d) => sum + (d.value as num).toInt());
    } catch (e) {
      logError('Error summing int data for type $type', e);
      return 0;
    }
  }

  double _sumDouble(List<HealthDataPoint> data, HealthDataType type) {
    try {
      return data
          .where((d) => d.type == type)
          .fold(0.0, (sum, d) => sum + (d.value as num).toDouble());
    } catch (e) {
      logError('Error summing double data for type $type', e);
      return 0.0;
    }
  }

  double? _latestDouble(List<HealthDataPoint> data, HealthDataType type) {
    try {
      final filtered = data.where((d) => d.type == type).toList();

      if (filtered.isEmpty) {
        return null;
      }

      filtered.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      return (filtered.first.value as num).toDouble();
    } catch (e) {
      logError('Error getting latest double for type $type', e);
      return null;
    }
  }
}
