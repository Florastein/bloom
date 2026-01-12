import 'package:bloom/firebase_options.dart';
import 'package:bloom/models/chat_message.dart';
import 'package:bloom/models/journal_entry.dart';
import 'package:bloom/models/breathing_session.dart';
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
import 'package:bloom/constants/colors.dart';

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
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(BreathingSessionAdapter());

  await Hive.openBox<ChatMessage>('chat_messages');
  await Hive.openBox<User>('users');
  await Hive.openBox<MoodLog>('mood_logs');

  // Open boxes for new features with correct types
  await Hive.openBox<JournalEntry>('journal_entries');
  await Hive.openBox<BreathingSession>('breathing_sessions');
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
            return const AnimatedSplashScreen(isChecking: true);
          }

          final isFirstLaunch = snapshot.data!;
          return AnimatedSplashScreen(
            isFirstLaunch: isFirstLaunch,
            isChecking: false,
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AnimatedSplashScreen extends StatefulWidget {
  final bool isFirstLaunch;
  final bool isChecking;

  const AnimatedSplashScreen({
    super.key,
    this.isFirstLaunch = false,
    this.isChecking = false,
  });

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

    // Only navigate if we are done checking and animations have some time to play
    if (!widget.isChecking) {
      _navigateToNext();
    }
  }

  @override
  void didUpdateWidget(AnimatedSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecking && !widget.isChecking) {
      _navigateToNext();
    }
  }

  void _navigateToNext() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => widget.isFirstLaunch
              ? const OnboardingFlow()
              : const DashboardScreen(),
        ),
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
      backgroundColor: AppColors.bgGreen,
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
                    gradient: LinearGradient(
                      colors: [AppColors.lightGreen, AppColors.primaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.spa, color: Colors.white, size: 70),
                ),
                const SizedBox(height: 25),
                Text(
                  'Bloom',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
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
