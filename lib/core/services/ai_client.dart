import '../services/aiIntegrations/chat_completion_service.dart';
import '../../providers/chat_notifier.dart';

export '../../providers/chat_notifier.dart' show ChatConfig;

class AiClient {
  /// Simple non-streaming chat completion that returns the response text
  Future<String?> chatCompletion({
    required ChatConfig config,
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic> parameters = const {},
  }) async {
    try {
      final result = await getChatCompletion(
        config.provider,
        config.model,
        messages,
        parameters: parameters,
      );
      return result['choices']?[0]?['message']?['content'] as String?;
    } catch (e) {
      return null;
    }
  }
}
