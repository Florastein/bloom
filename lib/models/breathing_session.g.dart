// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breathing_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BreathingSessionAdapter extends TypeAdapter<BreathingSession> {
  @override
  final int typeId = 4;

  @override
  BreathingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreathingSession(
      technique: fields[0] as String,
      durationSeconds: fields[1] as int,
      timestamp: fields[2] as DateTime,
      completed: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BreathingSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.technique)
      ..writeByte(1)
      ..write(obj.durationSeconds)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreathingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
