/// Base Repository Tests
/// 
/// Tests for the BaseRepository class.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_diacare/core/base/base_repository.dart';
import 'package:flutter_diacare/constants/error_messages.dart';

// Test repository implementation
class TestRepository extends BaseRepository {
  Future<String> testSuccessOperation() {
    return execute(
      operation: () async => 'success',
      errorMessage: 'Test failed',
    );
  }

  Future<String> testFailureOperation() {
    return execute(
      operation: () async => throw Exception('Test error'),
      errorMessage: 'Test operation failed',
    );
  }

  Future<Result<String>> testSuccessWithResult() {
    return executeWithResult(
      operation: () async => 'success',
      errorMessage: 'Test failed',
    );
  }

  Future<Result<String>> testFailureWithResult() {
    return executeWithResult(
      operation: () async => throw Exception('Test error'),
      errorMessage: 'Test operation failed',
    );
  }
}

void main() {
  late TestRepository repository;

  setUp(() {
    repository = TestRepository();
  });

  group('BaseRepository', () {
    test('execute should return success result', () async {
      final result = await repository.testSuccessOperation();
      expect(result, 'success');
    });

    test('execute should throw on failure', () async {
      expect(
        () => repository.testFailureOperation(),
        throwsException,
      );
    });

    test('executeWithResult should return success Result', () async {
      final result = await repository.testSuccessWithResult();
      expect(result.isSuccess, true);
      expect(result.data, 'success');
      expect(result.error, null);
    });

    test('executeWithResult should return failure Result', () async {
      final result = await repository.testFailureWithResult();
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.error, 'Test operation failed');
      expect(result.data, null);
    });
  });

  group('Result', () {
    test('Result.success should create success result', () {
      final result = Result.success('data');
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.data, 'data');
      expect(result.error, null);
    });

    test('Result.failure should create failure result', () {
      final exception = Exception('error');
      final result = Result.failure('Error message', exception);
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.error, 'Error message');
      expect(result.exception, exception);
      expect(result.data, null);
    });
  });
}
