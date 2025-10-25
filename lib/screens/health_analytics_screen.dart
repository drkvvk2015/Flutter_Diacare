import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/health_service.dart';
import '../widgets/glassmorphic_card.dart';

/// Modern health analytics screen showcasing enhanced HealthService features
class HealthAnalyticsScreen extends StatefulWidget {
  const HealthAnalyticsScreen({super.key});

  @override
  State<HealthAnalyticsScreen> createState() => _HealthAnalyticsScreenState();
}

class _HealthAnalyticsScreenState extends State<HealthAnalyticsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeHealthData();
  }

  Future<void> _initializeHealthData() async {
    setState(() => _isLoading = true);

    final healthService = Provider.of<HealthService>(context, listen: false);

    if (!healthService.isInitialized) {
      await healthService.requestAuthorization();
    }

    await Future.wait([
      healthService.fetchTodayData(),
      healthService.fetchWeeklyData(),
    ]);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeHealthData,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Consumer<HealthService>(
                  builder: (context, healthService, child) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHealthScoreCard(healthService),
                          const SizedBox(height: 16),
                          _buildVitalStatsGrid(healthService),
                          const SizedBox(height: 16),
                          _buildTrendsChart(healthService),
                          const SizedBox(height: 16),
                          _buildInsightsCard(healthService),
                          const SizedBox(height: 16),
                          _buildActivityCard(healthService),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(HealthService healthService) {
    final score = healthService.calculateHealthScore();
    final color = _getScoreColor(score);

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withOpacity(0.3), color],
                ),
              ),
              child: Center(
                child: Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Health Score',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getScoreDescription(score),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalStatsGrid(HealthService healthService) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildVitalCard(
          'Heart Rate',
          healthService.heartRate?.toStringAsFixed(0) ?? '--',
          'bpm',
          Icons.favorite,
          Colors.red,
        ),
        _buildVitalCard(
          'Blood Oxygen',
          healthService.spo2?.toStringAsFixed(1) ?? '--',
          '%',
          Icons.air,
          Colors.blue,
        ),
        _buildVitalCard(
          'Blood Pressure',
          healthService.bpSystolic != null && healthService.bpDiastolic != null
              ? '${healthService.bpSystolic!.toStringAsFixed(0)}/${healthService.bpDiastolic!.toStringAsFixed(0)}'
              : '--',
          'mmHg',
          Icons.monitor_heart,
          Colors.orange,
        ),
        _buildVitalCard(
          'Temperature',
          healthService.temperature?.toStringAsFixed(1) ?? '--',
          '°C',
          Icons.thermostat,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildVitalCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsChart(HealthService healthService) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Steps Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Day ${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
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
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getStepsChartData(healthService),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(HealthService healthService) {
    final insights = healthService.getHealthInsights();

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              const Text(
                'No insights available. Sync your health data to get personalized recommendations.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...insights.map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(HealthService healthService) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActivityStat(
                    'Steps',
                    healthService.steps.toString(),
                    Icons.directions_walk,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildActivityStat(
                    'Calories',
                    healthService.calories.toStringAsFixed(0),
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildActivityStat(
                    'Distance',
                    '${(healthService.distance / 1000).toStringAsFixed(1)} km',
                    Icons.straighten,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  List<FlSpot> _getStepsChartData(HealthService healthService) {
    // This is a simplified example - in a real app, you'd process the historical data
    // For now, we'll create sample data points
    return [
      const FlSpot(0, 8000),
      const FlSpot(1, 12000),
      const FlSpot(2, 6000),
      const FlSpot(3, 15000),
      const FlSpot(4, 9000),
      const FlSpot(5, 11000),
      FlSpot(6, healthService.steps.toDouble()),
    ];
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(int score) {
    if (score >= 90) return 'Excellent health status';
    if (score >= 80) return 'Good health status';
    if (score >= 60) return 'Fair health status';
    if (score >= 40) return 'Needs improvement';
    return 'Requires attention';
  }
}
