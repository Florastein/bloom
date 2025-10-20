import 'package:bloom/screens/genderSelection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedAgeSelectionScreen extends StatefulWidget {
  final Function(String)? onAgeSelected;

  const AnimatedAgeSelectionScreen({super.key, this.onAgeSelected});

  @override
  State<AnimatedAgeSelectionScreen> createState() =>
      _AnimatedAgeSelectionScreenState();
}

class _AnimatedAgeSelectionScreenState extends State<AnimatedAgeSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedAge;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<String> _ageRanges = [
    'Under 18',
    '18-24',
    '25-34',
    '35-44',
    '45 and above',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F0),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Title with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "What's your age range?",
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Description
                    Padding(
                      padding: EdgeInsets.only(left: 60.0),
                      child: Text(
                        "Select the option that best describes you",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Color(0xFF4CAF50),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Age options with staggered animation
                    Expanded(
                      child: ListView.builder(
                        itemCount: _ageRanges.length,
                        itemBuilder: (context, index) {
                          final ageRange = _ageRanges[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 8,
                              left: _fadeAnimation.value * 20 * (index + 1),
                            ),
                            child: _buildAnimatedAgeOption(ageRange, index),
                          );
                        },
                      ),
                    ),

                    // Continue button
                    const SizedBox(height: 20),
                    _buildContinueButton(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedAgeOption(String ageRange, int index) {
    final isSelected = _selectedAge == ageRange;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 100)),
      curve: Curves.easeInOut,
      transform: Matrix4.translationValues(isSelected ? 10 : 0, 0, 0),
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected ? Colors.green : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          onTap: () {
            setState(() {
              _selectedAge = ageRange;
            });
          },
          title: Text(
            ageRange,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.green,
            ),
          ),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.white : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.grey,
                width: 2,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check, size: 16, color: Colors.green)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selectedAge != null;

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, isEnabled ? 0 : 10, 0),
        child: ElevatedButton(
          onPressed: isEnabled ? _continue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isEnabled ? 4 : 0,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isEnabled ? 'Continue' : 'Select an option',
              key: ValueKey(isEnabled),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  void _continue() {
    if (_selectedAge != null) {
      widget.onAgeSelected?.call(_selectedAge!);
      // Navigate to next screen
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) =>
              AnimatedGenderSelectionScreen(selectedAge: _selectedAge!),
        ),
      );
    }
  }
}
