class ChatMessage {
  final String id;
  final String message;
  final int type; // 0 for User, 1 for AI
  final int timestamp;
  // Only meaningful for AI messages: whether this reply came from the live
  // Gemini API (true) or the offline built-in knowledge base (false/null).
  final bool? isLive;

  static const int typeUser = 0;
  static const int typeAI = 1;

  ChatMessage({
    this.id = '',
    required this.message,
    required this.type,
    required this.timestamp,
    this.isLive,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId,
      message: map['message'] ?? '',
      type: map['type'] ?? 0,
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'type': type,
      'timestamp': timestamp,
    };
  }
}
