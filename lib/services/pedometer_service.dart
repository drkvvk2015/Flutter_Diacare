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
  late Stream<StepCount> _stepCountStream;

  int get steps => _steps;
  double get calories => _calories;
  DateTime get lastUpdate => _lastUpdate;

  void startListening({double weightKg = 70}) {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen((StepCount event) {
      _steps = event.steps;
      _lastUpdate = event.timeStamp;
      _calories = _calculateCalories(_steps, weightKg);
      notifyListeners();
    });
  }

  double _calculateCalories(int steps, double weightKg) {
    return steps * weightKg * 0.0004;
  }
}
