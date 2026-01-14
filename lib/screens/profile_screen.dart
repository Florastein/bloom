import 'package:bloom/constants/colors.dart';
import 'package:bloom/models/user.dart';
import 'package:bloom/models/mood_log.dart';
import 'package:bloom/models/journal_entry.dart';
import 'package:bloom/models/breathing_session.dart';
import 'package:bloom/models/chat_message.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Guest';
  String _currentMood = 'Calm';
  int _streak = 0;
  String _joinDate = 'New Member';
  String _affirmation = 'Welcome to your wellness journey';
  int _wellnessScore = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get user info
      final userBox = Hive.box<User>('users');
      if (userBox.isNotEmpty) {
        final user = userBox.values.first;
        _userName = user.name;
      }

      // Get mood logs
      final moodBox = Hive.box<MoodLog>('mood_logs');
      final moodLogs = moodBox.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Get latest mood
      if (moodLogs.isNotEmpty) {
        _currentMood = moodLogs.first.mood;

        // Calculate streak (consecutive days with mood logs)
        _streak = _calculateStreak(moodLogs);

        // Calculate join date from earliest mood log
        final earliestMood = moodLogs.last;
        _joinDate =
            'Member since ${DateFormat('MMM yyyy').format(earliestMood.timestamp)}';
      }

      // Get journal entries for affirmation
      final journalBox = Hive.box<JournalEntry>('journal_entries');
      final journalEntries = journalBox.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Use latest journal title as affirmation if available
      if (journalEntries.isNotEmpty && journalEntries.first.title.isNotEmpty) {
        _affirmation = journalEntries.first.title;
      }

      // Get breathing sessions
      final breathingBox = Hive.box<BreathingSession>('breathing_sessions');
      final breathingSessions = breathingBox.values
          .where((s) => s.completed)
          .toList();

      // Calculate wellness score
      _wellnessScore = _calculateWellnessScore(
        moodLogs: moodLogs,
        journalEntries: journalEntries,
        breathingSessions: breathingSessions,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateStreak(List<MoodLog> moodLogs) {
    if (moodLogs.isEmpty) return 0;

    int streak = 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if there's a mood log today or yesterday
    final latestDate = DateTime(
      moodLogs.first.timestamp.year,
      moodLogs.first.timestamp.month,
      moodLogs.first.timestamp.day,
    );

    final daysDiff = today.difference(latestDate).inDays;
    if (daysDiff > 1) return 0; // Streak broken

    // Count consecutive days
    for (int i = 0; i < moodLogs.length - 1; i++) {
      final currentDate = DateTime(
        moodLogs[i].timestamp.year,
        moodLogs[i].timestamp.month,
        moodLogs[i].timestamp.day,
      );
      final nextDate = DateTime(
        moodLogs[i + 1].timestamp.year,
        moodLogs[i + 1].timestamp.month,
        moodLogs[i + 1].timestamp.day,
      );

      final diff = currentDate.difference(nextDate).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }

    return streak;
  }

  int _calculateWellnessScore({
    required List<MoodLog> moodLogs,
    required List<JournalEntry> journalEntries,
    required List<BreathingSession> breathingSessions,
  }) {
    // Base score
    int score = 0;

    // Activity in last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final recentMoods = moodLogs
        .where((m) => m.timestamp.isAfter(sevenDaysAgo))
        .length;
    final recentJournals = journalEntries
        .where((j) => j.timestamp.isAfter(sevenDaysAgo))
        .length;
    final recentBreathing = breathingSessions
        .where((b) => b.timestamp.isAfter(sevenDaysAgo))
        .length;

    // Score based on recent activity (max 40 points)
    score += (recentMoods * 3).clamp(0, 15);
    score += (recentJournals * 5).clamp(0, 15);
    score += (recentBreathing * 2).clamp(0, 10);

    // Streak bonus (max 30 points)
    score += (_streak * 3).clamp(0, 30);

    // Overall engagement (max 30 points)
    final totalActivity =
        moodLogs.length + journalEntries.length + breathingSessions.length;
    score += (totalActivity ~/ 5).clamp(0, 30);

    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgGreen,
        body: Center(
          child: CircularProgressIndicator(color: Colors.green.shade700),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bloom',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade900,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Colors.green.shade800,
                      ),
                      onPressed: _openSettings,
                    ),
                  ],
                ),
              ),

              // Profile Avatar with Wellness Score
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade100,
                            Colors.lightBlue.shade100,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        BootstrapIcons.person_fill,
                        size: 52,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade300,
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              BootstrapIcons.fire,
                              size: 16,
                              color: Colors.amber.shade300,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_streak days',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // User Info with Mood Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _editUsername,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        BootstrapIcons.pencil,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getMoodColor(_currentMood).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getMoodIcon(_currentMood),
                      size: 16,
                      color: _getMoodColor(_currentMood),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentMood,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getMoodColor(_currentMood),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _affirmation,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.green.shade800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Wellness Score Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade300.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Wellness Score',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Icon(
                            BootstrapIcons.star_fill,
                            color: Colors.amber.shade300,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$_wellnessScore',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getScoreMessage(_wellnessScore),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _wellnessScore / 100,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber.shade300,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Activity Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: BootstrapIcons.heart_pulse,
                        title: 'Mood Logs',
                        value: '${Hive.box<MoodLog>('mood_logs').length}',
                        color: Colors.pink.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: BootstrapIcons.journal_text,
                        title: 'Journals',
                        value:
                            '${Hive.box<JournalEntry>('journal_entries').length}',
                        color: Colors.blue.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: BootstrapIcons.wind,
                        title: 'Breathing',
                        value:
                            '${Hive.box<BreathingSession>('breathing_sessions').values.where((s) => s.completed).length}',
                        color: Colors.teal.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Account Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsItem(
                      icon: BootstrapIcons.person_circle,
                      title: 'Profile Information',
                      subtitle: _joinDate,
                      onTap: _editProfileInfo,
                    ),
                    _buildSettingsItem(
                      icon: BootstrapIcons.gear,
                      title: 'App Settings',
                      subtitle: 'Notifications, theme, and more',
                      onTap: _openSettings,
                    ),
                    _buildSettingsItem(
                      icon: BootstrapIcons.bell,
                      title: 'Reminders',
                      subtitle: 'Set daily wellness reminders',
                      onTap: _openReminders,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Data & Privacy Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data & Privacy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsItem(
                      icon: BootstrapIcons.download,
                      title: 'Export Data',
                      subtitle: 'Download your wellness data',
                      onTap: _exportData,
                    ),
                    _buildSettingsItem(
                      icon: BootstrapIcons.shield_check,
                      title: 'Privacy Policy',
                      subtitle: 'How we protect your data',
                      onTap: _openPrivacyPolicy,
                    ),
                    _buildSettingsItem(
                      icon: BootstrapIcons.trash,
                      title: 'Clear Data',
                      subtitle: 'Delete all local data',
                      onTap: _confirmClearData,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Support Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsItem(
                      icon: BootstrapIcons.info_circle,
                      title: 'About Bloom',
                      subtitle: 'Version 1.0.0',
                      onTap: _showAbout,
                    ),
                    _buildSettingsItem(
                      icon: BootstrapIcons.chat_dots,
                      title: 'Help & Feedback',
                      subtitle: 'Get help or share feedback',
                      onTap: _openHelp,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.red : Colors.green).shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: (isDestructive ? Colors.red : Colors.green).shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Colors.red.shade700
                          : Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              BootstrapIcons.chevron_right,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreMessage(int score) {
    if (score >= 80) return 'Excellent! Keep it up!';
    if (score >= 60) return 'Good progress!';
    if (score >= 40) return 'Keep going!';
    return 'Start your journey today!';
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.amber.shade600;
      case 'calm':
        return Colors.green.shade600;
      case 'anxious':
        return Colors.orange.shade600;
      case 'energetic':
        return Colors.blue.shade600;
      case 'sad':
        return Colors.blue.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return BootstrapIcons.emoji_smile;
      case 'calm':
        return BootstrapIcons.emoji_sunglasses;
      case 'anxious':
        return BootstrapIcons.emoji_frown;
      case 'energetic':
        return BootstrapIcons.emoji_heart_eyes;
      case 'sad':
        return BootstrapIcons.emoji_tear;
      default:
        return BootstrapIcons.emoji_sunglasses;
    }
  }

  void _editUsername() {
    final TextEditingController controller = TextEditingController(
      text: _userName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Username',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: Colors.green.shade900,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _updateUsername(newName);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUsername(String newName) async {
    try {
      final userBox = Hive.box<User>('users');
      if (userBox.isNotEmpty) {
        final user = userBox.values.first;
        user.name = newName;
        await user.save();
      } else {
        // Create a new user if none exists
        await userBox.add(
          User(name: newName, ageRange: '', gender: '', about: ''),
        );
      }

      setState(() {
        _userName = newName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Username updated successfully!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error updating username: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update username',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _editProfileInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Profile Information',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: $_userName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _joinDate,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wellness Score: $_wellnessScore/100',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReminders() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminders feature coming soon!',
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _exportData() {
    final moodLogs = Hive.box<MoodLog>('mood_logs').length;
    final journals = Hive.box<JournalEntry>('journal_entries').length;
    final breathingSessions = Hive.box<BreathingSession>(
      'breathing_sessions',
    ).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Export Data',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your data summary:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text('• $moodLogs mood logs', style: GoogleFonts.plusJakartaSans()),
            Text(
              '• $journals journal entries',
              style: GoogleFonts.plusJakartaSans(),
            ),
            Text(
              '• $breathingSessions breathing sessions',
              style: GoogleFonts.plusJakartaSans(),
            ),
            const SizedBox(height: 12),
            Text(
              'Export functionality coming soon!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Bloom prioritizes your privacy. Your wellness data is stored locally on your device using Hive. '
            'AI chat interactions use secure Firebase services and Google Gemini API. '
            'We do not sell or share your personal information with third parties.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              BootstrapIcons.exclamation_triangle,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              'Clear All Data?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all your mood logs, journal entries, and breathing sessions. This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _clearAllData();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Delete All',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      await Hive.box<MoodLog>('mood_logs').clear();
      await Hive.box<JournalEntry>('journal_entries').clear();
      await Hive.box<BreathingSession>('breathing_sessions').clear();
      await Hive.box<ChatMessage>('chat_messages').clear();

      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All data cleared successfully',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error clearing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to clear data',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              BootstrapIcons.flower1,
              size: 48,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              'Bloom',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Version 1.0.0',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your AI-powered mental wellness companion. Track your mood, journal your thoughts, practice breathing exercises, and chat with an empathetic AI.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Help center coming soon!',
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/settings');
  }
}
