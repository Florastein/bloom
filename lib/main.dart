import 'package:bloom/firebase_options.dart';
import 'package:bloom/models/chat_message.dart';
import 'package:bloom/models/mood_log.dart';
import 'package:bloom/models/user.dart';
//import 'package:bloom/screens/breath.dart';
import 'package:bloom/screens/dashboard.dart';
import 'package:bloom/screens/onboarding_one.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp(); // ✅ Wait for Firebase + Hive
  runApp(const MyApp()); // ✅ Run app only after init completes
}

Future<void> _initializeApp() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(MoodLogMigrationAdapter());

  await Hive.openBox<ChatMessage>('chat_messages');
  await Hive.openBox<User>('users');
  await Hive.openBox<MoodLog>('mood_logs');

  // Open boxes for new features (using dynamic type for now)
  await Hive.openBox('journal_entries');
  await Hive.openBox('breathing_sessions');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
    }

    return isFirstLaunch;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: FutureBuilder<bool>(
        future: _checkFirstLaunch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // Show a very lightweight splash while waiting
            return const AnimatedSplashScreen();
          }

          final isFirstLaunch = snapshot.data!;
          return isFirstLaunch ? AnimatedSplashScreen() : DashboardScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // ✅ Safer navigation
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return; // 👈 prevent context use after dispose
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => const OnboardingFlow()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.lightGreen, Colors.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.spa, color: Colors.white, size: 70),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Bloom',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                    letterSpacing: 3,
                    fontFamily: 'PlayfairDisplay', // Use a elegant font
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
