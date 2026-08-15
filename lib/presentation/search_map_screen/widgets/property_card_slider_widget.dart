import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../search_map_screen.dart';

// Mini carousel of compact property cards — swipeable horizontally
class PropertyCardSliderWidget extends StatefulWidget {
  final List<PropertyData> properties;
  final ScrollController scrollController;
  final Function(PropertyData) onPropertyTap;
  final VoidCallback? onSeeAll;

  const PropertyCardSliderWidget({
    required this.properties,
    required this.scrollController,
    required this.onPropertyTap,
    this.onSeeAll,
    super.key,
  });

  @override
  State<PropertyCardSliderWidget> createState() =>
      _PropertyCardSliderWidgetState();
}

class _PropertyCardSliderWidgetState extends State<PropertyCardSliderWidget> {
  final PageController _pageController = PageController(
    viewportFraction: 0.78,
    initialPage: 0,
  );
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (widget.properties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'search_off',
                color: AppTheme.primary.withAlpha(102),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'No properties match this filter',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mini card carousel
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.properties.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final property = widget.properties[i];
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.only(
                  right: 10,
                  top: isActive ? 0 : 8,
                  bottom: isActive ? 0 : 8,
                ),
                child: _MiniPropertyCard(
                  property: property,
                  onTap: () => widget.onPropertyTap(property),
                ),
              );
            },
          ),
        ),
        // Dot indicators
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.properties.length.clamp(0, 8),
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: i == _currentPage ? 16 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? AppTheme.primary
                      : AppTheme.primary.withAlpha(64),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        // See All Properties button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onSeeAll,
              icon: CustomIconWidget(
                iconName: 'grid_view',
                color: AppTheme.primary,
                size: 16,
              ),
              label: Text(
                loc.seeAllProperties,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primary.withAlpha(80)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: AppTheme.primary.withAlpha(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Mini Property Card ───────────────────────────────────────────────────────
class _MiniPropertyCard extends StatefulWidget {
  final PropertyData property;
  final VoidCallback onTap;

  const _MiniPropertyCard({required this.property, required this.onTap});

  @override
  State<_MiniPropertyCard> createState() => _MiniPropertyCardState();
}

class _MiniPropertyCardState extends State<_MiniPropertyCard> {
  bool _isFav = false;
  bool _isTogglingFav = false;

  @override
  void initState() {
    super.initState();
    _checkFavStatus();
  }

  Future<void> _checkFavStatus() async {
    try {
      final ids = await SupabaseService.instance.getFavoritePropertyIds();
      if (mounted) setState(() => _isFav = ids.contains(widget.property.id));
    } catch (_) {}
  }

  Future<void> _toggleFav() async {
    if (_isTogglingFav) return;
    setState(() {
      _isTogglingFav = true;
      _isFav = !_isFav;
    });
    try {
      await SupabaseService.instance.toggleFavorite(widget.property.id);
    } catch (_) {
      if (mounted) setState(() => _isFav = !_isFav);
    } finally {
      if (mounted) setState(() => _isTogglingFav = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.property;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: CustomImageWidget(
                    imageUrl: p.imageUrl,
                    width: 100,
                    height: 130,
                    fit: BoxFit.cover,
                    semanticLabel: p.semanticLabel,
                  ),
                ),
                // Listing type badge
                Positioned(
                  top: 8,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: p.listingTypeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.listingTypeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title + fav
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            p.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleFav,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _isTogglingFav
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.error,
                                    ),
                                  )
                                : CustomIconWidget(
                                    iconName: _isFav
                                        ? 'favorite'
                                        : 'favorite_border',
                                    color: _isFav
                                        ? AppTheme.error
                                        : Colors.grey,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    // Address
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'location_on',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 10,
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
                    // Specs
                    Row(
                      children: [
                        if (p.bedrooms > 0) ...[
                          _MiniSpec(icon: 'bed', value: '${p.bedrooms}'),
                          const SizedBox(width: 4),
                        ],
                        _MiniSpec(
                          icon: 'square_foot',
                          value: '${p.area.toInt()}m²',
                        ),
                      ],
                    ),
                    // Price
                    Text(
                      p.formattedPrice,
                      style: const TextStyle(
                        fontSize: 14,
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

class _MiniSpec extends StatelessWidget {
  final String icon;
  final String value;

  const _MiniSpec({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomIconWidget(iconName: icon, color: AppTheme.primary, size: 10),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
      ],
    );
  }
}
