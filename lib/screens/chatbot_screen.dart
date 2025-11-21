import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../secrets.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();

    debugPrint('Initializing Gemini API...');
    try {
      if (Secrets.geminiApiKey.isEmpty) {
        _error = 'Gemini API key is empty!';
        debugPrint(_error);
      } else {
        _model = GenerativeModel(
          model: "gemini-pro",
          apiKey: Secrets.geminiApiKey,
        );
        debugPrint('Gemini API initialized successfully');
      }
    } catch (e) {
      _error = 'Failed to initialize Gemini: $e';
      debugPrint(_error);
    }
  }

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    if (_error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chatbot Error: $_error')),
      );
      return;
    }

    setState(() {
      _messages.add({'sender': 'You', 'text': userMessage});
      _isLoading = true;
    });
    _controller.clear();

    try {
      debugPrint('Sending message to Gemini: $userMessage');
      // Build conversation memory
      final history = _messages
          .map((msg) => Content.text(
              '${msg['sender'] == 'You' ? "User" : "AI"}: ${msg['text']}'))
          .toList();

      // Add the latest message as the user prompt
      final response = await _model.generateContent([
        ...history,
        Content.text(
            "Respond empathetically like a supportive mental wellness assistant. Avoid giving medical or legal advice. The user says: $userMessage")
      ]);

      final aiReply = response.text ??
          "I'm here for you 🌸 Tell me more about how you feel.";

      debugPrint('Gemini response: $aiReply');

      setState(() {
        _messages.add({'sender': 'SheWell AI', 'text': aiReply});
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      String errorMsg = 'I\'m having trouble responding right now.';

      if (e.toString().contains('404')) {
        errorMsg =
            'API key issue - Please contact support. (Error: Invalid API key or model)';
      } else if (e.toString().contains('401')) {
        errorMsg =
            'Authentication failed - Please check API key configuration.';
      } else if (e.toString().contains('not found')) {
        errorMsg = 'Model not available - Please ensure Gemini API is enabled.';
      }

      setState(() {
        _messages.add({'sender': 'SheWell AI', 'text': errorMsg});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink, Colors.pinkAccent],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading bubble
                if (_isLoading && index == 0) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text("SheWell AI is typing..."),
                    ),
                  );
                }

                final msgIndex =
                    _messages.length - 1 - (index - (_isLoading ? 1 : 0));
                final msg = _messages[msgIndex];
                final isUser = msg['sender'] == 'You';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.pinkAccent : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(51, 0, 0, 0),
                          offset: const Offset(1, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                          color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromARGB(230, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(26, 0, 0, 0),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pinkAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
