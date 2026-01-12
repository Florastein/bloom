import 'package:bloom/services/db_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Widget displaying key statistics on the dashboard
class DashboardStatsCards extends StatefulWidget {
  const DashboardStatsCards({super.key});

  @override
  State<DashboardStatsCards> createState() => _DashboardStatsCardsState();
}

class _DashboardStatsCardsState extends State<DashboardStatsCards> {
  late Future<StatsData> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<StatsData> _loadStats() async {
    try {
      final [
        journalCount,
        chatSessionsThisWeek,
        breathingCount,
        moodStreak,
      ] = await Future.wait([
        _getJournalCount(),
        _getChatSessionsThisWeek(),
        _getBreathingCount(),
        _getMoodStreak(),
      ]);

      return StatsData(
        journalCount: journalCount,
        chatSessionsThisWeek: chatSessionsThisWeek,
        breathingCount: breathingCount,
        moodStreak: moodStreak,
      );
    } catch (e) {
      // Return default values on error
      return const StatsData();
    }
  }

  Future<int> _getJournalCount() async {
    try {
      final entries = HiveDBService.getAllJournalEntries();
      return entries.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getChatSessionsThisWeek() async {
    try {
      final messages = HiveDBService.getAllMessages();
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartMidnight = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );

      // Count unique days with chat messages this week
      final daysWithChats = <String>{};
      for (var message in messages) {
        if (message.timestamp.isAfter(weekStartMidnight)) {
          final dateKey = DateFormat('yyyy-MM-dd').format(message.timestamp);
          daysWithChats.add(dateKey);
        }
      }

      return daysWithChats.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getBreathingCount() async {
    try {
      final sessions = HiveDBService.getAllBreathingSessions();
      return sessions.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getMoodStreak() async {
    try {
      final moods = HiveDBService.getAllMoodLogs();
      if (moods.isEmpty) return 0;

      // Sort moods by date (newest first)
      final sortedMoods = moods.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Check if there's a mood logged today
      final latestMoodDate = DateTime(
        sortedMoods.first.timestamp.year,
        sortedMoods.first.timestamp.month,
        sortedMoods.first.timestamp.day,
      );

      if (latestMoodDate.isBefore(todayDate)) {
        // No mood today, streak is broken
        return 0;
      }

      // Create a set of all dates with moods for O(1) lookups
      final moodDates = <String>{};
      for (var mood in sortedMoods) {
        final dateKey = DateFormat('yyyy-MM-dd').format(mood.timestamp);
        moodDates.add(dateKey);
      }

      // Count consecutive days backwards from today
      int streak = 0;
      DateTime checkDate = todayDate;
      final dateFormat = DateFormat('yyyy-MM-dd');

      while (true) {
        final dateKey = dateFormat.format(checkDate);
        if (moodDates.contains(dateKey)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, size: 20, color: Colors.green[700]),
                onPressed: () => setState(() {
                  _statsFuture = _loadStats();
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Refresh stats',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<StatsData>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingGrid();
            }

            if (snapshot.hasError) {
              return _buildErrorState(context);
            }

            final stats = snapshot.data ?? const StatsData();

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _StatCard(
                  icon: Icons.book_outlined,
                  title: 'Journal Entries',
                  value: stats.journalCount.toString(),
                  color: Colors.purple,
                  isLoading: false,
                ),
                _StatCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat Sessions',
                  value: stats.chatSessionsThisWeek.toString(),
                  subtitle: 'This week',
                  color: Colors.blue,
                  isLoading: false,
                ),
                _StatCard(
                  icon: Icons.air,
                  title: 'Breathing',
                  value: stats.breathingCount.toString(),
                  subtitle: 'Sessions',
                  color: Colors.teal,
                  isLoading: false,
                ),
                _StatCard(
                  icon: Icons.local_fire_department,
                  title: 'Mood Streak',
                  value: '${stats.moodStreak} days',
                  color: Colors.orange,
                  isLoading: false,
                  showFireAnimation: stats.moodStreak >= 7,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: List.generate(4, (index) => _StatCard.loading()),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            'Unable to load stats',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => setState(() {
              _statsFuture = _loadStats();
            }),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final bool isLoading;
  final bool showFireAnimation;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    this.isLoading = false,
    this.showFireAnimation = false,
  });

  factory _StatCard.loading() {
    return const _StatCard(
      icon: Icons.circle,
      title: 'Loading...',
      value: '0',
      color: Colors.grey,
      isLoading: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value first (emphasis on numbers)
              if (isLoading)
                Container(
                  width: 120,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              else
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.green[900],
                    height: 0.9,
                  ),
                ),

              const SizedBox(height: 8),

              // Title and icon row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          )
                        : Icon(icon, color: color, size: 20),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoading)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        else
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),

                        if (subtitle != null && !isLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Subtle corner accent
          if (!isLoading)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
              ),
            ),

          // Streak indicator (minimal)
          if (!isLoading && showFireAnimation)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🔥',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'STREAK',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

@immutable
class StatsData {
  final int journalCount;
  final int chatSessionsThisWeek;
  final int breathingCount;
  final int moodStreak;

  const StatsData({
    this.journalCount = 0,
    this.chatSessionsThisWeek = 0,
    this.breathingCount = 0,
    this.moodStreak = 0,
  });
}
