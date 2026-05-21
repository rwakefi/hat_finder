import 'package:flutter/material.dart';
import '../services/agent_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final query = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _isLoading = true;
    });
    _controller.clear();

    final response = await AgentService.chatWithAgent(query);

    setState(() {
      _messages.add({'role': 'agent', 'content': response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask the AI Stylist'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A3525), // Softer, warmer brown
              Color(0xFF1E140E), // Deeper brown
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFFCBB593)
                            : const Color(0xFF2B1D14),
                        borderRadius: BorderRadius.circular(2), // Sharp corners
                        border: isUser
                            ? null
                            : Border.all(
                                color: const Color(0xFFCBB593)
                                    .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        msg['content'] ?? '',
                        style: TextStyle(
                          color: isUser
                              ? const Color(0xFF2B1D14)
                              : const Color(0xFFF5F0E8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCBB593)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Color(0xFFF5F0E8)),
                      decoration: InputDecoration(
                        hintText: 'e.g. I have a round face, what hat is best?',
                        hintStyle: TextStyle(
                            color:
                                const Color(0xFFF5F0E8).withValues(alpha: 0.5)),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFCBB593)),
                          borderRadius: BorderRadius.zero,
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFFCBB593), width: 2),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: const Color(0xFFCBB593),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
