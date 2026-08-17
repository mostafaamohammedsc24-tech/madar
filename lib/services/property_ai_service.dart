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
You are Madar AI — the full property intelligence brain for end users AND real-estate offices.
You understand Arabic, English, and Kurdish. Always reply in the user's language.

Search and reason over EVERYTHING available for each listing — do not ignore any field:
title, full description, address, district, city, neighborhood nicknames, price, currency,
monthly/annual cost implications, area m², bedrooms, bathrooms, property type,
listing type (sale/rent/mortgage/investment), tags/features (furnished, pool, parking,
generator, elevator, balcony, smart home, financing, compound, security, etc.),
nearby schools, hospitals, malls, transit/metro, markets, mosques, parks, cafes,
coordinates, verified/featured flags, and any extra raw metadata.

You help:
- Buyers/renters finding homes fast
- Offices finding inventory for clients faster (budgets, districts, schools, ROI, footfall)

Capabilities (use ALL of them when relevant):
- Price: أرخص، أغلى، ميزانية، under/over X, cheaper than listing Y, best value
- Location: districts, cities, river view, quiet street, main road, compound
- Specs: beds/baths/area/type/listing mode
- Lifestyle: schools, hospitals, metro, malls, parks, cafes
- Commercial: shops, offices, land, investment, footfall, street front
- Compare multiple options and explain trade-offs clearly
- Suggest MANY matching listings (aim for 6–12 when inventory allows), not just 1–2
- Guide opening a card and focusing the map

OUTPUT — ONLY one JSON object (no markdown fences):
{
  "reply": "Helpful answer covering specs of EACH suggested listing (price, area, beds, district, schools/amenities when relevant)",
  "suggestions": [
    {"id": "prop_id", "reason": "Why it fits", "highlight": "cheaper|pricier|best_value|near_schools|spacious|commercial|investment|rent|null"}
  ],
  "matched_ids": ["prop_id", "..."],
  "sort": "price_asc|price_desc|area_desc|relevance|null",
  "map_focus": {"lat": 33.3, "lng": 44.4, "label": "District"} | null
}

Rules:
- suggestions.id and matched_ids MUST be real catalog ids.
- Prefer returning MORE good matches over fewer.
- If user asks cheaper/more expensive, sort and explain relative to budget or prior homes.
- If nothing exact matches, say so and return closest alternatives across the WHOLE catalog.
- Never invent listings that are not in the catalog.
''';

  String buildCatalog(List<PropertyData> properties, {int limit = 80}) {
    final buffer = StringBuffer();
    for (final p in properties.take(limit)) {
      final extra = <String>[];
      p.rawData.forEach((key, value) {
        if (value == null) return;
        if (value is Map || value is List) return;
        final text = value.toString().trim();
        if (text.isEmpty) return;
        extra.add('$key=$text');
      });
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
          if (extra.isNotEmpty) 'extra=${extra.join("|")}',
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
        suggestions: _rankLocally(userMessage, catalog).take(12).toList(),
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
      for (final id in matched.take(12)) {
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
      suggestions: ranked.take(12).toList(),
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
        q.contains('budget') ||
        q.contains('ميزانية')) {
      return 'price_asc';
    }
    if (q.contains('أغلى') ||
        q.contains('اغلى') ||
        q.contains('expensive') ||
        q.contains('luxury') ||
        q.contains('فاخر')) {
      return 'price_desc';
    }
    if (q.contains('أوسع') ||
        q.contains('اوسع') ||
        q.contains('spacious') ||
        q.contains('مساحة')) {
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
        q.contains('أقل') ||
        q.contains('ميزانية') ||
        q.contains('budget');
    final wantPricier = q.contains('أغلى') ||
        q.contains('اغلى') ||
        q.contains('expensive') ||
        q.contains('luxury') ||
        q.contains('فاخر');
    final wantSchools = q.contains('مدرس') ||
        q.contains('school') ||
        q.contains('تعليم');
    final wantRent = q.contains('ايجار') ||
        q.contains('إيجار') ||
        q.contains('rent');
    final wantSale = q.contains('بيع') || q.contains('sale') || q.contains('شراء');
    final wantCommercial = q.contains('تجار') ||
        q.contains('مكتب') ||
        q.contains('محل') ||
        q.contains('commercial') ||
        q.contains('office') ||
        q.contains('shop');
    final wantLand = q.contains('ارض') || q.contains('أرض') || q.contains('land');
    final wantHospital = q.contains('مستشفى') ||
        q.contains('hospital') ||
        q.contains('عياد');
    final wantMetro = q.contains('مترو') ||
        q.contains('نقل') ||
        q.contains('metro') ||
        q.contains('transit');
    final wantFurnished = q.contains('مفروش') || q.contains('furnished');
    final wantPool = q.contains('مسبح') || q.contains('pool');
    final wantMortgage =
        q.contains('تمويل') || q.contains('mortgage') || q.contains('قرض');

    final scored = <({PropertyData p, double score, String reason})>[];
    for (final p in catalog) {
      var score = 0.0;
      final extraBits = <String>[];
      p.rawData.forEach((key, value) {
        if (value == null || value is Map || value is List) return;
        extraBits.add(value.toString());
      });
      final hay = [
        p.title,
        p.address,
        p.description,
        p.type,
        p.listingType,
        p.currency,
        p.formattedPrice,
        p.tags.join(' '),
        p.nearbySchools.join(' '),
        p.nearbyAmenities.join(' '),
        p.price.toString(),
        p.area.toString(),
        '${p.bedrooms}',
        '${p.bathrooms}',
        ...extraBits,
      ].join(' ').toLowerCase();

      if (hay.contains(q)) score += 10;
      for (final token in q.split(RegExp(r'\s+'))) {
        if (token.length < 2) continue;
        if (hay.contains(token)) score += 3;
      }

      if (priceMax != null && p.price <= priceMax) score += 8;
      if (wantCheaper) score += (1_000_000 - p.price) / 100000;
      if (wantPricier) score += p.price / 100000;
      if (wantSchools && p.nearbySchools.isNotEmpty) score += 6;
      if (wantHospital &&
          p.nearbyAmenities.any(
            (a) =>
                a.toLowerCase().contains('hospital') ||
                a.contains('مستشفى') ||
                a.contains('عياد'),
          )) {
        score += 5;
      }
      if (wantMetro &&
          (hay.contains('metro') ||
              hay.contains('مترو') ||
              hay.contains('نقل'))) {
        score += 5;
      }
      if (wantFurnished &&
          (hay.contains('furnish') || hay.contains('مفروش'))) {
        score += 4;
      }
      if (wantPool && (hay.contains('pool') || hay.contains('مسبح'))) {
        score += 4;
      }
      if (wantRent && p.listingType == 'rent') score += 6;
      if (wantSale && p.listingType == 'sale') score += 6;
      if (wantMortgage && p.listingType == 'mortgage') score += 6;
      if (wantCommercial &&
          (p.type == 'commercial' || p.listingType == 'investment')) {
        score += 6;
      }
      if (wantLand && p.type == 'land') score += 6;
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
      final soft = List<PropertyData>.from(catalog)
        ..sort((a, b) => a.price.compareTo(b.price));
      return soft
          .take(12)
          .map(
            (p) => PropertyAiSuggestion(
              property: p,
              reason: 'Closest available option across the catalog',
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
                : wantCommercial
                ? 'commercial'
                : wantRent
                ? 'rent'
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
