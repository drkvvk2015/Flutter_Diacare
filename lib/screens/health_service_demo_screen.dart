import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/health_service.dart';
import '../widgets/glassmorphic_card.dart';

/// Demo screen to showcase HealthService capabilities
class HealthServiceDemoScreen extends StatefulWidget {
  const HealthServiceDemoScreen({super.key});

  @override
  State<HealthServiceDemoScreen> createState() =>
      _HealthServiceDemoScreenState();
}

class _HealthServiceDemoScreenState extends State<HealthServiceDemoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Service Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFFf093fb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDemoControls(),
                const SizedBox(height: 20),
                Consumer<HealthService>(
                  builder: (context, healthService, child) {
                    return Column(
                      children: [
                        _buildHealthScoreDemo(healthService),
                        const SizedBox(height: 16),
                        _buildVitalsDemo(healthService),
                        const SizedBox(height: 16),
                        _buildInsightsDemo(healthService),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoControls() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Data Simulator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _simulateHealthyData(),
                    icon: const Icon(Icons.favorite, color: Colors.green),
                    label: const Text('Healthy Values'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withAlpha(204),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _simulateUnhealthyData(),
                    icon: const Icon(Icons.warning, color: Colors.orange),
                    label: const Text('Poor Values'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.withAlpha(204),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _clearData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.withAlpha(204),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreDemo(HealthService healthService) {
    final score = healthService.calculateHealthScore();
    final color = _getScoreColor(score);

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Health Score Algorithm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withAlpha(77), color],
                ),
                border: Border.all(color: color, width: 3),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Score',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getScoreDescription(score),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsDemo(HealthService healthService) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Vitals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildVitalRow(
              'Heart Rate',
              healthService.heartRate?.toStringAsFixed(0) ?? '--',
              'bpm',
              Icons.favorite,
              Colors.red,
            ),
            _buildVitalRow(
              'SpO2',
              healthService.spo2?.toStringAsFixed(1) ?? '--',
              '%',
              Icons.air,
              Colors.blue,
            ),
            _buildVitalRow(
              'Blood Pressure',
              healthService.bpSystolic != null &&
                      healthService.bpDiastolic != null
                  ? '${healthService.bpSystolic!.toStringAsFixed(0)}/${healthService.bpDiastolic!.toStringAsFixed(0)}'
                  : '--',
              'mmHg',
              Icons.monitor_heart,
              Colors.orange,
            ),
            _buildVitalRow(
              'Temperature',
              healthService.temperature?.toStringAsFixed(1) ?? '--',
              '°C',
              Icons.thermostat,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalRow(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsDemo(HealthService healthService) {
    final insights = healthService.getHealthInsights();

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI-Generated Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              const Text(
                'No insights available. Set some health data to see personalized recommendations.',
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
                        Icons.psychology,
                        color: Colors.deepPurple,
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

  void _simulateHealthyData() {
    final healthService = Provider.of<HealthService>(context, listen: false);
    healthService.simulateHealthData(
      heartRate: 72, // Excellent
      spo2: 98, // Excellent
      bpSystolic: 118, // Optimal
      bpDiastolic: 78, // Optimal
      temperature: 36.8, // Normal
      steps: 12000, // Active
      calories: 450, // Good burn
      distance: 8500, // Good distance
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Healthy values simulated! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _simulateUnhealthyData() {
    final healthService = Provider.of<HealthService>(context, listen: false);
    healthService.simulateHealthData(
      heartRate: 110, // Elevated
      spo2: 92, // Low normal
      bpSystolic: 140, // Borderline high
      bpDiastolic: 95, // Borderline high
      temperature: 38.2, // Slightly elevated
      steps: 3000, // Sedentary
      calories: 120, // Low burn
      distance: 2100, // Low activity
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Poor health values simulated ⚠️'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _clearData() {
    final healthService = Provider.of<HealthService>(context, listen: false);
    healthService.resetData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health data cleared 🔄'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(int score) {
    if (score >= 90) return 'Excellent Health Status';
    if (score >= 80) return 'Good Health Status';
    if (score >= 60) return 'Fair Health Status';
    if (score >= 40) return 'Needs Improvement';
    return 'Requires Medical Attention';
  }
}
