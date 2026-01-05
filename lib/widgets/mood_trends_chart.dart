import 'package:bloom/models/mood_log.dart';
import 'package:bloom/services/db_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget that displays mood trends in a bar chart format
class MoodTrendsChart extends StatefulWidget {
  const MoodTrendsChart({super.key});

  @override
  State<MoodTrendsChart> createState() => _MoodTrendsChartState();
}

class _MoodTrendsChartState extends State<MoodTrendsChart> {
  bool isWeeklyView = true; // Toggle between weekly and monthly view

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          // Header with toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Trends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildToggleButton('Week', isWeeklyView),
                    _buildToggleButton('Month', !isWeeklyView),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(height: 200, child: _buildChart()),

          const SizedBox(height: 16),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isWeeklyView = label == 'Week';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.green[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final moodLogs = HiveDBService.getAllMoodLogs();

    if (moodLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              'No mood data yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    final chartData = isWeeklyView
        ? _getWeeklyData(moodLogs)
        : _getMonthlyData(moodLogs);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${chartData[groupIndex]['label']}\n${rod.toY.toInt()} moods',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= chartData.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    chartData[value.toInt()]['label'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value % 2 != 0) return const SizedBox();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          chartData.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: chartData[index]['count'].toDouble(),
                color: _getBarColor(chartData[index]['avgMood']),
                width: isWeeklyView ? 24 : 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getWeeklyData(List<MoodLog> moodLogs) {
    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final data = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayMoods = moodLogs.where((log) {
        return log.timestamp.year == date.year &&
            log.timestamp.month == date.month &&
            log.timestamp.day == date.day;
      }).toList();

      final avgMood = dayMoods.isEmpty
          ? 0.0
          : _calculateAverageMoodScore(dayMoods);

      data.add({
        'label': weekDays[date.weekday - 1],
        'count': dayMoods.length,
        'avgMood': avgMood,
      });
    }

    return data;
  }

  List<Map<String, dynamic>> _getMonthlyData(List<MoodLog> moodLogs) {
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];

    for (int i = 3; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthMoods = moodLogs.where((log) {
        return log.timestamp.year == month.year &&
            log.timestamp.month == month.month;
      }).toList();

      final avgMood = monthMoods.isEmpty
          ? 0.0
          : _calculateAverageMoodScore(monthMoods);

      data.add({
        'label': DateFormat('MMM').format(month),
        'count': monthMoods.length,
        'avgMood': avgMood,
      });
    }

    return data;
  }

  double _calculateAverageMoodScore(List<MoodLog> moods) {
    if (moods.isEmpty) return 0.0;

    final scores = moods.map((mood) => _getMoodScore(mood.mood)).toList();
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  int _getMoodScore(String mood) {
    // Map moods to scores (1-10 scale)
    final moodScores = {
      'Awful': 2,
      'Bad': 4,
      'Okay': 5,
      'Good': 7,
      'Great': 9,
      'Amazing': 10,
    };

    return moodScores[mood] ?? 5;
  }

  Color _getBarColor(double avgMood) {
    if (avgMood >= 8) return Colors.green;
    if (avgMood >= 6) return Colors.lightGreen;
    if (avgMood >= 4) return Colors.orange;
    return Colors.red[300]!;
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('Great', Colors.green),
        _buildLegendItem('Good', Colors.lightGreen),
        _buildLegendItem('Okay', Colors.orange),
        _buildLegendItem('Low', Colors.red[300]!),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
