import '../core/cache/request_cache.dart';
import '../core/maps/map_bounds.dart';
import '../../presentation/search_map_screen/models/property_data.dart';
import '../../services/property_catalog_demo.dart';
import '../../services/supabase_service.dart';

/// Bounds-aware property loading with session cache + deduplication.
class PropertyMapRepository {
  PropertyMapRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  Future<List<PropertyData>> fetchInBounds({
    required MapBounds bounds,
    String? countryCode,
    String? listingFilter,
    int limit = 120,
  }) async {
    final key = bounds.cacheKey(filter: listingFilter);
    return propertyRequestCache.getOrLoad<List<PropertyData>>(
      key,
      () => _load(bounds, countryCode, listingFilter, limit),
      ttl: const Duration(minutes: 2),
    );
  }

  Future<List<PropertyData>> _load(
    MapBounds bounds,
    String? countryCode,
    String? listingFilter,
    int limit,
  ) async {
    final rows = await _supabase.getPropertiesInBounds(
      swLat: bounds.southwest.latitude,
      swLng: bounds.southwest.longitude,
      neLat: bounds.northeast.latitude,
      neLng: bounds.northeast.longitude,
      countryCode: countryCode,
      listingType: _listingTypeFromFilter(listingFilter),
      limit: limit,
    );

    if (rows.isEmpty) {
      return _filterDemo(bounds, listingFilter).take(limit).toList();
    }

    return rows
        .map(PropertyData.fromSupabase)
        .where((p) => p.lat != 0 && p.lng != 0)
        .where((p) => bounds.containsProperty(p.lat, p.lng))
        .toList();
  }

  List<PropertyData> _filterDemo(MapBounds bounds, String? filter) {
    return PropertyCatalogDemo.listings().where((p) {
      if (!bounds.containsProperty(p.lat, p.lng)) return false;
      if (filter == null || filter == 'All') return true;
      switch (filter) {
        case 'Sale':
          return p.listingType == 'sale';
        case 'Rent':
          return p.listingType == 'rent';
        case 'Mortgage':
          return p.listingType == 'mortgage';
        case 'Land':
          return p.type == 'land' || p.type == 'agricultural';
        case 'Commercial':
          return p.type == 'commercial';
        case 'Investment':
          return p.listingType == 'investment';
        default:
          return true;
      }
    }).toList();
  }

  String? _listingTypeFromFilter(String? filter) {
    switch (filter) {
      case 'Sale':
        return 'sale';
      case 'Rent':
        return 'rent';
      case 'Mortgage':
        return 'mortgage';
      case 'Investment':
        return 'investment';
      default:
        return null;
    }
  }
}
