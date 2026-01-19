/// Mock Data
/// 
/// Mock data for testing purposes.

import '../../lib/models/patient.dart';

/// Mock patient data
class MockData {
  MockData._();

  // Mock Patient
  static Patient get mockPatient => Patient(
        id: 'patient_1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '1234567890',
        dateOfBirth: DateTime(1990, 1, 1),
        gender: 'M',
        bloodGroup: 'O+',
        address: '123 Main St',
        emergencyContact: '0987654321',
        medicalHistory: ['Diabetes Type 2'],
        allergies: ['Penicillin'],
        currentMedications: ['Metformin'],
      );

  static List<Patient> get mockPatientList => [
        mockPatient,
        Patient(
          id: 'patient_2',
          name: 'Jane Smith',
          email: 'jane.smith@example.com',
          phone: '2345678901',
          dateOfBirth: DateTime(1985, 5, 15),
          gender: 'F',
          bloodGroup: 'A+',
          address: '456 Oak Ave',
          emergencyContact: '1234567890',
          medicalHistory: ['Hypertension'],
          allergies: [],
          currentMedications: ['Lisinopril'],
        ),
        Patient(
          id: 'patient_3',
          name: 'Bob Johnson',
          email: 'bob.johnson@example.com',
          phone: '3456789012',
          dateOfBirth: DateTime(1995, 12, 25),
          gender: 'M',
          bloodGroup: 'B+',
          address: '789 Pine Rd',
          emergencyContact: '2345678901',
          medicalHistory: [],
          allergies: ['Aspirin'],
          currentMedications: [],
        ),
      ];

  // Mock health data
  static Map<String, dynamic> get mockBloodGlucoseReading => {
        'id': 'reading_1',
        'patientId': 'patient_1',
        'value': 120.0,
        'unit': 'mg/dL',
        'timestamp': DateTime.now().toIso8601String(),
        'notes': 'Fasting',
      };

  static Map<String, dynamic> get mockBloodPressureReading => {
        'id': 'reading_2',
        'patientId': 'patient_1',
        'systolic': 120.0,
        'diastolic': 80.0,
        'unit': 'mmHg',
        'timestamp': DateTime.now().toIso8601String(),
        'notes': 'Morning reading',
      };

  // Mock appointment data
  static Map<String, dynamic> get mockAppointment => {
        'id': 'appointment_1',
        'patientId': 'patient_1',
        'doctorId': 'doctor_1',
        'patientName': 'John Doe',
        'doctorName': 'Dr. Smith',
        'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'time': '10:00 AM',
        'type': 'Consultation',
        'status': 'scheduled',
        'notes': 'Regular checkup',
      };

  static List<Map<String, dynamic>> get mockAppointmentList => [
        mockAppointment,
        {
          'id': 'appointment_2',
          'patientId': 'patient_2',
          'doctorId': 'doctor_2',
          'patientName': 'Jane Smith',
          'doctorName': 'Dr. Johnson',
          'date':
              DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          'time': '2:00 PM',
          'type': 'Follow-up',
          'status': 'scheduled',
          'notes': 'Check blood pressure',
        },
      ];

  // Mock user data
  static Map<String, dynamic> get mockUser => {
        'uid': 'user_1',
        'email': 'user@example.com',
        'displayName': 'Test User',
        'photoURL': null,
        'emailVerified': true,
        'role': 'patient',
      };

  // Mock API responses
  static Map<String, dynamic> get mockSuccessResponse => {
        'success': true,
        'message': 'Operation successful',
        'data': {},
      };

  static Map<String, dynamic> get mockErrorResponse => {
        'success': false,
        'message': 'Operation failed',
        'error': 'Something went wrong',
      };
}
