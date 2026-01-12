import 'package:bloom/models/breathing_session.dart';
import 'package:bloom/services/db_service.dart';
import 'package:bloom/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class FlowerBreathScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final int? durationSeconds;
  final String technique;

  const FlowerBreathScreen({
    super.key,
    required this.onComplete,
    this.durationSeconds,
    this.technique = "Flower Breathing",
  });

  @override
  State<FlowerBreathScreen> createState() => _FlowerBreathScreenState();
}

class _FlowerBreathScreenState extends State<FlowerBreathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late FlutterTts _flutterTts; // Added

  final List<String> _breathInstructions = [
    "Breathe In...",
    "Hold...",
    "Breathe Out...",
    "Hold...",
  ];
  int _currentInstruction = 0;
  bool _isCompleted = false;
  bool _isMuted = false; // Added

  @override
  void initState() {
    super.initState();
    _initTts(); // Added

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16), // 4 seconds per phase
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.2),
        weight: 1,
      ), // Breathe in
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.2), weight: 1), // Hold
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.7),
        weight: 1,
      ), // Breathe out
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.7), weight: 1), // Hold
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _startBreathingCycle();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4); // Slower for calming effect
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakInstruction(String text) async {
    if (_isMuted || _isCompleted) return;
    // Clean text (remove ellipsis)
    final cleanText = text.replaceAll('.', '');
    await _flutterTts.speak(cleanText);
  }

  void _startBreathingCycle() {
    _controller.repeat();

    // Update instructions based on animation progress
    _controller.addListener(() {
      final phase = (_controller.value * 4).floor();
      if (phase != _currentInstruction) {
        setState(() {
          _currentInstruction = phase;
        });
        _speakInstruction(_breathInstructions[phase]); // Added
      }
    });

    _speakInstruction(
      _breathInstructions[0],
    ); // Added: Speak first instruction immediately

    // Calculate duration
    // Each cycle is 16 seconds.
    // Default is 3 cycles (48s).
    int targetDuration = 48;
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      // Round up to nearest full cycle to avoid abrupt stops
      int cycles = (widget.durationSeconds! / 16).ceil();
      if (cycles < 1) cycles = 1;
      targetDuration = cycles * 16;
    }

    Future.delayed(Duration(seconds: targetDuration), () {
      if (mounted) _finishSession();
    });
  }

  void _finishSession() {
    if (_isCompleted) return; // Prevent double call
    _controller.stop();
    _flutterTts.stop(); // Added
    _saveSession();
    setState(() {
      _isCompleted = true;
    });
  }

  Future<void> _saveSession() async {
    // Determine actual duration used
    int duration = 48;
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      int cycles = (widget.durationSeconds! / 16).ceil();
      if (cycles < 1) cycles = 1;
      duration = cycles * 16;
    }

    final session = BreathingSession(
      technique: widget.technique,
      durationSeconds: duration,
      timestamp: DateTime.now(),
      completed: true,
    );
    await HiveDBService.saveBreathingSession(session);
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop(); // Added
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionView();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.technique == "Box Breathing"
                  ? Colors.blue[50]!
                  : AppColors.bgGreen,
              widget.technique == "Box Breathing"
                  ? Colors.blue[100]!
                  : const Color(0xFFC8E6C9),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header with app name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Bloom",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    Row(
                      // Modified: Wrapped TextButton and added IconButton
                      children: [
                        IconButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.green[800],
                          ),
                          onPressed: () {
                            setState(() {
                              _isMuted = !_isMuted;
                              if (_isMuted) {
                                _flutterTts.stop();
                              }
                            });
                          },
                        ),
                        TextButton(
                          onPressed: widget.onComplete,
                          child: Text(
                            "Skip",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.green[800],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Flower breathing animation
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateAnimation.value,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Flower petals
                                  ...List.generate(8, (index) {
                                    return Transform.rotate(
                                      angle: (index * 3.14159 / 4),
                                      child: Container(
                                        width: 80,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            40,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                  // Center circle
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.orange[300],
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.eco,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 80),

                      // Current instruction
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          _breathInstructions[_currentInstruction],
                          key: ValueKey<int>(_currentInstruction),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[900],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Cycle counter
                      Text(
                        "Cycle ${((_controller.value * 4) ~/ 4) + 1}/3",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Visual guidance dots
                      _buildBreathDots(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Lottie.asset(
                'assets/animations/meditating.json',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Text(
                "Great Job!",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "You've completed your breathing session. Taking time for yourself is a powerful act of self-care.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Done",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: index == _currentInstruction ? 16 : 12,
          height: index == _currentInstruction ? 16 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentInstruction
                ? Colors.green[600]
                : Colors.green.withOpacity(0.3),
            boxShadow: index == _currentInstruction
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
