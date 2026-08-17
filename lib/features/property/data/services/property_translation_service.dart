import 'dart:convert';

import '../../../../core/services/aiIntegrations/chat_completion_service.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/models/property_language.dart';
import '../../domain/models/property_report.dart';
import '../../domain/models/property_translation.dart';

/// AI-backed property translation with versioned cache.
/// Never mutates original property content.
class PropertyTranslationService {
  PropertyTranslationService({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  static const _provider = 'GEMINI';
  static const _model = 'gemini/gemini-2.5-flash';

  /// In-memory cache keyed by propertyId|target|contentVersion
  final Map<String, PropertyTranslationBundle> _memory = {};

  String _cacheKey(
    String propertyId,
    ContentLanguage target,
    String contentVersion,
  ) =>
      '$propertyId|${target.code}|$contentVersion';

  Future<PropertyTranslationBundle?> getCached({
    required String propertyId,
    required ContentLanguage targetLanguage,
    required String contentVersion,
  }) async {
    final key = _cacheKey(propertyId, targetLanguage, contentVersion);
    final mem = _memory[key];
    if (mem != null && mem.isValidFor(contentVersion)) return mem;

    try {
      final row = await _supabase.client
          .from('property_translations')
          .select()
          .eq('property_id', propertyId)
          .eq('target_language', targetLanguage.code)
          .eq('source_content_version', contentVersion)
          .maybeSingle();
      if (row == null) return null;
      final bundle = PropertyTranslationBundle.fromJson(
        Map<String, dynamic>.from(row),
      );
      _memory[key] = bundle;
      return bundle;
    } catch (_) {
      return null;
    }
  }

  Future<PropertyTranslationBundle> translateProperty({
    required PropertyReport report,
    required ContentLanguage targetLanguage,
    ContentLanguage? detectedSource,
  }) async {
    final payload = PropertyTranslatablePayload.fromReport(report);
    final sourceLang = detectedSource ??
        (report.originalLanguage == ContentLanguage.unknown
            ? ContentLanguage.unknown
            : report.originalLanguage);

    if (sourceLang.matches(targetLanguage) &&
        sourceLang != ContentLanguage.unknown) {
      return PropertyTranslationBundle(
        propertyId: report.id,
        originalLanguage: sourceLang,
        targetLanguage: targetLanguage,
        sourceContentVersion: report.contentVersion,
        translationVersion: 'passthrough',
        originalContent: payload.fields,
        translatedContent: Map<String, String>.from(payload.fields),
        createdAt: DateTime.now(),
        provider: 'passthrough',
      );
    }

    final cached = await getCached(
      propertyId: report.id,
      targetLanguage: targetLanguage,
      contentVersion: report.contentVersion,
    );
    if (cached != null) return cached;

    final translated = await _callAiTranslate(
      fields: payload.fields,
      source: sourceLang,
      target: targetLanguage,
    );

    final bundle = PropertyTranslationBundle(
      propertyId: report.id,
      originalLanguage: sourceLang,
      targetLanguage: targetLanguage,
      sourceContentVersion: report.contentVersion,
      translationVersion: DateTime.now().millisecondsSinceEpoch.toString(),
      originalContent: payload.fields,
      translatedContent: translated,
      createdAt: DateTime.now(),
      provider: '$_provider/$_model',
    );

    _memory[_cacheKey(report.id, targetLanguage, report.contentVersion)] =
        bundle;
    await _persist(bundle);
    return bundle;
  }

  Future<Map<String, String>> _callAiTranslate({
    required Map<String, String> fields,
    required ContentLanguage source,
    required ContentLanguage target,
  }) async {
    if (fields.isEmpty) return {};

    final system = '''
You are a professional real-estate translator for Middle East & North Africa markets.
Translate property listing content from ${source.code} to ${target.code}.

Rules:
- Natural, professional real-estate language — NOT word-for-word literal translation.
- Preserve meaning, numbers, currencies, units (m²), place names, project names, company names.
- Keep real-estate terms accurate (ownership, mortgage, rent, rent-to-own, deed, brokerage, taxes, land, investment).
- Do NOT translate or alter: prices, areas, room counts, coordinates, dates, IDs, technical codes.
- If a value is a JSON array string, return a JSON array string with each item translated.
- Return ONLY valid JSON object mapping the same keys to translated strings.
- No markdown fences. No commentary.
''';

    final user = jsonEncode({
      'source_language': source.code,
      'target_language': target.code,
      'fields': fields,
    });

    try {
      final response = await getChatCompletion(
        _provider,
        _model,
        [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        parameters: {'temperature': 0.2, 'max_tokens': 4000},
      );

      final content = _extractContent(response);
      final parsed = _parseJsonObject(content);
      if (parsed == null) {
        // Soft fallback: return originals rather than inventing.
        return Map<String, String>.from(fields);
      }

      final out = <String, String>{};
      for (final key in fields.keys) {
        final v = parsed[key];
        out[key] = v?.toString() ?? fields[key]!;
      }
      return out;
    } catch (_) {
      return Map<String, String>.from(fields);
    }
  }

  String _extractContent(Map<String, dynamic> response) {
    final choices = response['choices'];
    if (choices is List && choices.isNotEmpty) {
      final msg = choices.first['message'];
      if (msg is Map && msg['content'] != null) {
        return msg['content'].toString();
      }
    }
    if (response['content'] != null) return response['content'].toString();
    if (response['response'] != null) return response['response'].toString();
    return response.toString();
  }

  Map<String, dynamic>? _parseJsonObject(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?'), '').trim();
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3).trim();
      }
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          final decoded = jsonDecode(text.substring(start, end + 1));
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> _persist(PropertyTranslationBundle bundle) async {
    try {
      await _supabase.client.from('property_translations').upsert({
        'property_id': bundle.propertyId,
        'original_language': bundle.originalLanguage.code,
        'target_language': bundle.targetLanguage.code,
        'source_content_version': bundle.sourceContentVersion,
        'translation_version': bundle.translationVersion,
        'original_content': bundle.originalContent,
        'translated_content': bundle.translatedContent,
        'provider': bundle.provider,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Cache table may not exist yet — memory cache still works.
    }
  }

  /// Build grounded AI system prompt from structured property + optional translation.
  static String buildPropertyAiSystemPrompt({
    required PropertyReport report,
    PropertyTranslationBundle? translation,
    required ContentLanguage replyLanguage,
  }) {
    final buf = StringBuffer();
    buf.writeln(
      'You are a property-specific advisor for ONE listing only. '
      'Reply in language code: ${replyLanguage.code}.',
    );
    buf.writeln(
      'Never invent prices, taxes, ownership history, future projects, '
      'areas, yields, or legal facts. If unknown, say clearly that '
      'confirmed information is not available.',
    );
    buf.writeln(
      'Distinguish Verified vs Publisher Provided vs Estimated vs External '
      'vs your AI analysis when answering.',
    );
    buf.writeln();
    buf.writeln('STRUCTURED PROPERTY DATA:');
    buf.writeln('- id: ${report.id}');
    buf.writeln('- title (original): ${report.title}');
    buf.writeln('- status: ${report.status.wireValue}');
    buf.writeln('- price: ${report.pricing.currentPrice?.format() ?? 'n/a'}');
    buf.writeln('- price/m²: ${report.pricing.pricePerSqm?.format() ?? 'n/a'}');
    buf.writeln('- area: ${report.areas.primary?.format() ?? 'n/a'}');
    buf.writeln(
      '- beds/baths: ${report.facts.bedrooms ?? '-'}/'
      '${report.facts.bathrooms ?? '-'}',
    );
    buf.writeln('- type: ${report.facts.propertyType ?? 'n/a'}');
    buf.writeln('- location: ${report.location.displayLine}');
    buf.writeln('- originalLanguage: ${report.originalLanguage.code}');
    buf.writeln('- contentVersion: ${report.contentVersion}');
    buf.writeln('- verified: ${report.isVerified}');
    buf.writeln('- description (original): ${report.description ?? 'n/a'}');
    buf.writeln(
      '- whatsSpecial (original): ${report.whatsSpecial?.body ?? 'n/a'}',
    );
    buf.writeln(
      '- amenities: ${report.features.amenityTags.join(', ')}',
    );
    buf.writeln(
      '- rentToOwn available: ${report.rentToOwn?.isAvailable == true}',
    );
    if (report.rentToOwn?.isAvailable == true) {
      buf.writeln(
        '- rentToOwn monthly: '
        '${report.rentToOwn?.monthlyPayment?.format() ?? 'n/a'}',
      );
    }
    if (report.surroundings.nearbyPlaces.isNotEmpty) {
      buf.writeln(
        '- nearby: ${report.surroundings.nearbyPlaces.take(8).map((p) => p.name).join(', ')}',
      );
    }
    if (report.surroundings.futureProjects.isNotEmpty) {
      buf.writeln(
        '- futureProjects: ${report.surroundings.futureProjects.map((p) => p.name).join(', ')}',
      );
    }
    if (translation != null) {
      buf.writeln();
      buf.writeln(
        'TRANSLATION (${translation.originalLanguage.code} → '
        '${translation.targetLanguage.code}, version '
        '${translation.translationVersion}):',
      );
      translation.translatedContent.forEach((k, v) {
        buf.writeln('- $k: $v');
      });
      buf.writeln(
        'You may use original + structured data + translation. '
        'Prefer structured numbers over translated prose when they conflict.',
      );
    }
    return buf.toString();
  }
}
