import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/country_context_provider.dart';
import '../../services/property_ai_service.dart';
import '../../services/property_catalog_demo.dart';
import '../../services/supabase_service.dart';
import './models/property_data.dart';
import './widgets/ai_recommendations_sheet.dart';
import './widgets/map_filter_chips_widget.dart';
import './widgets/map_preview_carousel.dart';
import '../../features/authentication/presentation/widgets/demo_auto_advance.dart';
import './widgets/map_search_bar_widget.dart';
import './widgets/property_detail_sheet_widget.dart';
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
  List<String> _searchSuggestions = [];
  String? _activeAreaLabel;

  // Filter state
  RangeValues _priceRange = const RangeValues(0, 1000000);
  RangeValues _areaRange = const RangeValues(0, 1000);
  int _minBedrooms = 0;
  String _selectedCity = 'All';

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
    'Baghdad',
    'Basra',
    'Erbil',
    'Mosul',
    'Najaf',
    'Karbala',
  ];

  List<PropertyData> _allProperties = [];
  List<PropertyData> _filteredProperties = [];
  final PropertyAiService _propertyAi = PropertyAiService();
  Timer? _aiSearchDebounce;
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
  }

  @override
  void dispose() {
    _aiSearchDebounce?.cancel();
    _draggableController.removeListener(_onSheetExtentChanged);
    _draggableController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final countryCode = context.read<CountryContextProvider>().activeCountryCode;
      _loadedCountryCode = countryCode;
      final data = await SupabaseService.instance.getProperties(
        limit: 50,
        countryCode: countryCode,
      );
      if (data.isNotEmpty) {
        final props = data
            .map((d) => PropertyData.fromSupabase(d))
            .where((p) => p.lat != 0 && p.lng != 0)
            .toList();
        if (mounted) {
          setState(() {
            _allProperties = props;
            _filteredProperties = List.from(props);
          });
        }
      } else {
        _loadMockData();
      }
    } catch (e) {
      _loadMockData();
    }
    if (mounted) setState(() => _isLoading = false);
    _maybePlayDemoCardFlow();
  }

  void _maybePlayDemoCardFlow() {
    if (!DemoAutoAdvance.enabled || _demoCardFlowStarted) return;
    if (_filteredProperties.isEmpty) return;
    _demoCardFlowStarted = true;
    Future<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      _onPropertySelected(_filteredProperties.first);
      await Future<void>.delayed(const Duration(milliseconds: 2800));
      if (!mounted || _selectedProperty == null) return;
      _openPropertyDetail(_selectedProperty!);
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
      _activeAreaLabel = null;
      _filteredProperties = _allProperties.where((p) {
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
              if (p.type != 'land') return false;
              break;
            case 'Commercial':
              if (p.type != 'commercial') return false;
              break;
            case 'Investment':
              if (p.listingType != 'investment') return false;
              break;
          }
        }
        if (_priceRange.start > 0 && p.price < _priceRange.start) return false;
        if (_priceRange.end < 1000000 && p.price > _priceRange.end) {
          return false;
        }
        if (_areaRange.start > 0 && p.area < _areaRange.start) return false;
        if (_areaRange.end < 1000 && p.area > _areaRange.end) return false;
        if (_minBedrooms > 0 && p.bedrooms < _minBedrooms) return false;
        if (_selectedCity != 'All' &&
            !p.address.toLowerCase().contains(_selectedCity.toLowerCase())) {
          return false;
        }
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final hay = [
            p.title,
            p.address,
            p.description,
            p.type,
            p.listingType,
            p.formattedPrice,
            p.price.toString(),
            p.area.toString(),
            p.bedrooms.toString(),
            ...p.tags,
            ...p.nearbySchools,
            ...p.nearbyAmenities,
          ].join(' ').toLowerCase();
          final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 1);
          final anyMatch =
              hay.contains(q) || tokens.every((t) => hay.contains(t));
          if (!anyMatch) return false;
        }
        return true;
      }).toList();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _applyFilters();
    _addToFilterHistory();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final suggestions = <String>{};
        for (final p in _allProperties) {
          if (p.title.toLowerCase().contains(q)) suggestions.add(p.title);
          if (p.address.toLowerCase().contains(q)) suggestions.add(p.address);
          if (p.description.toLowerCase().contains(q)) {
            suggestions.add(p.title);
          }
          for (final t in p.tags) {
            if (t.toLowerCase().contains(q)) suggestions.add(t);
          }
          for (final s in p.nearbySchools) {
            if (s.toLowerCase().contains(q)) suggestions.add(s);
          }
        }
        _searchSuggestions = suggestions.take(6).toList();
      } else {
        _searchSuggestions = [];
        _aiSearchInsight = null;
      }
    });
    _applyFilters();
    if (query.isNotEmpty) _addToFilterHistory();
    _scheduleAiSearch(query);
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
        _searchSuggestions = {
          ...result.suggestions.map((s) => s.property.title),
          ..._searchSuggestions,
        }.take(6).toList();
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
    final nearby = List<PropertyData>.from(_filteredProperties)
      ..sort((a, b) {
        final da = _distance(property, a);
        final db = _distance(property, b);
        return da.compareTo(db);
      });
    setState(() {
      _selectedProperty = property;
      _previewProperties = nearby.take(12).toList();
      _showPreview = true;
    });
    _mapKey.currentState?.focusOnPin(LatLng(property.lat, property.lng));
  }

  double _distance(PropertyData a, PropertyData b) {
    final dLat = a.lat - b.lat;
    final dLng = a.lng - b.lng;
    return dLat * dLat + dLng * dLng;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropertyDetailSheetWidget(property: property),
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

    return Scaffold(
      extendBodyBehindAppBar: true,
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
              onZoomChanged: (z) {
                if ((z - _mapZoom).abs() > 0.15) {
                  setState(() => _mapZoom = z);
                }
              },
              onBackgroundTap: _closePreview,
            ),

            // Top overlay: search bar + filter chips
            Positioned(
              top: 0,
              left: 0,
              right: 0,
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
                              onVoiceSearch: () {},
                              onSearch: _onSearch,
                              suggestions: _searchSuggestions,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    MapFilterChipsWidget(
                      options: _filterOptions,
                      selected: _selectedFilter,
                      onChanged: _onFilterChanged,
                    ),
                  ],
                ),
              ),
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
                        onTap: () {
                          setState(() {
                            _activeAreaLabel = null;
                            _filteredProperties = List.from(_allProperties);
                          });
                          _applyFilters();
                        },
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

            // Drawing mode banner
            if (_isDrawingMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 130,
                left: 16,
                right: 16,
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
                        onTap: () => setState(() => _isDrawingMode = false),
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

            // ─── BOTTOM PANEL: handle + stats only, swipeable ───
            DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: 0.14,
              minChildSize: 0.12,
              maxChildSize: isTablet ? 0.36 : 0.42,
              snap: true,
              snapSizes: isTablet
                  ? const [0.14, 0.24, 0.36]
                  : const [0.14, 0.24, 0.42],
              builder: (context, scrollController) {
                return Material(
                  color: theme.colorScheme.surface,
                  elevation: 8,
                  shadowColor: Colors.black26,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: ListView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBDBDBD),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 160),
                    ],
                  ),
                );
              },
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
          ],
        ),
      );
  }

  void _showFilterPanel(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FullFilterSheet(
        selectedFilter: _selectedFilter,
        priceRange: _priceRange,
        areaRange: _areaRange,
        minBedrooms: _minBedrooms,
        selectedCity: _selectedCity,
        cities: _cities,
        onApply: (filter, price, area, beds, city) {
          setState(() {
            _selectedFilter = filter;
            _priceRange = price;
            _areaRange = area;
            _minBedrooms = beds;
            _selectedCity = city;
          });
          _applyFilters();
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedFilter = 'All';
            _priceRange = const RangeValues(0, 1000000);
            _areaRange = const RangeValues(0, 1000);
            _minBedrooms = 0;
            _selectedCity = 'All';
          });
          _applyFilters();
          Navigator.pop(context);
        },
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

// ─── Full Filter Sheet ────────────────────────────────────────────────────────
class _FullFilterSheet extends StatefulWidget {
  final String selectedFilter;
  final RangeValues priceRange;
  final RangeValues areaRange;
  final int minBedrooms;
  final String selectedCity;
  final List<String> cities;
  final Function(String, RangeValues, RangeValues, int, String) onApply;
  final VoidCallback onReset;

  const _FullFilterSheet({
    required this.selectedFilter,
    required this.priceRange,
    required this.areaRange,
    required this.minBedrooms,
    required this.selectedCity,
    required this.cities,
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
  late String _selectedCity;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedFilter;
    _priceRange = widget.priceRange;
    _areaRange = widget.areaRange;
    _minBedrooms = widget.minBedrooms;
    _selectedCity = widget.selectedCity;
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
                                    : AppTheme.surfaceVariantLight,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? null
                                    : Border.all(color: AppTheme.borderLight),
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
                    loc.city,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.cities.map((c) {
                      final isSelected = _selectedCity == c;
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
                                : AppTheme.surfaceVariantLight,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? null
                                : Border.all(color: AppTheme.borderLight),
                          ),
                          child: Text(
                            c,
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
                      Text(
                        '\$${(_priceRange.start / 1000).toStringAsFixed(0)}K — \$${(_priceRange.end / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000000,
                    divisions: 100,
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
                    values: _areaRange,
                    min: 0,
                    max: 1000,
                    divisions: 100,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.primaryContainer,
                    onChanged: (v) => setState(() => _areaRange = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.minBedrooms,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [0, 1, 2, 3, 4, 5].map((n) {
                      final isSelected = _minBedrooms == n;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _minBedrooms = n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.surfaceVariantLight,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? null
                                  : Border.all(color: AppTheme.borderLight),
                            ),
                            child: Center(
                              child: Text(
                                n == 0 ? loc.any : '$n+',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                  _selected,
                  _priceRange,
                  _areaRange,
                  _minBedrooms,
                  _selectedCity,
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

