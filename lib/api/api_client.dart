/// API Client
/// 
/// Centralized HTTP client for all API communications.
/// Provides request/response interceptors, error handling, and authentication.
/// 
/// Features:
/// - Automatic token refresh
/// - Request/response logging
/// - Error standardization
/// - Retry logic for failed requests
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/error/api_exception.dart';
import '../utils/logger.dart';

/// HTTP API client with interceptors and error handling
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _baseUrl;
  String? _authToken;
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Configuration
  Duration _timeout = const Duration(seconds: 30);
  int _maxRetries = 3;
  bool _enableLogging = kDebugMode;

  /// Initialize API client with base URL
  void initialize({
    required String baseUrl,
    Duration? timeout,
    int? maxRetries,
    bool? enableLogging,
  }) {
    _baseUrl = baseUrl;
    if (timeout != null) _timeout = timeout;
    if (maxRetries != null) _maxRetries = maxRetries;
    if (enableLogging != null) _enableLogging = enableLogging;
    
    logInfo('ApiClient initialized with baseUrl: $_baseUrl');
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    logInfo('Auth token updated');
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    logInfo('Auth token cleared');
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    return _executeRequest(
      () => _client.get(uri, headers: _buildHeaders(headers)),
      'GET',
      endpoint,
    );
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(endpoint);
    return _executeRequest(
      () => _client.post(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ),
      'POST',
      endpoint,
    );
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(endpoint);
    return _executeRequest(
      () => _client.put(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ),
      'PUT',
      endpoint,
    );
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    return _executeRequest(
      () => _client.delete(uri, headers: _buildHeaders(headers)),
      'DELETE',
      endpoint,
    );
  }

  /// Execute HTTP request with retry logic and error handling
  Future<Map<String, dynamic>> _executeRequest(
    Future<http.Response> Function() requestFn,
    String method,
    String endpoint,
  ) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        if (_enableLogging) {
          logInfo('$method $endpoint (attempt ${attempts + 1})');
        }

        final response = await requestFn().timeout(_timeout);

        if (_enableLogging) {
          logInfo('$method $endpoint - Status: ${response.statusCode}');
        }

        return _handleResponse(response);
      } on TimeoutException catch (e) {
        lastException = e;
        attempts++;
        if (attempts >= _maxRetries) {
          throw ApiException(
            'Request timeout after $_maxRetries attempts',
            statusCode: 408,
          );
        }
        await Future.delayed(Duration(seconds: attempts));
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Network error: $e');
      }
    }

    throw lastException ?? ApiException('Unknown error occurred');
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Success responses
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException('Invalid JSON response', statusCode: statusCode);
      }
    }

    // Error responses
    String errorMessage = 'Request failed';
    try {
      final errorData = jsonDecode(response.body);
      errorMessage = errorData['message'] ?? errorMessage;
    } catch (_) {
      errorMessage = response.body;
    }

    throw ApiException(errorMessage, statusCode: statusCode);
  }

  /// Build complete URI with query parameters
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    if (_baseUrl == null) {
      throw ApiException('API baseUrl not initialized');
    }

    final uri = Uri.parse('$_baseUrl$endpoint');
    
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }

    return uri;
  }

  /// Build request headers with authentication
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = Map<String, String>.from(_defaultHeaders);
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    
    return headers;
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
