import '../../../core/app_export.dart';
import '../../../core/currency/currency_registry.dart';
import '../../../core/localization/app_localizations.dart';

/// Lightweight listing model used by map search, AI chat cards, and list UIs.
class PropertyData {
  final String id;
  final String title;
  final String address;
  final double price;
  final String currency;
  final double area;
  final int bedrooms;
  final int bathrooms;
  final String type;
  final String listingType;
  final double lat;
  final double lng;
  final String imageUrl;
  final String semanticLabel;
  final bool isVerified;
  final bool isFeatured;
  final List<String> tags;
  final String description;
  final List<String> nearbySchools;
  final List<String> nearbyAmenities;
  final Map<String, dynamic> rawData;

  const PropertyData({
    required this.id,
    required this.title,
    required this.address,
    required this.price,
    required this.currency,
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    required this.type,
    required this.listingType,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.semanticLabel,
    required this.isVerified,
    required this.isFeatured,
    required this.tags,
    this.description = '',
    this.nearbySchools = const [],
    this.nearbyAmenities = const [],
    required this.rawData,
  });

  factory PropertyData.fromSupabase(Map<String, dynamic> d) {
    final media = d['property_media_v3'] as List?;
    String imageUrl = '';
    if (media != null && media.isNotEmpty) {
      imageUrl = media.first['media_url'] as String? ?? '';
    }
    if (imageUrl.isEmpty) {
      imageUrl =
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600';
    }

    final lat = (d['latitude'] as num?)?.toDouble() ??
        (d['lat'] as num?)?.toDouble() ??
        0.0;
    final lng = (d['longitude'] as num?)?.toDouble() ??
        (d['lng'] as num?)?.toDouble() ??
        0.0;

    final city = d['city'] as String? ?? '';
    final district = d['district'] as String? ?? '';
    final address =
        d['address_text'] as String? ??
        [district, city].where((s) => s.isNotEmpty).join(', ');

    final features = d['property_features_v3'] as List?;
    final tags = features != null
        ? features
              .map((f) => f['feature_name'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .take(3)
              .toList()
        : <String>[];

    final schools = (d['nearby_schools'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final amenities = (d['nearby_amenities'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return PropertyData(
      id: d['id'] as String? ?? '',
      title:
          d['title'] as String? ??
          '${d['property_type'] ?? 'Property'} — $district',
      address: address,
      price: (d['asking_price'] as num?)?.toDouble() ??
          (d['price'] as num?)?.toDouble() ??
          0,
      currency: d['currency'] as String? ?? 'USD',
      area: (d['total_area_sqm'] as num?)?.toDouble() ??
          (d['area'] as num?)?.toDouble() ??
          0,
      bedrooms: (d['bedrooms_count'] as num?)?.toInt() ??
          (d['bedrooms'] as num?)?.toInt() ??
          0,
      bathrooms: (d['bathrooms_count'] as num?)?.toInt() ??
          (d['bathrooms'] as num?)?.toInt() ??
          0,
      type: d['property_type'] as String? ?? d['type'] as String? ?? 'apartment',
      listingType: d['listing_type'] as String? ??
          d['listingType'] as String? ??
          'sale',
      lat: lat,
      lng: lng,
      imageUrl: imageUrl,
      semanticLabel: 'Property in $address',
      isVerified: d['is_verified'] as bool? ?? false,
      isFeatured: d['is_featured'] as bool? ?? false,
      tags: tags,
      description: d['description'] as String? ?? d['summary'] as String? ?? '',
      nearbySchools: schools,
      nearbyAmenities: amenities,
      rawData: d,
    );
  }

  factory PropertyData.fromMap(Map<String, dynamic> map) {
    return PropertyData(
      id: map['id'] as String,
      title: map['title'] as String,
      address: map['address'] as String,
      price: (map['price'] as num).toDouble(),
      currency: map['currency'] as String,
      area: (map['area'] as num).toDouble(),
      bedrooms: map['bedrooms'] as int,
      bathrooms: map['bathrooms'] as int,
      type: map['type'] as String,
      listingType: map['listingType'] as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      semanticLabel: map['semanticLabel'] as String,
      isVerified: map['isVerified'] as bool? ?? false,
      isFeatured: map['isFeatured'] as bool? ?? false,
      tags: List<String>.from(map['tags'] as List? ?? []),
      description: map['description'] as String? ?? '',
      nearbySchools: List<String>.from(map['nearbySchools'] as List? ?? []),
      nearbyAmenities: List<String>.from(
        map['nearbyAmenities'] as List? ?? [],
      ),
      rawData: map,
    );
  }

  double priceIn(String currencyCode) =>
      CurrencyRegistry.convert(price, from: currency, to: currencyCode);

  String displayPrice(
    String currencyCode, {
    bool monthlyRent = true,
    AppLanguage language = AppLanguage.arabic,
  }) {
    final amount = priceIn(currencyCode);
    final base = CurrencyRegistry.formatAmount(amount, currencyCode);
    if (listingType == 'rent' && monthlyRent) {
      final suffix = switch (language) {
        AppLanguage.arabic => '/ شهر',
        AppLanguage.kurdish => '/ مانگ',
        AppLanguage.english => '/mo',
      };
      return '$base $suffix';
    }
    return base;
  }

  String get formattedPrice => displayPrice(currency);

  String localizedTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.arabic:
        return rawData['title_ar']?.toString() ?? _arabicTitleFallback;
      case AppLanguage.kurdish:
        return rawData['title_ku']?.toString() ??
            rawData['title_ar']?.toString() ??
            title;
      case AppLanguage.english:
        return rawData['title_en']?.toString() ?? title;
    }
  }

  String localizedAddress(AppLanguage language) {
    switch (language) {
      case AppLanguage.arabic:
        return rawData['address_ar']?.toString() ?? address;
      case AppLanguage.kurdish:
        return rawData['address_ku']?.toString() ??
            rawData['address_ar']?.toString() ??
            address;
      case AppLanguage.english:
        return rawData['address_en']?.toString() ?? address;
    }
  }

  String localizedTag(AppLocalizations loc, String tag) {
    final feature = loc.featureName(tag);
    if (feature != tag) return feature;
    final nearby = loc.nearbyName(tag);
    if (nearby != tag) return nearby;
    final type = loc.propertyTypeName(tag);
    if (type != tag) return type;
    return tag;
  }

  String get _arabicTitleFallback {
    final districtAr = district.isNotEmpty ? district : address;
    switch (type) {
      case 'villa':
        return 'فيلا — $districtAr';
      case 'land':
        return 'أرض — $districtAr';
      case 'commercial':
        return 'عقار تجاري — $districtAr';
      case 'building':
        return 'عمارة — $districtAr';
      default:
        return 'شقة — $districtAr';
    }
  }

  String listingLabel(AppLocalizations loc) {
    switch (listingType) {
      case 'sale':
        return loc.forSale;
      case 'rent':
        return loc.forRent;
      case 'mortgage':
        return loc.mortgage;
      case 'investment':
        return loc.investment;
      default:
        return loc.propertyTypeName(listingType);
    }
  }

  String typeLabel(AppLocalizations loc) {
    final raw = type.trim();
    if (raw.isEmpty) return loc.informationUnavailable;
    final normalized = raw.toLowerCase().replaceAll('-', '_');
    final translated = loc.propertyTypeName(normalized);
    if (translated != normalized && translated != raw) return translated;
    // Some datasets store listing intent in property_type
    final listing = loc.filterLabel(raw);
    if (listing != raw) return listing;
    return loc.propertyTypeName(raw);
  }

  String get listingTypeLabel => listingLabel(
        AppLocalizations(AppLanguage.english),
      );

  Color get listingTypeColor {
    switch (listingType) {
      case 'sale':
        return AppTheme.saleColor;
      case 'rent':
        return AppTheme.rentColor;
      case 'mortgage':
        return AppTheme.mortgageColor;
      case 'investment':
        return AppTheme.investmentColor;
      default:
        return AppTheme.primary;
    }
  }

  List<String> get gallery {
    final urls = <String>[];
    if (imageUrl.isNotEmpty) urls.add(imageUrl);
    final extra = rawData['gallery'] ?? rawData['images'];
    if (extra is List) {
      for (final item in extra) {
        final url = item.toString();
        if (url.startsWith('http') && !urls.contains(url)) urls.add(url);
      }
    }
    if (urls.isEmpty) {
      urls.add(
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      );
    }
    return urls;
  }

  /// District/neighborhood name, from structured data or the address.
  String get district {
    final raw = rawData['district']?.toString().trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final parts = address.split(',');
    if (parts.length >= 2) return parts[parts.length - 2].trim();
    return '';
  }

  /// Builder / contractor company, when captured by data-entry staff.
  String get builderCompany {
    final keys = ['builder_company', 'builder', 'developer', 'contractor'];
    for (final key in keys) {
      final value = rawData[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  int get yearBuilt {
    final raw = rawData['year_built'] ?? rawData['yearBuilt'];
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> toDetailMap() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'asking_price': price,
      'estimatedValue': price,
      'total_area_sqm': area,
      'area': area,
      'bedrooms_count': bedrooms,
      'bedrooms': bedrooms,
      'bathrooms_count': bathrooms,
      'bathrooms': bathrooms,
      'property_type': type,
      'type': type,
      'listing_type': listingType,
      'listingType': listingType,
      'imageUrl': imageUrl,
      'description': description,
      'nearby_schools': nearbySchools,
      'nearby_amenities': nearbyAmenities,
      'is_verified': isVerified,
      'isVerified': isVerified,
      'is_featured': isFeatured,
      'isFeatured': isFeatured,
      ...rawData,
    };
  }
}
