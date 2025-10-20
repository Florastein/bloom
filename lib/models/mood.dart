/*class MoodLog {
  final int? id;
  final String mood;
  final String? note;
  final DateTime timestamp;

  MoodLog({this.id, required this.mood, this.note, required this.timestamp});

  Map<String, dynamic> toMap() => {
    'id': id,
    'mood': mood,
    'note': note,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MoodLog.fromMap(Map<String, dynamic> map) => MoodLog(
    id: map['id'],
    mood: map['mood'],
    note: map['note'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}*/
