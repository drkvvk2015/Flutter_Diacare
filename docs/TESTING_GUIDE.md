# Testing Guide

## Overview
Comprehensive guide for writing and running tests in the DiaCare application.

## Test Types

### 1. Unit Tests
Test individual functions, classes, and methods in isolation.

**Location**: `test/unit/`

**Example**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:diacare/validators/form_validators.dart';

void main() {
  group('FormValidators', () {
    test('email validator should accept valid email', () {
      final result = FormValidators.email('test@example.com');
      expect(result, null);
    });

    test('email validator should reject invalid email', () {
      final result = FormValidators.email('invalid-email');
      expect(result, isNotNull);
    });
  });
}
```

### 2. Widget Tests
Test individual widgets and their behavior.

**Location**: `test/widgets/`

**Example**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:diacare/widgets/form_components.dart';
import '../helpers/test_helpers.dart';

void main() {
  testWidgets('EmailFormField should display email field', (tester) async {
    await tester.pumpWidget(
      makeTestableWidget(EmailFormField()),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}
```

### 3. Integration Tests
Test complete user flows and app features.

**Location**: `integration_test/`

**Example**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete login flow', (tester) async {
    // Launch app
    await tester.pumpWidget(MyApp());
    
    // Enter credentials
    await tester.enterText(find.byKey(Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password')), 'password123');
    
    // Tap login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    
    // Verify dashboard is shown
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

## Test Helpers

Located in `test/helpers/`:
- `test_helpers.dart` - Common test utilities
- `mock_data.dart` - Mock data for testing

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/validators/form_validators_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Generate Coverage Report
```bash
# Install lcov (if not already installed)
# On macOS: brew install lcov
# On Linux: sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

### Run Integration Tests
```bash
flutter test integration_test
```

## Mocking

### Using Mockito
```dart
import 'package:mockito/mockito.dart';

class MockPatientRepository extends Mock implements PatientRepository {}

void main() {
  late MockPatientRepository mockRepository;

  setUp(() {
    mockRepository = MockPatientRepository();
  });

  test('should return patients from repository', () async {
    // Arrange
    when(mockRepository.getPatients())
        .thenAnswer((_) async => [mockPatient]);

    // Act
    final patients = await mockRepository.getPatients();

    // Assert
    expect(patients.length, 1);
    verify(mockRepository.getPatients()).called(1);
  });
}
```

## Test Coverage Goals

- **Overall Coverage**: > 80%
- **Business Logic**: > 90%
- **UI Components**: > 70%
- **Utilities**: > 90%

## Best Practices

### 1. Arrange-Act-Assert Pattern
```dart
test('description', () {
  // Arrange - Set up test data
  final input = 'test';
  
  // Act - Execute the code
  final result = function(input);
  
  // Assert - Verify the result
  expect(result, expectedValue);
});
```

### 2. Use Descriptive Test Names
```dart
// Good
test('should return error when email is empty', () {});

// Bad
test('email test', () {});
```

### 3. One Assertion Per Test
```dart
// Good
test('should validate email format', () {
  final result = validateEmail('test@example.com');
  expect(result, isTrue);
});

test('should reject invalid email', () {
  final result = validateEmail('invalid');
  expect(result, isFalse);
});

// Avoid
test('email validation', () {
  expect(validateEmail('test@example.com'), isTrue);
  expect(validateEmail('invalid'), isFalse);
  expect(validateEmail(''), isFalse);
});
```

### 4. Setup and Teardown
```dart
void main() {
  late TestClass testClass;

  setUp(() {
    // Runs before each test
    testClass = TestClass();
  });

  tearDown(() {
    // Runs after each test
    testClass.dispose();
  });

  test('first test', () {
    // testClass is initialized
  });

  test('second test', () {
    // testClass is re-initialized
  });
}
```

### 5. Test Error Cases
```dart
test('should throw exception for invalid input', () {
  expect(
    () => function(null),
    throwsException,
  );
});
```

### 6. Use Test Groups
```dart
void main() {
  group('UserRepository', () {
    group('getUser', () {
      test('should return user when id is valid', () {});
      test('should throw error when id is invalid', () {});
    });

    group('saveUser', () {
      test('should save user successfully', () {});
      test('should throw error when data is invalid', () {});
    });
  });
}
```

## Testing Asynchronous Code

```dart
test('async operation', () async {
  final result = await asyncFunction();
  expect(result, expectedValue);
});
```

## Testing Streams

```dart
test('stream emits values', () async {
  final stream = getStream();
  
  expectLater(
    stream,
    emitsInOrder([value1, value2, value3]),
  );
});
```

## CI/CD Integration

Add to your CI/CD pipeline:

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v2
```

## Debugging Tests

### Run Tests in Debug Mode
```bash
flutter test --debug
```

### Print Debug Information
```dart
test('debug test', () {
  print('Debug info: $value');
  debugPrint('Widget tree: ${tester.widget}');
});
```

## Common Pitfalls

1. **Not waiting for async operations**
   ```dart
   // Bad
   test('async test', () {
     asyncFunction(); // Missing await
     expect(result, expectedValue);
   });
   
   // Good
   test('async test', () async {
     await asyncFunction();
     expect(result, expectedValue);
   });
   ```

2. **Not pumping widgets**
   ```dart
   // Bad
   testWidgets('widget test', (tester) async {
     await tester.pumpWidget(MyWidget());
     expect(find.text('Hello'), findsOneWidget); // May not find
   });
   
   // Good
   testWidgets('widget test', (tester) async {
     await tester.pumpWidget(MyWidget());
     await tester.pumpAndSettle(); // Wait for animations
     expect(find.text('Hello'), findsOneWidget);
   });
   ```

3. **Forgetting to dispose resources**
   ```dart
   tearDown(() {
     controller.dispose();
     subscription.cancel();
   });
   ```

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)

## Related Documentation
- [Architecture](ARCHITECTURE.md)
- [Development Setup](DEVELOPMENT_SETUP.md)
