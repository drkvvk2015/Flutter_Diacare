/// Debouncer
/// 
/// Utility class for debouncing function calls.

import 'dart:async';

/// Debouncer for delaying function execution
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

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
  final Duration duration;
  Timer? _timer;
  bool _isThrottled = false;

  Throttler({this.duration = const Duration(milliseconds: 500)});

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
