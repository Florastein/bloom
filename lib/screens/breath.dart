import 'package:flutter/material.dart';

class FlowerBreathScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const FlowerBreathScreen({super.key, required this.onComplete});

  @override
  State<FlowerBreathScreen> createState() => _FlowerBreathScreenState();
}

class _FlowerBreathScreenState extends State<FlowerBreathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  final List<String> _breathInstructions = [
    "Breathe In...",
    "Hold...",
    "Breathe Out...",
    "Hold...",
  ];
  int _currentInstruction = 0;

  @override
  void initState() {
    super.initState();

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

  void _startBreathingCycle() {
    _controller.repeat();

    // Update instructions based on animation progress
    _controller.addListener(() {
      final phase = (_controller.value * 4).floor();
      if (phase != _currentInstruction) {
        setState(() {
          _currentInstruction = phase;
        });
      }
    });

    // Auto-complete after 3 cycles
    Future.delayed(const Duration(seconds: 48), () {
      widget.onComplete();
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
      backgroundColor: const Color(0xFFE8F5E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header with app name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Bloom",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: const Text(
                      "Continue",
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
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
                                      width: 80 * _scaleAnimation.value,
                                      height: 120 * _scaleAnimation.value,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                    ),
                                  );
                                }),

                                // Center circle
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
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
                    Text(
                      _breathInstructions[_currentInstruction],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Cycle counter
                    Text(
                      "Cycle ${((_controller.value * 4) ~/ 4) + 1}/3",
                      style: const TextStyle(fontSize: 16, color: Colors.green),
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
    );
  }

  Widget _buildBreathDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentInstruction
                ? Colors.green
                : Colors.green.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}
