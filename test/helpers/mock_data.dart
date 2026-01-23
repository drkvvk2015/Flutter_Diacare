/// Mock Data
/// 
/// Mock data for testing purposes.
library;

import 'package:flutter_diacare/models/patient.dart';

/// Mock patient data
class MockData {
  MockData._();

  // Mock Patient
  static Patient get mockPatient => const Patient(
        id: 'patient_1',
        uhid: 'UHID001',
        name: 'John Doe',
      );

  static List<Patient> get mockPatientList => [
        mockPatient,
        const Patient(
          id: 'patient_2',
          uhid: 'UHID002',
          name: 'Jane Smith',
        ),
        const Patient(
          id: 'patient_3',
          uhid: 'UHID003',
          name: 'Bob Johnson',
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
  static Map<String, dynamic> get mockSuccessResponse => <String, dynamic>{
        'success': true,
        'message': 'Operation successful',
        'data': <String, dynamic>{},
      };

  static Map<String, dynamic> get mockErrorResponse => {
        'success': false,
        'message': 'Operation failed',
        'error': 'Something went wrong',
      };
}
