# DiaCare - Constants

## Overview
Centralized constants for the entire application. Promotes consistency and makes updates easier.

## Files

### app_constants.dart
Application-wide configuration and limits.

**Categories:**
- App Information
- API Configuration
- Storage Keys
- Pagination
- Cache Configuration
- Health Data Limits
- Blood Glucose/Pressure Ranges
- BMI Categories
- Animation Durations
- File Upload Limits
- Appointment Settings
- Security Settings
- Date Formats
- Regular Expressions
- Standard Messages

**Usage:**
```dart
import 'package:flutter_diacare/constants/app_constants.dart';

// API configuration
ApiClient().initialize(
  baseUrl: AppConstants.apiBaseUrl,
  timeout: AppConstants.apiTimeout,
  maxRetries: AppConstants.maxRetries,
);

// Validation
if (bloodGlucose < AppConstants.minBloodGlucose || 
    bloodGlucose > AppConstants.maxBloodGlucose) {
  showError('Invalid blood glucose value');
}

// Storage
await storage.write(key: AppConstants.authTokenKey, value: token);

// Messages
showSuccessSnackBar(AppConstants.saveSuccess);
```

### ui_constants.dart
UI-related dimensions, spacing, and styling constants.

**Categories:**
- Spacing (xs, sm, md, lg, xl, 2xl)
- Border Radius
- Icon Sizes
- Font Sizes
- Button Heights
- Input Heights
- Card Styling
- App Bar Dimensions
- Avatar Sizes
- Progress Indicators
- Responsive Breakpoints
- Grid Settings
- Shadows
- Opacity Values
- Z-Index Layers

**Usage:**
```dart
import 'package:flutter_diacare/constants/ui_constants.dart';

// Spacing
Padding(
  padding: EdgeInsets.all(UIConstants.spacingMd),
  child: child,
)

// Border radius
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(UIConstants.radiusLg),
  ),
)

// Responsive design
final columns = context.isMobile 
    ? UIConstants.gridCrossAxisCountMobile
    : UIConstants.gridCrossAxisCountDesktop;

// Shadows
Container(
  decoration: BoxDecoration(
    boxShadow: UIConstants.shadowMd,
  ),
)
```

### routes.dart
Centralized route name definitions.

**Categories:**
- Authentication Routes
- Onboarding
- Main Dashboards
- Profile Routes
- Health Routes
- Appointment Routes
- Prescription Routes
- Patient Management
- Communication Routes
- Device Management
- Diagnostics
- Payments
- Exercise & Wellness
- Analytics & Monitoring
- Error & Info Pages

**Usage:**
```dart
import 'package:flutter_diacare/constants/routes.dart';

// Navigation
context.pushNamed(Routes.dashboard);
Navigator.of(context).pushNamed(Routes.patientProfile);

// Router configuration
routes: {
  Routes.login: (context) => LoginScreen(),
  Routes.dashboard: (context) => DashboardScreen(),
  Routes.patientProfile: (context) => PatientProfileScreen(),
}
```

## Best Practices

1. **Always use constants** instead of hardcoded values
2. **Group related constants** logically
3. **Use descriptive names** that explain the purpose
4. **Document units** (ms, px, kg, etc.) in comments
5. **Keep consistent naming** (camelCase for properties)
6. **Update in one place** - don't duplicate values
7. **Use type-safe constants** instead of strings where possible

## Adding New Constants

When adding new constants:

1. Choose the appropriate file
2. Add to the relevant section
3. Include a descriptive comment
4. Use consistent naming
5. Consider grouping related values

Example:
```dart
// In app_constants.dart

// Video Call Settings
static const int videoCallQuality = 720;
static const int videoCallFrameRate = 30;
static const Duration videoCallTimeout = Duration(minutes: 60);
static const int maxParticipants = 4;
```

## Environment-Specific Constants

For values that change between environments (dev/staging/prod), use `.env` files:

```dart
// .env
API_BASE_URL=https://api-dev.diacare.com
API_KEY=dev-key-123

// Access in code
final baseUrl = dotenv.env['API_BASE_URL'] ?? AppConstants.apiBaseUrl;
```

## Migration Guide

If you find hardcoded values in the codebase:

1. Identify the value and its purpose
2. Add it to the appropriate constants file
3. Replace all occurrences with the constant
4. Test thoroughly

Before:
```dart
if (value.length < 8) {
  return 'Password too short';
}
```

After:
```dart
if (value.length < AppConstants.minPasswordLength) {
  return 'Password too short';
}
```
