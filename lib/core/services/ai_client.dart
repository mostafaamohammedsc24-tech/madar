import '../services/aiIntegrations/chat_completion_service.dart';
import '../services/aiIntegrations/direct_llm_client.dart';
import '../../providers/chat_notifier.dart';

export '../../providers/chat_notifier.dart' show ChatConfig;

class AiClient {
  final DirectLlmClient _direct = DirectLlmClient();

  /// Chat completion: Lambda when configured, otherwise Qwen → Gemini direct.
  Future<String?> chatCompletion({
    required ChatConfig config,
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic> parameters = const {},
  }) async {
    const lambdaUrl = String.fromEnvironment('AWS_LAMBDA_CHAT_COMPLETION_URL');
    if (lambdaUrl.isNotEmpty) {
      try {
        final result = await getChatCompletion(
          config.provider,
          config.model,
          messages,
          parameters: parameters,
        );
        return result['choices']?[0]?['message']?['content'] as String?;
      } catch (_) {
        // Fall through to direct providers.
      }
    }

    if (DirectLlmClient.hasAnyKey) {
      return _direct.complete(
        messages: messages,
        temperature: (parameters['temperature'] as num?)?.toDouble() ?? 0.4,
        maxTokens: (parameters['max_tokens'] as num?)?.toInt() ?? 2048,
      );
    }

    return null;
  }
}
