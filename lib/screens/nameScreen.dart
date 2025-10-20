import 'package:bloom/models/user.dart';
import 'package:bloom/screens/dashboard.dart';
import 'package:bloom/services/db_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_edge_alert/smart_edge_alert.dart';

class AnimatedProfileInformationScreen extends StatefulWidget {
  final Function(Map<String, String>)? onProfileCompleted;
  final String selectedAge;
  final String selectedGender;

  const AnimatedProfileInformationScreen({
    super.key,
    this.onProfileCompleted,
    required this.selectedAge,
    required this.selectedGender,
  });

  @override
  State<AnimatedProfileInformationScreen> createState() =>
      _AnimatedProfileInformationScreenState();
}

class _AnimatedProfileInformationScreenState
    extends State<AnimatedProfileInformationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _preferNotToSay = false;

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
    _nameController.dispose();
    _dayController.dispose();
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
                            Icons.person_2_outlined,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Tell us more about you",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Description
                    const Padding(
                      padding: EdgeInsets.only(left: 44.0),
                      child: Text(
                        "Help us personalize your experience",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4CAF50),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAnimatedSection(
                              title: "Your Name",
                              subtitle: "What should we call you?",
                              child: _buildNameField(),
                              delay: 0,
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
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

  Widget _buildAnimatedSection({
    required String title,
    required String subtitle,
    required Widget child,
    required int delay,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeInOut,
      transform: Matrix4.translationValues(
        _fadeAnimation.value * 20 * (delay / 100),
        0,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Color(0xFF4CAF50)),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: "Enter your name",
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        prefixIcon: Icon(Icons.person_outline, color: Colors.green[700]),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _canContinue();

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
              isEnabled ? 'Continue' : 'Fill in your details',
              key: ValueKey(isEnabled),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  bool _canContinue() {
    return _nameController.text.trim().isNotEmpty;
  }

  void _continue() async {
    if (_canContinue()) {
      final profileData = {'name': _nameController.text.trim()};
      widget.onProfileCompleted?.call(profileData);

      final user = User(
        name: _nameController.text.trim(),
        ageRange: widget.selectedAge,
        gender: widget.selectedGender,
        about: "",
      );

      await HiveDBService.saveUser(user);

      debugPrint(_nameController.text);
      debugPrint(widget.selectedAge);
      debugPrint(widget.selectedGender);

      SmartEdgeAlert.show(
        context,
        title: 'Data Saved Successfully',
        titleFontSize: 20,
        //description: 'Description',
        descriptionFontSize: 16,
        gravity: SmartEdgeAlert.top,
        closeButtonColor: Colors.white,
        duration: SmartEdgeAlert.lengthVeryLong,
      );
    }
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => DashboardScreen()),
    );
  }
}
