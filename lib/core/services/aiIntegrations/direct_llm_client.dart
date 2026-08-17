import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Direct LLM client: tries Qwen (DashScope) first, then Gemini.
/// Keys come from `--dart-define` / `--dart-define-from-file` only.
class DirectLlmClient {
  DirectLlmClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String qwenApiKey = String.fromEnvironment('QWEN_API_KEY');
  static const String qwenBaseUrl = String.fromEnvironment(
    'QWEN_BASE_URL',
    defaultValue: 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1',
  );
  static const String qwenModel = String.fromEnvironment(
    'QWEN_MODEL',
    defaultValue: 'qwen-plus',
  );

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-flash-latest',
  );

  static bool get hasAnyKey =>
      qwenApiKey.isNotEmpty || geminiApiKey.isNotEmpty;

  /// Returns assistant text, or null if all providers fail.
  Future<String?> complete({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.4,
    int maxTokens = 2048,
  }) async {
    if (qwenApiKey.isNotEmpty) {
      try {
        final text = await _completeQwen(
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
        );
        if (text != null && text.trim().isNotEmpty) return text;
      } catch (e) {
        debugPrint('Qwen failed, falling back to Gemini: $e');
      }
    }

    if (geminiApiKey.isNotEmpty) {
      try {
        return await _completeGemini(
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      } catch (e) {
        debugPrint('Gemini failed: $e');
      }
    }

    return null;
  }

  Future<String?> _completeQwen({
    required List<Map<String, dynamic>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final url = '${qwenBaseUrl.replaceAll(RegExp(r'/$'), '')}/chat/completions';
    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: {
        'model': qwenModel,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $qwenApiKey',
          'Content-Type': 'application/json',
        },
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    final content = response.data?['choices']?[0]?['message']?['content'];
    if (content is String) return content;
    if (content is List) {
      return content
          .map((e) => e is Map ? (e['text'] ?? '') : '$e')
          .join();
    }
    return null;
  }

  Future<String?> _completeGemini({
    required List<Map<String, dynamic>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final systemParts = <String>[];
    final contents = <Map<String, dynamic>>[];

    for (final message in messages) {
      final role = (message['role'] as String? ?? 'user').toLowerCase();
      final content = message['content']?.toString() ?? '';
      if (content.isEmpty) continue;

      if (role == 'system') {
        systemParts.add(content);
        continue;
      }

      contents.add({
        'role': role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': content},
        ],
      });
    }

    if (contents.isEmpty) return null;

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$geminiModel:generateContent?key=$geminiApiKey';

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      },
    };
    if (systemParts.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemParts.join('\n\n')},
        ],
      };
    }

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: body,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    final parts =
        response.data?['candidates']?[0]?['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text']);
      }
    }
    return buffer.toString();
  }

  /// Extracts the first JSON object from a model response (handles markdown fences).
  static Map<String, dynamic>? extractJsonObject(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }
}
