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
      final mood = (entry['mood'] is int)
          ? entry['mood'].toDouble()
          : (entry['mood'] ?? 0.0);
      spots.add(FlSpot(i.toDouble(), mood.toDouble()));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_logs.isEmpty) return const Center(child: Text('No wellness logs yet'));

    final spots = _toSpots();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text('Mood over time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
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
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final e = _logs[index];
                final created = e['created_at'] ?? '';
                final mood = e['mood'] ?? '';
                return ListTile(
                  leading: CircleAvatar(child: Text(mood.toString())),
                  title: Text('Mood: $mood'),
                  subtitle: Text(created.toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
