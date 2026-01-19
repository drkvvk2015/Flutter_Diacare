# Development Setup Guide

## Prerequisites

- Flutter SDK (>= 3.3.0)
- Dart SDK (included with Flutter)
- Android Studio / VS Code
- Git
- Firebase CLI (for Firebase integration)

## Initial Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/flutter_diacare.git
cd flutter_diacare
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Environment Configuration

Create a `.env` file in the project root:
```env
# API Configuration
API_BASE_URL=https://api.example.com
API_VERSION=v1
API_TIMEOUT=30

# Firebase Configuration
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true

# Development
DEBUG_MODE=true
```

### 4. Firebase Setup

1. Create a Firebase project at [https://console.firebase.google.com](https://console.firebase.google.com)
2. Add Android and iOS apps to your Firebase project
3. Download configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
4. Configure Firebase CLI:
   ```bash
   npm install -g firebase-tools
   firebase login
   flutterfire configure
   ```

### 5. Generate Required Files

```bash
# Generate Hive adapters
flutter packages pub run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n
```

### 6. Run Code Analysis
```bash
flutter analyze
```

### 7. Run Tests
```bash
flutter test
```

## IDE Configuration

### VS Code

Install extensions:
- Flutter
- Dart
- Error Lens
- GitLens
- Prettier

Recommended `settings.json`:
```json
{
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "editor.rulers": [80],
  "dart.previewFlutterUiGuides": true,
  "dart.debugExternalPackageLibraries": true
}
```

### Android Studio

Install plugins:
- Flutter
- Dart
- Rainbow Brackets

## Running the App

### Development Mode
```bash
# Run on connected device
flutter run

# Run with specific flavor
flutter run --flavor development

# Run with hot reload
flutter run --hot
```

### Release Mode
```bash
flutter run --release
```

### Build APK
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

## Project Scripts

Located in `scripts/`:

### Build All Platforms
```bash
# Windows
powershell -ExecutionPolicy Bypass -File scripts/build-all.ps1

# Linux/Mac
./scripts/build-all.sh
```

### Setup Development Environment
```bash
powershell -ExecutionPolicy Bypass -File scripts/setup-dev.ps1
```

### Run Tests
```bash
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
```

## Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Follow code style guidelines
   - Write tests for new features
   - Update documentation

3. **Run Quality Checks**
   ```bash
   flutter analyze
   flutter test
   dart format .
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

5. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

## Code Style

### Naming Conventions
- Classes: `PascalCase`
- Files: `snake_case.dart`
- Variables/Functions: `camelCase`
- Constants: `UPPER_SNAKE_CASE`

### Documentation
```dart
/// Brief description of the class/function
///
/// Detailed explanation if needed.
///
/// Example:
/// ```dart
/// final result = myFunction('input');
/// ```
class MyClass {
  // ...
}
```

### Imports Order
1. Dart imports
2. Flutter imports
3. Package imports
4. Project imports

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/patient.dart';
import '../services/api_service.dart';
```

## Debugging

### Debug Mode
```bash
flutter run --debug
```

### Logging
```dart
import 'package:diacare/services/logger_service.dart';

logger.debug('Debug message');
logger.info('Info message');
logger.warning('Warning message');
logger.error('Error message', error: e, stackTrace: st);
```

### Performance Profiling
```bash
flutter run --profile
```

Open DevTools:
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## Troubleshooting

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

### Clear Cache
```bash
flutter pub cache repair
```

### Gradle Issues (Android)
```bash
cd android
./gradlew clean
cd ..
flutter run
```

### Pod Issues (iOS)
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

## Environment-Specific Configuration

### Development
```dart
const bool isDevelopment = true;
const String apiUrl = 'https://dev-api.example.com';
```

### Staging
```dart
const bool isDevelopment = false;
const String apiUrl = 'https://staging-api.example.com';
```

### Production
```dart
const bool isDevelopment = false;
const String apiUrl = 'https://api.example.com';
```

## Continuous Integration

### GitHub Actions

`.github/workflows/ci.yml`:
```yaml
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## Support

For issues or questions:
- Check [Issues](https://github.com/your-org/flutter_diacare/issues)
- Contact: dev-team@example.com

## Related Documentation
- [Architecture](ARCHITECTURE.md)
- [API Documentation](API_DOCUMENTATION.md)
- [Testing Guide](TESTING_GUIDE.md)
