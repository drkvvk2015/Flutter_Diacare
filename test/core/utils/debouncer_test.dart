/// Debouncer Tests
/// 
/// Tests for the Debouncer and Throttler classes.
library;

import 'package:flutter_diacare/core/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    test('should delay execution', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      var called = false;

      debouncer.run(() {
        called = true;
      });

      expect(called, false);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(called, true);
    });

    test('should cancel previous call when called multiple times', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      var callCount = 0;

      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1);
    });

    test('should cancel pending call', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      var called = false;

      debouncer.run(() {
        called = true;
      });
      debouncer.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(called, false);
    });
  });

  group('Throttler', () {
    test('should execute immediately on first call', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      var called = false;

      throttler.run(() {
        called = true;
      });

      expect(called, true);
    });

    test('should throttle subsequent calls', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      var callCount = 0;

      throttler.run(() => callCount++);
      throttler.run(() => callCount++);
      throttler.run(() => callCount++);

      expect(callCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      throttler.run(() => callCount++);
      expect(callCount, 2);
    });
  });
}

