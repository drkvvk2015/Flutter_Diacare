// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatHiveAdapter extends TypeAdapter<ChatHive> {
  @override
  final int typeId = 2;

  @override
  ChatHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatHive(
      id: fields[0] as String,
      messages: (fields[1] as List)
          .map((dynamic e) => (e as Map).cast<String, String>())
          .toList(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatHive obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.messages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
