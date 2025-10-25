// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientHiveAdapter extends TypeAdapter<PatientHive> {
  @override
  final int typeId = 0;

  @override
  PatientHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientHive(
      id: fields[0] as String,
      uhid: fields[1] as String,
      name: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PatientHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.uhid)
      ..writeByte(2)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
