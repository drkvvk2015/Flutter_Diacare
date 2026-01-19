/// Patient Hive Model
/// 
/// Hive-compatible data model for offline patient storage.
/// Used for local caching and offline functionality.
/// 
/// Note: This is a simplified version of the Patient model
/// optimized for Hive's NoSQL structure.
import 'package:hive/hive.dart';
part 'patient_hive.g.dart';

/// Hive-annotated patient model for local storage
/// 
/// TypeId: 0 - Unique identifier for Hive type system
@HiveType(typeId: 0)
class PatientHive extends HiveObject {
  /// Unique patient identifier
  @HiveField(0)
  String id;
  
  /// Universal Health Identifier
  @HiveField(1)
  String uhid;
  
  /// Patient's full name
  @HiveField(2)
  String name;

  PatientHive({required this.id, required this.uhid, required this.name});
}
