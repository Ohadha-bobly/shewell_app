import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityDetailsScreen extends StatefulWidget {
  final String communityId;

  const CommunityDetailsScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailsScreen> createState() => _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState extends State<CommunityDetailsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final data = await supabase
          .from('community_posts')
          .select('*, profiles(*)')
          .eq('community_id', widget.communityId)
          .order('created_at', ascending: false);

      setState(() {
        _posts = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Community posts exception: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final exists = await supabase
          .from('community_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .limit(1);

      if ((exists as List).isNotEmpty) {
        // unlike
        await supabase
            .from('community_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        await supabase.from('community_likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });
      }

      _fetchPosts();
    } catch (e) {
      debugPrint('Toggle like error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('No posts yet'))
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final profile = post['profiles'] ?? {};
                    final author = profile['full_name'] ?? 'Unknown';
                    final content = post['content'] ?? '';
                    final id = post['id']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      child: ListTile(
                        title: Text(author),
                        subtitle: Text(content),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () => _toggleLike(id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
