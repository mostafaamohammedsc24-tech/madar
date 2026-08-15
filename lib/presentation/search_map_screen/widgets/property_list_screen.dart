import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../search_map_screen.dart';

/// Full-screen property list that slides up from the map bottom sheet.
/// Shows sections: Suggested, Featured, Most Popular, Recently Added.
class PropertyListScreen extends StatefulWidget {
  final List<PropertyData> properties;
  final String activeFilter;
  final VoidCallback onClose;
  final Function(PropertyData) onPropertyTap;

  const PropertyListScreen({
    required this.properties,
    required this.activeFilter,
    required this.onClose,
    required this.onPropertyTap,
    super.key,
  });

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'suggested';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animController.reverse();
    widget.onClose();
  }

  List<PropertyData> get _filtered {
    var list = widget.properties;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }
    switch (_sortBy) {
      case 'price_asc':
        list = List.from(list)..sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list = List.from(list)..sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'area':
        list = List.from(list)..sort((a, b) => b.area.compareTo(a.area));
        break;
      case 'newest':
        list = list.reversed.toList();
        break;
    }
    return list;
  }

  List<PropertyData> get _suggested =>
      _filtered.where((p) => p.isVerified).take(6).toList();
  List<PropertyData> get _featured =>
      _filtered.where((p) => p.isFeatured).take(6).toList();
  List<PropertyData> get _popular => _filtered.take(6).toList();
  List<PropertyData> get _recent => _filtered.reversed.take(6).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isRTL = loc.isRTL;

    return SlideTransition(
      position: _slideAnim,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // ─── Header ────────────────────────────────────────────────────
            Container(
              color: theme.colorScheme.surface,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Drag handle + close
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _close,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: 'keyboard_arrow_down',
                                  color: theme.colorScheme.onSurface,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_filtered.length} ${loc.propertiesFound}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textDirection: isRTL
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                            ),
                          ),
                          // Sort button
                          GestureDetector(
                            onTap: () => _showSortSheet(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'tune',
                                    color: AppTheme.primary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    loc.sort,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _searchCtrl,
                        textDirection: isRTL
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: loc.searchHint,
                          hintTextDirection: isRTL
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: CustomIconWidget(
                              iconName: 'search',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: CustomIconWidget(
                                      iconName: 'close',
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 18,
                                    ),
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // ─── Sections ──────────────────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? _EmptyState(message: loc.searchHint)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        if (_suggested.isNotEmpty)
                          _PropertySection(
                            title: loc.suggested,
                            icon: 'auto_awesome',
                            properties: _suggested,
                            onTap: widget.onPropertyTap,
                          ),
                        if (_featured.isNotEmpty)
                          _PropertySection(
                            title: loc.featured,
                            icon: 'star',
                            properties: _featured,
                            onTap: widget.onPropertyTap,
                          ),
                        if (_popular.isNotEmpty)
                          _PropertySection(
                            title: loc.mostPopular,
                            icon: 'trending_up',
                            properties: _popular,
                            onTap: widget.onPropertyTap,
                          ),
                        if (_recent.isNotEmpty)
                          _PropertySection(
                            title: loc.recentlyAdded,
                            icon: 'schedule',
                            properties: _recent,
                            onTap: widget.onPropertyTap,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('suggested', 'auto_awesome', 'Suggested'),
              ('price_asc', 'arrow_upward', 'Price: Low to High'),
              ('price_desc', 'arrow_downward', 'Price: High to Low'),
              ('area', 'square_foot', 'Largest Area'),
              ('newest', 'schedule', 'Newest First'),
            ].map((item) {
              final isSelected = _sortBy == item.$1;
              return ListTile(
                leading: CustomIconWidget(
                  iconName: item.$2,
                  color: isSelected
                      ? AppTheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                title: Text(
                  item.$3,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? AppTheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  setState(() => _sortBy = item.$1);
                  Navigator.pop(context);
                },
              );
            }),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// ─── Section Widget ───────────────────────────────────────────────────────────
class _PropertySection extends StatelessWidget {
  final String title;
  final String icon;
  final List<PropertyData> properties;
  final Function(PropertyData) onTap;

  const _PropertySection({
    required this.title,
    required this.icon,
    required this.properties,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: icon,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                loc.viewAll,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: properties.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _LargePropertyCard(
                property: properties[i],
                onTap: () => onTap(properties[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Large Property Card with Photo Carousel ──────────────────────────────────
class _LargePropertyCard extends StatefulWidget {
  final PropertyData property;
  final VoidCallback onTap;

  const _LargePropertyCard({required this.property, required this.onTap});

  @override
  State<_LargePropertyCard> createState() => _LargePropertyCardState();
}

class _LargePropertyCardState extends State<_LargePropertyCard> {
  int _currentPhoto = 0;
  bool _isFav = false;

  // Multiple photo URLs per card (carousel)
  late final List<String> _photos;

  @override
  void initState() {
    super.initState();
    // Generate multiple photos for carousel from different sources
    _photos = _buildPhotoList(widget.property);
  }

  static List<String> _buildPhotoList(PropertyData p) {
    // Provide 3-4 images per card for carousel effect
    final base = p.imageUrl;
    final extras = [
      'https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/2724749/pexels-photo-2724749.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pixabay.com/photo/2016/11/18/17/20/living-room-1835923_640.jpg',
    ];
    return [base, extras[0], extras[1], extras[2]];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.property;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo Carousel ──────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 155,
                    child: PageView.builder(
                      itemCount: _photos.length,
                      onPageChanged: (i) => setState(() => _currentPhoto = i),
                      itemBuilder: (_, i) => CustomImageWidget(
                        imageUrl: _photos[i],
                        width: 220,
                        height: 155,
                        fit: BoxFit.cover,
                        semanticLabel: p.semanticLabel,
                      ),
                    ),
                  ),
                ),
                // Photo dots
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _photos.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: i == _currentPhoto ? 16 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: i == _currentPhoto
                              ? Colors.white
                              : Colors.white.withAlpha(128),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                // Listing type badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.listingTypeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.listingTypeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Favorite
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _isFav = !_isFav),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: _isFav ? 'favorite' : 'favorite_border',
                          color: _isFav
                              ? AppTheme.error
                              : const Color(0xFF757575),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ── Info ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'location_on',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            p.address,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (p.bedrooms > 0) ...[
                          _MiniChip(icon: 'bed', value: '${p.bedrooms}'),
                          const SizedBox(width: 4),
                        ],
                        _MiniChip(
                          icon: 'square_foot',
                          value: '${p.area.toInt()}m²',
                        ),
                      ],
                    ),
                    Text(
                      p.formattedPrice,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String icon;
  final String value;
  const _MiniChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: icon, color: AppTheme.primary, size: 10),
          const SizedBox(width: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color: AppTheme.primary.withAlpha(80),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primary.withAlpha(120),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
