import 'package:hive/hive.dart';
part 'appointment_hive.g.dart';

@HiveType(typeId: 1)
class AppointmentHive extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String patientId;
  @HiveField(2)
  String doctorId;
  @HiveField(3)
  DateTime time;
  @HiveField(4)
  String status;
  @HiveField(5)
  String? notes;
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
