import 'package:bloom/constants/colors.dart';
import 'package:bloom/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = false;
  bool _isLoading = true;
  List<String> _pendingNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    final pending = await NotificationService.getPendingNotifications();

    setState(() {
      _notificationsEnabled = enabled;
      _pendingNotifications = pending
          .map((n) => 'ID: ${n.id} - ${n.title ?? "No title"}')
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Request permissions and schedule
      final granted = await NotificationService.requestPermissions();
      if (granted) {
        await NotificationService.scheduleDailyMoodReminders();
        _showSnackBar('✅ Mood reminders enabled!', Colors.green);
      } else {
        _showSnackBar('❌ Permission denied', Colors.red);
      }
    } else {
      // Cancel all notifications
      await NotificationService.cancelAllNotifications();
      _showSnackBar('🔕 Mood reminders disabled', Colors.orange);
    }

    await _loadNotificationStatus();
  }

  Future<void> _testNotification() async {
    await NotificationService.showTestNotification();
    _showSnackBar('🧪 Test notification sent!', Colors.blue);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade900,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.green.shade700),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main toggle card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade100,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            BootstrapIcons.bell_fill,
                            color: Colors.green.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mood Reminders',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get daily reminders to log your mood',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeColor: Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Schedule info
                  Text(
                    'Notification Schedule',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildScheduleCard(
                    '🌅 Morning Check-in',
                    '9:00 AM',
                    'Start your day by logging your mood',
                  ),
                  const SizedBox(height: 12),
                  _buildScheduleCard(
                    '☀️ Midday Check-in',
                    '1:00 PM',
                    'Quick mood check during the day',
                  ),
                  const SizedBox(height: 12),
                  _buildScheduleCard(
                    '🌙 Evening Reflection',
                    '7:00 PM',
                    'Reflect on your day and log your mood',
                  ),

                  const SizedBox(height: 24),

                  // Test notification button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testNotification,
                      icon: const Icon(BootstrapIcons.bell),
                      label: Text(
                        'Send Test Notification',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Debug info (only show if there are pending notifications)
                  if (_pendingNotifications.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Pending Notifications (${_pendingNotifications.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _pendingNotifications
                            .map(
                              (n) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  n,
                                  style: GoogleFonts.sourceCodePro(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildScheduleCard(String title, String time, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
