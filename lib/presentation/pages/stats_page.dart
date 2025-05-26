import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart';
import '../widgets/stats/stats_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false).loadReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, reviewProvider, child) {
          if (reviewProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = reviewProvider.reviews;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Reviews',
                        reviews.length.toString(),
                        Icons.quiz,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Success Rate',
                        reviews.isEmpty
                            ? '0%'
                            : '${((reviews.where((r) => r.rating >= 7).length / reviews.length) * 100).toStringAsFixed(1)}%',
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Charts
                Expanded(
                  child: StatsChart(
                    reviews: reviews,
                    title: 'Performance Overview',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF373737),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: const Color(0xFF2496DC)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
