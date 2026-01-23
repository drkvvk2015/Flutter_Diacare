// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_diacare/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts and shows splash', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const DiaCareApp());

    // Initial splash contents are visible
    expect(find.text('Loading DiaCare...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the splash timer elapse to avoid pending timer failures
    await tester.pump(const Duration(milliseconds: 700));
  });
}
