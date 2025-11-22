import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> users = [];
  bool loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _usersSub;

  @override
  void initState() {
    super.initState();
    _loadUsers();

    // start realtime subscription to users table so presence updates in the list
    final currentUserId = supabase.auth.currentUser?.id ?? '';
    try {
      final stream = supabase
          .from('users')
          .stream(primaryKey: ['id'])
          .neq('id', currentUserId)
          .map((rows) => rows);

      _usersSub = stream.listen((rows) {
        setState(() {
          users = List<Map<String, dynamic>>.from(rows);
          loading = false;
        });
      }, onError: (e) {
        debugPrint('Users stream error: $e');
      });
    } catch (e) {
      debugPrint('Failed to subscribe to users stream: $e');
    }
  }

  Future<void> _loadUsers() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      final response =
          await supabase.from('users').select().neq('id', currentUserId ?? '');

      setState(() {
        users = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        // presence dot: green if online==true, grey otherwise
        final isOnline = user['online'] == true;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: (user['profile_url'] is String &&
                          (user['profile_url'] as String).trim().isNotEmpty)
                      ? NetworkImage(user['profile_url'] as String)
                      : null,
                  child: (user['profile_url'] == null ||
                          (user['profile_url'] is String &&
                              (user['profile_url'] as String).trim().isEmpty))
                      ? const Icon(Icons.person)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey[700],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              user['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user['email'] ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    peerId: user['id'],
                    peerName: user['name'] ?? 'User',
                    peerProfileUrl: user['profile_url'] ?? '',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }
}
