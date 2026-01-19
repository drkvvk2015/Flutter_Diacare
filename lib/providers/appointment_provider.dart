/// Appointment State Management Provider
/// 
/// Manages appointment scheduling, filtering, and categorization.
/// Integrates with Firestore for persistent appointment data.
/// 
/// Features:
/// - Appointment CRUD operations
/// - Automatic categorization (upcoming/past)
/// - Date-based filtering
/// - Real-time appointment updates
/// - Role-based appointment queries
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive appointment state management provider
/// 
/// Handles all appointment-related operations including creation,
/// updates, filtering, and categorization for doctors and patients.
class AppointmentProvider extends ChangeNotifier {
  // Appointment lists organized by status
  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _pastAppointments = [];
  
  // Loading and error state
  bool _isLoading = false;
  String? _error;
  
  // Filter and date selection state
  AppointmentFilter _currentFilter = AppointmentFilter.all;
  DateTime _selectedDate = DateTime.now();

  // Public getters for appointment data
  List<AppointmentModel> get appointments => _appointments;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  List<AppointmentModel> get pastAppointments => _pastAppointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AppointmentFilter get currentFilter => _currentFilter;
  DateTime get selectedDate => _selectedDate;

  List<AppointmentModel> get todaysAppointments {
    final today = DateTime.now();
    return _appointments
        .where(
          (apt) =>
              apt.dateTime.year == today.year &&
              apt.dateTime.month == today.month &&
              apt.dateTime.day == today.day,
        )
        .toList();
  }

  int get totalAppointments => _appointments.length;
  int get todaysCount => todaysAppointments.length;
  int get upcomingCount => _upcomingAppointments.length;

  /// Initialize appointment provider for a specific user
  /// 
  /// Args:
  ///   userId: Unique identifier for the user
  ///   userRole: Role of the user ('doctor' or 'patient')
  Future<void> initialize(String userId, String userRole) async {
    _setLoading(true);
    await loadAppointments(userId, userRole);
    _setLoading(false);
  }

  /// Load appointments from Firestore
  Future<void> loadAppointments(String userId, String userRole) async {
    _setLoading(true);

    try {
      Query query = FirebaseFirestore.instance.collection('appointments');

      // Filter based on user role
      if (userRole == 'doctor') {
        query = query.where('doctorId', isEqualTo: userId);
      } else {
        query = query.where('patientId', isEqualTo: userId);
      }

      final snapshot = await query.orderBy('dateTime', descending: false).get();

      _appointments = snapshot.docs.map((doc) {
        return AppointmentModel.fromFirestore(doc);
      }).toList();

      _categorizeAppointments();
      _clearError();
    } catch (e) {
      _setError('Failed to load appointments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create new appointment
  Future<bool> createAppointment(AppointmentModel appointment) async {
    _setLoading(true);

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointment.toMap());

      // Update the appointment with the generated ID
      final newAppointment = appointment.copyWith(id: docRef.id);
      _appointments.add(newAppointment);
      _categorizeAppointments();

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update appointment
  Future<bool> updateAppointment(AppointmentModel appointment) async {
    _setLoading(true);

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment.id)
          .update(appointment.toMap());

      final index = _appointments.indexWhere((apt) => apt.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment;
        _categorizeAppointments();
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    _setLoading(true);

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.cancelled,
          cancellationReason: reason,
        );
        _categorizeAppointments();
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to cancel appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Complete appointment
  Future<bool> completeAppointment(
    String appointmentId, {
    String? notes,
    List<String>? prescriptions,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);

    try {
      final updateData = {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) updateData['notes'] = notes;
      if (prescriptions != null) updateData['prescriptions'] = prescriptions;
      if (additionalData != null) {
        for (final entry in additionalData.entries) {
          updateData[entry.key] = entry.value;
        }
      }

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update(updateData);

      final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.completed,
          notes: notes,
        );
        _categorizeAppointments();
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to complete appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set appointment filter
  void setFilter(AppointmentFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Get filtered appointments
  List<AppointmentModel> getFilteredAppointments() {
    switch (_currentFilter) {
      case AppointmentFilter.all:
        return _appointments;
      case AppointmentFilter.upcoming:
        return _upcomingAppointments;
      case AppointmentFilter.completed:
        return _appointments
            .where((apt) => apt.status == AppointmentStatus.completed)
            .toList();
      case AppointmentFilter.cancelled:
        return _appointments
            .where((apt) => apt.status == AppointmentStatus.cancelled)
            .toList();
      case AppointmentFilter.today:
        return todaysAppointments;
    }
  }

  /// Get appointments for specific date
  List<AppointmentModel> getAppointmentsForDate(DateTime date) {
    return _appointments
        .where(
          (apt) =>
              apt.dateTime.year == date.year &&
              apt.dateTime.month == date.month &&
              apt.dateTime.day == date.day,
        )
        .toList();
  }

  /// Get appointment statistics
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final thisMonth = _appointments
        .where(
          (apt) =>
              apt.dateTime.year == now.year && apt.dateTime.month == now.month,
        )
        .toList();

    return {
      'total': _appointments.length,
      'upcoming': _upcomingAppointments.length,
      'completed': _appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .length,
      'cancelled': _appointments
          .where((apt) => apt.status == AppointmentStatus.cancelled)
          .length,
      'thisMonth': thisMonth.length,
      'today': todaysCount,
      'completionRate': _calculateCompletionRate(),
    };
  }

  /// Calculate appointment completion rate
  double _calculateCompletionRate() {
    if (_appointments.isEmpty) return 0.0;

    final completed = _appointments
        .where((apt) => apt.status == AppointmentStatus.completed)
        .length;
    return (completed / _appointments.length) * 100;
  }

  /// Categorize appointments into upcoming and past
  void _categorizeAppointments() {
    final now = DateTime.now();

    _upcomingAppointments = _appointments
        .where(
          (apt) =>
              apt.dateTime.isAfter(now) &&
              apt.status != AppointmentStatus.cancelled,
        )
        .toList();

    _pastAppointments = _appointments
        .where(
          (apt) =>
              apt.dateTime.isBefore(now) ||
              apt.status == AppointmentStatus.completed,
        )
        .toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    debugPrint('AppointmentProvider Error: $error');
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Refresh appointments
  Future<void> refresh(String userId, String userRole) async {
    await loadAppointments(userId, userRole);
  }
}

/// Appointment model
class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final DateTime dateTime;
  final Duration duration;
  final AppointmentType type;
  final AppointmentStatus status;
  final String? notes;
  final String? cancellationReason;
  final Map<String, dynamic>? metadata;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.dateTime,
    this.duration = const Duration(minutes: 30),
    this.type = AppointmentType.consultation,
    this.status = AppointmentStatus.scheduled,
    this.notes,
    this.cancellationReason,
    this.metadata,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorName: data['doctorName'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      duration: Duration(minutes: data['duration'] ?? 30),
      type: AppointmentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AppointmentType.consultation,
      ),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AppointmentStatus.scheduled,
      ),
      notes: data['notes'],
      cancellationReason: data['cancellationReason'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'dateTime': Timestamp.fromDate(dateTime),
      'duration': duration.inMinutes,
      'type': type.name,
      'status': status.name,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    DateTime? dateTime,
    Duration? duration,
    AppointmentType? type,
    AppointmentStatus? status,
    String? notes,
    String? cancellationReason,
    Map<String, dynamic>? metadata,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Appointment type enumeration
enum AppointmentType {
  consultation,
  followUp,
  checkup,
  emergency,
  vaccination,
  surgery;

  String get displayName {
    switch (this) {
      case AppointmentType.consultation:
        return 'Consultation';
      case AppointmentType.followUp:
        return 'Follow-up';
      case AppointmentType.checkup:
        return 'Check-up';
      case AppointmentType.emergency:
        return 'Emergency';
      case AppointmentType.vaccination:
        return 'Vaccination';
      case AppointmentType.surgery:
        return 'Surgery';
    }
  }
}

/// Appointment status enumeration
enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}

/// Appointment filter enumeration
enum AppointmentFilter {
  all,
  upcoming,
  completed,
  cancelled,
  today;

  String get displayName {
    switch (this) {
      case AppointmentFilter.all:
        return 'All Appointments';
      case AppointmentFilter.upcoming:
        return 'Upcoming';
      case AppointmentFilter.completed:
        return 'Completed';
      case AppointmentFilter.cancelled:
        return 'Cancelled';
      case AppointmentFilter.today:
        return 'Today';
    }
  }
}
