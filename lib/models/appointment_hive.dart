/// Appointment Hive Model
/// 
/// Hive-compatible data model for offline appointment storage.
/// Enables appointment management without internet connectivity.
/// 
/// Features:
/// - Patient-doctor appointment linking
/// - Status tracking
/// - Fee information
/// - Appointment notes
import 'package:hive/hive.dart';
part 'appointment_hive.g.dart';

/// Hive-annotated appointment model for local storage
/// 
/// TypeId: 1 - Unique identifier for Hive type system
@HiveType(typeId: 1)
class AppointmentHive extends HiveObject {
  /// Unique appointment identifier
  @HiveField(0)
  String id;
  
  /// Patient's unique ID
  @HiveField(1)
  String patientId;
  
  /// Doctor's unique ID
  @HiveField(2)
  String doctorId;
  
  /// Scheduled appointment time
  @HiveField(3)
  DateTime time;
  
  /// Appointment status (scheduled, completed, cancelled)
  @HiveField(4)
  String status;
  
  /// Optional appointment notes
  @HiveField(5)
  String? notes;
  
  /// Optional consultation fee
  @HiveField(6)
  double? fee;

  AppointmentHive({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.time,
    required this.status,
    this.notes,
    this.fee,
  });
}
