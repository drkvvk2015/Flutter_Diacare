import 'package:hive/hive.dart';
part 'patient_hive.g.dart';

@HiveType(typeId: 0)
class PatientHive extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String uhid;
  @HiveField(2)
  String name;

  PatientHive({required this.id, required this.uhid, required this.name});
}
