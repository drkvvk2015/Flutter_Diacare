/// HTTP Interceptor
/// 
/// Interceptor pattern for HTTP requests and responses.
library;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base interceptor interface
abstract class HttpInterceptor {
  /// Called before request is sent
  Future<http.Request> onRequest(http.Request request);

  /// Called after response is received
  Future<http.Response> onResponse(http.Response response);

  /// Called when an error occurs
  Future<void> onError(Exception error);
}

/// Logging interceptor
class LoggingInterceptor implements HttpInterceptor {
  @override
  Future<http.Request> onRequest(http.Request request) async {
    debugPrint('→ ${request.method} ${request.url}');
    debugPrint('Headers: ${request.headers}');
    if (request.body.isNotEmpty) {
      debugPrint('Body: ${request.body}');
    }
    return request;
  }

  @override
  Future<http.Response> onResponse(http.Response response) async {
    debugPrint('← ${response.statusCode} ${response.request?.url}');
    debugPrint('Body: ${response.body}');
    return response;
  }

  @override
  Future<void> onError(Exception error) async {
    debugPrint('✗ Error: $error');
  }
}

/// Authentication interceptor
class AuthInterceptor implements HttpInterceptor {

  AuthInterceptor(this.getToken);
  final String Function() getToken;

  @override
  Future<http.Request> onRequest(http.Request request) async {
    final token = getToken();
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }

  @override
  Future<http.Response> onResponse(http.Response response) async {
    return response;
  }

  @override
  Future<void> onError(Exception error) async {
    // Handle authentication errors
  }
}

/// Retry interceptor
class RetryInterceptor implements HttpInterceptor {

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });
  final int maxRetries;
  final Duration retryDelay;
  int _retryCount = 0;

  @override
  Future<http.Request> onRequest(http.Request request) async {
    return request;
  }

  @override
  Future<http.Response> onResponse(http.Response response) async {
    if (response.statusCode >= 500 && _retryCount < maxRetries) {
      _retryCount++;
      await Future<void>.delayed(retryDelay);
      throw Exception('Retry needed');
    }
    _retryCount = 0;
    return response;
  }

  @override
  Future<void> onError(Exception error) async {
    // Handle retry errors
  }
}

/// Cache interceptor
class CacheInterceptor implements HttpInterceptor {

  CacheInterceptor({this.cacheDuration = const Duration(minutes: 5)});
  final Map<String, http.Response> _cache = {};
  final Duration cacheDuration;

  @override
  Future<http.Request> onRequest(http.Request request) async {
    if (request.method == 'GET') {
      final cached = _cache[request.url.toString()];
      if (cached != null) {
        // Return cached response
      }
    }
    return request;
  }

  @override
  Future<http.Response> onResponse(http.Response response) async {
    if (response.request?.method == 'GET' && response.statusCode == 200) {
      _cache[response.request!.url.toString()] = response;
    }
    return response;
  }

  @override
  Future<void> onError(Exception error) async {
    // Handle cache errors
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
  }

  /// Clear specific URL from cache
  void clearUrl(String url) {
    _cache.remove(url);
  }
}

