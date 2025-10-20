import 'package:flutter/material.dart';

class MoodData {
  final String asset;
  final String moodText;
  final Color moodColor;
  final String buttonText;
  final String image;

  MoodData({
    required this.asset,
    required this.moodText,
    required this.moodColor,
    required this.buttonText,
    required this.image,
  });
}

final List<MoodData> moodData = [
  MoodData(
    asset: 'assets/verygood1.json',
    moodText: 'Very good!',
    moodColor: const Color(0xFF4CAF50),
    buttonText: 'Select',
    image: 'assets/emojis/verygood.png',
  ),
  MoodData(
    asset: 'assets/good.json',
    moodText: 'Good!',
    moodColor: const Color(0xFF8BC34A),
    buttonText: 'Select',
    image: 'assets/emojis/good.png',
  ),
  MoodData(
    asset: 'assets/notgood.json',
    moodText: 'Not good...',
    moodColor: const Color(0xFFFFC107),
    buttonText: 'Select',
    image: 'assets/emojis/notgood.png',
  ),
  MoodData(
    asset: 'assets/awful.json',
    moodText: 'Awful!',
    moodColor: const Color(0xFFFF9800),
    buttonText: 'Select',
    image: 'assets/emojis/awful.png',
  ),
  MoodData(
    asset: 'assets/angry.json',
    moodText: 'Angry!',
    moodColor: const Color(0xFFF44336),
    buttonText: 'Select',
    image: 'assets/emojis/angry.png',
  ),
];
