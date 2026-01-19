# DiaCare - Repositories

## Overview
Repositories provide an abstraction layer between the data sources (Firebase, API) and the application logic. They handle data fetching, caching, and transformation.

## Architecture

```
UI Layer (Providers/Screens)
         ↓
  Repository Layer
         ↓
Data Sources (Firebase, API, Local Storage)
```

## Available Repositories

### UserRepository
Manages user authentication and profile data.

**Methods:**
```dart
// Authentication
Future<User> login(String email, String password)
Future<User> register({required String email, required String password, required String displayName, String role})
Future<void> logout()

// Profile Management
Future<Map<String, dynamic>?> getUserProfile(String uid)
Future<void> updateUserProfile(String uid, Map<String, dynamic> data)

// Password Management
Future<void> changePassword({required String currentPassword, required String newPassword})
Future<void> sendPasswordResetEmail(String email)

// Account Management
Future<void> deleteAccount(String password)
```

**Usage Example:**
```dart
final userRepo = UserRepository();

// Login
try {
  final user = await userRepo.login('user@example.com', 'password123');
  print('Logged in as: ${user.email}');
} on AuthenticationException catch (e) {
  print('Login failed: ${e.message}');
}

// Update profile
await userRepo.updateUserProfile(userId, {
  'displayName': 'John Doe',
  'phoneNumber': '+1234567890',
});
```

### PatientRepository
Manages patient records and health data.

**Methods:**
```dart
// Patient CRUD
Future<List<Map<String, dynamic>>> getAllPatients()
Future<Map<String, dynamic>?> getPatientById(String patientId)
Future<String> createPatient(Map<String, dynamic> patientData)
Future<void> updatePatient(String patientId, Map<String, dynamic> updates)
Future<void> deletePatient(String patientId)

// Health Data
Future<void> addAnthropometryReading(String patientId, Anthropometry reading)
Future<void> addBPReading(String patientId, BPReading reading)
Future<void> addSMBGReading(String patientId, SMBGReading reading)

// History
Future<List<Anthropometry>> getAnthropometryHistory(String patientId, {int limit = 30})
Future<List<BPReading>> getBPHistory(String patientId, {int limit = 30})
Future<List<SMBGReading>> getSMBGHistory(String patientId, {int limit = 30})

// Search
Future<List<Map<String, dynamic>>> searchPatients(String query)
```

**Usage Example:**
```dart
final patientRepo = PatientRepository();

// Create patient
final patientId = await patientRepo.createPatient({
  'name': 'John Doe',
  'uhid': 'UHID001',
  'dateOfBirth': '1980-01-01',
  'gender': 'male',
});

// Add blood pressure reading
await patientRepo.addBPReading(
  patientId,
  BPReading(
    systolic: 120,
    diastolic: 80,
    pulse: 72,
    date: DateTime.now(),
  ),
);

// Get history
final bpHistory = await patientRepo.getBPHistory(patientId, limit: 7);
```

### AppointmentRepository
Manages appointment scheduling and tracking.

**Methods:**
```dart
// Appointment CRUD
Future<List<Map<String, dynamic>>> getAppointmentsByUser(String userId, String userRole)
Future<Map<String, dynamic>?> getAppointmentById(String appointmentId)
Future<String> createAppointment(Map<String, dynamic> appointmentData)
Future<void> updateAppointment(String appointmentId, Map<String, dynamic> updates)
Future<void> cancelAppointment(String appointmentId, String reason)

// Queries
Future<List<Map<String, dynamic>>> getUpcomingAppointments(String userId, String userRole)
Future<List<Map<String, dynamic>>> getPastAppointments(String userId, String userRole, {int limit = 20})
Future<List<Map<String, dynamic>>> getAppointmentsByDate(String userId, String userRole, DateTime date)

// Status Updates
Future<void> completeAppointment(String appointmentId, Map<String, dynamic>? notes)
```

**Usage Example:**
```dart
final appointmentRepo = AppointmentRepository();

// Create appointment
final appointmentId = await appointmentRepo.createAppointment({
  'patientId': 'patient-123',
  'doctorId': 'doctor-456',
  'dateTime': Timestamp.fromDate(DateTime(2026, 1, 20, 10, 0)),
  'type': 'consultation',
  'duration': 30,
});

// Get upcoming appointments
final upcoming = await appointmentRepo.getUpcomingAppointments(userId, 'doctor');

// Complete appointment
await appointmentRepo.completeAppointment(appointmentId, {
  'diagnosis': 'Type 2 Diabetes',
  'prescription': 'Metformin 500mg',
});
```

## Best Practices

1. **Always use repositories** instead of direct Firebase/API calls
2. **Handle errors at the repository level** when appropriate
3. **Return typed data** when possible
4. **Use consistent naming conventions**
5. **Log important operations** for debugging
6. **Implement caching** for frequently accessed data
7. **Use batch operations** for multiple writes

## Error Handling

Repositories should:
- Catch and log errors
- Re-throw with meaningful messages
- Use specific exception types

```dart
Future<Map<String, dynamic>?> getPatientById(String patientId) async {
  try {
    final doc = await _firestore.collection('patients').doc(patientId).get();
    
    if (!doc.exists) {
      logWarning('Patient not found: $patientId');
      return null;
    }

    return {'id': doc.id, ...doc.data()!};
  } catch (e) {
    logError('Error fetching patient', e);
    rethrow;
  }
}
```

## Testing

All repositories should have corresponding test files:
- `test/repositories/user_repository_test.dart`
- `test/repositories/patient_repository_test.dart`
- `test/repositories/appointment_repository_test.dart`

Use mocks for Firebase and API services.
