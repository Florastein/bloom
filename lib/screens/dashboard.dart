import 'package:bloom/data/mood_data.dart';
import 'package:bloom/models/mood_log.dart';
import 'package:bloom/presentation/screens/onboarding_screen.dart';
import 'package:bloom/screens/breath.dart';
import 'package:bloom/screens/chat.dart';
import 'package:bloom/screens/emergency.dart';
import 'package:bloom/screens/journal.dart';
import 'package:bloom/screens/userDetails.dart';
import 'package:bloom/services/db_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart' hide PopupCard;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "";
  String fullName = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeChatService();
  }

  Future<List<String>> getUsernames() async {
    try {
      final users = HiveDBService.getAllUsers();

      if (users.isEmpty) {
        return [];
      }

      return users
          .map((user) => user.name.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching usernames: $e');
      return [];
    }
  }

  Future<void> _initializeChatService() async {
    final List<String> usernames = await getUsernames();
    debugPrint("Usernames: ${usernames.toString()}");

    final String userName = usernames.isNotEmpty
        ? usernames.first.split(" ").first
        : 'User';

    final String fname = usernames.isNotEmpty ? usernames.first : 'User';

    setState(() {
      _userName = userName;
      fullName = fname;
      debugPrint("Username set: $_userName");
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Username: $_userName");
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with stats
              _buildHeader(_userName),
              const SizedBox(height: 30),

              // Welcome card
              _buildWelcomeCard(context),
              const SizedBox(height: 30),

              // Quick actions grid
              _buildQuickActions(context),
              const SizedBox(height: 30),

              // Recent moods section
              _buildRecentMoods(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bloom',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
                letterSpacing: 1,
              ),
            ),
          ],
        ),

        // Add profile icon or other header elements if needed
        /*Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  userName,
                  style: GoogleFonts.plusJakartaSans(color: Colors.green),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.green[800]),
              ),
            ),
          ],
        ),*/
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // User name on left
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                //color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Hi, $_userName",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.green[800],
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),

            // User icon on right
            GestureDetector(
              onTap: () {
                UserDetailsPopup.show(
                  context: context,
                  userName: fullName,
                  onEditProfile: () {
                    Navigator.of(context).pop();
                    showPopupCard(
                      context: context,
                      builder: (context) {
                        return PopupCard(
                          elevation: 8,
                          color: Colors.yellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('This is a popup card'),
                          ),
                        );
                      },
                      offset: const Offset(-16, 70),
                      alignment: Alignment.center,
                      useSafeArea: true,
                    );
                  },
                  onSettings: () {
                    Navigator.of(context).pop();
                    print('Open Settings');
                  },
                  onLogout: () {
                    Navigator.of(context).pop();
                    print('Logout user');
                  },
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.green[800], size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling now?',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tap below to start a chat – no login needed.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to chat screen
                Navigator.of(
                  context,
                ).push(CupertinoPageRoute(builder: (context) => ChatScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Start Chat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              icon: Icons.air,
              title: 'Breathe',
              color: Colors.blue,
              onTap: () {
                // Navigate to breathe exercises
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => FlowerBreathScreen(onComplete: () {}),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.sentiment_satisfied_alt,
              title: 'Mood',
              color: Colors.orange,
              onTap: () {
                // Navigate to mood tracking
                Navigator.of(context).push(
                  CupertinoDialogRoute(
                    builder: (context) => OnboardingScreen(),
                    context: context,
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.warning,
              title: 'Crisis',
              color: Colors.red,
              onTap: () {
                // Navigate to crisis resources
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (context) => EmergencyBottomSheet(),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.book,
              title: 'Journal',
              color: Colors.purple,
              onTap: () {
                // Navigate to journal
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => FloatingCardsJournal(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*Widget _buildRecentMoods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Moods',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.sentiment_neutral, size: 50, color: Colors.green[300]),
              const SizedBox(height: 12),
              Text(
                'No moods yet – tap "Mood" to add.',
                style: TextStyle(fontSize: 16, color: Colors.green[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to mood tracking
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => OnboardingScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.green[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Add Mood'),
              ),
            ],
          ),
        ),
      ],
    );
  }*/

  Widget _buildRecentMoods(BuildContext context) {
    final moods = HiveDBService.getAllMoodLogs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with improved styling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Moods',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[800],
                  letterSpacing: -0.5,
                ),
              ),
              if (moods.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${moods.length} ${moods.length == 1 ? 'entry' : 'entries'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (moods.isEmpty)
          _buildEmptyState(context)
        else
          _buildMoodsList(context, moods),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          // Mood preview icons
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: moodData.length,
              itemBuilder: (context, index) {
                final mood = moodData[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: mood.moodColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: mood.moodColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getMoodEmoji(mood.moodText),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Moods Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your emotional journey by adding your first mood entry.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) =>
                      const OnboardingScreen(), // Your mood selection screen
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Colors.green.withOpacity(0.3),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text(
                  'Add First Mood',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodsList(BuildContext context, List<MoodLog> moods) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: moods.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.green.withOpacity(0.1),
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final MoodLog mood = moods[index];
            final date = DateFormat(
              'MMM d, yyyy • hh:mm a',
            ).format(DateTime.parse(mood.timestamp));

            return _buildMoodItem(context, mood, date, index);
          },
        ),
      ),
    );
  }

  Widget _buildMoodItem(
    BuildContext context,
    MoodLog mood,
    String date,
    int index,
  ) {
    final moodData = _getMoodData(mood.mood);
    final moodColor = moodData.moodColor;

    return Dismissible(
      key: Key('mood_${mood.timestamp}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.delete, color: Colors.redAccent, size: 24),
                SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, mood.mood);
      },
      onDismissed: (direction) async {
        await HiveDBService.deleteMoodLog(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${mood.mood}" mood deleted'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // Note: You'd need to implement undo functionality
              },
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  moodColor.withOpacity(0.2),
                  moodColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: moodColor.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                _getMoodEmoji(mood.mood),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                mood.mood,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[900],
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: moodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getMoodIntensity(mood.mood),
                  style: TextStyle(
                    color: moodColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mood.note != null && mood.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    mood.note!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                date,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(Icons.more_vert, color: Colors.grey[600], size: 16),
            ),
            onPressed: () => _showMoodOptions(context, mood, index),
          ),
        ),
      ),
    );
  }

  // Helper method to get mood data from your predefined list
  MoodData _getMoodData(String mood) {
    return moodData.firstWhere(
      (data) => data.moodText.toLowerCase() == mood.toLowerCase(),
      orElse: () => MoodData(
        asset: '',
        moodText: mood,
        moodColor: Colors.grey,
        buttonText: 'Select',
        image: '',
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'very good!':
        return '😄';
      case 'good!':
        return '😊';
      case 'not good...':
        return '😕';
      case 'awful!':
        return '😞';
      case 'angry!':
        return '😠';
      default:
        return '😐';
    }
  }

  String _getMoodIntensity(String mood) {
    switch (mood.toLowerCase()) {
      case 'very good!':
        return 'HIGH';
      case 'good!':
        return 'MEDIUM';
      case 'not good...':
        return 'LOW';
      case 'awful!':
        return 'HIGH';
      case 'angry!':
        return 'HIGH';
      default:
        return 'MEDIUM';
    }
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    String mood,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Mood?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your "$mood" mood entry? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMoodOptions(BuildContext context, MoodLog mood, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue[700]),
              title: const Text('Edit Mood'),
              onTap: () {
                Navigator.pop(context);
                // Implement edit functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Delete Mood'),
              onTap: () async {
                Navigator.pop(context);
                final shouldDelete = await _showDeleteConfirmation(
                  context,
                  mood.mood,
                );
                if (shouldDelete) {
                  await HiveDBService.deleteMoodLog(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${mood.mood}" mood deleted'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
