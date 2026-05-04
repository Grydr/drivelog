import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../services/auth_provider.dart';
import '../services/trip_provider.dart';
import '../models/daily_stats.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Statistics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: userId.isEmpty
          ? const Center(
              child: Text(
                'Please log in to view statistics',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : FutureBuilder<List<dynamic>>(
              future: context.read<TripProvider>().get7DayStats(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final dailyStats = snapshot.data as List<DailyStats>? ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last 7 Days',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildChart(
                        title: 'Average Speed (km/h)',
                        data: dailyStats.map((d) => d.avgSpeed).toList(),
                        dailyStats: dailyStats,
                        maxValue:
                            dailyStats.isEmpty ? 100 : _getMaxValue(dailyStats.map((d) => d.avgSpeed).toList()),
                      ),
                      const SizedBox(height: 24),
                      _buildChart(
                        title: 'Top Speed (km/h)',
                        data: dailyStats.map((d) => d.topSpeed).toList(),
                        dailyStats: dailyStats,
                        maxValue: dailyStats.isEmpty ? 150 : _getMaxValue(dailyStats.map((d) => d.topSpeed).toList()),
                      ),
                      const SizedBox(height: 24),
                      _buildChart(
                        title: 'Distance (km)',
                        data: dailyStats.map((d) => d.distance).toList(),
                        dailyStats: dailyStats,
                        maxValue: dailyStats.isEmpty ? 50 : _getMaxValue(dailyStats.map((d) => d.distance).toList()),
                      ),
                      const SizedBox(height: 24),
                      _buildChart(
                        title: 'Duration (min)',
                        data: dailyStats.map((d) => d.duration.toDouble()).toList(),
                        dailyStats: dailyStats,
                        maxValue: dailyStats.isEmpty ? 600 : _getMaxValue(dailyStats.map((d) => d.duration.toDouble()).toList()),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }

  double _getMaxValue(List<double> values) {
    if (values.isEmpty) return 100;
    final max = values.reduce((a, b) => a > b ? a : b);
    return max * 1.2; // Add 20% padding
  }

  static Widget _buildChart({
    required String title,
    required List<double> data,
    required List<DailyStats> dailyStats,
    required double maxValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxValue,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dailyStats.length) {
                          return Text(
                            DateFormat('E').format(dailyStats[index].date),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                gridData: const FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  data.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data[index],
                        color: AppColors.primary,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
