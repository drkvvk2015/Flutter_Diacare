/// Form Validators Tests
/// 
/// Unit tests for form validators

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_diacare/validators/form_validators.dart';

void main() {
  group('Form Validators Tests', () {
    group('Email Validator', () {
      test('valid email returns null', () {
        expect(Validators.email('test@example.com'), isNull);
        expect(Validators.email('user.name@domain.co.uk'), isNull);
        expect(Validators.email('test+tag@example.com'), isNull);
      });

      test('invalid email returns error message', () {
        expect(Validators.email('invalid'), isNotNull);
        expect(Validators.email('invalid@'), isNotNull);
        expect(Validators.email('@example.com'), isNotNull);
        expect(Validators.email('test@'), isNotNull);
      });

      test('empty email returns error message', () {
        expect(Validators.email(''), isNotNull);
        expect(Validators.email(null), isNotNull);
      });
    });

    group('Password Validator', () {
      test('valid password returns null', () {
        expect(Validators.password('Test123!@#'), isNull);
        expect(Validators.password('ValidPass1!'), isNull);
      });

      test('short password returns error', () {
        expect(Validators.password('Test1!'), isNotNull);
      });

      test('password without uppercase returns error', () {
        expect(Validators.password('test123!'), isNotNull);
      });

      test('password without lowercase returns error', () {
        expect(Validators.password('TEST123!'), isNotNull);
      });

      test('password without number returns error', () {
        expect(Validators.password('TestTest!'), isNotNull);
      });

      test('password without special char returns error', () {
        expect(Validators.password('Test1234'), isNotNull);
      });

      test('empty password returns error', () {
        expect(Validators.password(''), isNotNull);
        expect(Validators.password(null), isNotNull);
      });
    });

    group('Confirm Password Validator', () {
      test('matching passwords return null', () {
        expect(Validators.confirmPassword('Test123!', 'Test123!'), isNull);
      });

      test('non-matching passwords return error', () {
        expect(
          Validators.confirmPassword('Test123!', 'Different123!'),
          isNotNull,
        );
      });

      test('empty confirmation returns error', () {
        expect(Validators.confirmPassword('', 'Test123!'), isNotNull);
        expect(Validators.confirmPassword(null, 'Test123!'), isNotNull);
      });
    });

    group('Required Validator', () {
      test('non-empty value returns null', () {
        expect(Validators.required('value'), isNull);
      });

      test('empty value returns error', () {
        expect(Validators.required(''), isNotNull);
        expect(Validators.required('  '), isNotNull);
        expect(Validators.required(null), isNotNull);
      });

      test('custom field name in error message', () {
        final error = Validators.required('', fieldName: 'Username');
        expect(error, contains('Username'));
      });
    });

    group('Numeric Validator', () {
      test('valid numbers return null', () {
        expect(Validators.numeric('123'), isNull);
        expect(Validators.numeric('123.45'), isNull);
        expect(Validators.numeric('-123.45'), isNull);
      });

      test('non-numeric value returns error', () {
        expect(Validators.numeric('abc'), isNotNull);
        expect(Validators.numeric('12.34.56'), isNotNull);
      });
    });

    group('Range Validator', () {
      test('value in range returns null', () {
        expect(Validators.range('50', 0, 100), isNull);
        expect(Validators.range('0', 0, 100), isNull);
        expect(Validators.range('100', 0, 100), isNull);
      });

      test('value out of range returns error', () {
        expect(Validators.range('150', 0, 100), isNotNull);
        expect(Validators.range('-10', 0, 100), isNotNull);
      });

      test('non-numeric value returns error', () {
        expect(Validators.range('abc', 0, 100), isNotNull);
      });
    });

    group('Phone Validator', () {
      test('valid phone numbers return null', () {
        expect(Validators.phone('1234567890'), isNull);
        expect(Validators.phone('+1 (234) 567-8900'), isNull);
        expect(Validators.phone('+44 20 1234 5678'), isNull);
      });

      test('invalid phone numbers return error', () {
        expect(Validators.phone('123'), isNotNull);
        expect(Validators.phone('abcdefghij'), isNotNull);
      });
    });

    group('URL Validator', () {
      test('valid URLs return null', () {
        expect(Validators.url('https://example.com'), isNull);
        expect(Validators.url('http://www.example.com'), isNull);
        expect(Validators.url('https://example.com/path?query=value'), isNull);
      });

      test('invalid URLs return error', () {
        expect(Validators.url('example.com'), isNotNull);
        expect(Validators.url('ftp://example.com'), isNotNull);
        expect(Validators.url('not a url'), isNotNull);
      });
    });
  });
}
