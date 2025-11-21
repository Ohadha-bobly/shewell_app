import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerProfileUrl;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.peerProfileUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final supabase = Supabase.instance.client;
  late final String chatId;
  late final String currentUserId;
  StreamSubscription<List<Map<String, dynamic>>>? _peerSub;
  StreamSubscription<List<Map<String, dynamic>>>? _peerTypingSub;

  bool _peerOnline = false;
  DateTime? _peerLastSeen;
  bool _peerIsTyping = false;

  @override
  void initState() {
    super.initState();

    final user = supabase.auth.currentUser;
    if (user == null) {
      // If no user, push to login or throw — keep simple fallback:
      currentUserId = '';
    } else {
      currentUserId = user.id;
    }

    // deterministic chat id (same ordering logic as before)
    chatId = (currentUserId.hashCode <= widget.peerId.hashCode)
        ? '$currentUserId-${widget.peerId}'
        : '${widget.peerId}-$currentUserId';
    _loadPeerStatus();
    _watchPeerTyping();
  }

  Future<void> _loadPeerStatus() async {
    try {
      // Subscribe to realtime changes on the peer's user row
      final stream = supabase
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', widget.peerId)
          .map((rows) => rows);

      _peerSub = stream.listen((rows) {
        if (rows.isNotEmpty) {
          final row = rows.first;
          final online = row['online'] == true;
          DateTime? lastSeen;
          try {
            if (row['last_seen'] != null) {
              lastSeen = DateTime.parse(row['last_seen']);
            }
          } catch (_) {
            lastSeen = null;
          }

          if (mounted) {
            setState(() {
              _peerOnline = online;
              _peerLastSeen = lastSeen;
            });
          }
        }
      }, onError: (e) {
        debugPrint('Peer status stream error: $e');
      });
    } catch (e) {
      debugPrint('Error loading peer status: $e');
    }
  }

  Future<void> _watchPeerTyping() async {
    try {
      // Stream messages and check if peer sent a message recently
      final stream = supabase
          .from('messages')
          .stream(primaryKey: ['id']).map((rows) => rows);

      _peerTypingSub = stream.listen((rows) {
        // Filter for this chat and from peer
        final peerMessages = rows
            .where((msg) =>
                msg['chat_id'] == chatId && msg['sender_id'] == widget.peerId)
            .toList();

        if (peerMessages.isNotEmpty) {
          // Sort by created_at and check most recent
          peerMessages.sort((a, b) {
            final dateA = DateTime.parse(a['created_at']);
            final dateB = DateTime.parse(b['created_at']);
            return dateB.compareTo(dateA);
          });

          final lastMessage = peerMessages.first;
          final createdAt = DateTime.parse(lastMessage['created_at']);
          final isRecent = DateTime.now().difference(createdAt).inSeconds < 3;

          if (mounted) {
            setState(() {
              _peerIsTyping = isRecent;
            });
          }
        }
      }, onError: (e) {
        debugPrint('Peer typing stream error: $e');
      });
    } catch (e) {
      debugPrint('Error watching peer typing: $e');
    }
  }

  @override
  void dispose() {
    _peerSub?.cancel();
    _peerTypingSub?.cancel();
    super.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    try {
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'receiver_id': widget.peerId,
        'text': text.trim(),
      });
      _controller.clear();
    } catch (e) {
      debugPrint('Send message error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
  }

  // Stream of messages for this chat (newest first)
  Stream<List<Map<String, dynamic>>> _messagesStream() {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((event) {
          // event is List<Map<String,dynamic>> of rows
          // ensure we return a copy sorted newest-first (already ordered but safe)
          final list = List<Map<String, dynamic>>.from(event);
          list.sort((a, b) {
            final aTs = a['created_at'] == null
                ? 0
                : DateTime.parse(a['created_at']).millisecondsSinceEpoch;
            final bTs = b['created_at'] == null
                ? 0
                : DateTime.parse(b['created_at']).millisecondsSinceEpoch;
            return bTs.compareTo(aTs);
          });
          return list;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.peerProfileUrl),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _peerOnline ? Colors.green : Colors.grey[700],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName),
                const SizedBox(height: 2),
                Text(
                  _peerOnline
                      ? 'online'
                      : (_peerLastSeen != null
                          ? 'last seen ${_timeAgo(_peerLastSeen!)}'
                          : 'offline'),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  reverse: true, // newest at bottom visually: list reversed
                  padding: const EdgeInsets.all(12),
                  itemCount:
                      docs.length + (_controller.text.isNotEmpty ? 0 : 0),
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final senderId = data['sender_id']?.toString() ?? '';
                    final text = data['text']?.toString() ?? '';
                    final isMe = senderId == currentUserId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.pinkAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // composer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[100],
            child: Column(
              children: [
                if (_peerIsTyping)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TypingIndicator(
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) => _sendMessage(val),
                        onChanged: (val) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.pinkAccent),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
