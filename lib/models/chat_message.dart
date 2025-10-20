import 'package:hive_flutter/hive_flutter.dart';
part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String sender;

  @HiveField(1)
  String message;

  @HiveField(2)
  DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
  });
}
