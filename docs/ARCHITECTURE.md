# Architecture Documentation

## Overview
DiaCare follows a clean architecture pattern with clear separation of concerns.

## Architecture Layers

### 1. Presentation Layer
- **Screens**: UI components and pages
- **Widgets**: Reusable UI components
- **ViewModels/Providers**: State management

### 2. Domain Layer
- **Models**: Data models and entities
- **Use Cases**: Business logic
- **Interfaces**: Abstract contracts

### 3. Data Layer
- **Repositories**: Data access abstraction
- **API**: Remote data sources
- **Local Storage**: Hive, SharedPreferences

## Directory Structure

```
lib/
├── api/                    # API client and networking
├── constants/              # App-wide constants
├── core/                   # Core utilities and base classes
│   ├── base/              # Base classes (ViewModel, Repository)
│   ├── error/             # Error handling
│   ├── network/           # Network utilities
│   └── utils/             # Utility functions
├── extensions/             # Dart extensions
├── features/               # Feature modules
├── l10n/                   # Localization files
├── models/                 # Data models
├── providers/              # State management
├── repositories/           # Data repositories
├── screens/                # UI screens
├── services/               # Services (Analytics, Logger, etc.)
├── themes/                 # App themes
├── utils/                  # Utilities
├── validators/             # Input validators
└── widgets/                # Reusable widgets
```

## Design Patterns

### 1. Repository Pattern
Abstracts data sources from business logic.

```dart
abstract class PatientRepository {
  Future<List<Patient>> getPatients();
  Future<Patient> getPatient(String id);
  Future<void> savePatient(Patient patient);
}
```

### 2. Provider Pattern
State management using Provider package.

```dart
class PatientProvider extends ChangeNotifier {
  List<Patient> _patients = [];
  
  Future<void> loadPatients() async {
    _patients = await repository.getPatients();
    notifyListeners();
  }
}
```

### 3. Singleton Pattern
Used for services like Logger, Analytics.

```dart
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();
}
```

## Data Flow

```
User Action → Widget → Provider/ViewModel → Repository → API/Storage
                ↓           ↓                   ↓            ↓
            UI Update ← State Change ← Data Transform ← Response
```

## Error Handling Strategy

1. **API Errors**: Caught in repositories, transformed to custom exceptions
2. **Business Logic Errors**: Handled in ViewModels
3. **UI Errors**: Displayed using ErrorBoundary and error widgets
4. **Global Errors**: Caught by GlobalErrorHandler

## State Management

We use Provider for state management:

- **Local State**: StatefulWidget with setState
- **Shared State**: Provider with ChangeNotifier
- **Global State**: Singleton services

## Testing Strategy

### Unit Tests
- Models
- Validators
- Utilities
- Repository logic

### Widget Tests
- Individual widgets
- Forms
- Dialogs

### Integration Tests
- User flows
- API integration
- End-to-end scenarios

## Performance Considerations

1. **Lazy Loading**: Load data on demand
2. **Caching**: Cache API responses
3. **Pagination**: Paginate large lists
4. **Image Optimization**: Use cached_network_image
5. **Build Optimization**: Use const constructors

## Security Best Practices

1. **Authentication**: JWT tokens stored securely
2. **API Keys**: Use environment variables
3. **Sensitive Data**: Encrypt with flutter_secure_storage
4. **Input Validation**: Validate all user inputs
5. **HTTPS**: All API calls use HTTPS

## Code Style

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

- Use meaningful names
- Keep functions small
- Document public APIs
- Use proper formatting
- Follow linter rules

## Development Workflow

1. Create feature branch
2. Implement feature following architecture
3. Write tests
4. Run linter and fix issues
5. Create pull request
6. Code review
7. Merge to main

## Related Documentation
- [API Documentation](API_DOCUMENTATION.md)
- [State Management](STATE_MANAGEMENT.md)
- [Testing Guide](TESTING_GUIDE.md)
