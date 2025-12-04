import 'package:hive/hive.dart';

part 'mood_log.g.dart';

@HiveType(typeId: 2)
class MoodLog extends HiveObject {
  @HiveField(0)
  String mood;

  @HiveField(1)
  String? note;

  @HiveField(2)
  DateTime timestamp;

  MoodLog({required this.mood, this.note, required this.timestamp});
}

// Custom adapter to handle migration from String to DateTime
class MoodLogMigrationAdapter extends TypeAdapter<MoodLog> {
  @override
  final int typeId = 2;

  @override
  MoodLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Handle timestamp migration: convert String to DateTime if needed
    dynamic timestampField = fields[2];
    DateTime timestamp;

    if (timestampField is String) {
      // Old format: timestamp was stored as String
      timestamp = DateTime.parse(timestampField);
    } else if (timestampField is DateTime) {
      // New format: timestamp is already DateTime
      timestamp = timestampField;
    } else {
      // Fallback: use current time
      timestamp = DateTime.now();
    }

    return MoodLog(
      mood: fields[0] as String,
      note: fields[1] as String?,
      timestamp: timestamp,
    );
  }

  @override
  void write(BinaryWriter writer, MoodLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.mood)
      ..writeByte(1)
      ..write(obj.note)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodLogMigrationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
