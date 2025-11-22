import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cryptography/cryptography.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerProfileUrl;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.peerProfileUrl = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;

  late final String currentUserId;
  late final String chatId;

  final TextEditingController _controller = TextEditingController();
  final Map<String, String> _decryptedCache = {};
  SecretKey? _symmetricKey;

  bool _peerOnline = false;
  DateTime? _peerLastSeen;
  bool _peerIsTyping = false;

  List<Map<String, dynamic>> _initialMessages = [];
  bool _messagesLoaded = false;

  StreamSubscription<List<Map<String, dynamic>>>? _peerSub;
  StreamSubscription<List<Map<String, dynamic>>>? _peerTypingSub;

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser?.id ?? '';
    final ids = [currentUserId, widget.peerId]..removeWhere((e) => e.isEmpty);
    ids.sort();
    chatId = ids.join('_');

    _fetchInitialMessages();
  }

  Future<void> _fetchInitialMessages() async {
    try {
      final resp = await supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false);
      setState(() {
        _initialMessages = List<Map<String, dynamic>>.from(resp ?? []);
        _messagesLoaded = true;
      });
    } catch (e) {
      debugPrint('Failed to load initial messages: $e');
      setState(() => _messagesLoaded = true);
    }
  }

  Future<void> _decryptAndCache(String rawText, String id) async {
    try {
      final decoded = jsonDecode(rawText);
      if (decoded is Map && decoded['enc'] == true && _symmetricKey != null) {
        final nonce = base64Decode(decoded['n']);
        final cipher = base64Decode(decoded['c']);
        final mac = base64Decode(decoded['m']);
        final secretBox = SecretBox(cipher, nonce: nonce, mac: Mac(mac));
        final aes = AesGcm.with256bits();
        final clear = await aes.decrypt(secretBox, secretKey: _symmetricKey!);
        final text = utf8.decode(clear);
        if (mounted) setState(() => _decryptedCache[id] = text);
        return;
      }
    } catch (e) {
      // ignore and fall back to raw
    }
    if (mounted) setState(() => _decryptedCache[id] = rawText);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (currentUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Not authenticated')));
      }
      return;
    }

    try {
      String payload = text.trim();
      if (_symmetricKey != null) {
        final aes = AesGcm.with256bits();
        final nonce = aes.newNonce();
        final secretBox = await aes.encrypt(utf8.encode(text.trim()),
            secretKey: _symmetricKey!, nonce: nonce);
        final obj = {
          'enc': true,
          'n': base64Encode(secretBox.nonce),
          'c': base64Encode(secretBox.cipherText),
          'm': base64Encode(secretBox.mac.bytes),
        };
        payload = jsonEncode(obj);
      }

      await supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'receiver_id': widget.peerId,
        'text': payload,
      });
      _controller.clear();
    } catch (e) {
      debugPrint('Send message error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _messagesStream() {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((event) {
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    _peerSub?.cancel();
    _peerTypingSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Building ChatScreen for peer="${widget.peerName}" (peerId=${widget.peerId})');
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: (widget.peerProfileUrl.isNotEmpty)
                      ? NetworkImage(widget.peerProfileUrl)
                      : null,
                  child: (widget.peerProfileUrl.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
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
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Tooltip(
                message: 'Encryption status',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _symmetricKey != null
                        ? Colors.green[600]
                        : Colors.grey[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _symmetricKey != null ? Icons.lock : Icons.lock_open,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _symmetricKey != null ? 'Encrypted' : 'Not encrypted',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Messages stream error: ${snapshot.error}');
                }

                final liveDocs = snapshot.data;
                final docs = (liveDocs == null ||
                        snapshot.connectionState == ConnectionState.waiting)
                    ? _initialMessages
                    : liveDocs;

                if (!_messagesLoaded && (docs.isEmpty)) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12).copyWith(bottom: 120),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final senderId = data['sender_id']?.toString() ?? '';
                    final rawText = data['text']?.toString() ?? '';
                    final msgId = data['id']?.toString() ?? index.toString();
                    String text;

                    if (_decryptedCache.containsKey(msgId)) {
                      text = _decryptedCache[msgId]!;
                    } else {
                      bool looksEncrypted = false;
                      try {
                        final decoded = jsonDecode(rawText);
                        if (decoded is Map && decoded['enc'] == true)
                          looksEncrypted = true;
                      } catch (_) {
                        looksEncrypted = false;
                      }

                      if (looksEncrypted && _symmetricKey != null) {
                        _decryptAndCache(rawText, msgId);
                        text = 'Decrypting...';
                      } else {
                        text = rawText;
                      }
                    }
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white,
                  child: Container(
                    key: const ValueKey('composer_overlay'),
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 12),
                              ),
                              style: const TextStyle(color: Colors.black87),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (val) => _sendMessage(val),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_symmetricKey != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Icon(Icons.lock,
                                size: 18, color: Colors.green[700]),
                          ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.pinkAccent,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: () => _sendMessage(_controller.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
