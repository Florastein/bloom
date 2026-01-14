import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:bloom/services/db_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with callback for notification taps
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    debugPrint('✅ Notification service initialized');
  }

  /// Request notification permissions (Android 13+)
  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    // Request notification permission
    final status = await Permission.notification.request();

    if (status.isGranted) {
      debugPrint('✅ Notification permission granted');
      return true;
    } else if (status.isDenied) {
      debugPrint('❌ Notification permission denied');
      return false;
    } else if (status.isPermanentlyDenied) {
      debugPrint('❌ Notification permission permanently denied');
      // Open app settings
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Schedule daily mood reminder notifications
  static Future<void> scheduleDailyMoodReminders() async {
    if (!_initialized) await initialize();

    // Cancel existing notifications first
    await _notifications.cancelAll();

    // Define notification times
    final notifications = [
      {
        'id': 1,
        'hour': 9,
        'minute': 0,
        'title': 'Good morning! 🌸',
        'body': 'How are you feeling today? Take a moment to log your mood.',
      },
      {
        'id': 2,
        'hour': 13,
        'minute': 0,
        'title': 'Midday Check-in 💚',
        'body': 'Time for a quick mood check-in! How\'s your day going?',
      },
      {
        'id': 3,
        'hour': 19,
        'minute': 0,
        'title': 'Evening Reflection 🌙',
        'body': 'How was your day? Log your mood and reflect on your journey.',
      },
    ];

    // Schedule each notification
    for (final notif in notifications) {
      await _scheduleDailyNotification(
        id: notif['id'] as int,
        hour: notif['hour'] as int,
        minute: notif['minute'] as int,
        title: notif['title'] as String,
        body: notif['body'] as String,
      );
    }

    debugPrint('✅ Scheduled ${notifications.length} daily mood reminders');
  }

  /// Schedule a single daily notification
  static Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    // Get current time
    final now = tz.TZDateTime.now(tz.local);

    // Schedule for today at the specified time
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      'mood_reminders',
      'Mood Reminders',
      channelDescription: 'Daily reminders to log your mood',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification to repeat daily
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'mood_reminder',
    );

    debugPrint(
      '📅 Scheduled notification #$id for ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
    );
  }

  /// Check if we should show a notification (based on last mood log)
  static bool shouldShowNotification() {
    final lastMoodTime = HiveDBService.getAllMoodLogs().isNotEmpty
        ? HiveDBService.getAllMoodLogs().first.timestamp
        : null;

    if (lastMoodTime == null) return true;

    // Don't show if user logged mood in the last 4 hours
    final hoursSinceLastLog = DateTime.now().difference(lastMoodTime).inHours;
    return hoursSinceLastLog >= 4;
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🔕 Cancelled all notifications');
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('🔕 Cancelled notification #$id');
  }

  /// Show an immediate test notification
  static Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'mood_reminders',
      'Mood Reminders',
      channelDescription: 'Daily reminders to log your mood',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Test Notification 🧪',
      'This is a test notification from Bloom!',
      notificationDetails,
      payload: 'test',
    );

    debugPrint('🧪 Showed test notification');
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    // TODO: Navigate to mood logging screen
    // This will be handled by the app's navigation system
    // For now, we just log the tap
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}
