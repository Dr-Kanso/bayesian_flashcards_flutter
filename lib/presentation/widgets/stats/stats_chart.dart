import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/models/review.dart';
import '../../../domain/models/session.dart';
import '../../../domain/models/user.dart';
import '../../../services/bayesian_service.dart';
import 'dart:math' as math;

class StatsChart extends StatefulWidget {
  final String statsType;
  final User? user;
  final List<Review>? reviews;
  final Session? session;
  final String? deckName;

  const StatsChart({
    super.key,
    required this.statsType,
    this.user,
    this.reviews,
    this.session,
    this.deckName,
  });

  @override
  State<StatsChart> createState() => _StatsChartState();
}

class _StatsChartState extends State<StatsChart> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF373737),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Success Rate'),
              Tab(text: 'Performance Distribution'),
            ],
            indicatorColor: const Color(0xFF2496DC),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSuccessRateChart(),
                _buildPerformanceDistribution(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = '';
    switch (widget.statsType) {
      case 'user':
        title = 'User: ${widget.user?.username ?? "Unknown"}';
        break;
      case 'deck':
        title = 'Deck: ${widget.deckName ?? "Unknown"}';
        break;
      case 'session':
        title = 'Session: ${widget.session?.name ?? "Unknown"}';
        break;
    }

    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSuccessRateChart() {
    final data = _getSuccessRateData();
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.2,
          verticalInterval: data.length > 10 ? data.length / 5 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: data.length > 10 ? data.length / 5 : 1,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.2,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: 1.05,
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF2496DC), Color(0xFF1A7BB9)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2496DC).withValues(alpha: 0.3),
                  const Color(0xFF2496DC).withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Target line
          LineChartBarData(
            spots: [
              const FlSpot(0, 0.7),
              FlSpot(data.length.toDouble() - 1, 0.7),
            ],
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDistribution() {
    final distributionData = _getPerformanceDistribution();
    if (distributionData.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final stats = _getDistributionStats();

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: distributionData.map((e) => e.y).reduce(math.max) / 5,
                verticalInterval: 0.2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 0.2,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              minX: 0,
              maxX: 1,
              minY: 0,
              maxY: distributionData.map((e) => e.y).reduce(math.max) * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: distributionData,
                  isCurved: true,
                  color: const Color(0xFF2496DC),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2496DC).withValues(alpha: 0.3),
                        const Color(0xFF2496DC).withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Mean line
                if (stats['mean'] != null)
                  LineChartBarData(
                    spots: [
                      FlSpot(stats['mean']!, 0),
                      FlSpot(stats['mean']!, distributionData.map((e) => e.y).reduce(math.max)),
                    ],
                    isCurved: false,
                    color: Colors.red,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
              ],
            ),
          ),
        ),
        if (stats.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              'α=${stats['alpha']?.toStringAsFixed(1)}, β=${stats['beta']?.toStringAsFixed(1)}, Mean=${stats['mean']?.toStringAsFixed(3)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
      ],
    );
  }

  List<FlSpot> _getSuccessRateData() {
    List<Review> reviews = [];
    
    switch (widget.statsType) {
      case 'user':
        if (widget.user != null) {
          final history = widget.user!.getRecallHistory();
          reviews = history.asMap().entries.map((entry) => Review(
            cardId: 0,
            userId: widget.user!.id,
            sessionId: '',
            rating: entry.value[1] == 1 ? 8 : 4,
            reviewTime: DateTime.now().subtract(Duration(days: history.length - entry.key)),
            responseTime: 0,
          )).toList();
        }
        break;
      case 'deck':
      case 'session':
        reviews = widget.reviews ?? [];
        break;
    }

    if (reviews.isEmpty) return [];

    final spots = <FlSpot>[];
    double cumulativeSuccess = 0;

    for (int i = 0; i < reviews.length; i++) {
      if (reviews[i].rating >= 7) {
        cumulativeSuccess++;
      }
      final successRate = cumulativeSuccess / (i + 1);
      spots.add(FlSpot(i.toDouble(), successRate));
    }

    return spots;
  }

  List<FlSpot> _getPerformanceDistribution() {
    Map<String, double> posterior = {};
    
    switch (widget.statsType) {
      case 'user':
        if (widget.user != null) {
          posterior = BayesianService.getRecentPosterior(widget.user!);
        }
        break;
      case 'deck':
      case 'session':
        final reviews = widget.reviews ?? [];
        if (reviews.isNotEmpty) {
          final successes = reviews.where((r) => r.rating >= 7).length;
          final failures = reviews.length - successes;
          posterior = {'alpha': 2.0 + successes, 'beta': 1.0 + failures};
        }
        break;
    }

    if (posterior.isEmpty) return [];

    final alpha = posterior['alpha']!;
    final beta = posterior['beta']!;
    final spots = <FlSpot>[];

    for (int i = 0; i <= 100; i++) {
      final x = i / 100.0;
      final y = _betaPdf(x, alpha, beta);
      spots.add(FlSpot(x, y));
    }

    return spots;
  }

  Map<String, double?> _getDistributionStats() {
    switch (widget.statsType) {
      case 'user':
        if (widget.user != null) {
          final posterior = BayesianService.getRecentPosterior(widget.user!);
          final alpha = posterior['alpha']!;
          final beta = posterior['beta']!;
          return {
            'alpha': alpha,
            'beta': beta,
            'mean': alpha / (alpha + beta),
          };
        }
        break;
      case 'deck':
      case 'session':
        final reviews = widget.reviews ?? [];
        if (reviews.isNotEmpty) {
          final successes = reviews.where((r) => r.rating >= 7).length;
          final failures = reviews.length - successes;
          final alpha = 2.0 + successes;
          final beta = 1.0 + failures;
          return {
            'alpha': alpha,
            'beta': beta,
            'mean': alpha / (alpha + beta),
          };
        }
        break;
    }
    return {};
  }

  double _betaPdf(double x, double alpha, double beta) {
    if (x <= 0 || x >= 1) return 0;
    
    // Simplified beta PDF calculation
    final logBeta = _logGamma(alpha) + _logGamma(beta) - _logGamma(alpha + beta);
    final logPdf = (alpha - 1) * math.log(x) + (beta - 1) * math.log(1 - x) - logBeta;
    
    return math.exp(logPdf);
  }

  double _logGamma(double x) {
    // Simplified log gamma approximation using Stirling's formula
    if (x < 1) return _logGamma(x + 1) - math.log(x);
    return (x - 0.5) * math.log(x) - x + 0.5 * math.log(2 * math.pi);
  }
}
