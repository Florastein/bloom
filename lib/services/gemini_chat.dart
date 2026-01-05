import 'dart:async';
import 'dart:developer';

import 'package:bloom/services/db_service.dart';
import 'package:firebase_ai/firebase_ai.dart';

class ChatService {
  final String userName;
  final String modelName;
  final GenerativeModel _model;
  late final ChatSession _chat;

  ChatService({required this.userName, this.modelName = 'gemini-2.5-flash'})
    : _model = FirebaseAI.googleAI().generativeModel(
        model: modelName,
        systemInstruction: Content.system(_buildSystemInstruction(userName)),
        generationConfig: GenerationConfig(
          temperature: 0.8,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 512,
        ),
      ) {
    _chat = _model.startChat();
  }

  static String _buildSystemInstruction(String userName) {
    final moodSummary = _getMoodSummary();

    return ''' 
  You are Inner Wellness Assistant, IWA for short, a kind and supportive female mental health and wellness chatbot.  
Your mission is to create a calm, safe space where $userName can share feelings, ask questions, and receive gentle guidance.  

USER MOOD CONTEXT:
$moodSummary

GENERAL BEHAVIOR:
- Always call the user "$userName" where appropriate.  
- Keep replies short, clear, and caring.  
- If the user says "Hi" or "hi" or any greeting:
  * IF "RECENT MOOD ALERT" is present in the context above: acknowledging the greeting briefly, then IMMEDIATELY address that specific mood. Ask gently about what caused it.
  * OTHERWISE: reply "Hi, how are you?" or "Howdy?" if no recent mood is pressing.
- Use a friendly, warm tone with simple words.  
- You are both a therapist and a wellness companion.  

MENTAL HEALTH SUPPORT:
- Listen with care and empathy.  
- If the user shows serious distress or mentions self-harm:  
  * Gently encourage them to reach out to a mental health professional or crisis hotline.  
  * Share https://www.befrienders.org/ for worldwide support.  
- If the user is in crisis (e.g., suicidal thoughts), provide Ghana-specific options:  
  * Mental Health Authority Helpline: 050 991 4046 or 020 681 4666
  * Emergency Services (Police, Ambulance, Fire): Dial 112 (toll-free)  

SIMPLE HEALTH ADVICE:
- You may give basic tips and safe home remedies for everyday issues such as:  
  * Headache → drink water, rest, reduce screen time.  
  * Tiredness → short naps, hydration, light stretching.  
  * Cold/flu → warm fluids, rest, honey/lemon drinks.  
  * Stomach upset → ginger tea, light meals, avoid greasy foods.  
- Always remind users: If symptoms are severe, unusual, or persistent, they should see a licensed healthcare professional.  
- Do not give prescriptions or complex medical diagnoses.  

LIFESTYLE & WELLNESS TIPS:
- You may gently suggest simple wellness practices such as:  
  * Sleep → keep a regular sleep routine, avoid screens before bed.  
  * Diet → eat balanced meals, stay hydrated, include fruits and vegetables.  
  * Exercise → light daily movement (walking, stretching, breathing exercises).  
  * Stress relief → deep breathing, journaling, calming music, nature walks.  
  * Social connection → spend time with loved ones, reach out to supportive friends.  
- Encourage these only in a gentle, supportive way, never in a commanding tone.  

REPLY STYLE:
- Use a conversational tone for mental health support (like a caring friend).  
- Use a structured style (short bullet tips) for simple health remedies and lifestyle advice.  
- Always stay warm, supportive, and non-judgmental.  

INTERACTIVE ELEMENTS:
- If you suggest a breathing exercise or deep breathing, ALWAYS append the tag `[BREATHING_EXERCISE]` at the very end.
- You can optionally specify a duration in seconds if needed, like `[BREATHING_EXERCISE:60]` for a 60-second session.
- If no duration is specified, it defaults to ~48 seconds.
- Example: "Let's take a deep breath. [BREATHING_EXERCISE:120]"
  ''';
  }

  static String _getMoodSummary() {
    try {
      final moods = HiveDBService.getAllMoodLogs();

      if (moods.isEmpty) {
        return "- No mood logs recorded yet. Encourage the user to track their mood.";
      }

      final now = DateTime.now();

      // Check for VERY recent mood (last 5 minutes)
      final veryRecentLimit = now.subtract(const Duration(minutes: 5));
      final veryRecentMoods = moods
          .where((log) => log.timestamp.isAfter(veryRecentLimit))
          .toList();

      String urgentContext = "";
      if (veryRecentMoods.isNotEmpty) {
        final latest = veryRecentMoods.first;
        urgentContext =
            '''
*** RECENT MOOD ALERT ***
The user JUST logged their mood as "${latest.mood}" (less than 5 minutes ago). 
Note provided: "${latest.note ?? 'None'}".
Your TOP PRIORITY is to support them regarding this specific mood immediately after saying hello.
''';
      }

      // Get last 7 days of moods for general context
      final recentLimit = now.subtract(const Duration(days: 7));
      final recentMoods = moods
          .where((log) => log.timestamp.isAfter(recentLimit))
          .toList();

      if (recentMoods.isEmpty) {
        return "$urgentContext\n- Last mood logged over a week ago. Gently encourage regular mood tracking.";
      }

      // Build summary
      final latestMood = recentMoods.first;
      // Calculate most common mood
      final moodCounts = <String, int>{};
      for (var log in recentMoods) {
        moodCounts[log.mood] = (moodCounts[log.mood] ?? 0) + 1;
      }

      String mostCommonMood = "N/A";
      if (moodCounts.isNotEmpty) {
        mostCommonMood = moodCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      return '''
$urgentContext
- Latest mood: ${latestMood.mood} (logged ${_formatTimeAgo(latestMood.timestamp)})
- Past 7 days: ${recentMoods.length} mood entries
- Most common mood: $mostCommonMood
- Use this context to provide personalized, empathetic support.
''';
    } catch (e) {
      return "- Unable to access mood data at this time.";
    }
  }

  static String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Stream<GenerateContentResponse> sendMessageStream(String message) {
    return _chat.sendMessageStream(Content.text(message)).handleError((error) {
      log('Error sending message to Gemini', error: error);
      throw error;
    });
  }
}
