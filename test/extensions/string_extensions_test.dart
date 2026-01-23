/// String Extensions Tests
/// 
/// Unit tests for string extensions
library;

import 'package:flutter_diacare/extensions/string_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('String Extensions Tests', () {
    group('capitalize', () {
      test('capitalizes first letter', () {
        expect('hello'.capitalize(), equals('Hello'));
        expect('HELLO'.capitalize(), equals('HELLO'));
        expect('h'.capitalize(), equals('H'));
      });

      test('handles empty string', () {
        expect(''.capitalize(), equals(''));
      });
    });

    group('capitalizeWords', () {
      test('capitalizes first letter of each word', () {
        expect('hello world'.capitalizeWords(), equals('Hello World'));
        expect('the quick brown fox'.capitalizeWords(), 
            equals('The Quick Brown Fox'),);
      });

      test('handles single word', () {
        expect('hello'.capitalizeWords(), equals('Hello'));
      });
    });

    group('isValidEmail', () {
      test('validates correct emails', () {
        expect('test@example.com'.isValidEmail, isTrue);
        expect('user.name@domain.co.uk'.isValidEmail, isTrue);
      });

      test('rejects invalid emails', () {
        expect('invalid'.isValidEmail, isFalse);
        expect('@example.com'.isValidEmail, isFalse);
        expect('test@'.isValidEmail, isFalse);
      });
    });

    group('isNumeric', () {
      test('validates numeric strings', () {
        expect('123'.isNumeric, isTrue);
        expect('123.45'.isNumeric, isTrue);
        expect('-123.45'.isNumeric, isTrue);
      });

      test('rejects non-numeric strings', () {
        expect('abc'.isNumeric, isFalse);
        expect('12.34.56'.isNumeric, isFalse);
      });
    });

    group('truncate', () {
      test('truncates long strings', () {
        expect('Hello World'.truncate(5), equals('He...'));
        expect('Test'.truncate(10), equals('Test'));
      });

      test('uses custom ellipsis', () {
        expect('Hello World'.truncate(5, ellipsis: '>>'), equals('Hel>>'));
      });
    });

    group('removeWhitespace', () {
      test('removes all whitespace', () {
        expect('hello world'.removeWhitespace(), equals('helloworld'));
        expect('  test  '.removeWhitespace(), equals('test'));
        expect('a b c d'.removeWhitespace(), equals('abcd'));
      });
    });

    group('toSnakeCase', () {
      test('converts to snake_case', () {
        expect('HelloWorld'.toSnakeCase(), equals('hello_world'));
        expect('testValue'.toSnakeCase(), equals('test_value'));
        expect('APIKey'.toSnakeCase(), equals('a_p_i_key'));
      });
    });

    group('toCamelCase', () {
      test('converts to camelCase', () {
        expect('hello_world'.toCamelCase(), equals('helloWorld'));
        expect('test-value'.toCamelCase(), equals('testValue'));
        expect('api key'.toCamelCase(), equals('apiKey'));
      });
    });

    group('toPascalCase', () {
      test('converts to PascalCase', () {
        expect('hello_world'.toPascalCase(), equals('HelloWorld'));
        expect('test-value'.toPascalCase(), equals('TestValue'));
        expect('api key'.toPascalCase(), equals('ApiKey'));
      });
    });

    group('toKebabCase', () {
      test('converts to kebab-case', () {
        expect('HelloWorld'.toKebabCase(), equals('hello-world'));
        expect('testValue'.toKebabCase(), equals('test-value'));
        expect('APIKey'.toKebabCase(), equals('a-p-i-key'));
      });
    });

    group('maskEmail', () {
      test('masks email addresses', () {
        expect('test@example.com'.maskEmail(), equals('te***@example.com'));
        expect('john.doe@domain.com'.maskEmail(), 
            equals('jo***@domain.com'),);
      });

      test('handles short names', () {
        expect('a@example.com'.maskEmail(), equals('a***@example.com'));
      });
    });

    group('maskPhone', () {
      test('masks phone numbers', () {
        expect('1234567890'.maskPhone(), equals('****7890'));
        expect('+1 (234) 567-8900'.maskPhone(), equals('****8900'));
      });
    });

    group('count', () {
      test('counts substring occurrences', () {
        expect('hello world hello'.count('hello'), equals(2));
        expect('aaa'.count('a'), equals(3));
        expect('test'.count('x'), equals(0));
      });

      test('handles empty substring', () {
        expect('hello'.count(''), equals(0));
      });
    });
  });
}
