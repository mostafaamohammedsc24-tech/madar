import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../search_map_screen.dart';

/// Sheet to manage saved area searches (polygon-based or city-based)
class SavedAreaSearchSheet extends StatefulWidget {
  final List<PropertyData> allProperties;
  final Function(List<PropertyData>, String) onAreaSelected;

  const SavedAreaSearchSheet({
    required this.allProperties,
    required this.onAreaSelected,
    super.key,
  });

  @override
  State<SavedAreaSearchSheet> createState() => _SavedAreaSearchSheetState();
}

class _SavedAreaSearchSheetState extends State<SavedAreaSearchSheet> {
  List<Map<String, dynamic>> _savedAreas = [];
  bool _isLoading = true;

  // Predefined area zones for quick selection
  final List<_AreaZone> _popularAreas = [
    _AreaZone(
      name: 'Karrada',
      nameAr: 'الكرادة',
      icon: Icons.location_city_rounded,
      color: const Color(0xFF1565C0),
      keywords: ['karrada', 'كرادة'],
    ),
    _AreaZone(
      name: 'Mansour',
      nameAr: 'المنصور',
      icon: Icons.villa_rounded,
      color: const Color(0xFF388E3C),
      keywords: ['mansour', 'منصور'],
    ),
    _AreaZone(
      name: 'Adhamiya',
      nameAr: 'الأعظمية',
      icon: Icons.home_work_rounded,
      color: const Color(0xFFF57C00),
      keywords: ['adhamiya', 'أعظمية'],
    ),
    _AreaZone(
      name: 'Jadriya',
      nameAr: 'الجادرية',
      icon: Icons.water_rounded,
      color: const Color(0xFF00838F),
      keywords: ['jadriya', 'جادرية'],
    ),
    _AreaZone(
      name: 'Kadhimiya',
      nameAr: 'الكاظمية',
      icon: Icons.mosque_rounded,
      color: const Color(0xFF7B1FA2),
      keywords: ['kadhimiya', 'كاظمية'],
    ),
    _AreaZone(
      name: 'Zayouna',
      nameAr: 'الزيونة',
      icon: Icons.business_rounded,
      color: const Color(0xFFE53935),
      keywords: ['zayouna', 'زيونة'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedAreas();
  }

  Future<void> _loadSavedAreas() async {
    try {
      final searches = await SupabaseService.instance.getSavedSearches();
      // Filter only area-based searches
      final areas = searches
          .where(
            (s) =>
                (s['filters'] as Map<String, dynamic>?)?['type'] == 'area' ||
                (s['filters'] as Map<String, dynamic>?)?['city'] != null,
          )
          .toList();
      if (mounted) setState(() => _savedAreas = areas);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveArea(String areaName) async {
    await SupabaseService.instance.saveSearch(
      query: areaName,
      filters: {'type': 'area', 'areaName': areaName},
    );
    await _loadSavedAreas();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Area "$areaName" saved'),
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

  Future<void> _deleteArea(String id) async {
    await SupabaseService.instance.deleteSavedSearch(id);
    await _loadSavedAreas();
  }

  List<PropertyData> _filterByArea(_AreaZone zone) {
    return widget.allProperties.where((p) {
      final addr = p.address.toLowerCase();
      return zone.keywords.any((k) => addr.contains(k.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isRTL = loc.isRTL;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRTL ? 'البحث بالمنطقة' : 'Area Search',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        isRTL
                            ? 'اختر منطقة لعرض العقارات'
                            : 'Select an area to browse properties',
                        style: TextStyle(
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
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Popular areas grid
                  Text(
                    isRTL ? 'المناطق الشائعة' : 'Popular Areas',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: _popularAreas.length,
                    itemBuilder: (_, i) {
                      final zone = _popularAreas[i];
                      final count = _filterByArea(zone).length;
                      return _AreaZoneCard(
                        zone: zone,
                        propertyCount: count,
                        isRTL: isRTL,
                        onTap: () {
                          final filtered = _filterByArea(zone);
                          Navigator.pop(context);
                          widget.onAreaSelected(
                            filtered,
                            isRTL ? zone.nameAr : zone.name,
                          );
                        },
                        onSave: () => _saveArea(zone.name),
                      );
                    },
                  ),

                  // Saved areas
                  if (_savedAreas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          isRTL ? 'المناطق المحفوظة' : 'Saved Areas',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_savedAreas.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._savedAreas.map(
                      (area) => _SavedAreaTile(
                        area: area,
                        isRTL: isRTL,
                        onTap: () {
                          final query = area['query'] as String? ?? '';
                          final filtered = widget.allProperties
                              .where(
                                (p) => p.address.toLowerCase().contains(
                                  query.toLowerCase(),
                                ),
                              )
                              .toList();
                          Navigator.pop(context);
                          widget.onAreaSelected(filtered, query);
                        },
                        onDelete: () =>
                            _deleteArea(area['id'] as String? ?? ''),
                      ),
                    ),
                  ],

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Area Zone Card ───────────────────────────────────────────────────────────
class _AreaZoneCard extends StatelessWidget {
  final _AreaZone zone;
  final int propertyCount;
  final bool isRTL;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _AreaZoneCard({
    required this.zone,
    required this.propertyCount,
    required this.isRTL,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onSave,
      child: Container(
        decoration: BoxDecoration(
          color: zone.color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: zone.color.withAlpha(50)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(zone.icon, color: zone.color, size: 26),
            const SizedBox(height: 6),
            Text(
              isRTL ? zone.nameAr : zone.name,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '$propertyCount ${isRTL ? 'عقار' : 'props'}',
              style: TextStyle(
                fontSize: 10,
                color: zone.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Saved Area Tile ──────────────────────────────────────────────────────────
class _SavedAreaTile extends StatelessWidget {
  final Map<String, dynamic> area;
  final bool isRTL;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedAreaTile({
    required this.area,
    required this.isRTL,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = area['query'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.bookmark_rounded,
            color: AppTheme.primary,
            size: 18,
          ),
        ),
        title: Text(
          query,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          isRTL ? 'اضغط للبحث في هذه المنطقة' : 'Tap to search this area',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: AppTheme.error.withAlpha(180),
            size: 18,
          ),
          onPressed: onDelete,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────
class _AreaZone {
  final String name;
  final String nameAr;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  const _AreaZone({
    required this.name,
    required this.nameAr,
    required this.icon,
    required this.color,
    required this.keywords,
  });
}
