import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoodAnalyticsScreen extends StatefulWidget {
  const MoodAnalyticsScreen({super.key});

  @override
  State<MoodAnalyticsScreen> createState() => _MoodAnalyticsScreenState();
}

class _MoodAnalyticsScreenState extends State<MoodAnalyticsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final data = await supabase
          .from('wellness_logs')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true)
          .limit(100);

      setState(() {
        _logs = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Fetch logs exception: $e');
      setState(() => _loading = false);
    }
  }

  List<FlSpot> _toSpots() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _logs.length; i++) {
      final entry = _logs[i];
      final rawMood = entry['mood'];
      double moodValue;

      // If mood is already numeric, use it.
      if (rawMood is num) {
        moodValue = rawMood.toDouble();
      } else if (rawMood is String) {
        // Map known mood strings to numeric scores.
        moodValue = _moodToValue(rawMood);
      } else {
        moodValue = 0.0;
      }

      spots.add(FlSpot(i.toDouble(), moodValue));
    }
    return spots;
  }

  double _moodToValue(String mood) {
    const mapping = {
      '😊 Happy': 4.0,
      '😐 Neutral': 3.0,
      '😢 Sad': 2.0,
      '😖 Stressed': 1.0,
    };

    // Exact match first
    if (mapping.containsKey(mood)) return mapping[mood]!;

    // Fallbacks: check for keywords
    final lower = mood.toLowerCase();
    if (lower.contains('happy') || lower.contains('😊')) return 4.0;
    if (lower.contains('neutral') || lower.contains('😐')) return 3.0;
    if (lower.contains('sad') || lower.contains('😢')) return 2.0;
    if (lower.contains('stress') || lower.contains('😖')) return 1.0;

    // Try to parse numeric value in string
    final parsed = double.tryParse(mood);
    if (parsed != null) return parsed;

    return 0.0;
  }

  // Compute aggregated stats used by the UI (averages and distribution).
  double _avgMood = 0.0;
  double _avgSleep = 0.0;
  Map<String, int> _moodCounts = {};

  void _computeStats() {
    final moodValues = <double>[];
    double sleepSum = 0.0;
    int sleepCount = 0;
    final counts = <String, int>{};

    for (final entry in _logs) {
      final rawMood = entry['mood'];
      String moodLabel = rawMood?.toString() ?? 'Unknown';
      final moodValue = (rawMood is num)
          ? rawMood.toDouble()
          : _moodToValue(moodLabel);

      moodValues.add(moodValue);

      counts[moodLabel] = (counts[moodLabel] ?? 0) + 1;

      final rawSleep = entry['sleep_hours'];
      double? sleepVal;
      if (rawSleep is num)
        sleepVal = rawSleep.toDouble();
      else if (rawSleep is String)
        sleepVal = double.tryParse(rawSleep);

      if (sleepVal != null) {
        sleepSum += sleepVal;
        sleepCount += 1;
      }
    }

    _moodCounts = counts;
    _avgMood = moodValues.isEmpty
        ? 0.0
        : (moodValues.reduce((a, b) => a + b) / moodValues.length);
    _avgSleep = sleepCount == 0 ? 0.0 : (sleepSum / sleepCount);
  }

  List<FlSpot> _sleepSpots() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _logs.length; i++) {
      final entry = _logs[i];
      final rawSleep = entry['sleep_hours'];
      double sleepVal = 0.0;
      if (rawSleep is num)
        sleepVal = rawSleep.toDouble();
      else if (rawSleep is String)
        sleepVal = double.tryParse(rawSleep) ?? 0.0;
      spots.add(FlSpot(i.toDouble(), sleepVal));
    }
    return spots;
  }

  List<BarChartGroupData> _buildMoodBarData() {
    final labels = _moodCounts.keys.toList();
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < labels.length; i++) {
      final count = _moodCounts[labels[i]] ?? 0;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: count.toDouble())],
        ),
      );
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_logs.isEmpty) return const Center(child: Text('No wellness logs yet'));

    _computeStats();
    final moodSpots = _toSpots();
    final sleepSpots = _sleepSpots();
    final barData = _buildMoodBarData();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Wellness Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Avg Mood',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(_avgMood.toStringAsFixed(2)),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Avg Sleep',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('${_avgSleep.toStringAsFixed(1)} hrs'),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Logs',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('${_logs.length}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Mood over time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: moodSpots,
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.pinkAccent,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Sleep hours over time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                minY: 0,
                maxY: 12,
                lineBarsData: [
                  LineChartBarData(
                    spots: sleepSpots,
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.blueAccent,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Mood distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: barData,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _moodCounts.keys.length)
                          return const SizedBox();
                        final label = _moodCounts.keys.elementAt(idx);
                        return Text(
                          label,
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'Logs',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final e = _logs[index];
              final created = e['created_at'] ?? '';
              final mood = e['mood'] ?? '';
              final sleep = e['sleep_hours'] ?? '';
              return ListTile(
                leading: CircleAvatar(child: Text(mood.toString())),
                title: Text('Mood: $mood • Sleep: $sleep'),
                subtitle: Text(created.toString()),
              );
            },
          ),
        ],
      ),
    );
  }
}
