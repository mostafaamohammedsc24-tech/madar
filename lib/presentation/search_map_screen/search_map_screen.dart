import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_export.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/supabase_service.dart';
import '../../widgets/country_context_switcher.dart';
import '../notifications/notification_center_screen.dart';
import './widgets/ai_recommendations_sheet.dart';
import './widgets/map_filter_chips_widget.dart';
import './widgets/map_search_bar_widget.dart';
import './widgets/property_card_slider_widget.dart';
import './widgets/property_detail_sheet_widget.dart';
import './widgets/property_list_screen.dart';
import './widgets/property_map_widget.dart';
import './widgets/saved_area_search_widget.dart';

class SearchMapScreen extends StatefulWidget {
  const SearchMapScreen({super.key});

  @override
  State<SearchMapScreen> createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends State<SearchMapScreen>
    with TickerProviderStateMixin {
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  bool _isSheetExpanded = false;
  bool _isFullScreenList = false;
  String _selectedFilter = 'All';
  PropertyData? _selectedProperty;
  bool _isMapLoaded = false;
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

  // Map legend items
  final List<Map<String, dynamic>> _legendItems = [
    {'label': 'Apartment', 'color': Color(0xFF1565C0)},
    {'label': 'Villa', 'color': Color(0xFF388E3C)},
    {'label': 'Land', 'color': Color(0xFFF57C00)},
    {'label': 'Commercial', 'color': Color(0xFF7B1FA2)},
    {'label': 'For Rent', 'color': Color(0xFF00BCD4)},
    {'label': 'Mortgage', 'color': Color(0xFFE91E63)},
  ];

  List<Map<String, dynamic>> _savedSearches = [];
  final List<Map<String, dynamic>> _filterHistory = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _loadSavedSearches();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isMapLoaded = true);
    });
  }

  @override
  void dispose() {
    _draggableController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getProperties(limit: 50);
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
        isRTL: loc.isRTL,
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
          content: Text(
            loc.isRTL
                ? 'أدخل بحثاً أو فلتراً لحفظه'
                : 'Enter a search or filter to save',
          ),
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
          content: Text(loc.isRTL ? 'تم حفظ البحث ✓' : 'Search saved ✓'),
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
    final mockMaps = [
      {
        'id': 'prop_001',
        'title': 'Modern Apartment — Karrada',
        'address': '14 Al-Nidhal St, Karrada, Baghdad',
        'price': 185000,
        'currency': 'USD',
        'area': 180,
        'bedrooms': 3,
        'bathrooms': 2,
        'type': 'apartment',
        'listingType': 'sale',
        'lat': 33.3152,
        'lng': 44.3932,
        'imageUrl':
            'https://images.unsplash.com/photo-1723709125265-889b7d62dcba',
        'semanticLabel':
            'Modern apartment building exterior with balconies in Baghdad',
        'isVerified': true,
        'isFeatured': true,
        'tags': ['Furnished', 'Central AC', 'Parking'],
      },
      {
        'id': 'prop_002',
        'title': 'Villa — Mansour District',
        'address': '7 Prince Rd, Mansour, Baghdad',
        'price': 420000,
        'currency': 'USD',
        'area': 350,
        'bedrooms': 5,
        'bathrooms': 4,
        'type': 'villa',
        'listingType': 'sale',
        'lat': 33.3351,
        'lng': 44.3601,
        'imageUrl':
            'https://img.rocket.new/generatedImages/rocket_gen_img_15d2727d0-1784505971937.png',
        'semanticLabel':
            'Large two-storey villa with garden and white exterior walls',
        'isVerified': true,
        'isFeatured': false,
        'tags': ['Garden', 'Pool', 'Generator'],
      },
      {
        'id': 'prop_003',
        'title': 'Office Space — Zayouna',
        'address': '22 Commerce Ave, Zayouna, Baghdad',
        'price': 2800,
        'currency': 'USD',
        'area': 120,
        'bedrooms': 0,
        'bathrooms': 2,
        'type': 'commercial',
        'listingType': 'rent',
        'lat': 33.3289,
        'lng': 44.4521,
        'imageUrl':
            'https://img.rocket.new/generatedImages/rocket_gen_img_181ce75b0-1780309836489.png',
        'semanticLabel':
            'Modern open-plan office space with large windows and city view',
        'isVerified': true,
        'isFeatured': true,
        'tags': ['Elevator', 'Backup Power', 'Reception'],
      },
      {
        'id': 'prop_004',
        'title': 'Residential Land — Adhamiya',
        'address': 'Block 14, Adhamiya District, Baghdad',
        'price': 95000,
        'currency': 'USD',
        'area': 500,
        'bedrooms': 0,
        'bathrooms': 0,
        'type': 'land',
        'listingType': 'sale',
        'lat': 33.3712,
        'lng': 44.4089,
        'imageUrl':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1b3327534-1772466446472.png',
        'semanticLabel':
            'Empty residential land plot with surrounding neighborhood visible',
        'isVerified': false,
        'isFeatured': false,
        'tags': ['Corner Plot', 'Main Road Access'],
      },
      {
        'id': 'prop_005',
        'title': 'Townhouse — Jadriya',
        'address': '9 River View St, Jadriya, Baghdad',
        'price': 260000,
        'currency': 'USD',
        'area': 240,
        'bedrooms': 4,
        'bathrooms': 3,
        'type': 'villa',
        'listingType': 'mortgage',
        'lat': 33.2981,
        'lng': 44.3821,
        'imageUrl':
            'https://img.rocket.new/generatedImages/rocket_gen_img_151ea03e2-1786738383786.png',
        'semanticLabel':
            'Townhouse with modern architecture near the Tigris River',
        'isVerified': true,
        'isFeatured': true,
        'tags': ['River View', 'Smart Home', 'Garage'],
      },
      {
        'id': 'prop_006',
        'title': 'Apartment — Kadhimiya',
        'address': '33 Al-Kadhim St, Kadhimiya, Baghdad',
        'price': 75000,
        'currency': 'USD',
        'area': 110,
        'bedrooms': 2,
        'bathrooms': 1,
        'type': 'apartment',
        'listingType': 'sale',
        'lat': 33.3822,
        'lng': 44.3411,
        'imageUrl':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1cbf890d9-1781368726031.png',
        'semanticLabel':
            'Clean bright apartment interior with modern furnishings',
        'isVerified': false,
        'isFeatured': false,
        'tags': ['Near Metro', 'Quiet Area'],
      },
    ];
    final props = mockMaps.map(PropertyData.fromMap).toList();
    setState(() {
      _allProperties = props;
      _filteredProperties = List.from(props);
    });
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
          if (!p.title.toLowerCase().contains(q) &&
              !p.address.toLowerCase().contains(q) &&
              !p.type.toLowerCase().contains(q) &&
              !p.tags.any((t) => t.toLowerCase().contains(q))) {
            return false;
          }
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
          for (final t in p.tags) {
            if (t.toLowerCase().contains(q)) suggestions.add(t);
          }
        }
        _searchSuggestions = suggestions.take(6).toList();
      } else {
        _searchSuggestions = [];
      }
    });
    _applyFilters();
    if (query.isNotEmpty) _addToFilterHistory();
  }

  void _onPropertySelected(PropertyData property) {
    setState(() => _selectedProperty = property);
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

  /// Opens the bottom sheet panel programmatically
  void _openPanel() {
    try {
      final currentSize = _draggableController.isAttached
          ? _draggableController.size
          : 0.12;
      final isCurrentlyExpanded = currentSize > 0.3;
      final targetSize = isCurrentlyExpanded ? 0.12 : 0.55;
      _draggableController.animateTo(
        targetSize,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      setState(() => _isSheetExpanded = !isCurrentlyExpanded);
    } catch (_) {
      // Controller not attached yet, just update state
      setState(() => _isSheetExpanded = !_isSheetExpanded);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isRTL = loc.isRTL;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    const bottomNavHeight = 0.0;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Full-screen map
            PropertyMapWidget(
              properties: _filteredProperties,
              onPropertyTap: _onPropertySelected,
              mapType: _mapType,
              isDrawingMode: _isDrawingMode,
              onPolygonDrawn: _onPolygonDrawn,
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                          const SizedBox(width: 8),
                          // Country context chip
                          CountryContextChip(),
                          const SizedBox(width: 8),
                          // Notification bell
                          _TopIconButton(
                            icon: Icons.notifications_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationCenterScreen(),
                              ),
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
                          '${isRTL ? 'منطقة:' : 'Area:'} $_activeAreaLabel — ${_filteredProperties.length} ${isRTL ? 'عقار' : 'properties'}',
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

            // Map legend
            Positioned(
              left: isRTL ? null : 16,
              right: isRTL ? 16 : null,
              bottom: bottomNavHeight + 200,
              child: _buildMapLegend(theme),
            ),

            // Map type + My Location + Draw controls
            Positioned(
              right: isRTL ? null : 16,
              left: isRTL ? 16 : null,
              bottom: bottomNavHeight + 180,
              child: Column(
                children: [
                  _MapControlButton(
                    iconName: 'my_location',
                    onTap: () {},
                    tooltip: isRTL ? 'موقعي' : 'My Location',
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    iconName: 'layers',
                    onTap: () => _showMapTypeSheet(context),
                    tooltip: isRTL ? 'نوع الخريطة' : 'Map Type',
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
                    tooltip: _isDrawingMode
                        ? (isRTL ? 'إلغاء' : 'Cancel Draw')
                        : (isRTL ? 'رسم منطقة' : 'Draw Area'),
                    isActive: _isDrawingMode,
                  ),
                  const SizedBox(height: 8),
                  // AI Recommendations button
                  _MapControlButton(
                    iconName: 'auto_awesome',
                    onTap: _showAiRecommendations,
                    tooltip: isRTL ? 'توصيات الذكاء الاصطناعي' : 'AI Picks',
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
                          isRTL
                              ? 'اضغط على الخريطة لرسم منطقة التحديد'
                              : 'Tap on map to draw selection area',
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
                            isRTL ? 'تم' : 'Done',
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
                          isRTL ? 'جاري التحميل...' : 'Loading properties...',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ─── BOTTOM PANEL: Floating open button + DraggableScrollableSheet ───
            // Floating "open panel" button — always visible above the panel
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _isSheetExpanded ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _isSheetExpanded,
                    child: GestureDetector(
                      onTap: _openPanel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(100),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isRTL
                                  ? '${_filteredProperties.length} عقار'
                                  : '${_filteredProperties.length} Properties',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // DraggableScrollableSheet — uses AbsorbPointer on map area to prevent conflict
            DraggableScrollableSheet(
              controller: _draggableController,
              initialChildSize: 0.12,
              minChildSize: 0.12,
              maxChildSize: isTablet ? 0.5 : 0.65,
              snap: true,
              snapSizes: const [0.12, 0.22, 0.65],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(31),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle area — intercepts vertical drags ONLY
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openPanel,
                        onVerticalDragUpdate: (details) {
                          final screenHeight = MediaQuery.of(
                            context,
                          ).size.height;
                          final delta = -details.primaryDelta! / screenHeight;
                          final current = _draggableController.size;
                          final newSize = (current + delta).clamp(
                            0.12,
                            isTablet ? 0.5 : 0.65,
                          );
                          _draggableController.jumpTo(newSize);
                        },
                        onVerticalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          final current = _draggableController.size;
                          double targetSize;
                          if (velocity < -300) {
                            targetSize = isTablet ? 0.5 : 0.65;
                          } else if (velocity > 300) {
                            targetSize = 0.12;
                          } else {
                            const snapPoints = [0.12, 0.22, 0.65];
                            targetSize = snapPoints.reduce(
                              (a, b) =>
                                  (a - current).abs() < (b - current).abs()
                                  ? a
                                  : b,
                            );
                          }
                          _draggableController.animateTo(
                            targetSize,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                          setState(() => _isSheetExpanded = targetSize > 0.3);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.outline,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Header row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              '${_filteredProperties.length} ${loc.propertiesFound}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            // Save Search button
                            GestureDetector(
                              onTap: _saveCurrentSearch,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primary.withAlpha(40),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bookmark_add_outlined,
                                      color: AppTheme.primary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isRTL ? 'حفظ' : 'Save',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_savedSearches.isNotEmpty)
                              GestureDetector(
                                onTap: _showSavedSearches,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight.withAlpha(20),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryLight.withAlpha(
                                        60,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bookmarks_outlined,
                                        color: AppTheme.primaryLight,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_savedSearches.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PropertyCardSliderWidget(
                          properties: _filteredProperties,
                          scrollController: scrollController,
                          onPropertyTap: _onPropertySelected,
                          onSeeAll: () =>
                              setState(() => _isFullScreenList = true),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Full-screen property list overlay
            if (_isFullScreenList)
              Positioned.fill(
                child: PropertyListScreen(
                  properties: _filteredProperties,
                  activeFilter: _selectedFilter,
                  onClose: () => setState(() => _isFullScreenList = false),
                  onPropertyTap: (p) {
                    setState(() => _isFullScreenList = false);
                    _onPropertySelected(p);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLegend(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    final isRTL = loc.isRTL;
    final labels = isRTL
        ? ['شقة', 'فيلا', 'أرض', 'تجاري', 'إيجار', 'رهن']
        : ['Apartment', 'Villa', 'Land', 'Commercial', 'For Rent', 'Mortgage'];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _legendItems
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: entry.value['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labels[entry.key],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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
        isRTL: loc.isRTL,
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
    final isRTL = loc.isRTL;
    final types = [
      {'id': 'normal', 'label': isRTL ? 'عادي' : 'Standard', 'icon': 'map'},
      {
        'id': 'satellite',
        'label': isRTL ? 'قمر صناعي' : 'Satellite',
        'icon': 'satellite_alt',
      },
      {
        'id': 'terrain',
        'label': isRTL ? 'تضاريس' : 'Terrain',
        'icon': 'terrain',
      },
      {'id': 'hybrid', 'label': isRTL ? 'هجين' : 'Hybrid', 'icon': 'layers'},
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
            isRTL ? 'نوع الخريطة' : 'Map Type',
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
  final bool isRTL;
  final Function(String, RangeValues, RangeValues, int, String) onApply;
  final VoidCallback onReset;

  const _FullFilterSheet({
    required this.selectedFilter,
    required this.priceRange,
    required this.areaRange,
    required this.minBedrooms,
    required this.selectedCity,
    required this.cities,
    required this.isRTL,
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
    final isRTL = widget.isRTL;
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
                  isRTL ? 'التصفية' : 'Filters',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onReset,
                  child: Text(
                    isRTL ? 'إعادة تعيين' : 'Reset All',
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
                    isRTL ? 'نوع الإعلان' : 'Listing Type',
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
                          final label = isRTL ? _localizeFilter(f) : f;
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
                    isRTL ? 'المدينة' : 'City',
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
                        isRTL ? 'نطاق السعر' : 'Price Range',
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
                        isRTL ? 'المساحة (م²)' : 'Area (m²)',
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
                    isRTL ? 'الحد الأدنى للغرف' : 'Min Bedrooms',
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
                                n == 0 ? (isRTL ? 'أي' : 'Any') : '$n+',
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
                  isRTL ? 'تطبيق التصفية' : 'Apply Filters',
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

  String _localizeFilter(String f) {
    switch (f) {
      case 'All':
        return 'الكل';
      case 'Sale':
        return 'للبيع';
      case 'Rent':
        return 'للإيجار';
      case 'Mortgage':
        return 'رهن';
      case 'Land':
        return 'أرض';
      case 'Commercial':
        return 'تجاري';
      case 'Investment':
        return 'استثمار';
      default:
        return f;
    }
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
    final isRTL = loc.isRTL;
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
                  isRTL ? 'البحوث المحفوظة' : 'Saved Searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${savedSearches.length} ${isRTL ? 'محفوظ' : 'saved'}',
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
  final bool isRTL;
  final Function(Map<String, dynamic>) onHistorySelected;
  final Function(Map<String, dynamic>) onSavedSearchSelected;
  final Function(String) onDeleteSaved;
  final VoidCallback onClearHistory;

  const _FilterHistorySheet({
    required this.filterHistory,
    required this.savedSearches,
    required this.isRTL,
    required this.onHistorySelected,
    required this.onSavedSearchSelected,
    required this.onDeleteSaved,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  isRTL ? 'سجل البحث والتصفية' : 'Search & Filter History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (filterHistory.isNotEmpty)
                  TextButton(
                    onPressed: onClearHistory,
                    child: Text(
                      isRTL ? 'مسح الكل' : 'Clear All',
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
                      Tab(text: isRTL ? 'السجل الأخير' : 'Recent'),
                      Tab(text: isRTL ? 'المحفوظة' : 'Saved'),
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
                                      isRTL
                                          ? 'لا يوجد سجل بحث بعد'
                                          : 'No search history yet',
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
                                      timeLabel =
                                          '${diff.inMinutes}${isRTL ? ' دقيقة' : 'm ago'}';
                                    } else if (diff.inHours < 24) {
                                      timeLabel =
                                          '${diff.inHours}${isRTL ? ' ساعة' : 'h ago'}';
                                    } else {
                                      timeLabel =
                                          '${diff.inDays}${isRTL ? ' يوم' : 'd ago'}';
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
                                          '$count ${isRTL ? 'نتيجة' : 'results'}',
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
                                      isRTL
                                          ? 'لا توجد بحوث محفوظة'
                                          : 'No saved searches',
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

// ─── Unified Property Data Model ──────────────────────────────────────────────
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

    final lat = (d['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (d['longitude'] as num?)?.toDouble() ?? 0.0;

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

    return PropertyData(
      id: d['id'] as String? ?? '',
      title:
          d['title'] as String? ??
          '${d['property_type'] ?? 'Property'} — $district',
      address: address,
      price: (d['asking_price'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] as String? ?? 'USD',
      area: (d['total_area_sqm'] as num?)?.toDouble() ?? 0,
      bedrooms: (d['bedrooms_count'] as num?)?.toInt() ?? 0,
      bathrooms: (d['bathrooms_count'] as num?)?.toInt() ?? 0,
      type: d['property_type'] as String? ?? 'apartment',
      listingType: d['listing_type'] as String? ?? 'sale',
      lat: lat,
      lng: lng,
      imageUrl: imageUrl,
      semanticLabel: 'Property in $address',
      isVerified: d['is_verified'] as bool? ?? false,
      isFeatured: d['is_featured'] as bool? ?? false,
      tags: tags,
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
      rawData: map,
    );
  }

  String get formattedPrice {
    if (listingType == 'rent') {
      return '\$${price.toStringAsFixed(0)}/mo';
    }
    if (price >= 1000000) {
      return '\$${(price / 1000000).toStringAsFixed(1)}M';
    }
    return '\$${(price / 1000).toStringAsFixed(0)}K';
  }

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

  String get listingTypeLabel {
    switch (listingType) {
      case 'sale':
        return 'For Sale';
      case 'rent':
        return 'For Rent';
      case 'mortgage':
        return 'Mortgage';
      case 'investment':
        return 'Investment';
      default:
        return listingType;
    }
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
      'is_verified': isVerified,
      'isVerified': isVerified,
      'is_featured': isFeatured,
      'isFeatured': isFeatured,
      ...rawData,
    };
  }
}
