# API Documentation

## Overview
This directory contains the API client and related utilities for making HTTP requests to the backend server.

## Structure
```
api/
├── api_client.dart          # Main HTTP client
├── endpoints.dart           # API endpoint definitions
├── api_exception.dart       # Custom API exceptions
├── interceptors/
│   └── http_interceptor.dart # Request/response interceptors
└── models/
    └── api_response.dart    # Response models
```

## Usage

### Basic API Call
```dart
import 'package:diacare/api/api_client.dart';
import 'package:diacare/api/endpoints.dart';

final client = ApiClient();

// Initialize client
client.initialize(
  baseUrl: 'https://api.example.com',
  timeout: Duration(seconds: 30),
);

// Make GET request
final response = await client.get(Endpoints.patients);

// Make POST request
final response = await client.post(
  Endpoints.appointments,
  body: {'patientId': '123', 'date': '2024-01-15'},
);
```

### With Authentication
```dart
// Set auth token
client.setAuthToken('your-jwt-token');

// Make authenticated request
final response = await client.get(Endpoints.profile);
```

### With Interceptors
```dart
import 'package:diacare/api/interceptors/http_interceptor.dart';

// Add logging interceptor
final loggingInterceptor = LoggingInterceptor();

// Add auth interceptor
final authInterceptor = AuthInterceptor(() => getToken());

// Interceptors will automatically process all requests
```

### Error Handling
```dart
import 'package:diacare/api/api_exception.dart';

try {
  final response = await client.get(Endpoints.patients);
} on NetworkException catch (e) {
  print('Network error: ${e.message}');
} on ServerException catch (e) {
  print('Server error: ${e.statusCode} - ${e.message}');
} catch (e) {
  print('Unknown error: $e');
}
```

## Best Practices

1. **Always handle errors** - Use try-catch blocks for all API calls
2. **Use endpoints constants** - Don't hardcode URLs
3. **Set authentication** - Use `setAuthToken()` after login
4. **Check network connectivity** - Before making requests
5. **Use proper HTTP methods** - GET for read, POST for create, PUT for update, DELETE for delete

## Response Format

All API responses follow this structure:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {},
  "metadata": {
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

## Error Response Format
```json
{
  "success": false,
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE",
    "details": {}
  }
}
```

## Testing

See `test/api/` for API client tests.

## Related Documentation
- [Endpoints](endpoints.dart)
- [Error Handling](../core/error/README.md)
- [Repositories](../repositories/README.md)
