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

  Future<void> _seedExampleCommunities() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to create communities')),
        );
        return;
      }

      final examples = [
        {
          'name': 'Mindful Mornings',
          'description':
              'A space to share morning routines and mindfulness tips.',
          'image_url': null,
          'owner': user.id,
        },
        {
          'name': 'Sleep Support',
          'description': 'Discuss sleep hygiene, trackers, and restful habits.',
          'image_url': null,
          'owner': user.id,
        },
        {
          'name': 'Women in Wellness',
          'description': 'Community for peer support and resources.',
          'image_url': null,
          'owner': user.id,
        },
      ];

      // Insert examples only if table is empty (defensive).
      final current = await supabase.from('communities').select('id').limit(1);
      if ((current as List).isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Communities already exist')),
        );
        return;
      }

      await supabase.from('communities').insert(examples);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserted sample communities')),
      );
      setState(() {});
    } catch (e) {
      debugPrint('Seeding communities failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create communities: $e')),
      );
    }
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

          final communitiesRaw = snapshot.data!;
          final communities =
              List<Map<String, dynamic>>.from(communitiesRaw as List);

          if (communities.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No communities yet',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {}); // re-run FutureBuilder
                        },
                        child: const Text('Refresh'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _seedExampleCommunities,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                        ),
                        child: const Text('Create sample communities'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

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
                        backgroundImage: (community['image_url'] is String &&
                                (community['image_url'] as String)
                                    .trim()
                                    .isNotEmpty)
                            ? NetworkImage(community['image_url'] as String)
                            : null,
                        child: (community['image_url'] == null ||
                                (community['image_url'] is String &&
                                    (community['image_url'] as String)
                                        .trim()
                                        .isEmpty))
                            ? const Icon(Icons.group)
                            : null,
                      ),
                      title: Text(
                        community['name'] ?? 'Community',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(community['description'] ?? ''),
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
