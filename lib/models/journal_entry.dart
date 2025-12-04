import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 3)
class JournalEntry extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  String? mood; // Optional mood tag

  JournalEntry({
    required this.title,
    required this.content,
    required this.timestamp,
    this.mood,
  });
}
