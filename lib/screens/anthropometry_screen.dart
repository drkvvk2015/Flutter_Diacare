import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/anthropometry_service.dart';
import '../services/bp_service.dart';
import '../services/smbg_service.dart';

class AnthropometryScreen extends StatefulWidget {
  const AnthropometryScreen({super.key});

  @override
  State<AnthropometryScreen> createState() => _AnthropometryScreenState();
}

class _AnthropometryScreenState extends State<AnthropometryScreen> {
  final SMBGService _smbgService = SMBGService();
  List<SMBGReading> _smbgHistory = [];
  final BPService _bpService = BPService();
  List<BPReading> _bpHistory = [];
  String _generateAIInsights(List<Anthropometry> history) {
    if (history.isEmpty) return 'No data available.';
    final latest = history.first;
    String bmiCategory;
    if (latest.bmi < 18.5) {
      bmiCategory = 'Underweight';
    } else if (latest.bmi < 25) {
      bmiCategory = 'Normal weight';
    } else if (latest.bmi < 30) {
      bmiCategory = 'Overweight';
    } else {
      bmiCategory = 'Obese';
    }
    String trend = '';
    if (history.length > 1) {
      final prev = history[1];
      if (latest.weight > prev.weight) {
        trend = 'Your weight has increased since the last measurement.';
      } else if (latest.weight < prev.weight) {
        trend = 'Your weight has decreased since the last measurement.';
      } else {
        trend = 'Your weight is stable compared to the last measurement.';
      }
    }
    final whr = latest.waist / (latest.hip == 0 ? 1 : latest.hip);
    String whrRisk = '';
    if (whr > 0.9) {
      whrRisk =
          'High waist/hip ratio: Increased risk of metabolic complications.';
    } else {
      whrRisk = 'Waist/hip ratio is within a healthy range.';
    }
    return 'BMI: ${latest.bmi.toStringAsFixed(1)} ($bmiCategory)\n$trend\n$whrRisk';
  }

  final AnthropometryService _service = AnthropometryService();
  List<Anthropometry> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchBP();
    _fetchSMBG();
  }

  Future<void> _fetchSMBG() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final data = await _smbgService.getSMBGHistory(user.uid);
      setState(() {
        _smbgHistory = data;
      });
    } catch (_) {}
  }

  String _generateSMBGAIInsights(List<SMBGReading> history) {
    if (history.isEmpty) return 'No glucose data available.';
    final latest = history.first;
    final String fastingStatus = latest.fasting < 100
        ? 'Normal'
        : (latest.fasting < 126 ? 'Prediabetes' : 'Diabetes');
    String trend = '';
    if (history.length > 1) {
      final prev = history[1];
      if (latest.fasting > prev.fasting) {
        trend =
            'Your fasting glucose has increased since the last measurement.';
      } else if (latest.fasting < prev.fasting) {
        trend =
            'Your fasting glucose has decreased since the last measurement.';
      } else {
        trend =
            'Your fasting glucose is stable compared to the last measurement.';
      }
    }
    return 'Fasting: ${latest.fasting} mg/dL ($fastingStatus)\n$trend';
  }

  Future<void> _fetchBP() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final data = await _bpService.getBPHistory(user.uid);
      setState(() {
        _bpHistory = data;
      });
    } catch (_) {}
  }

  String _generateBPAIInsights(List<BPReading> history) {
    if (history.isEmpty) return 'No BP data available.';
    final latest = history.first;
    String category = '';
    if (latest.systolic < 120 && latest.diastolic < 80) {
      category = 'Normal';
    } else if (latest.systolic < 130 && latest.diastolic < 80) {
      category = 'Elevated';
    } else if (latest.systolic < 140 || latest.diastolic < 90) {
      category = 'Hypertension Stage 1';
    } else {
      category = 'Hypertension Stage 2';
    }
    String trend = '';
    if (history.length > 1) {
      final prev = history[1];
      if (latest.systolic > prev.systolic ||
          latest.diastolic > prev.diastolic) {
        trend = 'Your BP has increased since the last measurement.';
      } else if (latest.systolic < prev.systolic ||
          latest.diastolic < prev.diastolic) {
        trend = 'Your BP has decreased since the last measurement.';
      } else {
        trend = 'Your BP is stable compared to the last measurement.';
      }
    }
    return 'BP: ${latest.systolic}/${latest.diastolic} mmHg ($category)\n$trend';
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final data = await _service.getAnthropometryHistory(user.uid);
      setState(() {
        _history = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _buildLineChart({
    required List<FlSpot> spots,
    required String title,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(),
              ),
              minX: 0,
              maxX: spots.length.toDouble() - 1,
              minY: spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1,
              maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extended Anthropometry & AI Insights'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _history.isEmpty
          ? const Center(child: Text('No anthropometry data found.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Anthropometry History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._history.map(
                  (a) => Card(
                    child: ListTile(
                      title: Text(
                        'Date:  \t${a.date.toLocal().toString().substring(0, 10)}',
                      ),
                      subtitle: Text(
                        'Height: ${a.height} cm\nWeight: ${a.weight} kg\nBMI: ${a.bmi.toStringAsFixed(1)}\nWaist: ${a.waist} cm\nHip: ${a.hip} cm',
                      ),
                    ),
                  ),
                ),
                if (_history.length > 1) ...[
                  _buildLineChart(
                    spots: List.generate(
                      _history.length,
                      (i) => FlSpot(
                        (_history.length - 1 - i).toDouble(),
                        _history[i].weight,
                      ),
                    ),
                    title: 'Weight Trend',
                    unit: 'kg',
                    color: Colors.blue,
                  ),
                  _buildLineChart(
                    spots: List.generate(
                      _history.length,
                      (i) => FlSpot(
                        (_history.length - 1 - i).toDouble(),
                        _history[i].bmi,
                      ),
                    ),
                    title: 'BMI Trend',
                    unit: '',
                    color: Colors.deepOrange,
                  ),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const Text(
                  'AI Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(_generateAIInsights(_history)),
                const SizedBox(height: 32),
                if (_bpHistory.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Blood Pressure History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._bpHistory.map(
                    (b) => Card(
                      child: ListTile(
                        title: Text(
                          'Date:  \t${b.date.toLocal().toString().substring(0, 10)}',
                        ),
                        subtitle: Text(
                          'Systolic: ${b.systolic} mmHg\nDiastolic: ${b.diastolic} mmHg\nPulse: ${b.pulse} bpm',
                        ),
                      ),
                    ),
                  ),
                  if (_bpHistory.length > 1)
                    _buildLineChart(
                      spots: List.generate(
                        _bpHistory.length,
                        (i) => FlSpot(
                          (_bpHistory.length - 1 - i).toDouble(),
                          _bpHistory[i].systolic.toDouble(),
                        ),
                      ),
                      title: 'Systolic BP Trend',
                      unit: 'mmHg',
                      color: Colors.purple,
                    ),
                  if (_bpHistory.length > 1)
                    _buildLineChart(
                      spots: List.generate(
                        _bpHistory.length,
                        (i) => FlSpot(
                          (_bpHistory.length - 1 - i).toDouble(),
                          _bpHistory[i].diastolic.toDouble(),
                        ),
                      ),
                      title: 'Diastolic BP Trend',
                      unit: 'mmHg',
                      color: Colors.red,
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'BP AI Insights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(_generateBPAIInsights(_bpHistory)),
                ],
                if (_smbgHistory.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Glucose (SMBG) History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._smbgHistory.map(
                    (g) => Card(
                      child: ListTile(
                        title: Text(
                          'Date:  \t${g.date.toLocal().toString().substring(0, 10)}',
                        ),
                        subtitle: Text(
                          'Fasting: ${g.fasting} mg/dL\nPre-Lunch: ${g.preLunch} mg/dL\nPre-Dinner: ${g.preDinner} mg/dL\nPost-Meal: ${g.postMeal} mg/dL',
                        ),
                      ),
                    ),
                  ),
                  if (_smbgHistory.length > 1)
                    _buildLineChart(
                      spots: List.generate(
                        _smbgHistory.length,
                        (i) => FlSpot(
                          (_smbgHistory.length - 1 - i).toDouble(),
                          _smbgHistory[i].fasting,
                        ),
                      ),
                      title: 'Fasting Glucose Trend',
                      unit: 'mg/dL',
                      color: Colors.green,
                    ),
                  if (_smbgHistory.length > 1)
                    _buildLineChart(
                      spots: List.generate(
                        _smbgHistory.length,
                        (i) => FlSpot(
                          (_smbgHistory.length - 1 - i).toDouble(),
                          _smbgHistory[i].postMeal,
                        ),
                      ),
                      title: 'Post-Meal Glucose Trend',
                      unit: 'mg/dL',
                      color: Colors.orange,
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Glucose AI Insights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(_generateSMBGAIInsights(_smbgHistory)),
                ],
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ],
            ),
    );
  }
}
