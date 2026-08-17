import 'dart:convert';

import 'property_language.dart';
import 'property_report.dart';

/// Keys for human-readable property fields that may be AI-translated.
abstract class TranslationFieldKeys {
  static const title = 'title';
  static const description = 'description';
  static const whatsSpecialHeadline = 'whats_special.headline';
  static const whatsSpecialBody = 'whats_special.body';
  static const whatsSpecialHighlights = 'whats_special.highlights';
  static const whatsSpecialInvestmentNotes = 'whats_special.investment_notes';
  static const neighborhoodSummary = 'neighborhood.summary';
  static const neighborhoodAccessibility = 'neighborhood.accessibility';
  static const rentToOwnEligibility = 'rent_to_own.eligibility';
  static const rentToOwnConditions = 'rent_to_own.conditions';
  static const publisherNotes = 'publisher.notes';
  static const locationDescription = 'location.description';
  static const interiorPrefix = 'interior.';
  static const exteriorPrefix = 'exterior.';
  static const utilitiesPrefix = 'utilities.';
  static const energyPrefix = 'energy.';
  static const buildingPrefix = 'building.';
  static const renovationPrefix = 'renovation.';
  static const developmentPrefix = 'development.';
  static const infrastructurePrefix = 'infrastructure.';
  static const futureProjectPrefix = 'future_project.';
  static const amenityPrefix = 'amenity.';
}

/// Snapshot of all translatable strings extracted from a [PropertyReport].
class PropertyTranslatablePayload {
  const PropertyTranslatablePayload({
    required this.fields,
    required this.contentVersion,
    required this.originalLanguage,
  });

  /// Flat key → original text (or JSON-encoded list for multi-line fields).
  final Map<String, String> fields;
  final String contentVersion;
  final ContentLanguage originalLanguage;

  bool get isEmpty => fields.isEmpty;
  bool get isNotEmpty => fields.isNotEmpty;

  String fingerprint() {
    final sorted = fields.keys.toList()..sort();
    final buf = StringBuffer(contentVersion);
    for (final k in sorted) {
      buf.write('|$k=${fields[k]}');
    }
    return buf.toString().hashCode.toRadixString(16);
  }

  static PropertyTranslatablePayload fromReport(PropertyReport report) {
    final fields = <String, String>{};

    void put(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) fields[key] = v;
    }

    void putList(String key, List<String> values) {
      final cleaned = values.map((e) => e.trim()).where((e) => e.isNotEmpty);
      if (cleaned.isNotEmpty) fields[key] = jsonEncode(cleaned.toList());
    }

    void putFeatureBag(String prefix, Map<String, dynamic> entries) {
      for (final e in entries.entries) {
        final v = e.value;
        if (v is String && v.trim().isNotEmpty) {
          fields['$prefix${e.key}'] = v.trim();
        }
      }
    }

    put(TranslationFieldKeys.title, report.title);
    put(TranslationFieldKeys.description, report.description);

    final ws = report.whatsSpecial;
    if (ws != null) {
      put(TranslationFieldKeys.whatsSpecialHeadline, ws.headline);
      put(TranslationFieldKeys.whatsSpecialBody, ws.body);
      putList(TranslationFieldKeys.whatsSpecialHighlights, ws.highlights);
      putList(
        TranslationFieldKeys.whatsSpecialInvestmentNotes,
        ws.investmentNotes,
      );
    }

    final n = report.surroundings.neighborhood;
    if (n != null) {
      put(TranslationFieldKeys.neighborhoodSummary, n.summary);
      put(
        TranslationFieldKeys.neighborhoodAccessibility,
        n.accessibilityNotes,
      );
    }

    final lto = report.rentToOwn;
    if (lto != null) {
      put(TranslationFieldKeys.rentToOwnEligibility, lto.eligibilityNotes);
      put(TranslationFieldKeys.rentToOwnConditions, lto.ownershipConditions);
    }

    putFeatureBag(
      TranslationFieldKeys.interiorPrefix,
      report.features.interior.entries,
    );
    putFeatureBag(
      TranslationFieldKeys.exteriorPrefix,
      report.features.exterior.entries,
    );
    putFeatureBag(
      TranslationFieldKeys.utilitiesPrefix,
      report.features.utilities.entries,
    );
    putFeatureBag(
      TranslationFieldKeys.energyPrefix,
      report.features.energy.entries,
    );
    putFeatureBag(
      TranslationFieldKeys.buildingPrefix,
      report.features.building.entries,
    );
    putFeatureBag(
      TranslationFieldKeys.renovationPrefix,
      report.features.renovation.entries,
    );
    putFeatureBag(
      TranslationFieldKeys.developmentPrefix,
      report.features.developmentPotential.entries,
    );

    for (var i = 0; i < report.surroundings.infrastructureNotes.length; i++) {
      put(
        '${TranslationFieldKeys.infrastructurePrefix}$i',
        report.surroundings.infrastructureNotes[i],
      );
    }

    for (final p in report.surroundings.futureProjects) {
      put('${TranslationFieldKeys.futureProjectPrefix}${p.id}.name', p.name);
      put(
        '${TranslationFieldKeys.futureProjectPrefix}${p.id}.description',
        p.description,
      );
    }

    for (var i = 0; i < report.features.amenityTags.length; i++) {
      put(
        '${TranslationFieldKeys.amenityPrefix}$i',
        report.features.amenityTags[i],
      );
    }

    final lang = report.originalLanguage;
    final version = report.contentVersion;

    return PropertyTranslatablePayload(
      fields: fields,
      contentVersion: version,
      originalLanguage: lang,
    );
  }
}

/// Cached AI translation for one property + target language + content version.
class PropertyTranslationBundle {
  const PropertyTranslationBundle({
    required this.propertyId,
    required this.originalLanguage,
    required this.targetLanguage,
    required this.sourceContentVersion,
    required this.translationVersion,
    required this.originalContent,
    required this.translatedContent,
    this.createdAt,
    this.provider,
  });

  final String propertyId;
  final ContentLanguage originalLanguage;
  final ContentLanguage targetLanguage;
  final String sourceContentVersion;
  final String translationVersion;
  final Map<String, String> originalContent;
  final Map<String, String> translatedContent;
  final DateTime? createdAt;
  final String? provider;

  bool isValidFor(String contentVersion) =>
      sourceContentVersion == contentVersion;

  String? translated(String key) => translatedContent[key];
  String? original(String key) => originalContent[key];

  String display(String key, {required bool showTranslated}) {
    if (showTranslated) {
      return translatedContent[key] ?? originalContent[key] ?? '';
    }
    return originalContent[key] ?? '';
  }

  List<String> displayList(String key, {required bool showTranslated}) {
    final raw = display(key, showTranslated: showTranslated);
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [raw];
  }

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'original_language': originalLanguage.code,
        'target_language': targetLanguage.code,
        'source_content_version': sourceContentVersion,
        'translation_version': translationVersion,
        'original_content': originalContent,
        'translated_content': translatedContent,
        'provider': provider,
        'created_at': createdAt?.toIso8601String(),
      };

  factory PropertyTranslationBundle.fromJson(Map<String, dynamic> json) {
    Map<String, String> asStringMap(dynamic v) {
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val.toString()));
      }
      return {};
    }

    return PropertyTranslationBundle(
      propertyId: json['property_id']?.toString() ?? '',
      originalLanguage:
          ContentLanguage.parse(json['original_language'] as String?),
      targetLanguage:
          ContentLanguage.parse(json['target_language'] as String?),
      sourceContentVersion:
          json['source_content_version']?.toString() ?? '',
      translationVersion: json['translation_version']?.toString() ?? '1',
      originalContent: asStringMap(json['original_content']),
      translatedContent: asStringMap(json['translated_content']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      provider: json['provider'] as String?,
    );
  }
}

/// Display overlay: original report texts with optional translation applied.
class PropertyLocalizedTexts {
  const PropertyLocalizedTexts({
    required this.title,
    this.description,
    this.whatsSpecialHeadline,
    this.whatsSpecialBody,
    this.whatsSpecialHighlights = const [],
    this.whatsSpecialInvestmentNotes = const [],
    this.neighborhoodSummary,
    this.rentToOwnEligibility,
    this.rentToOwnConditions,
    this.amenityTags = const [],
    this.isTranslated = false,
    this.isAiGenerated = false,
  });

  final String title;
  final String? description;
  final String? whatsSpecialHeadline;
  final String? whatsSpecialBody;
  final List<String> whatsSpecialHighlights;
  final List<String> whatsSpecialInvestmentNotes;
  final String? neighborhoodSummary;
  final String? rentToOwnEligibility;
  final String? rentToOwnConditions;
  final List<String> amenityTags;
  final bool isTranslated;
  final bool isAiGenerated;

  factory PropertyLocalizedTexts.fromReport(
    PropertyReport report, {
    PropertyTranslationBundle? bundle,
    bool showTranslated = false,
  }) {
    if (bundle == null || !showTranslated) {
      return PropertyLocalizedTexts(
        title: report.title,
        description: report.description,
        whatsSpecialHeadline: report.whatsSpecial?.headline,
        whatsSpecialBody: report.whatsSpecial?.body,
        whatsSpecialHighlights: report.whatsSpecial?.highlights ?? const [],
        whatsSpecialInvestmentNotes:
            report.whatsSpecial?.investmentNotes ?? const [],
        neighborhoodSummary: report.surroundings.neighborhood?.summary,
        rentToOwnEligibility: report.rentToOwn?.eligibilityNotes,
        rentToOwnConditions: report.rentToOwn?.ownershipConditions,
        amenityTags: report.features.amenityTags,
        isTranslated: false,
      );
    }

    String? opt(String key, String? fallback) {
      final t = bundle.translated(key);
      if (t != null && t.isNotEmpty) return t;
      return fallback;
    }

    return PropertyLocalizedTexts(
      title: opt(TranslationFieldKeys.title, report.title) ?? report.title,
      description: opt(TranslationFieldKeys.description, report.description),
      whatsSpecialHeadline: opt(
        TranslationFieldKeys.whatsSpecialHeadline,
        report.whatsSpecial?.headline,
      ),
      whatsSpecialBody: opt(
        TranslationFieldKeys.whatsSpecialBody,
        report.whatsSpecial?.body,
      ),
      whatsSpecialHighlights: bundle.displayList(
        TranslationFieldKeys.whatsSpecialHighlights,
        showTranslated: true,
      ),
      whatsSpecialInvestmentNotes: bundle.displayList(
        TranslationFieldKeys.whatsSpecialInvestmentNotes,
        showTranslated: true,
      ),
      neighborhoodSummary: opt(
        TranslationFieldKeys.neighborhoodSummary,
        report.surroundings.neighborhood?.summary,
      ),
      rentToOwnEligibility: opt(
        TranslationFieldKeys.rentToOwnEligibility,
        report.rentToOwn?.eligibilityNotes,
      ),
      rentToOwnConditions: opt(
        TranslationFieldKeys.rentToOwnConditions,
        report.rentToOwn?.ownershipConditions,
      ),
      amenityTags: [
        for (var i = 0; i < report.features.amenityTags.length; i++)
          bundle.translated('${TranslationFieldKeys.amenityPrefix}$i') ??
              report.features.amenityTags[i],
      ],
      isTranslated: true,
      isAiGenerated: true,
    );
  }
}
