/// Debouncer
/// 
/// Utility class for debouncing function calls.
library;

import 'dart:async';

/// Debouncer for delaying function execution
class Debouncer {

  Debouncer({this.delay = const Duration(milliseconds: 500)});
  final Duration delay;
  Timer? _timer;

  /// Run the action after delay
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel pending action
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler for limiting function execution rate
class Throttler {

  Throttler({this.duration = const Duration(milliseconds: 500)});
  final Duration duration;
  Timer? _timer;
  bool _isThrottled = false;

  /// Run the action if not throttled
  void run(void Function() action) {
    if (!_isThrottled) {
      action();
      _isThrottled = true;
      _timer = Timer(duration, () {
        _isThrottled = false;
      });
    }
  }

  /// Dispose the throttler
  void dispose() {
    _timer?.cancel();
  }
}
