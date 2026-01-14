/*import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

class ChatDBService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    return await _initDB();
  }

  static Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'chat_memory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp TEXT NOT NULL
          );
        ''');
      },
    );
  }

  static Future<void> saveMessage(String sender, String message, String timestamp) async {
    final db = await database;
    await db.insert('chat_messages', {
      'sender': sender,
      'message': message,
      'timestamp': timestamp,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllMessages() async {
    final db = await database;
    return await db.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
    );
  }

static Future<void> deleteMessage(String timestamp) async {
  final db = await database;
  await db.delete('chat_messages', where: 'timestamp = ?', whereArgs: [timestamp]);
}

}*/

/*import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class ChatDBService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    return await _initDB();
  }

  static Future<Database> _initDB() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'chat_memory.db');
    debugPrint('Database created at: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create chat_messages table
        await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sender TEXT NOT NULL,
          message TEXT NOT NULL,
          timestamp TEXT NOT NULL
        );
      ''');

        // Create users table
        await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          age_range TEXT NOT NULL,
          gender TEXT NOT NULL,
          about TEXT
        );
      ''');

        // Create mood_logs table
        await db.execute('''
        CREATE TABLE IF NOT EXISTS mood_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mood TEXT NOT NULL,
          note TEXT,
          timestamp TEXT NOT NULL
        );
      ''');
      },
    );
  }

  /// Chat operations
  static Future<void> saveMessage(
    String sender,
    String message,
    String timestamp,
  ) async {
    final db = await database;
    await db.insert('chat_messages', {
      'sender': sender,
      'message': message,
      'timestamp': timestamp,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllMessages() async {
    final db = await database;
    return await db.query('chat_messages', orderBy: 'timestamp ASC');
  }

  static Future<void> deleteMessage(String timestamp) async {
    final db = await database;
    await db.delete(
      'chat_messages',
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
  }

  /// User operations
  static Future<void> saveUser(
    String name,
    String ageRange,
    String gender,
    String about,
  ) async {
    final db = await database;
    await db.insert('users', {
      'name': name,
      'age_range': ageRange,
      'gender': gender,
      'about': about,
    });
  }

  /// Mood log operations
  static Future<void> saveMoodLog(
    String mood,
    String? note,
    String timestamp,
  ) async {
    final db = await database;
    await db.insert('mood_logs', {
      'mood': mood,
      'note': note,
      'timestamp': timestamp,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllMoodLogs() async {
    final db = await database;
    return await db.query('mood_logs', orderBy: 'timestamp DESC');
  }

  static Future<void> deleteMoodLog(int id) async {
    final db = await database;
    await db.delete('mood_logs', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteDatabaseFile() async {
    final dbPath =
        await getDatabasesPath(); // Better than getApplicationDocumentsDirectory()
    final path = join(dbPath, 'chat_memory.db');
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
      debugPrint('Old database deleted');
    } else {
      debugPrint('No database file found to delete');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  static Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}*/

import 'package:bloom/models/breathing_session.dart';
import 'package:bloom/models/chat_message.dart';
import 'package:bloom/models/journal_entry.dart';
import 'package:bloom/models/mood_log.dart';
import 'package:bloom/models/user.dart';
import 'package:hive/hive.dart';

class HiveDBService {
  /// Chat messages
  static Future<void> saveMessage(ChatMessage message) async {
    final box = Hive.box<ChatMessage>('chat_messages');
    await box.add(message);
  }

  static List<ChatMessage> getAllMessages() {
    final box = Hive.box<ChatMessage>('chat_messages');
    return box.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static Future<void> deleteMessage(int index) async {
    final box = Hive.box<ChatMessage>('chat_messages');
    await box.deleteAt(index);
  }

  /// Users
  static Future<void> saveUser(User user) async {
    final box = Hive.box<User>('users');
    await box.add(user);
  }

  static List<User> getAllUsers() {
    final box = Hive.box<User>('users');
    return box.values.toList();
  }

  static Future<void> deleteUser(int index) async {
    final box = Hive.box<User>('users');
    await box.deleteAt(index);
  }

  static String? getFirstUserName() {
    final users = getAllUsers();
    if (users.isEmpty) return null;
    return users.first.name;
  }

  /// Mood Logs
  static Future<void> saveMoodLog(MoodLog log) async {
    final box = Hive.box<MoodLog>('mood_logs');
    await box.add(log);
  }

  static List<MoodLog> getAllMoodLogs() {
    final box = Hive.box<MoodLog>('mood_logs');
    return box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> deleteMoodLog(int index) async {
    final box = Hive.box<MoodLog>('mood_logs');
    await box.deleteAt(index);
  }

  /// Get the timestamp of the last mood log
  static DateTime? getLastMoodLogTime() {
    final logs = getAllMoodLogs();
    if (logs.isEmpty) return null;
    return logs.first.timestamp; // Already sorted DESC
  }

  /// Delete all Hive boxes (optional, similar to delete database)
  static Future<void> deleteAllData() async {
    await Hive.box<ChatMessage>('chat_messages').clear();
    await Hive.box<User>('users').clear();
    await Hive.box<MoodLog>('mood_logs').clear();
  }

  /// Journal Entries
  static Future<void> saveJournalEntry(JournalEntry entry) async {
    final box = Hive.box<JournalEntry>('journal_entries');
    await box.add(entry);
  }

  static List<JournalEntry> getAllJournalEntries() {
    final box = Hive.box<JournalEntry>('journal_entries');
    return box.values.toList();
  }

  static Future<void> deleteJournalEntry(int index) async {
    final box = Hive.box<JournalEntry>('journal_entries');
    await box.deleteAt(index);
  }

  /// Breathing Sessions
  static Future<void> saveBreathingSession(BreathingSession session) async {
    final box = Hive.box<BreathingSession>('breathing_sessions');
    await box.add(session);
  }

  static List<BreathingSession> getAllBreathingSessions() {
    final box = Hive.box<BreathingSession>('breathing_sessions');
    return box.values.toList();
  }

  static Future<void> deleteBreathingSession(int index) async {
    final box = Hive.box<BreathingSession>('breathing_sessions');
    await box.deleteAt(index);
  }
}
