import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../models/chat_message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late final AIService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = AIService();
    _messages.add(ChatMessage(
      message: "Hello! I am your AI Government Assistant. How can I help you today?",
      type: ChatMessage.typeAI,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        message: text,
        type: ChatMessage.typeUser,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final response = await _aiService.askQuestion(text);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          message: response.text,
          type: ChatMessage.typeAI,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          isLive: response.isLive,
        ));
      });
      _scrollToBottom();
      _saveToHistory(text, response.text);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _saveToHistory(String question, String answer) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('chat_history').add({
        'userId': user.uid,
        'question': question,
        'answer': answer,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAI = msg.type == ChatMessage.typeAI;
                return Align(
                  alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAI ? Colors.grey[200] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(msg.message),
                        // Transparency badge: tells the user honestly whether
                        // this answer came from the live Gemini API or the
                        // offline built-in guide, instead of both looking
                        // identical.
                        if (isAI && msg.isLive != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                msg.isLive! ? Icons.bolt : Icons.menu_book,
                                size: 12,
                                color: msg.isLive! ? Colors.green[700] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                msg.isLive! ? 'Live AI answer' : 'Offline guide answer',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: msg.isLive! ? Colors.green[700] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('AI is typing...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Ask anything...', border: OutlineInputBorder()),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
