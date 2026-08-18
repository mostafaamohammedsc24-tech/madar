import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../core/currency/currency_registry.dart';
import '../../core/geo/iraq_governorates.dart';
import '../../core/geo/region_detection_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../providers/country_context_provider.dart';
import '../../core/performance/performance_monitor.dart';
import '../../services/places_service.dart';
import '../../services/property_ai_service.dart';
import '../../services/property_catalog_demo.dart';
import '../../core/maps/map_bounds.dart';
import '../../services/property_map_repository.dart';
import '../../services/supabase_service.dart';
import '../../features/property/presentation/navigation/open_property_report.dart';
import '../../features/property/presentation/widgets/sheet_grabber.dart';
import './models/property_data.dart';
import './widgets/ai_recommendations_sheet.dart';
import './widgets/map_filter_chips_widget.dart';
import './widgets/map_preview_carousel.dart';
import './widgets/property_card_copy.dart';
import '../../features/authentication/presentation/widgets/demo_auto_advance.dart';
import './widgets/map_search_bar_widget.dart';
import './widgets/property_listing_card.dart';
import './widgets/property_map_widget.dart';
import './widgets/saved_area_search_widget.dart';

export './models/property_data.dart';

class SearchMapScreen extends StatefulWidget {
  const SearchMapScreen({super.key});

  @override
  State<SearchMapScreen> createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends State<SearchMapScreen>
    with TickerProviderStateMixin {
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  final GlobalKey<PropertyMapWidgetState> _mapKey =
      GlobalKey<PropertyMapWidgetState>();
  bool _demoCardFlowStarted = false;
  String? _loadedCountryCode;
  String _selectedFilter = 'All';
  PropertyData? _selectedProperty;
  bool _showPreview = false;
  List<PropertyData> _previewProperties = [];
  double _mapZoom = 12.5;
  double _sheetExtent = 0.14;
  String _mapType = 'normal';
  bool _isDrawingMode = false;
  bool _isLoading = true;
  String _searchQuery = '';
  List<SearchSuggestionItem> _searchSuggestions = [];
  String? _activeAreaLabel;

  // Area / landmark focus
  final PlacesService _places = PlacesService();
  Timer? _placesDebounce;
  List<LatLng>? _areaPolygon;
  LandmarkResult? _activeLandmark;

  // Filter state
  RangeValues _priceRange = const RangeValues(0, 1000000000000);
  RangeValues _areaRange = const RangeValues(0, 5000000);
  int _minBedrooms = 0;
  int _minBathrooms = 0;
  String _selectedCity = 'All';
  String _selectedPropertyType = 'All';
  final Set<String> _selectedFeatures = {};
  final Set<String> _selectedNearby = {};
  String _builderQuery = '';
  int _minYearBuilt = 0;
  bool _verifiedOnly = false;

  // Sort
  String _sortMode = 'for_you';

  final List<String> _filterOptions = [
    'All',
    'Sale',
    'Rent',
    'Mortgage',
    'Land',
    'Commercial',
    'Investment',
  ];

  final List<String> _cities = [
    'All',
    ...IraqGovernorates.all.map((g) => g.id),
  ];

  List<PropertyData> _allProperties = [];
  List<PropertyData> _filteredProperties = [];
  final PropertyAiService _propertyAi = PropertyAiService();
  final PropertyMapRepository _mapRepo = PropertyMapRepository();
  Timer? _aiSearchDebounce;
  Timer? _boundsDebounce;
  String? _aiSearchInsight;
  int _aiSearchToken = 0;

  List<Map<String, dynamic>> _savedSearches = [];
  final List<Map<String, dynamic>> _filterHistory = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _loadSavedSearches();
    _draggableController.addListener(_onSheetExtentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyGpsContext());
  }

  @override
  void dispose() {
    _aiSearchDebounce?.cancel();
    _placesDebounce?.cancel();
    _boundsDebounce?.cancel();
    _draggableController.removeListener(_onSheetExtentChanged);
    _draggableController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    // Initial viewport fetch (Baghdad default) — refined on first map idle.
    const bootstrap = MapBounds(
      southwest: LatLng(33.20, 44.25),
      northeast: LatLng(33.45, 44.55),
    );
    await _fetchPropertiesForBounds(bootstrap, showLoading: true);
  }

  void _onMapBoundsChanged(MapBounds bounds) {
    _boundsDebounce?.cancel();
    _boundsDebounce = Timer(const Duration(milliseconds: 450), () {
      _fetchPropertiesForBounds(bounds.padded());
    });
  }

  Future<void> _fetchPropertiesForBounds(
    MapBounds bounds, {
    bool showLoading = false,
  }) async {
    if (showLoading) setState(() => _isLoading = true);
    PerformanceMonitor.instance.mark('map_bounds_fetch');
    try {
      final countryCode =
          context.read<CountryContextProvider>().activeCountryCode;
      _loadedCountryCode = countryCode;
      final filter = _selectedFilter == 'All' ? null : _selectedFilter;
      final props = await _mapRepo.fetchInBounds(
        bounds: bounds,
        countryCode: countryCode,
        listingFilter: filter,
        limit: 150,
      );
      if (!mounted) return;
      PerformanceMonitor.instance.measure('map_bounds_ready', 'map_bounds_fetch');
      setState(() {
        _allProperties = props;
        _filteredProperties = List.from(props);
        _isLoading = false;
      });
      _applySortLocked();
      _maybePlayDemoCardFlow();
    } catch (_) {
      if (mounted) {
        _loadMockData();
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyGpsContext() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      final detected =
          await RegionDetectionService().detectFromCurrentLocation();
      if (!mounted || detected == null) return;
      await context.read<LocaleProvider>().setLanguage(detected.suggestedLanguage);
      await context.read<CountryContextProvider>().setCountry(detected.country);
      await context.read<CountryContextProvider>().setCurrency(
            detected.suggestedCurrencyCode,
            overridden: false,
          );
      _mapKey.currentState?.moveToLocation(
        LatLng(detected.latitude ?? 33.3152, detected.longitude ?? 44.3661),
      );
      await _loadProperties();
    } catch (_) {}
  }

  void _maybePlayDemoCardFlow() {
    if (!DemoAutoAdvance.enabled || _demoCardFlowStarted) return;
    if (_filteredProperties.isEmpty) return;
    _demoCardFlowStarted = true;
    Future<void>(() async {
      Future<void> wait(int ms) =>
          Future<void>.delayed(Duration(milliseconds: ms));

      // 1) Pin tap → floating card strip
      await wait(2200);
      if (!mounted) return;
      _onPropertySelected(_filteredProperties.first);

      // 2) Open the full listing sheet
      await wait(3000);
      if (!mounted || _selectedProperty == null) return;
      _openPropertyDetail(_selectedProperty!);

      // 3) Close listing + preview
      await wait(3600);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      _closePreview();

      // 4) Area polygon focus (الكرادة)
      await wait(1200);
      if (!mounted) return;
      final karrada = PlacesService.demoAreaByName('الكرادة');
      if (karrada != null) _applyAreaFocus(karrada);

      // 5) Landmark focus (جامعة بغداد)
      await wait(3800);
      if (!mounted) return;
      _clearAreaFocus();
      final uni = PlacesService.demoLandmarkByName('جامعة بغداد');
      if (uni != null) _applyLandmarkFocus(uni);

      // 6) Expanded sheet with categorized rows
      await wait(3800);
      if (!mounted) return;
      _clearAreaFocus();
      _draggableController.animateTo(
        0.92,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );

      // 7) Back to map
      await wait(4200);
      if (!mounted) return;
      _draggableController.animateTo(
        0.14,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _loadSavedSearches() async {
    try {
      final searches = await SupabaseService.instance.getSavedSearches();
      if (mounted) setState(() => _savedSearches = searches);
    } catch (_) {}
  }

  void _addToFilterHistory() {
    if (_selectedFilter == 'All' &&
        _searchQuery.isEmpty &&
        _selectedCity == 'All') {
      return;
    }
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'query': _searchQuery,
      'filter': _selectedFilter,
      'city': _selectedCity,
      'bedrooms': _minBedrooms,
      'priceMin': _priceRange.start,
      'priceMax': _priceRange.end,
      'timestamp': DateTime.now().toIso8601String(),
      'resultCount': _filteredProperties.length,
    };
    setState(() {
      // Avoid duplicates
      _filterHistory.removeWhere(
        (h) =>
            h['query'] == entry['query'] &&
            h['filter'] == entry['filter'] &&
            h['city'] == entry['city'],
      );
      _filterHistory.insert(0, entry);
      if (_filterHistory.length > 20) _filterHistory.removeLast();
    });
  }

  void _showFilterHistory() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterHistorySheet(
        filterHistory: _filterHistory,
        savedSearches: _savedSearches,
        onHistorySelected: (entry) {
          Navigator.pop(context);
          setState(() {
            _searchQuery = entry['query'] as String? ?? '';
            _selectedFilter = entry['filter'] as String? ?? 'All';
            _selectedCity = entry['city'] as String? ?? 'All';
            _minBedrooms = (entry['bedrooms'] as num?)?.toInt() ?? 0;
            final priceMin = (entry['priceMin'] as num?)?.toDouble() ?? 0;
            final priceMax = (entry['priceMax'] as num?)?.toDouble() ?? 1000000;
            _priceRange = RangeValues(priceMin, priceMax);
          });
          _applyFilters();
        },
        onClearHistory: () {
          setState(() => _filterHistory.clear());
          Navigator.pop(context);
        },
        onSavedSearchSelected: (search) {
          Navigator.pop(context);
          final query = search['query'] as String? ?? '';
          final filters = search['filters'] as Map<String, dynamic>?;
          setState(() {
            _searchQuery = query;
            if (filters != null) {
              _selectedFilter = filters['filter'] as String? ?? 'All';
              _selectedCity = filters['city'] as String? ?? 'All';
              _minBedrooms = (filters['minBedrooms'] as num?)?.toInt() ?? 0;
              final priceMin = (filters['priceMin'] as num?)?.toDouble() ?? 0;
              final priceMax =
                  (filters['priceMax'] as num?)?.toDouble() ?? 1000000;
              _priceRange = RangeValues(priceMin, priceMax);
            }
          });
          _applyFilters();
        },
        onDeleteSaved: (id) async {
          await SupabaseService.instance.deleteSavedSearch(id);
          await _loadSavedSearches();
          if (mounted) Navigator.pop(context);
          _showFilterHistory();
        },
      ),
    );
  }

  Future<void> _saveCurrentSearch() async {
    final loc = AppLocalizations.of(context);
    if (_searchQuery.isEmpty &&
        _selectedFilter == 'All' &&
        _selectedCity == 'All') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.enterSearchToSave),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    await SupabaseService.instance.saveSearch(
      query: _searchQuery.isNotEmpty ? _searchQuery : _selectedFilter,
      filters: {
        'filter': _selectedFilter,
        'city': _selectedCity,
        'minBedrooms': _minBedrooms,
        'priceMin': _priceRange.start,
        'priceMax': _priceRange.end,
      },
    );
    await _loadSavedSearches();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.searchSaved),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSavedSearches() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SavedSearchesSheet(
        savedSearches: _savedSearches,
        onSearchSelected: (search) {
          Navigator.pop(context);
          final query = search['query'] as String? ?? '';
          final filters = search['filters'] as Map<String, dynamic>?;
          setState(() {
            _searchQuery = query;
            if (filters != null) {
              _selectedFilter = filters['filter'] as String? ?? 'All';
              _selectedCity = filters['city'] as String? ?? 'All';
              _minBedrooms = (filters['minBedrooms'] as num?)?.toInt() ?? 0;
              final priceMin = (filters['priceMin'] as num?)?.toDouble() ?? 0;
              final priceMax =
                  (filters['priceMax'] as num?)?.toDouble() ?? 1000000;
              _priceRange = RangeValues(priceMin, priceMax);
            }
          });
          _applyFilters();
        },
        onDelete: (id) async {
          await SupabaseService.instance.deleteSavedSearch(id);
          await _loadSavedSearches();
          if (mounted) Navigator.pop(context);
          _showSavedSearches();
        },
      ),
    );
  }

  void _loadMockData() {
    final props = PropertyCatalogDemo.listings();
    setState(() {
      _allProperties = props;
      _filteredProperties = List.from(props);
    });
    _maybePlayDemoCardFlow();
  }

  void _applyFilters() {
    setState(() {
      _filteredProperties = _allProperties.where(_matchesFilters).toList();
      _applySortLocked();
    });
  }

  bool _matchesFilters(PropertyData p) {
    if (_selectedFilter != 'All') {
      switch (_selectedFilter) {
        case 'Sale':
          if (p.listingType != 'sale') return false;
          break;
        case 'Rent':
          if (p.listingType != 'rent') return false;
          break;
        case 'Mortgage':
          if (p.listingType != 'mortgage') return false;
          break;
        case 'Land':
          if (p.type != 'land' && p.type != 'agricultural') return false;
          break;
        case 'Commercial':
          if (p.type != 'commercial') return false;
          break;
        case 'Investment':
          if (p.listingType != 'investment') return false;
          break;
      }
    }
    final currency =
        context.read<CountryContextProvider>().activeCurrency;
    final priceMax = CurrencyRegistry.filterMaxFor(currency);
    final price = p.priceIn(currency);
    if (_priceRange.start > 0 && price < _priceRange.start) return false;
    if (_priceRange.end < priceMax && price > _priceRange.end) return false;
    if (_areaRange.start > 0 && p.area < _areaRange.start) return false;
    if (_areaRange.end < 5000000 && p.area > _areaRange.end) return false;
    if (_minBedrooms > 0 && p.bedrooms < _minBedrooms) return false;
    if (_minBathrooms > 0 && p.bathrooms < _minBathrooms) return false;
    if (_selectedPropertyType != 'All' && p.type != _selectedPropertyType) {
      return false;
    }
    if (_verifiedOnly && !p.isVerified) return false;
    if (_minYearBuilt > 0 && (p.yearBuilt == 0 || p.yearBuilt < _minYearBuilt)) {
      return false;
    }
    if (_builderQuery.isNotEmpty &&
        !p.builderCompany.toLowerCase().contains(
              _builderQuery.toLowerCase(),
            )) {
      return false;
    }
    if (_selectedFeatures.isNotEmpty) {
      final tagText = [...p.tags, p.description].join(' ').toLowerCase();
      for (final feature in _selectedFeatures) {
        final words = _featureKeywords[feature] ?? [feature.toLowerCase()];
        if (!words.any(tagText.contains)) return false;
      }
    }
    if (_selectedNearby.isNotEmpty) {
      final nearText = [
        ...p.nearbySchools,
        ...p.nearbyAmenities,
        p.description,
      ].join(' ').toLowerCase();
      for (final near in _selectedNearby) {
        final words = _nearbyKeywords[near] ?? [near.toLowerCase()];
        if (!words.any(nearText.contains)) return false;
      }
    }
    if (_selectedCity != 'All') {
      final gov = IraqGovernorates.byId(_selectedCity);
      final hay = '${p.address} ${p.district} ${p.title} ${p.description}';
      if (gov == null || !gov.matches(hay)) return false;
    }
    if (_areaPolygon != null &&
        !_isPointInPolygon(LatLng(p.lat, p.lng), [
          ..._areaPolygon!,
          _areaPolygon!.first,
        ])) {
      return false;
    }
    if (_activeLandmark != null) {
      final d = _distanceKm(
        p.lat,
        p.lng,
        _activeLandmark!.location.latitude,
        _activeLandmark!.location.longitude,
      );
      if (d > 3.0) return false;
    }
    if (_searchQuery.isNotEmpty &&
        _areaPolygon == null &&
        _activeLandmark == null) {
      final q = _searchQuery.toLowerCase();
      final hay = [
        p.title,
        p.localizedTitle(AppLanguage.arabic),
        p.localizedTitle(AppLanguage.kurdish),
        p.localizedTitle(AppLanguage.english),
        p.address,
        p.localizedAddress(AppLanguage.arabic),
        p.description,
        p.type,
        p.listingType,
        p.formattedPrice,
        p.price.toString(),
        p.area.toString(),
        p.bedrooms.toString(),
        p.builderCompany,
        ...p.tags,
        ...p.nearbySchools,
        ...p.nearbyAmenities,
      ].join(' ').toLowerCase();
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 1);
      final anyMatch = hay.contains(q) || tokens.every((t) => hay.contains(t));
      if (!anyMatch) return false;
    }
    return true;
  }

  static const Map<String, List<String>> _featureKeywords = {
    'Furnished': ['furnished', 'مفروش'],
    'Parking': ['parking', 'garage', 'موقف', 'كراج'],
    'Elevator': ['elevator', 'مصعد'],
    'Garden': ['garden', 'حديقة'],
    'Pool': ['pool', 'مسبح'],
    'Generator': ['generator', 'backup power', 'مولد'],
    'Balcony': ['balcony', 'بلكون', 'شرفة'],
    'Security': ['security', 'حراسة', 'أمن'],
  };

  static const Map<String, List<String>> _nearbyKeywords = {
    'Schools': ['school', 'college', 'مدرسة', 'كلية'],
    'Hospital': ['hospital', 'clinic', 'مستشفى', 'عيادة'],
    'Mall': ['mall', 'مول', 'تسوق'],
    'Transit': ['metro', 'transit', 'bus', 'محطة', 'مترو'],
    'Mosque': ['mosque', 'جامع', 'مسجد'],
    'Park': ['park', 'حديقة', 'متنزه'],
  };

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const degKm = 111.32;
    final dLat = (lat1 - lat2) * degKm;
    final dLng = (lng1 - lng2) * degKm * 0.84; // cos(33°)
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  void _applySortLocked() {
    switch (_sortMode) {
      case 'price_asc':
        _filteredProperties.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        _filteredProperties.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'area_desc':
        _filteredProperties.sort((a, b) => b.area.compareTo(a.area));
        break;
      case 'newest':
        _filteredProperties.sort((a, b) => b.yearBuilt.compareTo(a.yearBuilt));
        break;
      default:
        _filteredProperties.sort((a, b) {
          int score(PropertyData p) =>
              (p.isFeatured ? 2 : 0) + (p.isVerified ? 1 : 0);
          return score(b).compareTo(score(a));
        });
    }
  }

  void _setSortMode(String mode) {
    setState(() => _sortMode = mode);
    _applyFilters();
  }

  // ─── Area & landmark focus ─────────────────────────────────────────────────

  Future<void> _onSuggestionTap(SearchSuggestionItem item) async {
    final payload = item.payload;
    if (payload is PlaceSuggestion) {
      if (payload.kind == 'area') {
        final area = await _places.resolveArea(payload);
        if (area != null) {
          _applyAreaFocus(area);
          return;
        }
      } else if (payload.kind == 'landmark') {
        final landmark = await _places.resolveLandmark(payload);
        if (landmark != null) {
          _applyLandmarkFocus(landmark);
          return;
        }
      }
    }
    _onSearch(item.label);
  }

  void _applyAreaFocus(AreaResult area) {
    setState(() {
      _activeLandmark = null;
      _areaPolygon = area.polygon;
      _activeAreaLabel = area.name;
      _searchQuery = '';
      _searchSuggestions = [];
    });
    _applyFilters();
    _mapKey.currentState?.fitBounds(area.polygon);
  }

  void _applyLandmarkFocus(LandmarkResult landmark) {
    setState(() {
      _areaPolygon = null;
      _activeLandmark = landmark;
      _activeAreaLabel = landmark.name;
      _searchQuery = '';
      _searchSuggestions = [];
    });
    _applyFilters();
    setState(() {
      _filteredProperties.sort((a, b) {
        final da = _distanceKm(
          a.lat,
          a.lng,
          landmark.location.latitude,
          landmark.location.longitude,
        );
        final db = _distanceKm(
          b.lat,
          b.lng,
          landmark.location.latitude,
          landmark.location.longitude,
        );
        return da.compareTo(db);
      });
    });
    final points = [
      landmark.location,
      ..._filteredProperties.take(8).map((p) => LatLng(p.lat, p.lng)),
    ];
    _mapKey.currentState?.fitBounds(points);
  }

  void _clearAreaFocus() {
    setState(() {
      _areaPolygon = null;
      _activeLandmark = null;
      _activeAreaLabel = null;
    });
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _applyFilters();
    _addToFilterHistory();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchSuggestions = [];
        _aiSearchInsight = null;
        _areaPolygon = null;
        _activeLandmark = null;
        _activeAreaLabel = null;
      } else {
        _searchSuggestions = _localPropertySuggestions(query);
      }
    });
    _applyFilters();
    if (query.isNotEmpty) {
      _addToFilterHistory();
      _schedulePlacesSuggestions(query);
    }
    _scheduleAiSearch(query);
  }

  void _onVoiceSearch() {
    // Voice capture runs inside MapSearchBarWidget (speech_to_text).
  }

  List<SearchSuggestionItem> _localPropertySuggestions(String query) {
    final q = query.toLowerCase();
    final out = <SearchSuggestionItem>[];
    final seen = <String>{};
    void add(String label, String kind) {
      if (label.isEmpty || !seen.add(label)) return;
      out.add(SearchSuggestionItem(label: label, kind: kind));
    }

    for (final p in _allProperties) {
      if (p.title.toLowerCase().contains(q)) add(p.title, 'property');
      if (p.address.toLowerCase().contains(q)) add(p.address, 'property');
      for (final t in p.tags) {
        if (t.toLowerCase().contains(q)) add(t, 'query');
      }
      for (final s in p.nearbySchools) {
        if (s.toLowerCase().contains(q)) add(s, 'landmark');
      }
    }
    return out.take(4).toList();
  }

  void _schedulePlacesSuggestions(String query) {
    _placesDebounce?.cancel();
    if (query.trim().length < 2) return;
    _placesDebounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _places.suggest(
        query,
        near: const LatLng(33.3152, 44.3932),
      );
      if (!mounted || _searchQuery != query) return;
      setState(() {
        final placeItems = results.map(
          (s) => SearchSuggestionItem(
            label: s.label,
            kind: s.kind,
            payload: s,
          ),
        );
        final merged = <String, SearchSuggestionItem>{};
        for (final item in [...placeItems, ..._searchSuggestions]) {
          merged.putIfAbsent(item.label, () => item);
        }
        _searchSuggestions = merged.values.take(6).toList();
      });
    });
  }

  void _scheduleAiSearch(String query) {
    _aiSearchDebounce?.cancel();
    if (query.trim().length < 3) return;
    final token = ++_aiSearchToken;
    _aiSearchDebounce = Timer(const Duration(milliseconds: 700), () async {
      final result = await _propertyAi.search(
        query: query,
        catalog: _allProperties,
      );
      if (!mounted || token != _aiSearchToken) return;

      final byId = {for (final p in _allProperties) p.id: p};
      var matched = result.matchedIds
          .map((id) => byId[id])
          .whereType<PropertyData>()
          .toList();
      if (matched.isEmpty) {
        matched = result.suggestions.map((s) => s.property).toList();
      }
      if (matched.isEmpty) return;

      if (result.sortHint == 'price_asc') {
        matched = List.from(matched)..sort((a, b) => a.price.compareTo(b.price));
      } else if (result.sortHint == 'price_desc') {
        matched = List.from(matched)..sort((a, b) => b.price.compareTo(a.price));
      } else if (result.sortHint == 'area_desc') {
        matched = List.from(matched)..sort((a, b) => b.area.compareTo(a.area));
      }

      setState(() {
        _filteredProperties = matched;
        _aiSearchInsight = result.reply.isNotEmpty ? result.reply : null;
        final merged = <String, SearchSuggestionItem>{};
        for (final s in result.suggestions) {
          merged.putIfAbsent(
            s.property.title,
            () => SearchSuggestionItem(
              label: s.property.title,
              kind: 'property',
            ),
          );
        }
        for (final item in _searchSuggestions) {
          merged.putIfAbsent(item.label, () => item);
        }
        _searchSuggestions = merged.values.take(6).toList();
      });

      if (_aiSearchInsight != null && _aiSearchInsight!.trim().isNotEmpty) {
        final preview = _aiSearchInsight!.length > 120
            ? '${_aiSearchInsight!.substring(0, 120)}…'
            : _aiSearchInsight!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(preview),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      if (result.mapFocusLat != null && result.mapFocusLng != null) {
        _mapKey.currentState?.moveToLocation(
          LatLng(result.mapFocusLat!, result.mapFocusLng!),
        );
      }
    });
  }

  void _onPropertySelected(PropertyData property) {
    final pool = _filteredProperties.isEmpty
        ? _allProperties
        : _filteredProperties;
    final similar = List<PropertyData>.from(pool)
      ..sort(
        (a, b) => _similarityScore(property, b)
            .compareTo(_similarityScore(property, a)),
      );
    setState(() {
      _selectedProperty = property;
      _previewProperties = [
        property,
        ...similar.where((p) => p.id != property.id),
      ].take(12).toList();
      _showPreview = true;
    });
    _mapKey.currentState?.focusOnPin(LatLng(property.lat, property.lng));
  }

  /// Similarity across every axis: location, price, area, type, specs, district.
  double _similarityScore(PropertyData base, PropertyData other) {
    if (other.id == base.id) return double.negativeInfinity;
    var score = 0.0;

    final km = _distanceKm(base.lat, base.lng, other.lat, other.lng);
    score += (5.0 - km).clamp(0, 5) * 2.0;

    if (base.price > 0 && other.price > 0) {
      final ratio = (other.price - base.price).abs() / base.price;
      score += (1.0 - ratio).clamp(0, 1) * 4.0;
    }
    if (base.area > 0 && other.area > 0) {
      final ratio = (other.area - base.area).abs() / base.area;
      score += (1.0 - ratio).clamp(0, 1) * 3.0;
    }
    if (other.type == base.type) score += 3.0;
    if (other.listingType == base.listingType) score += 2.0;
    if (base.district.isNotEmpty && other.district == base.district) {
      score += 2.5;
    }
    if ((other.bedrooms - base.bedrooms).abs() <= 1) score += 1.0;
    if (base.builderCompany.isNotEmpty &&
        other.builderCompany == base.builderCompany) {
      score += 1.5;
    }
    final sharedTags = other.tags.toSet().intersection(base.tags.toSet());
    score += sharedTags.length * 0.5;
    return score;
  }

  void _onPreviewPageChanged(int index) {
    if (index < 0 || index >= _previewProperties.length) return;
    final property = _previewProperties[index];
    setState(() => _selectedProperty = property);
    _mapKey.currentState?.focusOnPin(LatLng(property.lat, property.lng));
  }

  void _onSheetExtentChanged() {
    if (!_draggableController.isAttached) return;
    final size = _draggableController.size;
    if ((size - _sheetExtent).abs() > 0.008) {
      setState(() => _sheetExtent = size);
    }
  }

  void _closePreview() {
    setState(() {
      _showPreview = false;
      _selectedProperty = null;
    });
  }

  void _openPropertyDetail(PropertyData property) {
    openPropertyReport(
      context,
      propertyMap: property.toDetailMap(),
    );
  }

  void _onPolygonDrawn(List<LatLng> points) {
    setState(() {
      _isDrawingMode = false;
      _filteredProperties = _allProperties.where((p) {
        return _isPointInPolygon(LatLng(p.lat, p.lng), points);
      }).toList();
    });
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      if (_rayCastIntersect(point, polygon[j], polygon[j + 1])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    final aY = vertA.latitude;
    final bY = vertB.latitude;
    final aX = vertA.longitude;
    final bX = vertB.longitude;
    final pY = point.latitude;
    final pX = point.longitude;
    if ((aY > pY) == (bY > pY)) return false;
    final xIntersect = (bX - aX) * (pY - aY) / (bY - aY) + aX;
    return pX < xIntersect;
  }

  void _showAiRecommendations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        child: AiRecommendationsSheet(
          allProperties: _allProperties,
          onPropertyTap: _onPropertySelected,
        ),
      ),
    );
  }

  void _showAreaSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavedAreaSearchSheet(
        allProperties: _allProperties,
        onAreaSelected: (filtered, label) {
          setState(() {
            _filteredProperties = filtered;
            _activeAreaLabel = label;
          });
        },
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _mapKey.currentState?.moveToLocation(
        LatLng(position.latitude, position.longitude),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final countryCode =
        context.watch<CountryContextProvider>().activeCountryCode;
    if (_loadedCountryCode != null && _loadedCountryCode != countryCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProperties());
    }

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    const bottomNavHeight = 0.0;
    final media = MediaQuery.of(context);
    final searchBand = media.padding.top + 76;
    final sheetMax = (1.0 - searchBand / media.size.height).clamp(0.82, 0.93);
    final sheetMerged = _sheetExtent >= sheetMax - 0.04;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
          children: [
            // Full-screen map
            PropertyMapWidget(
              key: _mapKey,
              properties: _filteredProperties,
              onPropertyTap: _onPropertySelected,
              mapType: _mapType,
              isDrawingMode: _isDrawingMode,
              onPolygonDrawn: _onPolygonDrawn,
              selectedPropertyId: _selectedProperty?.id,
              areaPolygon: _areaPolygon,
              landmarkLocation: _activeLandmark?.location,
              landmarkLabel: _activeLandmark?.name,
              onZoomChanged: (z) {
                if ((z - _mapZoom).abs() > 0.15) {
                  setState(() => _mapZoom = z);
                }
              },
              onBackgroundTap: _closePreview,
              onBoundsChanged: _onMapBoundsChanged,
            ),

            // Active area label banner
            if (_activeAreaLabel != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 130,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.areaLabel(_activeAreaLabel!, _filteredProperties.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearAreaFocus,
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Map controls — end side
            PositionedDirectional(
              end: 16,
              bottom: bottomNavHeight + 180,
              child: PointerInterceptor(
                child: Column(
                children: [
                  _MapControlButton(
                    iconName: 'my_location',
                    onTap: _goToMyLocation,
                    tooltip: loc.nearMe,
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    iconName: 'layers',
                    onTap: () => _showMapTypeSheet(context),
                    tooltip: loc.mapType,
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    iconName: _isDrawingMode ? 'close' : 'draw',
                    onTap: () {
                      setState(() {
                        _isDrawingMode = !_isDrawingMode;
                        if (!_isDrawingMode) _applyFilters();
                      });
                    },
                    tooltip: _isDrawingMode ? loc.cancelDraw : loc.drawArea,
                    isActive: _isDrawingMode,
                  ),
                  const SizedBox(height: 8),
                  // AI Recommendations button
                  _MapControlButton(
                    iconName: 'auto_awesome',
                    onTap: _showAiRecommendations,
                    tooltip: loc.aiPicks,
                    isActive: false,
                  ),
                ],
                ),
              ),
            ),

            // Drawing mode banner
            if (_isDrawingMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 130,
                left: 16,
                right: 16,
                child: PointerInterceptor(
                  child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gesture, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.drawAreaHint,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _mapKey.currentState?.completeDrawing();
                          setState(() => _isDrawingMode = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            loc.done,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              Positioned(
                top: MediaQuery.of(context).padding.top + 130,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.loadingProperties,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ─── BOTTOM PANEL: collapsed = stats, expanded = categorized rows ───
            DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: 0.14,
              minChildSize: 0.12,
              maxChildSize: sheetMax,
              snap: true,
              snapSizes: [0.14, 0.45, sheetMax],
              builder: (context, scrollController) {
                final expanded = _sheetExtent > 0.3;
                final listMode = _sheetExtent > 0.52;
                return Material(
                  color: theme.colorScheme.surface,
                  elevation: 8,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(sheetMerged ? 0 : 24),
                  ),
                  child: ListView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    children: [
                      const SheetGrabber(),
                      Text(
                        _mapZoom < 11
                            ? loc.zoomToSeeProperties
                            : loc.resultsCountLabel(
                                _filteredProperties.length,
                              ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 8),
                        _buildSheetToolbar(theme, loc),
                        const Divider(height: 20),
                        if (listMode)
                          ..._buildVerticalFeed(theme, loc)
                        else
                          ..._buildCategorySections(theme, loc),
                        const SizedBox(height: 60),
                      ] else
                        const SizedBox(height: 160),
                    ],
                  ),
                );
              },
            ),

            // Floating "back to map" button when the sheet covers the map
            if (_sheetExtent > 0.4)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: PointerInterceptor(
                    child: FloatingActionButton.extended(
                      heroTag: 'back_to_map',
                      backgroundColor: const Color(0xFF212121),
                      foregroundColor: Colors.white,
                      onPressed: () {
                        _draggableController.animateTo(
                          0.14,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      icon: const Icon(Icons.map_outlined, size: 20),
                      label: Text(
                        loc.backToMap,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),

            if (_showPreview && _previewProperties.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: (MediaQuery.sizeOf(context).height * _sheetExtent) + 8,
                child: PointerInterceptor(
                  child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: MapPreviewCarousel(
                    key: ValueKey(_previewProperties.first.id),
                    properties: _previewProperties,
                    initialIndex: _selectedProperty == null
                        ? 0
                        : _previewProperties
                            .indexWhere((p) => p.id == _selectedProperty!.id)
                            .clamp(0, _previewProperties.length - 1),
                    onPageChanged: _onPreviewPageChanged,
                    onOpen: _openPropertyDetail,
                    onClose: _closePreview,
                  ),
                  ),
                ),
              ),

            // Top overlay: search bar + filter chips (merges with the sheet)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: PointerInterceptor(
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                color: sheetMerged
                    ? theme.colorScheme.surface
                    : Colors.transparent,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          12,
                          16,
                          0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: MapSearchBarWidget(
                                onFilterTap: () => _showFilterPanel(context),
                                onVoiceSearch: _onVoiceSearch,
                                onSearch: _onSearch,
                                suggestions: _searchSuggestions,
                                onSuggestionTap: _onSuggestionTap,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        child: sheetMerged
                            ? const SizedBox(height: 8)
                            : Column(
                                children: [
                                  const SizedBox(height: 8),
                                  MapFilterChipsWidget(
                                    options: _filterOptions,
                                    selected: _selectedFilter,
                                    onChanged: _onFilterChanged,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  // ─── Expanded sheet: sort bar + save search ─────────────────────────────────
  Widget _buildSheetToolbar(ThemeData theme, AppLocalizations loc) {
    final sortLabels = {
      'for_you': loc.sortHomesForYou,
      'price_asc': loc.sortPriceLowHigh,
      'price_desc': loc.sortPriceHighLow,
      'area_desc': loc.sortAreaLarge,
      'newest': loc.sortNewest,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          PopupMenuButton<String>(
            initialValue: _sortMode,
            onSelected: _setSortMode,
            itemBuilder: (_) => sortLabels.entries
                .map(
                  (e) => PopupMenuItem<String>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${loc.sort}: ${sortLabels[_sortMode]}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.swap_vert,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _saveCurrentSearch,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.saved_search, size: 20),
            label: Text(
              loc.saveSearch,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Expanded sheet: categorized horizontal rows ────────────────────────────
  List<Widget> _buildCategorySections(ThemeData theme, AppLocalizations loc) {
    final items = _filteredProperties;
    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              loc.noData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }

    final aiPicks = items.where((p) => p.isFeatured || p.isVerified).toList();
    final popular = List<PropertyData>.from(items)
      ..sort((a, b) {
        int score(PropertyData p) =>
            (p.isFeatured ? 2 : 0) + (p.isVerified ? 1 : 0) + p.tags.length;
        return score(b).compareTo(score(a));
      });
    final newest = List<PropertyData>.from(items)
      ..sort((a, b) => b.yearBuilt.compareTo(a.yearBuilt));

    Widget section(String title, List<PropertyData> list) {
      if (list.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 10),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            height: 232,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
              itemCount: list.length.clamp(0, 10),
              itemBuilder: (context, i) => _HorizontalPropertyCard(
                property: list[i],
                onTap: () => _openPropertyDetail(list[i]),
              ),
            ),
          ),
        ],
      );
    }

    return [
      section(loc.aiPicksForYou, aiPicks),
      section(loc.mostPopular, popular),
      section(loc.recentlyAdded, newest),
    ];
  }

  List<Widget> _buildVerticalFeed(ThemeData theme, AppLocalizations loc) {
    final items = _filteredProperties;
    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              loc.noData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }
    return [
      for (final property in items)
        PropertyListingCard(
          property: property,
          onTap: () => _openPropertyDetail(property),
        ),
    ];
  }

  void _showFilterPanel(BuildContext context) {
    final currency = context.read<CountryContextProvider>().activeCurrency;
    final priceMax = CurrencyRegistry.filterMaxFor(currency);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PointerInterceptor(
        child: _FullFilterSheet(
        values: DeepFilterValues(
          filter: _selectedFilter,
          priceRange: RangeValues(
            _priceRange.start.clamp(0, priceMax),
            _priceRange.end.clamp(0, priceMax),
          ),
          areaRange: RangeValues(
            _areaRange.start.clamp(0, 5000000),
            _areaRange.end.clamp(0, 5000000),
          ),
          minBedrooms: _minBedrooms,
          minBathrooms: _minBathrooms,
          city: _selectedCity,
          propertyType: _selectedPropertyType,
          features: Set.from(_selectedFeatures),
          nearby: Set.from(_selectedNearby),
          builderQuery: _builderQuery,
          minYearBuilt: _minYearBuilt,
          verifiedOnly: _verifiedOnly,
        ),
        cities: _cities,
        currencyCode: currency,
        onApply: (v) {
          setState(() {
            _selectedFilter = v.filter;
            _priceRange = v.priceRange;
            _areaRange = v.areaRange;
            _minBedrooms = v.minBedrooms;
            _minBathrooms = v.minBathrooms;
            _selectedCity = v.city;
            _selectedPropertyType = v.propertyType;
            _selectedFeatures
              ..clear()
              ..addAll(v.features);
            _selectedNearby
              ..clear()
              ..addAll(v.nearby);
            _builderQuery = v.builderQuery;
            _minYearBuilt = v.minYearBuilt;
            _verifiedOnly = v.verifiedOnly;
          });
          _applyFilters();
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedFilter = 'All';
            _priceRange = RangeValues(0, priceMax);
            _areaRange = const RangeValues(0, 5000000);
            _minBedrooms = 0;
            _minBathrooms = 0;
            _selectedCity = 'All';
            _selectedPropertyType = 'All';
            _selectedFeatures.clear();
            _selectedNearby.clear();
            _builderQuery = '';
            _minYearBuilt = 0;
            _verifiedOnly = false;
          });
          _applyFilters();
          Navigator.pop(context);
        },
      ),
      ),
    );
  }

  void _showMapTypeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapTypeSheet(
        current: _mapType,
        onSelect: (type) {
          setState(() => _mapType = type);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Horizontal property card (categorized rows) ─────────────────────────────
class _HorizontalPropertyCard extends StatelessWidget {
  const _HorizontalPropertyCard({required this.property, required this.onTap});

  final PropertyData property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final p = property;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        margin: const EdgeInsetsDirectional.only(end: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.home_work_outlined),
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: p.listingTypeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        PropertyCardCopy.listing(context, p),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (p.isVerified)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          loc.verified,
                          style: const TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PropertyCardCopy.price(context, p),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    PropertyCardCopy.title(context, p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (p.bedrooms > 0) ...[
                        const Icon(Icons.bed_outlined, size: 13),
                        const SizedBox(width: 2),
                        Text('${p.bedrooms}',
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                      ],
                      if (p.bathrooms > 0) ...[
                        const Icon(Icons.bathtub_outlined, size: 13),
                        const SizedBox(width: 2),
                        Text('${p.bathrooms}',
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.square_foot, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        '${p.area.toStringAsFixed(0)}م²',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PropertyCardCopy.address(context, p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Icon Button ──────────────────────────────────────────────────────────
class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
    );
  }
}

// ─── Map Control Button ───────────────────────────────────────────────────────
class _MapControlButton extends StatelessWidget {
  final String iconName;
  final VoidCallback onTap;
  final String tooltip;
  final bool isActive;

  const _MapControlButton({
    required this.iconName,
    required this.onTap,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? AppTheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        shadowColor: Colors.black.withAlpha(38),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: isActive ? Colors.white : AppTheme.primary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Map Type Sheet ───────────────────────────────────────────────────────────
class _MapTypeSheet extends StatelessWidget {
  final String current;
  final Function(String) onSelect;

  const _MapTypeSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final types = [
      {'id': 'normal', 'label': loc.mapTypeStandard, 'icon': 'map'},
      {
        'id': 'satellite',
        'label': loc.mapTypeSatellite,
        'icon': 'satellite_alt',
      },
      {
        'id': 'terrain',
        'label': loc.mapTypeTerrain,
        'icon': 'terrain',
      },
      {'id': 'hybrid', 'label': loc.mapTypeHybrid, 'icon': 'layers'},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.mapType,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: types
                .map(
                  (t) => Expanded(
                    child: GestureDetector(
                      onTap: () => onSelect(t['id']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: current == t['id']
                              ? AppTheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            CustomIconWidget(
                              iconName: t['icon']!,
                              color: current == t['id']
                                  ? Colors.white
                                  : AppTheme.primary,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t['label']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: current == t['id']
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ─── Deep Filter Values ───────────────────────────────────────────────────────
class DeepFilterValues {
  DeepFilterValues({
    required this.filter,
    required this.priceRange,
    required this.areaRange,
    required this.minBedrooms,
    required this.minBathrooms,
    required this.city,
    required this.propertyType,
    required this.features,
    required this.nearby,
    required this.builderQuery,
    required this.minYearBuilt,
    required this.verifiedOnly,
  });

  String filter;
  RangeValues priceRange;
  RangeValues areaRange;
  int minBedrooms;
  int minBathrooms;
  String city;
  String propertyType;
  Set<String> features;
  Set<String> nearby;
  String builderQuery;
  int minYearBuilt;
  bool verifiedOnly;
}

// ─── Full Filter Sheet ────────────────────────────────────────────────────────
class _FullFilterSheet extends StatefulWidget {
  final DeepFilterValues values;
  final List<String> cities;
  final String currencyCode;
  final ValueChanged<DeepFilterValues> onApply;
  final VoidCallback onReset;

  const _FullFilterSheet({
    required this.values,
    required this.cities,
    required this.currencyCode,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FullFilterSheet> createState() => _FullFilterSheetState();
}

class _FullFilterSheetState extends State<_FullFilterSheet> {
  late String _selected;
  late RangeValues _priceRange;
  late RangeValues _areaRange;
  late int _minBedrooms;
  late int _minBathrooms;
  late String _selectedCity;
  late String _propertyType;
  late Set<String> _features;
  late Set<String> _nearby;
  late TextEditingController _builderCtrl;
  late int _minYearBuilt;
  late bool _verifiedOnly;

  double get _priceMax => CurrencyRegistry.filterMaxFor(widget.currencyCode);

  @override
  void initState() {
    super.initState();
    final v = widget.values;
    _selected = v.filter;
    final max = CurrencyRegistry.filterMaxFor(widget.currencyCode);
    _priceRange = RangeValues(
      v.priceRange.start.clamp(0, max),
      v.priceRange.end.clamp(0, max),
    );
    _areaRange = RangeValues(
      v.areaRange.start.clamp(0, 5000000),
      v.areaRange.end.clamp(0, 5000000),
    );
    _minBedrooms = v.minBedrooms.clamp(0, 50);
    _minBathrooms = v.minBathrooms.clamp(0, 30);
    _selectedCity = v.city;
    _propertyType = v.propertyType;
    _features = Set.from(v.features);
    _nearby = Set.from(v.nearby);
    _builderCtrl = TextEditingController(text: v.builderQuery);
    _minYearBuilt = v.minYearBuilt;
    _verifiedOnly = v.verifiedOnly;
  }

  @override
  void dispose() {
    _builderCtrl.dispose();
    super.dispose();
  }

  Widget _chipWrap({
    required List<String> options,
    required bool Function(String) isSelected,
    required void Function(String) onTap,
    String Function(String)? label,
  }) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = isSelected(option);
        return GestureDetector(
          onTap: () => onTap(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary
                  : theme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(20),
              border: selected
                  ? null
                  : Border.all(color: theme.borderColor),
            ),
            child: Text(
              label != null ? label(option) : option,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  loc.filters,
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onReset,
                  child: Text(
                    loc.resetAll,
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.listingType,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'All',
                          'Sale',
                          'Rent',
                          'Mortgage',
                          'Land',
                          'Commercial',
                          'Investment',
                        ].map((f) {
                          final isSelected = _selected == f;
                          final label = loc.filterLabel(f);
                          return GestureDetector(
                            onTap: () => setState(() => _selected = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : theme.surfaceVariantColor,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? null
                                    : Border.all(color: theme.borderColor),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loc.governorateLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.cities.map((c) {
                      final isSelected = _selectedCity == c;
                      final label = c == 'All'
                          ? loc.allGovernorates
                          : (IraqGovernorates.byId(c)?.name(loc.language) ?? c);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCity = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryLight
                                : theme.surfaceVariantColor,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? null
                                : Border.all(color: theme.borderColor),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.priceRange,
                        style: theme.textTheme.titleSmall,
                      ),
                      Flexible(
                        child: Text(
                          '${CurrencyRegistry.formatAmount(_priceRange.start, widget.currencyCode)} — ${CurrencyRegistry.formatAmount(_priceRange.end, widget.currencyCode)}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(
                      _priceRange.start.clamp(0, _priceMax),
                      _priceRange.end.clamp(0, _priceMax),
                    ),
                    min: 0,
                    max: _priceMax,
                    divisions: 200,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.primaryContainer,
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.areaSqm,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${_areaRange.start.toInt()} — ${_areaRange.end.toInt()} m²',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(
                      _areaRange.start.clamp(0, 5000000),
                      _areaRange.end.clamp(0, 5000000),
                    ),
                    min: 0,
                    max: 5000000,
                    divisions: 200,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.primaryContainer,
                    onChanged: (v) => setState(() => _areaRange = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.minBedrooms, style: theme.textTheme.titleSmall),
                      Text(
                        _minBedrooms == 0 ? loc.any : '$_minBedrooms+',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _minBedrooms.clamp(0, 50).toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.primaryContainer,
                    onChanged: (v) =>
                        setState(() => _minBedrooms = v.round()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.minBathrooms, style: theme.textTheme.titleSmall),
                      Text(
                        _minBathrooms == 0 ? loc.any : '$_minBathrooms+',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _minBathrooms.clamp(0, 30).toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.primaryContainer,
                    onChanged: (v) =>
                        setState(() => _minBathrooms = v.round()),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loc.propertyTypeLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _chipWrap(
                    options: const [
                      'All',
                      'apartment',
                      'villa',
                      'land',
                      'commercial',
                      'building',
                      'agricultural',
                    ],
                    isSelected: (o) => _propertyType == o,
                    onTap: (o) => setState(() => _propertyType = o),
                    label: (o) => o == 'All' ? loc.all : loc.propertyTypeName(o),
                  ),
                  const SizedBox(height: 24),
                  Text(loc.featuresLabel, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _chipWrap(
                    options: const [
                      'Furnished',
                      'Parking',
                      'Elevator',
                      'Garden',
                      'Pool',
                      'Generator',
                      'Balcony',
                      'Security',
                    ],
                    isSelected: _features.contains,
                    onTap: (o) => setState(() {
                      _features.contains(o)
                          ? _features.remove(o)
                          : _features.add(o);
                    }),
                    label: loc.featureName,
                  ),
                  const SizedBox(height: 24),
                  Text(loc.nearbyLabel, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _chipWrap(
                    options: const [
                      'Schools',
                      'Hospital',
                      'Mall',
                      'Transit',
                      'Mosque',
                      'Park',
                    ],
                    isSelected: _nearby.contains,
                    onTap: (o) => setState(() {
                      _nearby.contains(o) ? _nearby.remove(o) : _nearby.add(o);
                    }),
                    label: loc.nearbyName,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loc.builderCompanyLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _builderCtrl,
                    decoration: InputDecoration(
                      hintText: loc.builderCompanyHint,
                      prefixIcon: const Icon(Icons.engineering_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.yearBuiltLabel,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        _minYearBuilt == 0 ? loc.any : '$_minYearBuilt+',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _minYearBuilt.toDouble().clamp(1990, 2026),
                    min: 1990,
                    max: 2026,
                    divisions: 36,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.primaryContainer,
                    onChanged: (v) => setState(
                      () => _minYearBuilt = v.round() <= 1990 ? 0 : v.round(),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      loc.verifiedOnly,
                      style: theme.textTheme.titleSmall,
                    ),
                    value: _verifiedOnly,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (v) => setState(() => _verifiedOnly = v),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onApply(
                  DeepFilterValues(
                    filter: _selected,
                    priceRange: _priceRange,
                    areaRange: _areaRange,
                    minBedrooms: _minBedrooms,
                    minBathrooms: _minBathrooms,
                    city: _selectedCity,
                    propertyType: _propertyType,
                    features: _features,
                    nearby: _nearby,
                    builderQuery: _builderCtrl.text.trim(),
                    minYearBuilt: _minYearBuilt,
                    verifiedOnly: _verifiedOnly,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  loc.applyFilters,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ─── Saved Searches Sheet ─────────────────────────────────────────────────────
class _SavedSearchesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> savedSearches;
  final Function(Map<String, dynamic>) onSearchSelected;
  final Function(String) onDelete;

  const _SavedSearchesSheet({
    required this.savedSearches,
    required this.onSearchSelected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Icon(Icons.bookmarks, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  loc.savedSearchesTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  loc.savedCount(savedSearches.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: savedSearches.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20),
              itemBuilder: (_, i) {
                final search = savedSearches[i];
                final query = search['query'] as String? ?? '';
                final filters = search['filters'] as Map<String, dynamic>?;
                final city = filters?['city'] as String? ?? '';
                final filter = filters?['filter'] as String? ?? '';
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.search,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    query.isNotEmpty ? query : filter,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: city.isNotEmpty && city != 'All'
                      ? Text(
                          city,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppTheme.error.withAlpha(180),
                      size: 20,
                    ),
                    onPressed: () => onDelete(search['id'] as String? ?? ''),
                  ),
                  onTap: () => onSearchSelected(search),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Filter History Sheet ─────────────────────────────────────────────────────
class _FilterHistorySheet extends StatelessWidget {
  final List<Map<String, dynamic>> filterHistory;
  final List<Map<String, dynamic>> savedSearches;
  final Function(Map<String, dynamic>) onHistorySelected;
  final Function(Map<String, dynamic>) onSavedSearchSelected;
  final Function(String) onDeleteSaved;
  final VoidCallback onClearHistory;

  const _FilterHistorySheet({
    required this.filterHistory,
    required this.savedSearches,
    required this.onHistorySelected,
    required this.onSavedSearchSelected,
    required this.onDeleteSaved,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Icon(Icons.history, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  loc.searchFilterHistory,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (filterHistory.isNotEmpty)
                  TextButton(
                    onPressed: onClearHistory,
                    child: Text(
                      loc.clearAll,
                      style: TextStyle(color: AppTheme.error, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBar(
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primary,
                    tabs: [
                      Tab(text: loc.recent),
                      Tab(text: loc.savedTab),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        // Recent history tab
                        filterHistory.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 48,
                                      color: Colors.grey.withAlpha(100),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      loc.noSearchHistoryYet,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: filterHistory.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, indent: 20),
                                itemBuilder: (_, i) {
                                  final entry = filterHistory[i];
                                  final query = entry['query'] as String? ?? '';
                                  final filter =
                                      entry['filter'] as String? ?? 'All';
                                  final city = entry['city'] as String? ?? '';
                                  final count =
                                      entry['resultCount'] as int? ?? 0;
                                  final timestamp =
                                      entry['timestamp'] as String? ?? '';
                                  String timeLabel = '';
                                  try {
                                    final dt = DateTime.parse(timestamp);
                                    final diff = DateTime.now().difference(dt);
                                    if (diff.inMinutes < 60) {
                                      timeLabel = loc.timeAgoMinutes(diff.inMinutes);
                                    } else if (diff.inHours < 24) {
                                      timeLabel = loc.timeAgoHours(diff.inHours);
                                    } else {
                                      timeLabel = loc.timeAgoDays(diff.inDays);
                                    }
                                  } catch (_) {}

                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withAlpha(15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.search,
                                        color: AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      query.isNotEmpty ? query : filter,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Row(
                                      children: [
                                        if (city.isNotEmpty &&
                                            city != 'All') ...[
                                          Text(
                                            city,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          const Text(
                                            ' • ',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                        ],
                                        Text(
                                          loc.resultsCount(count),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          timeLabel,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => onHistorySelected(entry),
                                  );
                                },
                              ),

                        // Saved searches tab
                        savedSearches.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bookmarks_outlined,
                                      size: 48,
                                      color: Colors.grey.withAlpha(100),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      loc.noSavedSearchesYet,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: savedSearches.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, indent: 20),
                                itemBuilder: (_, i) {
                                  final search = savedSearches[i];
                                  final query =
                                      search['query'] as String? ?? '';
                                  final filters =
                                      search['filters']
                                          as Map<String, dynamic>?;
                                  final city =
                                      filters?['city'] as String? ?? '';
                                  final filter =
                                      filters?['filter'] as String? ?? '';

                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withAlpha(15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.bookmark,
                                        color: AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      query.isNotEmpty ? query : filter,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: city.isNotEmpty && city != 'All'
                                        ? Text(
                                            city,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          )
                                        : null,
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: AppTheme.error.withAlpha(180),
                                        size: 20,
                                      ),
                                      onPressed: () => onDeleteSaved(
                                        search['id'] as String? ?? '',
                                      ),
                                    ),
                                    onTap: () => onSavedSearchSelected(search),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

