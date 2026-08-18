import '../../domain/enums/data_provenance.dart';
import '../../domain/enums/media_category.dart';
import '../../domain/enums/property_status.dart';
import '../../domain/models/property_areas.dart';
import '../../domain/models/property_documents.dart';
import '../../domain/models/property_extended.dart';
import '../../domain/models/property_features.dart';
import '../../domain/models/property_finance.dart';
import '../../domain/models/property_language.dart';
import '../../domain/models/property_location.dart';
import '../../domain/models/property_media.dart';
import '../../domain/models/property_pricing.dart';
import '../../domain/models/property_report.dart';
import '../../domain/models/property_surroundings.dart';
import '../../domain/value_objects/area_measure.dart';
import '../../domain/value_objects/money_amount.dart';

/// Maps existing `properties_v3` (+ nested media/features) and optional
/// intelligence JSON into a [PropertyReport]. Never invents trusted data.
class PropertyReportMapper {
  const PropertyReportMapper();

  PropertyReport fromSupabaseMap(
    Map<String, dynamic> d, {
    bool isSaved = false,
  }) {
    final currency = _asString(d['currency']) ?? 'USD';
    final price = _asDouble(d['asking_price']) ?? _asDouble(d['price']);
    final areaSqm =
        _asDouble(d['total_area_sqm']) ?? _asDouble(d['area']);

    final status = PropertyStatus.fromString(
      _asString(d['listing_type']) ?? _asString(d['listingType']),
    );

    // Optional intelligence payloads (JSONB columns or nested objects).
    final intel = _asMap(d['intelligence']) ??
        _asMap(d['property_intelligence']) ??
        const <String, dynamic>{};
    final areasJson = _asMap(d['areas']) ?? _asMap(intel['areas']);
    final interiorJson =
        _asMap(d['interior_features']) ?? _asMap(intel['interior']);
    final exteriorJson =
        _asMap(d['exterior_features']) ?? _asMap(intel['exterior']);
    final utilitiesJson =
        _asMap(d['utilities']) ?? _asMap(intel['utilities']);
    final energyJson = _asMap(d['energy']) ?? _asMap(intel['energy']);
    final buildingJson =
        _asMap(d['building_details']) ?? _asMap(intel['building']);
    final renovationJson =
        _asMap(d['renovation']) ?? _asMap(intel['renovation']);
    final developmentJson = _asMap(d['development_potential']) ??
        _asMap(intel['development_potential']);
    final whatsSpecialJson =
        _asMap(d['whats_special']) ?? _asMap(intel['whats_special']);
    final ltoJson =
        _asMap(d['rent_to_own']) ?? _asMap(intel['rent_to_own']);
    final investmentJson =
        _asMap(d['investment']) ?? _asMap(intel['investment']);
    final rentalJson = _asMap(d['rental']) ?? _asMap(intel['rental']);
    final historyJson = _asMap(d['history']) ?? _asMap(intel['history']);
    final surroundingsJson =
        _asMap(d['surroundings']) ?? _asMap(intel['surroundings']);

    final media = _mapMedia(d);
    final amenityTags = _mapAmenityTags(d);

    final current = MoneyAmount.maybe(price, currency);
    MoneyAmount? perSqm;
    if (current != null && areaSqm != null && areaSqm > 0) {
      perSqm = MoneyAmount(
        amount: current.amount / areaSqm,
        currencyCode: currency,
        provenance: DataProvenance.publisherProvided,
      );
    }

    // Estimated value only if publisher/backend provided it — never invent.
    final estimated = MoneyAmount.maybe(
      d['estimated_value'] as num? ?? intel['estimated_value'] as num?,
      currency,
      provenance: DataProvenance.estimated,
    );

    final previous = MoneyAmount.maybe(
      d['previous_price'] as num? ?? historyJson?['previous_price'] as num?,
      currency,
    );

    double? changePercent;
    if (current != null && previous != null && previous.amount > 0) {
      changePercent =
          ((current.amount - previous.amount) / previous.amount) * 100;
    } else if (d['price_change_percent'] is num) {
      changePercent = (d['price_change_percent'] as num).toDouble();
    }

    final areas = PropertyAreas(
      builtUp: AreaMeasure.maybe(
            areasJson?['built_up'] as num? ?? areaSqm,
          ),
      land: AreaMeasure.maybe(areasJson?['land'] as num?),
      floor: AreaMeasure.maybe(areasJson?['floor'] as num?),
      net: AreaMeasure.maybe(areasJson?['net'] as num?),
      gross: AreaMeasure.maybe(areasJson?['gross'] as num?),
      garden: AreaMeasure.maybe(areasJson?['garden'] as num?),
      roof: AreaMeasure.maybe(areasJson?['roof'] as num?),
      pool: AreaMeasure.maybe(areasJson?['pool'] as num?),
      parking: AreaMeasure.maybe(areasJson?['parking'] as num?),
      storage: AreaMeasure.maybe(areasJson?['storage'] as num?),
      basement: AreaMeasure.maybe(areasJson?['basement'] as num?),
      annexes: AreaMeasure.maybe(areasJson?['annexes'] as num?),
      shops: AreaMeasure.maybe(areasJson?['shops'] as num?),
      units: AreaMeasure.maybe(areasJson?['units'] as num?),
      leasable: AreaMeasure.maybe(areasJson?['leasable'] as num?),
      investable: AreaMeasure.maybe(areasJson?['investable'] as num?),
    );

    final city = _asString(d['city']) ?? '';
    final district = _asString(d['district']) ?? '';
    final address = _asString(d['address_text']) ??
        _asString(d['address']) ??
        [district, city].where((s) => s.isNotEmpty).join(', ');

    return PropertyReport(
      id: d['id']?.toString() ?? '',
      title: _asString(d['title']) ??
          '${d['property_type'] ?? 'Property'}${district.isNotEmpty ? ' — $district' : ''}',
      status: status,
      location: PropertyLocation(
        latitude: _asDouble(d['latitude']) ?? _asDouble(d['lat']),
        longitude: _asDouble(d['longitude']) ?? _asDouble(d['lng']),
        addressText: address.isEmpty ? null : address,
        countryCode: _asString(d['country_code']),
        countryName: _asString(d['country_name']),
        city: city.isEmpty ? null : city,
        district: district.isEmpty ? null : district,
        neighborhood: _asString(d['neighborhood']),
        street: _asString(d['street']),
        postalCode: _asString(d['postal_code']),
        elevationM:
            _asDouble(d['elevation_m']) ?? _asDouble(intel['elevation_m']),
        province: _asString(d['province']) ?? _asString(intel['province']),
      ),
      pricing: PropertyPricing(
        currentPrice: current,
        pricePerSqm: perSqm,
        previousPrice: previous,
        estimatedValue: estimated,
        estimatedRentalValue: MoneyAmount.maybe(
          intel['estimated_rental_value'] as num?,
          currency,
          provenance: DataProvenance.estimated,
        ),
        potentialValue: MoneyAmount.maybe(
          intel['potential_value'] as num?,
          currency,
          provenance: DataProvenance.estimated,
        ),
        changePercent: changePercent,
        status: status,
      ),
      areas: areas,
      facts: PropertyFacts(
        propertyType: d['property_type'] as String? ?? d['type'] as String?,
        buildingType: d['building_type'] as String?,
        unitType: d['unit_type'] as String?,
        bedrooms: (d['bedrooms_count'] as num?)?.toInt() ??
            (d['bedrooms'] as num?)?.toInt(),
        bathrooms: (d['bathrooms_count'] as num?)?.toInt() ??
            (d['bathrooms'] as num?)?.toInt(),
        livingRooms: (d['living_rooms'] as num?)?.toInt(),
        floors: (d['floors'] as num?)?.toInt(),
        floorNumber: (d['floor_number'] as num?)?.toInt(),
        totalFloors: (d['total_floors'] as num?)?.toInt(),
        parkingSpaces: (d['parking_spaces'] as num?)?.toInt(),
        yearBuilt: (d['year_built'] as num?)?.toInt(),
        yearRenovated: (d['year_renovated'] as num?)?.toInt(),
        orientation: d['orientation'] as String?,
        hasElevator: d['has_elevator'] as bool?,
        isFurnished: d['is_furnished'] as bool?,
        hasBalcony: d['has_balcony'] as bool?,
        hasGarden: d['has_garden'] as bool?,
        hasPool: d['has_pool'] as bool?,
      ),
      media: media,
      features: PropertyFeatures(
        interior: PropertyFeatureBag(entries: interiorJson ?? {}),
        exterior: PropertyFeatureBag(entries: exteriorJson ?? {}),
        utilities: PropertyFeatureBag(entries: utilitiesJson ?? {}),
        energy: PropertyFeatureBag(entries: energyJson ?? {}),
        building: PropertyFeatureBag(entries: buildingJson ?? {}),
        renovation: PropertyFeatureBag(entries: renovationJson ?? {}),
        developmentPotential:
            PropertyFeatureBag(entries: developmentJson ?? {}),
        amenityTags: amenityTags,
      ),
      history: _mapHistory(historyJson, currency),
      surroundings: _mapSurroundings(surroundingsJson),
      description: d['description'] as String?,
      whatsSpecial: _mapWhatsSpecial(whatsSpecialJson, d),
      rentToOwn: _mapRentToOwn(ltoJson, currency),
      investment: _mapInvestment(investmentJson, currency),
      rental: _mapRental(rentalJson, currency, status),
      mortgageDefaults: MortgageDefaults(
        downPaymentPercent:
            (intel['mortgage_down_percent'] as num?)?.toDouble() ?? 20,
        interestRatePercent:
            (intel['mortgage_rate'] as num?)?.toDouble() ?? 7.5,
        termYears: (intel['mortgage_years'] as num?)?.toInt() ?? 20,
      ),
      documents: _mapDocuments(d),
      publisher: _mapPublisher(d),
      insights: const [],
      lastUpdatedAt: _parseDate(d['updated_at']) ?? _parseDate(d['created_at']),
      isVerified: d['is_verified'] as bool? ?? false,
      isFeatured: d['is_featured'] as bool? ?? false,
      isSaved: isSaved,
      originalLanguage: _resolveOriginalLanguage(d, intel),
      contentVersion: _resolveContentVersion(d, intel),
      rawSource: d,
      dimensions: _mapDimensions(
        _asMap(intel['dimensions']) ?? _asMap(d['dimensions']),
      ),
      construction: _mapConstruction(
        _asMap(intel['construction']) ?? _asMap(d['construction']),
        d,
      ),
      builder: _mapBuilder(
        _asMap(intel['builder']) ?? _asMap(d['builder']),
        d,
      ),
      listingMeta: _mapListingMeta(d),
      verification: _mapVerification(d, intel),
      tags: _mapTags(d, intel),
      marketAnalytics: _mapMarketAnalytics(
        _asMap(intel['market_analytics']),
      ),
      floorPlan: _mapFloorPlan(
        _asMap(intel['floor_plan']) ?? _asMap(d['floor_plan']),
      ),
    );
  }

  ContentLanguage _resolveOriginalLanguage(
    Map<String, dynamic> d,
    Map<String, dynamic> intel,
  ) {
    final explicit = d['original_language'] as String? ??
        intel['original_language'] as String? ??
        d['content_language'] as String?;
    if (explicit != null && explicit.isNotEmpty) {
      return ContentLanguage.parse(explicit);
    }
    // Lightweight heuristic when publisher did not set language.
    return _detectLanguageHeuristic(
      [
        d['title'] as String? ?? '',
        d['description'] as String? ?? '',
      ].join(' '),
    );
  }

  String _resolveContentVersion(
    Map<String, dynamic> d,
    Map<String, dynamic> intel,
  ) {
    final v = d['content_version'] ??
        intel['content_version'] ??
        d['updated_at'] ??
        d['created_at'] ??
        '1';
    return v.toString();
  }

  ContentLanguage _detectLanguageHeuristic(String sample) {
    final text = sample.trim();
    if (text.isEmpty) return ContentLanguage.unknown;

    final arabic = RegExp(r'[\u0600-\u06FF]');
    final matches = arabic.allMatches(text).length;
    if (matches > text.length * 0.15) {
      // Kurdish (Sorani) also uses Arabic script — prefer ku if common letters.
      if (text.contains('ە') || text.contains('ڵ') || text.contains('ڕ')) {
        return ContentLanguage.kurdish;
      }
      return ContentLanguage.arabic;
    }

    final latin = RegExp(r'[A-Za-z]');
    if (latin.hasMatch(text)) return ContentLanguage.english;
    return ContentLanguage.unknown;
  }

  Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  List<dynamic>? _asList(dynamic v) {
    if (v is List) return v;
    return null;
  }

  String? _asString(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    return v.toString();
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }

  bool _asBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.toLowerCase().trim();
      if (t == 'true' || t == '1' || t == 'yes') return true;
      if (t == 'false' || t == '0' || t == 'no') return false;
    }
    return fallback;
  }

  DateTime? _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  PropertyMediaGallery _mapMedia(Map<String, dynamic> d) {
    final list = _asList(d['property_media_v3']) ?? _asList(d['media']);
    if (list == null || list.isEmpty) {
      final fallback = _asString(d['imageUrl']) ?? _asString(d['image_url']);
      if (fallback != null && fallback.isNotEmpty) {
        return PropertyMediaGallery(
          items: [
            PropertyMediaItem(
              id: 'fallback',
              url: fallback,
              kind: MediaKind.photo,
              category: MediaCategory.exterior,
            ),
          ],
        );
      }
      return const PropertyMediaGallery();
    }

    final items = <PropertyMediaItem>[];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      if (m is! Map) continue;
      final map = Map<String, dynamic>.from(m);
      final url = _asString(map['media_url']) ?? _asString(map['url']) ?? '';
      if (url.isEmpty) continue;
      items.add(
        PropertyMediaItem(
          id: map['id']?.toString() ?? 'media_$i',
          url: url,
          kind: MediaKind.fromString(
            _asString(map['media_type']) ?? _asString(map['kind']),
          ),
          category: MediaCategory.fromString(
            _asString(map['category']) ?? _asString(map['room_type']),
          ),
          caption: _asString(map['caption']),
          sortOrder: _asDouble(map['sort_order'])?.toInt() ?? i,
          thumbnailUrl: _asString(map['thumbnail_url']),
          externalProvider: _asString(map['external_provider']),
          externalId: _asString(map['external_id']),
          roomKey: _asString(map['room_key']),
        ),
      );
    }
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return PropertyMediaGallery(items: items);
  }

  List<String> _mapAmenityTags(Map<String, dynamic> d) {
    final features = _asList(d['property_features_v3']);
    if (features == null) return const [];
    return features
        .map((f) {
          if (f is Map) {
            return _asString(f['feature_name']) ?? _asString(f['name']) ?? '';
          }
          return f?.toString() ?? '';
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  WhatsSpecialContent? _mapWhatsSpecial(
    Map<String, dynamic>? json,
    Map<String, dynamic> d,
  ) {
    if (json != null) {
      final highlights = _asList(json['highlights'])
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final notes = _asList(json['investment_notes'])
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final content = WhatsSpecialContent(
        headline: _asString(json['headline']),
        body: _asString(json['body']) ?? _asString(json['text']),
        highlights: highlights,
        investmentNotes: notes,
      );
      if (content.hasContent) return content;
    }
    // Fall back to first amenity tags as soft highlights only if description exists.
    final desc = _asString(d['description']);
    if (desc != null && desc.trim().length > 40) {
      return null; // description shown separately; don't fabricate What's Special
    }
    return null;
  }

  RentToOwnTerms? _mapRentToOwn(Map<String, dynamic>? json, String currency) {
    if (json == null) return null;
    final available = json['available'] as bool? ?? json['is_available'] as bool? ?? false;
    if (!available) {
      return const RentToOwnTerms(isAvailable: false);
    }
    return RentToOwnTerms(
      isAvailable: true,
      initialPayment: MoneyAmount.maybe(json['initial_payment'] as num?, currency),
      monthlyPayment: MoneyAmount.maybe(json['monthly_payment'] as num?, currency),
      minMonthlyPayment:
          MoneyAmount.maybe(json['min_monthly_payment'] as num?, currency),
      maxMonthlyPayment:
          MoneyAmount.maybe(json['max_monthly_payment'] as num?, currency),
      contractMonths: (json['contract_months'] as num?)?.toInt(),
      ownershipAllocationPercent:
          (json['ownership_allocation_percent'] as num?)?.toDouble(),
      purchasePrice: MoneyAmount.maybe(json['purchase_price'] as num?, currency),
      remainingAmount:
          MoneyAmount.maybe(json['remaining_amount'] as num?, currency),
      optionalFees: MoneyAmount.maybe(json['optional_fees'] as num?, currency),
      eligibilityNotes: json['eligibility'] as String?,
      ownershipConditions: json['ownership_conditions'] as String?,
      calculationRules: Map<String, dynamic>.from(
        json['calculation_rules'] as Map? ?? {},
      ),
    );
  }

  InvestmentMetrics? _mapInvestment(
    Map<String, dynamic>? json,
    String currency,
  ) {
    if (json == null || json.isEmpty) return null;
    final metrics = InvestmentMetrics(
      expectedRentalYield: (json['expected_rental_yield'] as num?)?.toDouble(),
      estimatedAnnualRent:
          MoneyAmount.maybe(json['estimated_annual_rent'] as num?, currency,
              provenance: DataProvenance.estimated),
      grossYield: (json['gross_yield'] as num?)?.toDouble(),
      netYield: (json['net_yield'] as num?)?.toDouble(),
      expectedAppreciation:
          (json['expected_appreciation'] as num?)?.toDouble(),
      estimatedOperatingCost: MoneyAmount.maybe(
        json['estimated_operating_cost'] as num?,
        currency,
        provenance: DataProvenance.estimated,
      ),
      vacancyAssumption: (json['vacancy_assumption'] as num?)?.toDouble(),
      paybackYears: (json['payback_years'] as num?)?.toDouble(),
      roi: (json['roi'] as num?)?.toDouble(),
      cashFlowMonthly: MoneyAmount.maybe(
        json['cash_flow_monthly'] as num?,
        currency,
        provenance: DataProvenance.estimated,
      ),
      investmentHorizonYears:
          (json['investment_horizon_years'] as num?)?.toInt(),
      provenance: DataProvenance.estimated,
    );
    return metrics.hasAny ? metrics : null;
  }

  RentalAnalysis? _mapRental(
    Map<String, dynamic>? json,
    String currency,
    PropertyStatus status,
  ) {
    if (json == null || json.isEmpty) {
      return null;
    }
    final analysis = RentalAnalysis(
      monthlyRent: MoneyAmount.maybe(json['monthly_rent'] as num?, currency),
      annualRent: MoneyAmount.maybe(json['annual_rent'] as num?, currency),
      expectedExpenses:
          MoneyAmount.maybe(json['expected_expenses'] as num?, currency),
      rentalYield: (json['rental_yield'] as num?)?.toDouble(),
      estimatedMarketRent: MoneyAmount.maybe(
        json['estimated_market_rent'] as num?,
        currency,
        provenance: DataProvenance.estimated,
      ),
    );
    return analysis.hasAny ? analysis : null;
  }

  PropertyHistory _mapHistory(Map<String, dynamic>? json, String currency) {
    if (json == null) return const PropertyHistory();

    final prices = <PriceHistoryEntry>[];
    for (final e in (json['price_history'] as List? ?? const [])) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final amount = MoneyAmount.maybe(m['price'] as num?, currency);
      final date = _parseDate(m['date'] ?? m['effective_date']);
      if (amount == null || date == null) continue;
      prices.add(
        PriceHistoryEntry(
          effectiveDate: date,
          price: amount,
          previousPrice:
              MoneyAmount.maybe(m['previous_price'] as num?, currency),
          changePercent: (m['change_percent'] as num?)?.toDouble(),
          reason: m['reason'] as String?,
          provenance: DataProvenance.publisherProvided,
        ),
      );
    }

    final taxes = <TaxHistoryEntry>[];
    for (final e in (json['tax_history'] as List? ?? const [])) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final year = (m['tax_year'] as num?)?.toInt();
      if (year == null) continue;
      taxes.add(
        TaxHistoryEntry(
          taxYear: year,
          assessedValue:
              MoneyAmount.maybe(m['assessed_value'] as num?, currency),
          taxAmount: MoneyAmount.maybe(m['tax_amount'] as num?, currency),
          notes: m['notes'] as String?,
        ),
      );
    }

    final sales = <SalesHistoryEntry>[];
    for (final e in (json['sales_history'] as List? ?? const [])) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final price = MoneyAmount.maybe(m['sale_price'] as num?, currency);
      final date = _parseDate(m['sold_at'] ?? m['date']);
      if (price == null || date == null) continue;
      sales.add(
        SalesHistoryEntry(
          soldAt: date,
          salePrice: price,
          transactionType: m['transaction_type'] as String?,
          sourceName: m['source'] as String?,
        ),
      );
    }

    return PropertyHistory(
      priceHistory: prices,
      taxHistory: taxes,
      salesHistory: sales,
    );
  }

  PropertySurroundings _mapSurroundings(Map<String, dynamic>? json) {
    if (json == null) return const PropertySurroundings();

    NeighborhoodIntel? neighborhood;
    final n = _asMap(json['neighborhood']);
    if (n != null) {
      neighborhood = NeighborhoodIntel(
        summary: n['summary'] as String?,
        demandLevel: n['demand_level'] as String?,
        density: n['density'] as String?,
        commercialActivity: n['commercial_activity'] as String?,
        accessibilityNotes: n['accessibility'] as String?,
        proximityToMainRoads: n['proximity_to_main_roads'] as String?,
        walkScore: (n['walk_score'] as num?)?.toDouble(),
        transitScore: (n['transit_score'] as num?)?.toDouble(),
        provenance: DataProvenance.estimated,
      );
    }

    final places = <NearbyPlace>[];
    for (final e in (json['nearby_places'] as List? ?? const [])) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final name = m['name'] as String?;
      if (name == null || name.isEmpty) continue;
      places.add(
        NearbyPlace(
          name: name,
          category: _placeCategory(m['category'] as String?),
          distanceMeters: (m['distance_meters'] as num?)?.toDouble(),
          travelTimeMinutes: (m['travel_time_minutes'] as num?)?.toInt(),
          subtype: m['subtype'] as String?,
          rating: (m['rating'] as num?)?.toDouble(),
          isPublic: m['is_public'] as bool?,
        ),
      );
    }

    final projects = <FutureProject>[];
    for (final e in (json['future_projects'] as List? ?? const [])) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final name = m['name'] as String?;
      if (name == null) continue;
      projects.add(
        FutureProject(
          id: m['id']?.toString() ?? name,
          name: name,
          type: m['type'] as String?,
          locationLabel: m['location'] as String?,
          distanceMeters: (m['distance_meters'] as num?)?.toDouble(),
          status: m['status'] as String?,
          expectedCompletion: _parseDate(m['expected_completion']),
          developer: m['developer'] as String?,
          estimatedImpact: _impact(m['estimated_impact'] as String?),
          description: m['description'] as String?,
          imageUrls: (m['images'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
          source: m['source'] as String?,
        ),
      );
    }

    TransportationInfo? transport;
    final t = _asMap(json['transportation']);
    if (t != null) {
      transport = TransportationInfo(
        nearestMainRoad: t['nearest_main_road'] as String?,
        highways: (t['highways'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        transitOptions:
            (t['transit'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        airportDistanceKm: (t['airport_distance_km'] as num?)?.toDouble(),
        cityCenterDistanceKm:
            (t['city_center_distance_km'] as num?)?.toDouble(),
      );
    }

    ClimateRiskInfo? climate;
    final c = _asMap(json['climate_risk']);
    if (c != null) {
      climate = ClimateRiskInfo(
        floodRisk: c['flood'] as String?,
        extremeHeat: c['extreme_heat'] as String?,
        wildfire: c['wildfire'] as String?,
        wind: c['wind'] as String?,
        waterRisk: c['water'] as String?,
        notes: c['notes'] as String?,
      );
    }

    return PropertySurroundings(
      neighborhood: neighborhood,
      nearbyPlaces: places,
      transportation: transport,
      futureProjects: projects,
      investmentProjects: (json['investment_projects'] as List? ?? const [])
          .whereType<Map>()
          .map((e) {
            final m = Map<String, dynamic>.from(e);
            return FutureProject(
              id: m['id']?.toString() ?? m['name']?.toString() ?? '',
              name: m['name'] as String? ?? '',
              type: m['type'] as String?,
              locationLabel: m['location'] as String?,
              distanceMeters: (m['distance_meters'] as num?)?.toDouble(),
              status: m['status'] as String?,
              estimatedImpact: _impact(m['estimated_impact'] as String?),
              description: m['description'] as String?,
              source: m['source'] as String?,
            );
          })
          .where((p) => p.name.isNotEmpty)
          .toList(),
      infrastructureNotes:
          (json['infrastructure'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      climateRisk: climate,
    );
  }

  NearbyPlaceCategory _placeCategory(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'education':
      case 'school':
        return NearbyPlaceCategory.education;
      case 'healthcare':
      case 'hospital':
        return NearbyPlaceCategory.healthcare;
      case 'shopping':
        return NearbyPlaceCategory.shopping;
      case 'services':
        return NearbyPlaceCategory.services;
      case 'lifestyle':
        return NearbyPlaceCategory.lifestyle;
      case 'transportation':
      case 'transit':
        return NearbyPlaceCategory.transportation;
      default:
        return NearbyPlaceCategory.other;
    }
  }

  ProjectImpact _impact(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'positive':
        return ProjectImpact.positive;
      case 'negative':
        return ProjectImpact.negative;
      case 'neutral':
        return ProjectImpact.neutral;
      default:
        return ProjectImpact.unknown;
    }
  }

  List<PropertyDocumentMeta> _mapDocuments(Map<String, dynamic> d) {
    final list = _asList(d['documents']) ??
        _asList(_asMap(d['intelligence'])?['documents']);
    if (list == null) return const [];
    return list.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      return PropertyDocumentMeta(
        id: m['id']?.toString() ?? m['title']?.toString() ?? '',
        title: _asString(m['title']) ?? 'Document',
        documentType: _asString(m['type']) ?? 'other',
        url: _asString(m['url']),
        isSensitive: _asBool(m['is_sensitive'], fallback: true),
        uploadedAt: _parseDate(m['uploaded_at']),
      );
    }).toList();
  }

  PropertyPublisher? _mapPublisher(Map<String, dynamic> d) {
    final p = _asMap(d['publisher']) ?? _asMap(d['advertiser']);
    final origin = _listingOrigin(
      d['listing_source'] ??
          d['source'] ??
          d['published_by'] ??
          p?['origin'] ??
          p?['source'],
    );
    if (p == null) {
      final name = d['publisher_name'] as String?;
      if (name == null && origin == ListingOrigin.madar) return null;
      if (name == null) return null;
      return PropertyPublisher(name: name, origin: origin);
    }
    return PropertyPublisher(
      id: p['id']?.toString(),
      name: p['name'] as String? ?? p['agent_name'] as String?,
      companyName: p['company_name'] as String? ?? p['office_name'] as String?,
      logoUrl: p['logo_url'] as String?,
      photoUrl: p['photo_url'] as String? ??
          p['avatar_url'] as String? ??
          p['image_url'] as String?,
      phone: p['phone'] as String?,
      isVerified: p['is_verified'] as bool? ?? false,
      origin: origin,
    );
  }

  ListingOrigin _listingOrigin(Object? raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    switch (value) {
      case 'office':
      case 'agent':
      case 'broker':
      case 'partner':
        return ListingOrigin.office;
      case 'owner':
      case 'seller':
        return ListingOrigin.owner;
      case 'madar':
      case 'company':
      case 'us':
      case 'internal':
      default:
        return ListingOrigin.madar;
    }
  }

  PropertyDimensions? _mapDimensions(Map<String, dynamic>? json) {
    if (json == null) return null;
    final roomsRaw = json['rooms'] as List?;
    final rooms = <RoomDimensions>[];
    if (roomsRaw != null) {
      for (final r in roomsRaw) {
        if (r is! Map) continue;
        final m = Map<String, dynamic>.from(r);
        final room = RoomDimensions(
          name: m['name'] as String? ?? m['room'] as String? ?? '',
          lengthM: (m['length_m'] as num?)?.toDouble(),
          widthM: (m['width_m'] as num?)?.toDouble(),
          areaSqm: (m['area_sqm'] as num?)?.toDouble(),
          ceilingHeightM: (m['ceiling_height_m'] as num?)?.toDouble(),
          roomKey: m['room_key'] as String?,
          linked3dPointId: m['linked_3d_point_id'] as String?,
          linkedMediaIds: (m['linked_media_ids'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
        );
        if (room.name.isNotEmpty && room.hasAny) rooms.add(room);
      }
    }
    final dims = PropertyDimensions(
      landLengthM: (json['land_length_m'] as num?)?.toDouble(),
      landWidthM: (json['land_width_m'] as num?)?.toDouble(),
      buildingLengthM: (json['building_length_m'] as num?)?.toDouble(),
      buildingWidthM: (json['building_width_m'] as num?)?.toDouble(),
      frontageM: (json['frontage_m'] as num?)?.toDouble(),
      rearWidthM: (json['rear_width_m'] as num?)?.toDouble(),
      sideLengthM: (json['side_length_m'] as num?)?.toDouble(),
      streetWidthM: (json['street_width_m'] as num?)?.toDouble(),
      setbackM: (json['setback_m'] as num?)?.toDouble(),
      buildingHeightM: (json['building_height_m'] as num?)?.toDouble(),
      ceilingHeightM: (json['ceiling_height_m'] as num?)?.toDouble(),
      rooms: rooms,
    );
    return dims.hasAny ? dims : null;
  }

  PropertyConstruction? _mapConstruction(
    Map<String, dynamic>? json,
    Map<String, dynamic> d,
  ) {
    final c = PropertyConstruction(
      yearBuilt: (json?['year_built'] as num?)?.toInt() ??
          (d['year_built'] as num?)?.toInt(),
      constructionStatus: json?['construction_status'] as String?,
      lastRenovation: json?['last_renovation'] as String?,
      lastMaintenance: json?['last_maintenance'] as String?,
      constructionMaterial: json?['construction_material'] as String?,
      structureType: json?['structure_type'] as String?,
      foundationType: json?['foundation_type'] as String?,
      roofType: json?['roof_type'] as String?,
      exteriorMaterial: json?['exterior_material'] as String?,
      interiorMaterial: json?['interior_material'] as String?,
    );
    return c.hasAny ? c : null;
  }

  PropertyBuilderInfo? _mapBuilder(
    Map<String, dynamic>? json,
    Map<String, dynamic> d,
  ) {
    final b = PropertyBuilderInfo(
      companyName: json?['company_name'] as String? ??
          d['builder_company'] as String? ??
          d['builder'] as String?,
      companyId: json?['company_id'] as String?,
      contractorName: json?['contractor_name'] as String?,
      projectName: json?['project_name'] as String?,
      developer: json?['developer'] as String?,
      constructionCompany: json?['construction_company'] as String?,
      architect: json?['architect'] as String?,
      engineeringOffice: json?['engineering_office'] as String?,
    );
    return b.hasAny ? b : null;
  }

  PropertyListingMeta? _mapListingMeta(Map<String, dynamic> d) {
    final propertyNumberId = d['property_number_id']?.toString() ??
        d['propertyNumberId']?.toString();
    final listingId =
        d['listing_id']?.toString() ?? d['listingId']?.toString();
    final meta = PropertyListingMeta(
      listingId: listingId,
      propertyNumberId: propertyNumberId,
      publisherName: d['publisher_name'] as String?,
      publishedAt: _parseDate(d['published_at']) ?? _parseDate(d['created_at']),
      views: (d['views_count'] as num?)?.toInt() ?? (d['views'] as num?)?.toInt(),
      saves: (d['saves_count'] as num?)?.toInt() ?? (d['saves'] as num?)?.toInt(),
      shares: (d['shares_count'] as num?)?.toInt(),
      statusLabel: d['listing_status'] as String?,
    );
    return meta.hasAny ? meta : null;
  }

  PropertyVerificationFlags _mapVerification(
    Map<String, dynamic> d,
    Map<String, dynamic> intel,
  ) {
    final v = _asMap(d['verification']) ?? _asMap(intel['verification']);
    if (v == null) {
      final verified = _asBool(d['is_verified']);
      return PropertyVerificationFlags(propertyVerified: verified);
    }
    return PropertyVerificationFlags(
      propertyVerified: v['property_verified'] as bool? ?? false,
      locationVerified: v['location_verified'] as bool? ?? false,
      informationVerified: v['information_verified'] as bool? ?? false,
      documentsVerified: v['documents_verified'] as bool? ?? false,
      photosVerified: v['photos_verified'] as bool? ?? false,
    );
  }

  List<String> _mapTags(Map<String, dynamic> d, Map<String, dynamic> intel) {
    final raw = d['tags'] ?? intel['tags'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  PropertyMarketAnalytics? _mapMarketAnalytics(Map<String, dynamic>? json) {
    if (json == null) return null;
    final m = PropertyMarketAnalytics(
      averagePriceInArea: json['average_price_in_area']?.toString(),
      averagePricePerSqm: json['average_price_per_sqm']?.toString(),
      averageRent: json['average_rent']?.toString(),
      averageRentalYield: (json['average_rental_yield'] as num?)?.toDouble(),
      priceTrend: json['price_trend'] as String?,
      demand: json['demand'] as String?,
      listingsCount: (json['listings_count'] as num?)?.toInt(),
      daysOnMarket: (json['days_on_market'] as num?)?.toInt(),
    );
    return m.hasAny ? m : null;
  }

  PropertyFloorPlan? _mapFloorPlan(Map<String, dynamic>? json) {
    if (json == null) return null;
    final roomsRaw = json['rooms'] as List? ?? const [];
    final rooms = <FloorPlanRoom>[];
    for (final r in roomsRaw) {
      if (r is! Map) continue;
      final m = Map<String, dynamic>.from(r);
      final name = m['name'] as String? ?? m['room'] as String? ?? '';
      if (name.isEmpty) continue;
      rooms.add(
        FloorPlanRoom(
          name: name,
          x: (m['x'] as num?)?.toDouble() ?? 0,
          y: (m['y'] as num?)?.toDouble() ?? 0,
          width: (m['w'] as num?)?.toDouble() ??
              (m['width'] as num?)?.toDouble() ??
              0.2,
          height: (m['h'] as num?)?.toDouble() ??
              (m['height'] as num?)?.toDouble() ??
              0.2,
          roomKey: m['room_key'] as String?,
          linked3dPointId: m['linked_3d_point_id'] as String?,
          linkedMediaCategory: m['linked_media_category'] as String?,
        ),
      );
    }
    final floors = (json['floors'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const [];
    final plan = PropertyFloorPlan(
      imageUrl: json['image_url'] as String? ?? json['url'] as String?,
      floors: floors,
      rooms: rooms,
    );
    return plan.hasAny ? plan : null;
  }
}
