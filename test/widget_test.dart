// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_diacare/main.dart';

void main() {
  testWidgets('Login screen renders with expected widgets', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DiacareApp());

    // Verify that the login screen title is present.
    expect(find.text('Doctor Login'), findsOneWidget);

    // Verify that Email and Password input fields are present.
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

    // Verify that Login button is present.
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
