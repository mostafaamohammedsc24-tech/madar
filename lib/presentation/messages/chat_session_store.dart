import 'models/chat_models.dart';

/// Session-scoped chat transcripts so popping a room does not lose messages.
class ChatSessionStore {
  ChatSessionStore._();
  static final ChatSessionStore instance = ChatSessionStore._();

  final Map<String, List<ChatMessage>> _threads = {};

  List<ChatMessage> messagesFor(String threadId) {
    return _threads.putIfAbsent(threadId, () {
      if (threadId == 'ai') {
        return [
          ChatMessage(
            id: 'ai-welcome',
            content:
                'مرحباً، أنا مساعد مدار الذكي. اسألني عن **شقق** أو **فلل** أو أي عقار في العراق.',
            isUser: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
            senderType: 'ai',
          ),
        ];
      }
      return <ChatMessage>[];
    });
  }

  void add(String threadId, ChatMessage message) {
    messagesFor(threadId).add(message);
  }

  ChatMessage? last(String threadId) {
    final list = messagesFor(threadId);
    if (list.isEmpty) return null;
    return list.last;
  }
}
