import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';

class StepData {
  StepData({required this.steps, required this.date, required this.calories});
  final int steps;
  final DateTime date;
  final double calories;
}

class PedometerService with ChangeNotifier {
  int _steps = 0;
  double _calories = 0;
  DateTime _lastUpdate = DateTime.now();
  Stream<StepCount>? _stepCountStream;
  bool _isSupported = false;

  int get steps => _steps;
  double get calories => _calories;
  DateTime get lastUpdate => _lastUpdate;
  
  /// Whether pedometer is supported on this platform
  bool get isSupported => _isSupported;

  void startListening({double weightKg = 70}) {
    // Pedometer is not supported on web platform
    if (kIsWeb) {
      debugPrint('[PedometerService] Not supported on web platform');
      _isSupported = false;
      return;
    }
    
    try {
      _isSupported = true;
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream?.listen(
        (StepCount event) {
          _steps = event.steps;
          _lastUpdate = event.timeStamp;
          _calories = _calculateCalories(_steps, weightKg);
          notifyListeners();
        },
        onError: (Object error) {
          debugPrint('[PedometerService] Error: $error');
          _isSupported = false;
        },
      );
    } catch (e) {
      debugPrint('[PedometerService] Failed to initialize: $e');
      _isSupported = false;
    }
  }

  double _calculateCalories(int steps, double weightKg) {
    return steps * weightKg * 0.0004;
  }
}
