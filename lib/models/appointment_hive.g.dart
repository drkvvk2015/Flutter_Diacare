// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppointmentHiveAdapter extends TypeAdapter<AppointmentHive> {
  @override
  final int typeId = 1;

  @override
  AppointmentHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppointmentHive(
      id: fields[0] as String,
      patientId: fields[1] as String,
      doctorId: fields[2] as String,
      time: fields[3] as DateTime,
      status: fields[4] as String,
      notes: fields[5] as String?,
      fee: fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.doctorId)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.fee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
