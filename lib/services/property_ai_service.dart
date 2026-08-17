import '../core/services/aiIntegrations/direct_llm_client.dart';
import '../presentation/search_map_screen/models/property_data.dart';

/// Structured AI answer for chat + search + map.
class PropertyAiResult {
  const PropertyAiResult({
    required this.reply,
    required this.suggestions,
    this.sortHint,
    this.mapFocusLat,
    this.mapFocusLng,
    this.mapFocusLabel,
    this.matchedIds = const [],
    this.provider = 'local',
  });

  final String reply;
  final List<PropertyAiSuggestion> suggestions;
  final String? sortHint;
  final double? mapFocusLat;
  final double? mapFocusLng;
  final String? mapFocusLabel;
  final List<String> matchedIds;
  final String provider;
}

class PropertyAiSuggestion {
  const PropertyAiSuggestion({
    required this.property,
    required this.reason,
    this.highlight,
  });

  final PropertyData property;
  final String reason;
  final String? highlight;
}

/// Natural-language property intelligence for Madar (search bar + AI chat).
class PropertyAiService {
  PropertyAiService({DirectLlmClient? client})
    : _client = client ?? DirectLlmClient();

  final DirectLlmClient _client;

  static const _systemPrompt = '''
You are Madar AI — the property search brain for a real-estate app in Iraq, Saudi Arabia, and the UAE.
You understand Arabic, English, and Kurdish. Always reply in the user's language.

You can search and reason over EVERY field of each listing: title, description, address, district/area, city, price, currency, area m², bedrooms, bathrooms, type, listing type (sale/rent/mortgage), tags/features, nearby schools, hospitals, markets, transit, and map coordinates.

Capabilities you MUST use when asked:
- Find matches by price ("أرخص", "أغلى", under 200k, cheaper than X, budget...).
- Find by area/district/neighborhood, schools nearby, furnished, pool, parking, river view, etc.
- Compare options and explain trade-offs.
- Suggest multiple listings (typically 3–6) with short reasons.
- Guide the user to open a card / see it on the map.

OUTPUT RULES — return ONLY a single JSON object (no markdown fences):
{
  "reply": "Natural helpful answer that mentions key specs of each suggested home",
  "suggestions": [
    {"id": "prop_id", "reason": "Why this fits", "highlight": "cheaper|pricier|best_value|near_schools|spacious|null"}
  ],
  "matched_ids": ["prop_id", "..."],
  "sort": "price_asc|price_desc|area_desc|relevance|null",
  "map_focus": {"lat": 33.3, "lng": 44.4, "label": "Karrada"} | null
}

Rules:
- suggestions.id MUST be real ids from the catalog.
- If the user asks for cheaper/more expensive, sort and explain relative to their budget or the previously discussed homes.
- If nothing matches, say so honestly and suggest the closest alternatives.
- When discussing a home, include price, area, bedrooms, district, and nearby schools if available.
''';

  String buildCatalog(List<PropertyData> properties, {int limit = 40}) {
    final buffer = StringBuffer();
    for (final p in properties.take(limit)) {
      buffer.writeln(
        [
          'ID=${p.id}',
          'title=${p.title}',
          'type=${p.type}',
          'listing=${p.listingType}',
          'price=${p.price} ${p.currency}',
          'area_sqm=${p.area}',
          'beds=${p.bedrooms}',
          'baths=${p.bathrooms}',
          'address=${p.address}',
          'desc=${p.description}',
          'tags=${p.tags.join("|")}',
          'schools=${p.nearbySchools.join("|")}',
          'amenities=${p.nearbyAmenities.join("|")}',
          'lat=${p.lat}',
          'lng=${p.lng}',
          'verified=${p.isVerified}',
          'featured=${p.isFeatured}',
        ].join(' · '),
      );
    }
    return buffer.toString();
  }

  Future<PropertyAiResult> chat({
    required String userMessage,
    required List<PropertyData> catalog,
    List<Map<String, String>> history = const [],
  }) async {
    final catalogText = buildCatalog(catalog);
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'system',
        'content': 'PROPERTY CATALOG:\n$catalogText',
      },
      ...history.map((m) => {'role': m['role'], 'content': m['content']}),
      {'role': 'user', 'content': userMessage},
    ];

    final raw = await _client.complete(
      messages: messages,
      temperature: 0.35,
      maxTokens: 2200,
    );

    if (raw == null || raw.trim().isEmpty) {
      return _localFallback(userMessage, catalog, provider: 'local');
    }

    final parsed = DirectLlmClient.extractJsonObject(raw);
    if (parsed == null) {
      return PropertyAiResult(
        reply: raw.trim(),
        suggestions: _rankLocally(userMessage, catalog).take(4).toList(),
        matchedIds: _rankLocally(
          userMessage,
          catalog,
        ).map((s) => s.property.id).toList(),
        provider: DirectLlmClient.qwenApiKey.isNotEmpty ? 'llm' : 'gemini',
      );
    }

    return _fromJson(parsed, catalog, provider: 'llm');
  }

  /// Search-bar NL query → filtered matches + short reply.
  Future<PropertyAiResult> search({
    required String query,
    required List<PropertyData> catalog,
  }) async {
    if (query.trim().isEmpty) {
      return PropertyAiResult(
        reply: '',
        suggestions: const [],
        matchedIds: catalog.map((p) => p.id).toList(),
        provider: 'local',
      );
    }

    if (!DirectLlmClient.hasAnyKey) {
      return _localFallback(query, catalog, provider: 'local');
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'system',
        'content': 'PROPERTY CATALOG:\n${buildCatalog(catalog)}',
      },
      {
        'role': 'user',
        'content':
            'Search query from the map search bar. Return JSON with matched listings for: "$query"',
      },
    ];

    final raw = await _client.complete(
      messages: messages,
      temperature: 0.2,
      maxTokens: 1600,
    );
    if (raw == null) {
      return _localFallback(query, catalog, provider: 'local');
    }
    final parsed = DirectLlmClient.extractJsonObject(raw);
    if (parsed == null) {
      return _localFallback(query, catalog, provider: 'llm-text');
    }
    return _fromJson(parsed, catalog, provider: 'llm');
  }

  PropertyAiResult _fromJson(
    Map<String, dynamic> json,
    List<PropertyData> catalog, {
    required String provider,
  }) {
    final byId = {for (final p in catalog) p.id: p};
    final suggestions = <PropertyAiSuggestion>[];
    final rawSuggestions = json['suggestions'];
    if (rawSuggestions is List) {
      for (final item in rawSuggestions) {
        if (item is! Map) continue;
        final id = item['id']?.toString() ?? '';
        final property = byId[id];
        if (property == null) continue;
        suggestions.add(
          PropertyAiSuggestion(
            property: property,
            reason: item['reason']?.toString() ?? '',
            highlight: item['highlight']?.toString(),
          ),
        );
      }
    }

    final matched = <String>[];
    final rawMatched = json['matched_ids'];
    if (rawMatched is List) {
      for (final id in rawMatched) {
        final s = id.toString();
        if (byId.containsKey(s)) matched.add(s);
      }
    }
    if (matched.isEmpty) {
      matched.addAll(suggestions.map((s) => s.property.id));
    }
    if (suggestions.isEmpty && matched.isNotEmpty) {
      for (final id in matched.take(6)) {
        suggestions.add(
          PropertyAiSuggestion(
            property: byId[id]!,
            reason: 'Matches your search',
          ),
        );
      }
    }

    double? lat;
    double? lng;
    String? label;
    final focus = json['map_focus'];
    if (focus is Map) {
      lat = (focus['lat'] as num?)?.toDouble();
      lng = (focus['lng'] as num?)?.toDouble();
      label = focus['label']?.toString();
    } else if (suggestions.isNotEmpty) {
      lat = suggestions.first.property.lat;
      lng = suggestions.first.property.lng;
      label = suggestions.first.property.address;
    }

    return PropertyAiResult(
      reply: json['reply']?.toString() ?? '',
      suggestions: suggestions,
      sortHint: json['sort']?.toString(),
      mapFocusLat: lat,
      mapFocusLng: lng,
      mapFocusLabel: label,
      matchedIds: matched,
      provider: provider,
    );
  }

  PropertyAiResult _localFallback(
    String query,
    List<PropertyData> catalog, {
    required String provider,
  }) {
    final ranked = _rankLocally(query, catalog);
    final reply = ranked.isEmpty
        ? (query.trim().isEmpty
              ? ''
              : 'لم أجد تطابقاً مباشراً. جرّب حيّاً أو سعراً أو عدد غرف مختلف.')
        : 'وجدت ${ranked.length} عقاراً مناسباً. إليك أفضل الاقتراحات مع المواصفات.';

    return PropertyAiResult(
      reply: reply,
      suggestions: ranked.take(6).toList(),
      matchedIds: ranked.map((s) => s.property.id).toList(),
      sortHint: _inferSort(query),
      mapFocusLat: ranked.isNotEmpty ? ranked.first.property.lat : null,
      mapFocusLng: ranked.isNotEmpty ? ranked.first.property.lng : null,
      mapFocusLabel: ranked.isNotEmpty ? ranked.first.property.address : null,
      provider: provider,
    );
  }

  String? _inferSort(String query) {
    final q = query.toLowerCase();
    if (q.contains('أرخص') ||
        q.contains('ارخص') ||
        q.contains('cheap') ||
        q.contains('أقل سعر') ||
        q.contains('اقل سعر') ||
        q.contains('budget')) {
      return 'price_asc';
    }
    if (q.contains('أغلى') ||
        q.contains('اغلى') ||
        q.contains('expensive') ||
        q.contains('luxury') ||
        q.contains('فاخر')) {
      return 'price_desc';
    }
    if (q.contains('أوسع') || q.contains('اوسع') || q.contains('spacious')) {
      return 'area_desc';
    }
    return 'relevance';
  }

  List<PropertyAiSuggestion> _rankLocally(
    String query,
    List<PropertyData> catalog,
  ) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      return catalog
          .map(
            (p) => PropertyAiSuggestion(
              property: p,
              reason: 'Available listing',
            ),
          )
          .toList();
    }

    final priceMax = _extractBudget(q);
    final wantCheaper = q.contains('أرخص') ||
        q.contains('ارخص') ||
        q.contains('cheap') ||
        q.contains('أقل');
    final wantPricier = q.contains('أغلى') ||
        q.contains('اغلى') ||
        q.contains('expensive') ||
        q.contains('luxury');
    final wantSchools = q.contains('مدرس') ||
        q.contains('school') ||
        q.contains('تعليم');

    final scored = <({PropertyData p, double score, String reason})>[];
    for (final p in catalog) {
      var score = 0.0;
      final hay = [
        p.title,
        p.address,
        p.description,
        p.type,
        p.listingType,
        p.tags.join(' '),
        p.nearbySchools.join(' '),
        p.nearbyAmenities.join(' '),
        p.price.toString(),
        p.area.toString(),
        '${p.bedrooms}',
      ].join(' ').toLowerCase();

      for (final token in q.split(RegExp(r'\s+'))) {
        if (token.length < 2) continue;
        if (hay.contains(token)) score += 3;
      }

      if (priceMax != null && p.price <= priceMax) score += 8;
      if (wantCheaper) score += (1_000_000 - p.price) / 100000;
      if (wantPricier) score += p.price / 100000;
      if (wantSchools && p.nearbySchools.isNotEmpty) score += 5;
      if (p.isFeatured) score += 1;
      if (p.isVerified) score += 1;

      if (score <= 0) continue;
      scored.add((
        p: p,
        score: score,
        reason: _localReason(p, wantCheaper, wantPricier, wantSchools),
      ));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (wantCheaper) {
      scored.sort((a, b) => a.p.price.compareTo(b.p.price));
    } else if (wantPricier) {
      scored.sort((a, b) => b.p.price.compareTo(a.p.price));
    }

    if (scored.isEmpty) {
      // Soft fallback: return cheapest / featured when no token match
      final soft = List<PropertyData>.from(catalog)
        ..sort((a, b) => a.price.compareTo(b.price));
      return soft
          .take(4)
          .map(
            (p) => PropertyAiSuggestion(
              property: p,
              reason: 'Closest available option',
              highlight: 'best_value',
            ),
          )
          .toList();
    }

    return scored
        .map(
          (e) => PropertyAiSuggestion(
            property: e.p,
            reason: e.reason,
            highlight: wantCheaper
                ? 'cheaper'
                : wantPricier
                ? 'pricier'
                : wantSchools
                ? 'near_schools'
                : null,
          ),
        )
        .toList();
  }

  String _localReason(
    PropertyData p,
    bool cheaper,
    bool pricier,
    bool schools,
  ) {
    final bits = <String>[
      '${p.formattedPrice} · ${p.area.toStringAsFixed(0)} m²',
      if (p.bedrooms > 0) '${p.bedrooms} bed',
      p.address,
      if (schools && p.nearbySchools.isNotEmpty)
        'near ${p.nearbySchools.first}',
      if (cheaper) 'budget-friendly',
      if (pricier) 'premium option',
    ];
    return bits.join(' · ');
  }

  double? _extractBudget(String q) {
    final match = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(k|m|الف|ألف|مليون)?',
      caseSensitive: false,
    ).firstMatch(q);
    if (match == null) return null;
    var value = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0;
    final unit = (match.group(2) ?? '').toLowerCase();
    if (unit == 'k' || unit.contains('الف') || unit.contains('ألف')) {
      value *= 1000;
    } else if (unit == 'm' || unit.contains('مليون')) {
      value *= 1000000;
    } else if (value > 0 && value < 1000 && q.contains('ألف')) {
      value *= 1000;
    }
    return value > 0 ? value : null;
  }
}
