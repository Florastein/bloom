import 'package:hive/hive.dart';

part 'breathing_session.g.dart';

@HiveType(typeId: 4)
class BreathingSession extends HiveObject {
  @HiveField(0)
  String technique; // e.g., "Flower Breathing", "Box Breathing"

  @HiveField(1)
  int durationSeconds;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  bool completed;

  BreathingSession({
    required this.technique,
    required this.durationSeconds,
    required this.timestamp,
    this.completed = true,
  });
}
