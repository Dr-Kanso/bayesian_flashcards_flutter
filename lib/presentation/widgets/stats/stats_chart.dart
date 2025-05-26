import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/models/review.dart';

class StatsChart extends StatelessWidget {
  final List<Review> reviews;
  final String title;

  const StatsChart({
    super.key,
    required this.reviews,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF373737),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildSuccessRateChart()),
                const SizedBox(width: 16),
                Expanded(child: _buildPerformanceDistribution()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRateChart() {
    if (reviews.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final successfulReviews = reviews.where((r) => r.rating >= 7).length;
    final successRate = successfulReviews / reviews.length;

    return Column(
      children: [
        const Text(
          'Success Rate',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: successRate * 100,
                  color: const Color(0xFF2496DC),
                  title: '${(successRate * 100).toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: (1 - successRate) * 100,
                  color: const Color(0xFF484848),
                  title: '${((1 - successRate) * 100).toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceDistribution() {
    if (reviews.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group ratings into ranges
    final Map<String, int> distribution = {
      '1-3': 0,
      '4-6': 0,
      '7-8': 0,
      '9-10': 0,
    };

    for (final review in reviews) {
      if (review.rating <= 3) {
        distribution['1-3'] = distribution['1-3']! + 1;
      } else if (review.rating <= 6) {
        distribution['4-6'] = distribution['4-6']! + 1;
      } else if (review.rating <= 8) {
        distribution['7-8'] = distribution['7-8']! + 1;
      } else {
        distribution['9-10'] = distribution['9-10']! + 1;
      }
    }

    return Column(
      children: [
        const Text(
          'Rating Distribution',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: distribution.values.reduce((a, b) => a > b ? a : b).toDouble(),
              barGroups: distribution.entries.map((entry) {
                final index = distribution.keys.toList().indexOf(entry.key);
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: const Color(0xFF2496DC),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
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
                      final labels = distribution.keys.toList();
                      if (value.toInt() < labels.length) {
                        return Text(
                          labels[value.toInt()],
                          style: const TextStyle(fontSize: 12),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}
