import 'package:hive/hive.dart';

part 'mood_log.g.dart';

@HiveType(typeId: 2)
class MoodLog extends HiveObject {
  @HiveField(0)
  String mood; // Non-nullable String

  @HiveField(1)
  String? note; // Nullable String

  @HiveField(2)
  String timestamp; // Non-nullable String

  MoodLog({required this.mood, this.note, required this.timestamp});
  // Note: Uses named parameters with {}
}
