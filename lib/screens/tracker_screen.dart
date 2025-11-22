import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mood_analytics_screen.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  String? _selectedMood;
  double _sleepHours = 7;
  String? _cycleInfo;
  int _currentTabIndex = 0;

  final List<String> moods = [
    '😊 Happy',
    '😐 Neutral',
    '😢 Sad',
    '😖 Stressed',
  ];
  final supabase = Supabase.instance.client;

  Future<void> _saveLog() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your mood 😊')),
      );
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure there's a user row in `users` to satisfy any foreign-key
      // constraints that the `wellness_logs` table may enforce.
      final existing = await supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        try {
          await supabase.from('users').insert({'id': userId});
          debugPrint('Created missing users row for id=$userId');
        } catch (e) {
          debugPrint('Failed creating users row: $e');
          // Continue — insertion below may still fail, but surface the
          // underlying error to the user rather than crash.
        }
      }

      final response = await supabase
          .from('wellness_logs')
          .insert({
            'user_id': userId,
            'mood': _selectedMood,
            'sleep_hours': _sleepHours,
            'cycle_info': _cycleInfo ?? '',
          })
          .select()
          .maybeSingle();
      // Prefer to let the database set `created_at` with its default value
      // to avoid conflicts with DB constraints or triggers.
      // If you want the inserted row returned, consider:
      // final response = await supabase.from('wellness_logs').insert({...}).select().maybeSingle();

      // If the client returns an error object, throw it to be handled below.
      // The supabase_flutter client will usually throw a PostgrestException on error,
      // but checking the response can help in some client versions.
      if (response == null) {
        throw Exception('No response from Supabase when saving log.');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wellness log saved successfully! 🌸')),
        );
      }

      setState(() {
        _selectedMood = null;
        _sleepHours = 7;
        _cycleInfo = '';
        _currentTabIndex = 1; // Switch to analytics
      });
    } catch (e) {
      String message = e.toString();
      try {
        if (e is PostgrestException) {
          message = '${e.message}';
        }
      } catch (_) {}
      // Also try to extract common error fields if available
      try {
        // Some exceptions include a `details` or `hint` property.
        final details = (e as dynamic).details ?? null;
        final hint = (e as dynamic).hint ?? null;
        if (details != null) message += '\nDetails: $details';
        if (hint != null) message += '\nHint: $hint';
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving log: $message')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _currentTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wellness Tracker'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Log Mood', icon: Icon(Icons.edit)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Log Mood Tab
            _buildLogMoodTab(),
            // Analytics Tab
            const MoodAnalyticsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogMoodTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Daily Wellness Tracker',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Color.fromARGB(230, 255, 255, 255),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How are you feeling today?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: moods.map((mood) {
                        return ChoiceChip(
                          label: Text(mood),
                          selected: _selectedMood == mood,
                          selectedColor: Colors.pinkAccent,
                          onSelected: (_) =>
                              setState(() => _selectedMood = mood),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'How many hours did you sleep?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _sleepHours,
                      min: 0,
                      max: 12,
                      divisions: 12,
                      label: _sleepHours.toStringAsFixed(1),
                      activeColor: Colors.pinkAccent,
                      onChanged: (val) => setState(() => _sleepHours = val),
                    ),
                    Center(
                      child: Text(
                        '${_sleepHours.toStringAsFixed(1)} hours',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Any cycle notes? (optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g., light cramps, first day, etc.',
                      ),
                      onChanged: (val) => _cycleInfo = val,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save Log'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _saveLog,
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
}
