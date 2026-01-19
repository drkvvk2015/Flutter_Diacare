# DiaCare - API Layer

## Overview
The API layer provides a centralized HTTP client for all backend communications. It handles authentication, request/response interceptors, error handling, and retry logic.

## Components

### ApiClient
Central HTTP client for making API requests.

**Features:**
- Automatic authentication token injection
- Request/response logging (debug mode)
- Retry logic for failed requests
- Timeout handling
- Standardized error responses

**Usage:**
```dart
// Initialize
final apiClient = ApiClient();
apiClient.initialize(baseUrl: 'https://api.diacare.com');
apiClient.setAuthToken(token);

// GET request
final data = await apiClient.get('/users/profile');

// POST request
final response = await apiClient.post(
  '/appointments',
  body: {'doctorId': '123', 'dateTime': '2026-01-20T10:00:00'},
);

// PUT request
await apiClient.put('/users/profile', body: {'displayName': 'John Doe'});

// DELETE request
await apiClient.delete('/appointments/123');
```

### ApiEndpoints
Centralized endpoint definitions.

**Usage:**
```dart
// Use predefined endpoints
final url = ApiEndpoints.userProfile;
final doctorUrl = ApiEndpoints.doctorById('doctor-123');

// Access grouped endpoints
final loginUrl = ApiEndpoints.login;
final appointmentUrl = ApiEndpoints.createAppointment;
```

### API Exceptions
Structured exception types for error handling.

**Types:**
- `ApiException` - Base exception
- `NetworkException` - Network connectivity issues
- `AuthenticationException` - 401 errors
- `AuthorizationException` - 403 errors
- `NotFoundException` - 404 errors
- `ServerException` - 500+ errors
- `ValidationException` - 422 errors with field validation

**Usage:**
```dart
try {
  final data = await apiClient.get('/users/profile');
} on AuthenticationException catch (e) {
  // Handle auth error - redirect to login
} on NetworkException catch (e) {
  // Handle network error - show offline message
} on ApiException catch (e) {
  // Handle general API error
  print('Error: ${e.message} (${e.statusCode})');
}
```

## Configuration

### Initialization
```dart
void main() async {
  // Initialize API client
  ApiClient().initialize(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'https://api.diacare.com',
    timeout: const Duration(seconds: 30),
    maxRetries: 3,
    enableLogging: kDebugMode,
  );
  
  runApp(MyApp());
}
```

### Authentication
```dart
// Set token after login
final token = await authService.login(email, password);
ApiClient().setAuthToken(token);

// Clear token on logout
ApiClient().clearAuthToken();
```

## Best Practices

1. **Always use ApiEndpoints** for route definitions
2. **Handle specific exceptions** before general ApiException
3. **Use proper HTTP methods** (GET for reads, POST for creates, PUT for updates, DELETE for removals)
4. **Include try-catch blocks** for all API calls
5. **Check for null responses** when appropriate
6. **Use loading states** in UI while requests are in progress

## Error Handling Example

```dart
Future<void> loadUserData() async {
  try {
    setState(() => isLoading = true);
    
    final data = await apiClient.get(ApiEndpoints.userProfile);
    
    setState(() {
      userData = data;
      isLoading = false;
    });
  } on NetworkException catch (e) {
    showSnackBar('No internet connection');
  } on AuthenticationException catch (e) {
    navigateToLogin();
  } on ApiException catch (e) {
    showSnackBar('Error: ${e.message}');
  } finally {
    setState(() => isLoading = false);
  }
}
```
