import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'community_details_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchCommunities() async {
    final response = await supabase.from('communities').select('*');
    return response;
  }

  Future<bool> _isJoined(String communityId) async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('community_members')
        .select()
        .eq('community_id', communityId)
        .eq('user_id', userId);

    return res.isNotEmpty;
  }

  Future<void> _toggleJoin(String communityId) async {
    final userId = supabase.auth.currentUser!.id;

    if (await _isJoined(communityId)) {
      await supabase
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You left the community.")));
    } else {
      await supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You joined the community 🎉")));
    }

    setState(() {}); // refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Communities"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: FutureBuilder(
        future: _fetchCommunities(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final communities = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: communities.length,
            itemBuilder: (context, i) {
              final community = communities[i];

              return FutureBuilder<bool>(
                future: _isJoined(community['id']),
                builder: (context, joinSnapshot) {
                  final joined = joinSnapshot.data ?? false;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            NetworkImage(community['image_url'] ?? ""),
                      ),
                      title: Text(
                        community['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(community['description']),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              joined ? Colors.grey : Colors.pinkAccent,
                        ),
                        onPressed: () => _toggleJoin(community['id']),
                        child: Text(
                          joined ? "Joined" : "Join",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommunityDetailsScreen(
                              communityId: community['id'],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
