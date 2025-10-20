import 'package:bloom/screens/nameScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedGenderSelectionScreen extends StatefulWidget {
  final String selectedAge;
  final Function(String)? onGenderSelected;

  const AnimatedGenderSelectionScreen({
    super.key,
    this.onGenderSelected,
    required this.selectedAge,
  });

  @override
  State<AnimatedGenderSelectionScreen> createState() =>
      _AnimatedGenderSelectionScreenState();
}

class _AnimatedGenderSelectionScreenState
    extends State<AnimatedGenderSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedGender;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

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
                    const SizedBox(height: 10),

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
                            Icons.people_outline,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "What's your gender?",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    const Padding(
                      padding: EdgeInsets.only(left: 44.0),
                      child: Text(
                        "This helps us personalize your experience",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4CAF50),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Gender options with animation
                    Expanded(
                      child: Column(
                        children: [
                          _buildAnimatedGenderOption(
                            gender: 'Male',
                            icon: Icons.male,
                            delay: 0,
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedGenderOption(
                            gender: 'Female',
                            icon: Icons.female,
                            delay: 100,
                          ),
                        ],
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

  Widget _buildAnimatedGenderOption({
    required String gender,
    required IconData icon,
    required int delay,
  }) {
    final isSelected = _selectedGender == gender;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeInOut,
      transform: Matrix4.translationValues(
        _fadeAnimation.value * 20 * (delay / 100),
        0,
        0,
      ),
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
              _selectedGender = gender;
            });
          },
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.green : Colors.green[700],
              size: 24,
            ),
          ),
          title: Text(
            gender,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.green,
            ),
          ),
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
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

  Widget _buildAnimatedSkipOption({required int delay}) {
    final isSelected = _selectedGender == 'Skip';

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeInOut,
      transform: Matrix4.translationValues(
        _fadeAnimation.value * 20 * (delay / 100),
        0,
        0,
      ),
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected ? Colors.green : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          onTap: () {
            setState(() {
              _selectedGender = 'Skip';
            });
          },
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: isSelected ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          title: Text(
            'Skip',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
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
    final isEnabled = _selectedGender != null;

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
    if (_selectedGender != null) {
      widget.onGenderSelected?.call(_selectedGender!);
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => AnimatedProfileInformationScreen(
            selectedAge: widget.selectedAge,
            selectedGender: _selectedGender!,
          ),
        ),
      );
    }
  }
}
