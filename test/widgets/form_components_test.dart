/// Form Components Widget Tests
/// 
/// Tests for reusable form components.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_diacare/widgets/form_components.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('EmailFormField', () {
    testWidgets('should display email field', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const EmailFormField()),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('should accept valid email', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        makeTestableWidget(
          Form(
            child: EmailFormField(controller: controller),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.pump();

      expect(controller.text, 'test@example.com');
    });
  });

  group('PasswordFormField', () {
    testWidgets('should display password field', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const PasswordFormField()),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const PasswordFormField()),
      );

      final textField = tester.widget<TextField>(
        find.descendant(
          of: find.byType(TextFormField),
          matching: find.byType(TextField),
        ),
      );

      expect(textField.obscureText, true);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      final updatedTextField = tester.widget<TextField>(
        find.descendant(
          of: find.byType(TextFormField),
          matching: find.byType(TextField),
        ),
      );

      expect(updatedTextField.obscureText, false);
    });
  });

  group('FormSubmitButton', () {
    testWidgets('should display button with label', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          FormSubmitButton(
            label: 'Submit',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          FormSubmitButton(
            label: 'Submit',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('should be disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          FormSubmitButton(
            label: 'Submit',
            enabled: false,
            onPressed: () {},
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        makeTestableWidget(
          FormSubmitButton(
            label: 'Submit',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, true);
    });
  });

  group('FormSectionHeader', () {
    testWidgets('should display title', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const FormSectionHeader(title: 'Test Section'),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
    });

    testWidgets('should display subtitle when provided', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const FormSectionHeader(
            title: 'Test Section',
            subtitle: 'Test Subtitle',
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });
  });
}
