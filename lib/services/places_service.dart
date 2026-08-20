import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/cache/request_cache.dart';

/// One smart-search suggestion: free text, an area/district, or a landmark.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.label,
    required this.kind,
    this.placeId,
    this.location,
    this.polygon,
    this.landmarkType,
  });

  final String label;

  /// 'area' | 'landmark' | 'query'
  final String kind;
  final String? placeId;
  final LatLng? location;
  final List<LatLng>? polygon;
  final String? landmarkType;
}

/// A resolved landmark with location (school, university, mall, gas station…).
class LandmarkResult {
  const LandmarkResult({
    required this.name,
    required this.type,
    required this.location,
  });

  final String name;
  final String type;
  final LatLng location;
}

/// A resolved area with a boundary polygon.
class AreaResult {
  const AreaResult({
    required this.name,
    required this.polygon,
    required this.center,
  });

  final String name;
  final List<LatLng> polygon;
  final LatLng center;
}

/// Google Places (Autocomplete + Details + Nearby) on the Maps API key.
class PlacesService {
  PlacesService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const _nearbyUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Mixed suggestions for the query via Google Places when an API key is set.
  Future<List<PlaceSuggestion>> suggest(
    String query, {
    LatLng? near,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final cacheKey =
        'suggest:${trimmed.toLowerCase()}:${near?.latitude}:${near?.longitude}';
    return placesRequestCache.getOrLoad<List<PlaceSuggestion>>(
      cacheKey,
      () => _suggestUncached(trimmed, near),
      ttl: const Duration(minutes: 5),
    );
  }

  Future<List<PlaceSuggestion>> _suggestUncached(
    String trimmed,
    LatLng? near,
  ) async {
    if (_apiKey.isEmpty) return const [];

    try {
      final response = await _dio.get(
        _autocompleteUrl,
        queryParameters: {
          'input': trimmed,
          'key': _apiKey,
          'language': 'ar',
          if (near != null) 'location': '${near.latitude},${near.longitude}',
          if (near != null) 'radius': '30000',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      final predictions = (response.data['predictions'] as List?) ?? const [];
      final remote = predictions.map((p) {
        final types = List<String>.from(p['types'] as List? ?? const []);
        final isArea = types.any(
          (t) => const {
            'locality',
            'sublocality',
            'neighborhood',
            'administrative_area_level_1',
            'administrative_area_level_2',
            'postal_town',
          }.contains(t),
        );
        return PlaceSuggestion(
          label: p['description'] as String? ?? '',
          kind: isArea ? 'area' : 'landmark',
          placeId: p['place_id'] as String?,
          landmarkType: isArea ? null : _landmarkTypeFromTypes(types),
        );
      }).where((s) => s.label.isNotEmpty);
      return remote.take(8).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Resolve a suggestion into a concrete location (+ viewport polygon).
  Future<AreaResult?> resolveArea(PlaceSuggestion suggestion) async {
    if (suggestion.polygon != null && suggestion.location != null) {
      return AreaResult(
        name: suggestion.label,
        polygon: suggestion.polygon!,
        center: suggestion.location!,
      );
    }
    if (suggestion.placeId == null || _apiKey.isEmpty) return null;

    final cacheKey = 'area:${suggestion.placeId}';
    return placesRequestCache.getOrLoad<AreaResult?>(
      cacheKey,
      () => _resolveAreaRemote(suggestion),
      ttl: const Duration(hours: 1),
    );
  }

  Future<AreaResult?> _resolveAreaRemote(PlaceSuggestion suggestion) async {
    try {
      final response = await _dio.get(
        _detailsUrl,
        queryParameters: {
          'place_id': suggestion.placeId,
          'key': _apiKey,
          'fields': 'geometry,name',
        },
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final geometry = response.data['result']?['geometry'];
      if (geometry == null) return null;
      final loc = geometry['location'];
      final center = LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );
      final viewport = geometry['viewport'];
      List<LatLng> polygon;
      if (viewport != null) {
        final ne = viewport['northeast'];
        final sw = viewport['southwest'];
        polygon = _rectPolygon(
          LatLng((sw['lat'] as num).toDouble(), (sw['lng'] as num).toDouble()),
          LatLng((ne['lat'] as num).toDouble(), (ne['lng'] as num).toDouble()),
        );
      } else {
        polygon = _circlePolygon(center, 0.012);
      }
      return AreaResult(
        name: suggestion.label,
        polygon: polygon,
        center: center,
      );
    } catch (_) {
      return null;
    }
  }

  Future<LandmarkResult?> resolveLandmark(PlaceSuggestion suggestion) async {
    if (suggestion.location != null) {
      return LandmarkResult(
        name: suggestion.label,
        type: suggestion.landmarkType ?? 'landmark',
        location: suggestion.location!,
      );
    }
    if (suggestion.placeId == null || _apiKey.isEmpty) return null;

    final cacheKey = 'landmark:${suggestion.placeId}';
    return placesRequestCache.getOrLoad<LandmarkResult?>(
      cacheKey,
      () => _resolveLandmarkRemote(suggestion),
      ttl: const Duration(hours: 1),
    );
  }

  Future<LandmarkResult?> _resolveLandmarkRemote(
    PlaceSuggestion suggestion,
  ) async {
    try {
      final response = await _dio.get(
        _detailsUrl,
        queryParameters: {
          'place_id': suggestion.placeId,
          'key': _apiKey,
          'fields': 'geometry,name',
        },
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final geometry = response.data['result']?['geometry'];
      if (geometry == null) return null;
      final loc = geometry['location'];
      return LandmarkResult(
        name: response.data['result']?['name'] as String? ?? suggestion.label,
        type: suggestion.landmarkType ?? 'landmark',
        location: LatLng(
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Landmarks near a point by category (school, university, mall, gas…).
  Future<List<LandmarkResult>> nearbyLandmarks({
    required LatLng near,
    required String category,
  }) async {
    final cacheKey =
        'nearby:${near.latitude.toStringAsFixed(3)}:${near.longitude.toStringAsFixed(3)}:$category';
    return placesRequestCache.getOrLoad<List<LandmarkResult>>(
      cacheKey,
      () => _nearbyLandmarksUncached(near: near, category: category),
      ttl: const Duration(minutes: 30),
    );
  }

  Future<List<LandmarkResult>> _nearbyLandmarksUncached({
    required LatLng near,
    required String category,
  }) async {
    final googleType = _googleTypeForCategory(category);
    if (_apiKey.isNotEmpty && googleType != null) {
      try {
        final response = await _dio.get(
          _nearbyUrl,
          queryParameters: {
            'location': '${near.latitude},${near.longitude}',
            'radius': '6000',
            'type': googleType,
            'key': _apiKey,
            'language': 'ar',
          },
          options: Options(receiveTimeout: const Duration(seconds: 5)),
        );
        final results = (response.data['results'] as List?) ?? const [];
        final parsed = results.map((r) {
          final loc = r['geometry']?['location'];
          return LandmarkResult(
            name: r['name'] as String? ?? '',
            type: category,
            location: LatLng(
              (loc?['lat'] as num?)?.toDouble() ?? 0,
              (loc?['lng'] as num?)?.toDouble() ?? 0,
            ),
          );
        }).where((l) => l.name.isNotEmpty && l.location.latitude != 0);
        if (parsed.isNotEmpty) return parsed.take(10).toList();
      } catch (_) {}
    }
    return demoLandmarks
        .where((l) => l.type == category)
        .toList(growable: false);
  }

  /// Detect a landmark category from a natural query (AR/EN/KU keywords).
  static String? landmarkCategoryFor(String query) {
    final q = query.toLowerCase();
    bool hasAny(List<String> words) => words.any(q.contains);
    if (hasAny(['مدرسة', 'مدارس', 'school'])) return 'school';
    if (hasAny(['جامعة', 'كلية', 'university', 'college'])) return 'university';
    if (hasAny(['مول', 'تسوق', 'mall', 'shopping'])) return 'mall';
    if (hasAny(['بنزين', 'وقود', 'محطة وقود', 'gas', 'fuel', 'petrol'])) {
      return 'gas_station';
    }
    if (hasAny(['مستشفى', 'مستشفيات', 'hospital', 'clinic', 'عيادة'])) {
      return 'hospital';
    }
    if (hasAny(['جامع', 'مسجد', 'mosque'])) return 'mosque';
    if (hasAny(['حديقة', 'منتزه', 'بارك', 'park'])) return 'park';
    return null;
  }

  static String? _googleTypeForCategory(String category) {
    switch (category) {
      case 'school':
        return 'school';
      case 'university':
        return 'university';
      case 'mall':
        return 'shopping_mall';
      case 'gas_station':
        return 'gas_station';
      case 'hospital':
        return 'hospital';
      case 'mosque':
        return 'mosque';
      case 'park':
        return 'park';
    }
    return null;
  }

  static String? _landmarkTypeFromTypes(List<String> types) {
    for (final t in types) {
      switch (t) {
        case 'school':
        case 'primary_school':
        case 'secondary_school':
          return 'school';
        case 'university':
          return 'university';
        case 'shopping_mall':
          return 'mall';
        case 'gas_station':
          return 'gas_station';
        case 'hospital':
          return 'hospital';
        case 'mosque':
          return 'mosque';
        case 'park':
          return 'park';
      }
    }
    return null;
  }

  // ─── Local demo registry (Baghdad) ─────────────────────────────────────────

  // Kept for compile compatibility; production suggest/resolve never uses it.
  // ignore: unused_element
  List<PlaceSuggestion> _localSuggestions(String query) {
    final q = query.toLowerCase();
    final out = <PlaceSuggestion>[];
    for (final area in demoAreas) {
      if (area.name.toLowerCase().contains(q) ||
          (_areaAliases[area.name] ?? const [])
              .any((alias) => alias.toLowerCase().contains(q))) {
        out.add(
          PlaceSuggestion(
            label: area.name,
            kind: 'area',
            location: area.center,
            polygon: area.polygon,
          ),
        );
      }
    }
    for (final landmark in demoLandmarks) {
      if (landmark.name.toLowerCase().contains(q)) {
        out.add(
          PlaceSuggestion(
            label: landmark.name,
            kind: 'landmark',
            location: landmark.location,
            landmarkType: landmark.type,
          ),
        );
      }
    }
    final category = landmarkCategoryFor(query);
    if (category != null) {
      for (final landmark in demoLandmarks.where((l) => l.type == category)) {
        if (!out.any((s) => s.label == landmark.name)) {
          out.add(
            PlaceSuggestion(
              label: landmark.name,
              kind: 'landmark',
              location: landmark.location,
              landmarkType: landmark.type,
            ),
          );
        }
      }
    }
    return out.take(8).toList();
  }

  static AreaResult? demoAreaByName(String name) {
    final q = name.toLowerCase();
    for (final area in demoAreas) {
      if (q.contains(area.name.toLowerCase()) ||
          (_areaAliases[area.name] ?? const [])
              .any((alias) => q.contains(alias.toLowerCase()))) {
        return area;
      }
    }
    return null;
  }

  static LandmarkResult? demoLandmarkByName(String name) {
    final q = name.toLowerCase();
    for (final landmark in demoLandmarks) {
      if (q.contains(landmark.name.toLowerCase()) ||
          landmark.name.toLowerCase().contains(q)) {
        return landmark;
      }
    }
    return null;
  }

  static List<LatLng> _rectPolygon(LatLng sw, LatLng ne) => [
        LatLng(sw.latitude, sw.longitude),
        LatLng(sw.latitude, ne.longitude),
        LatLng(ne.latitude, ne.longitude),
        LatLng(ne.latitude, sw.longitude),
      ];

  static List<LatLng> _circlePolygon(LatLng center, double r) => [
        LatLng(center.latitude + r, center.longitude),
        LatLng(center.latitude + r * 0.7, center.longitude + r * 0.9),
        LatLng(center.latitude, center.longitude + r * 1.2),
        LatLng(center.latitude - r * 0.7, center.longitude + r * 0.9),
        LatLng(center.latitude - r, center.longitude),
        LatLng(center.latitude - r * 0.7, center.longitude - r * 0.9),
        LatLng(center.latitude, center.longitude - r * 1.2),
        LatLng(center.latitude + r * 0.7, center.longitude - r * 0.9),
      ];

  static const Map<String, List<String>> _areaAliases = {
    'الكرادة': ['karrada', 'karada', 'كراده'],
    'المنصور': ['mansour', 'mansur', 'منصور'],
    'زيونة': ['zayouna', 'zayuna', 'زيونه'],
    'الأعظمية': ['adhamiya', 'اعظمية', 'الاعظمية'],
    'الكاظمية': ['kadhimiya', 'كاظمية'],
    'الدورة': ['dora', 'دوره'],
    'الجادرية': ['jadriya', 'جادرية'],
  };

  static final List<AreaResult> demoAreas = [
    AreaResult(
      name: 'الكرادة',
      center: const LatLng(33.3095, 44.4130),
      polygon: const [
        LatLng(33.2950, 44.3900),
        LatLng(33.3230, 44.3880),
        LatLng(33.3300, 44.4110),
        LatLng(33.3210, 44.4370),
        LatLng(33.2980, 44.4400),
        LatLng(33.2890, 44.4150),
      ],
    ),
    AreaResult(
      name: 'المنصور',
      center: const LatLng(33.3330, 44.3550),
      polygon: const [
        LatLng(33.3190, 44.3350),
        LatLng(33.3460, 44.3300),
        LatLng(33.3530, 44.3560),
        LatLng(33.3420, 44.3760),
        LatLng(33.3220, 44.3730),
      ],
    ),
    AreaResult(
      name: 'زيونة',
      center: const LatLng(33.3300, 44.4520),
      polygon: const [
        LatLng(33.3190, 44.4360),
        LatLng(33.3410, 44.4340),
        LatLng(33.3450, 44.4600),
        LatLng(33.3280, 44.4720),
        LatLng(33.3160, 44.4560),
      ],
    ),
    AreaResult(
      name: 'الأعظمية',
      center: const LatLng(33.3720, 44.3720),
      polygon: const [
        LatLng(33.3570, 44.3520),
        LatLng(33.3860, 44.3480),
        LatLng(33.3930, 44.3750),
        LatLng(33.3790, 44.3960),
        LatLng(33.3590, 44.3900),
      ],
    ),
    AreaResult(
      name: 'الكاظمية',
      center: const LatLng(33.3830, 44.3400),
      polygon: const [
        LatLng(33.3680, 44.3220),
        LatLng(33.3970, 44.3170),
        LatLng(33.4030, 44.3480),
        LatLng(33.3870, 44.3640),
        LatLng(33.3690, 44.3560),
      ],
    ),
    AreaResult(
      name: 'الدورة',
      center: const LatLng(33.2560, 44.4160),
      polygon: const [
        LatLng(33.2400, 44.3920),
        LatLng(33.2700, 44.3880),
        LatLng(33.2790, 44.4230),
        LatLng(33.2640, 44.4460),
        LatLng(33.2420, 44.4380),
      ],
    ),
    AreaResult(
      name: 'الجادرية',
      center: const LatLng(33.2790, 44.3830),
      polygon: const [
        LatLng(33.2650, 44.3650),
        LatLng(33.2900, 44.3600),
        LatLng(33.2970, 44.3870),
        LatLng(33.2830, 44.4050),
        LatLng(33.2650, 44.3960),
      ],
    ),
  ];

  static const List<LandmarkResult> demoLandmarks = [
    LandmarkResult(
      name: 'جامعة بغداد',
      type: 'university',
      location: LatLng(33.2732, 44.3787),
    ),
    LandmarkResult(
      name: 'الجامعة المستنصرية',
      type: 'university',
      location: LatLng(33.3568, 44.4009),
    ),
    LandmarkResult(
      name: 'كلية بغداد',
      type: 'school',
      location: LatLng(33.3706, 44.3925),
    ),
    LandmarkResult(
      name: 'المدرسة الدولية في بغداد',
      type: 'school',
      location: LatLng(33.3120, 44.3900),
    ),
    LandmarkResult(
      name: 'مدرسة المنصور الأهلية',
      type: 'school',
      location: LatLng(33.3360, 44.3580),
    ),
    LandmarkResult(
      name: 'مول المنصور',
      type: 'mall',
      location: LatLng(33.3266, 44.3565),
    ),
    LandmarkResult(
      name: 'بابل مول',
      type: 'mall',
      location: LatLng(33.3080, 44.3691),
    ),
    LandmarkResult(
      name: 'زيونة مول',
      type: 'mall',
      location: LatLng(33.3324, 44.4448),
    ),
    LandmarkResult(
      name: 'بغداد مول',
      type: 'mall',
      location: LatLng(33.3369, 44.3719),
    ),
    LandmarkResult(
      name: 'محطة وقود الكرادة',
      type: 'gas_station',
      location: LatLng(33.3110, 44.4010),
    ),
    LandmarkResult(
      name: 'محطة وقود المنصور',
      type: 'gas_station',
      location: LatLng(33.3330, 44.3620),
    ),
    LandmarkResult(
      name: 'محطة وقود زيونة',
      type: 'gas_station',
      location: LatLng(33.3300, 44.4480),
    ),
    LandmarkResult(
      name: 'مستشفى ابن سينا',
      type: 'hospital',
      location: LatLng(33.3220, 44.3680),
    ),
    LandmarkResult(
      name: 'مدينة الطب',
      type: 'hospital',
      location: LatLng(33.3450, 44.3830),
    ),
    LandmarkResult(
      name: 'جامع أبي حنيفة',
      type: 'mosque',
      location: LatLng(33.3739, 44.3552),
    ),
    LandmarkResult(
      name: 'متنزه الزوراء',
      type: 'park',
      location: LatLng(33.3100, 44.3600),
    ),
  ];
}
