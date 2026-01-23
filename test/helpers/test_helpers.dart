/// Test Helpers
/// 
/// Common utilities and helpers for testing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Create a test widget wrapper with MaterialApp
Widget makeTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

/// Create a testable widget with theme
Widget makeTestableWidgetWithTheme(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    home: Scaffold(
      body: child,
    ),
  );
}

/// Pump and settle with a max duration
Future<void> pumpAndSettleWithTimeout(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(timeout);
}

/// Find widget by key
Finder findByKey(String key) {
  return find.byKey(Key(key));
}

/// Find widget by text
Finder findByText(String text) {
  return find.text(text);
}

/// Find widget by icon
Finder findByIcon(IconData icon) {
  return find.byIcon(icon);
}

/// Tap widget and settle
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Enter text and settle
Future<void> enterTextAndSettle(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Scroll until visible
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder,
  Finder scrollable, {
  double delta = 300.0,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: scrollable,
  );
}

/// Mock delayed response
Future<T> mockDelayedResponse<T>(
  T response, {
  Duration delay = const Duration(milliseconds: 100),
}) async {
  await Future<void>.delayed(delay);
  return response;
}

/// Mock error response
Future<T> mockErrorResponse<T>(
  Exception error, {
  Duration delay = const Duration(milliseconds: 100),
}) async {
  await Future<void>.delayed(delay);
  throw error;
}

