import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/property/presentation/navigation/open_property_report.dart';
import '../../../services/supabase_service.dart';
import '../search_map_screen.dart';
import 'property_card_copy.dart';

class PropertyDetailSheetWidget extends StatefulWidget {
  final PropertyData property;

  const PropertyDetailSheetWidget({required this.property, super.key});

  @override
  State<PropertyDetailSheetWidget> createState() =>
      _PropertyDetailSheetWidgetState();
}

class _PropertyDetailSheetWidgetState extends State<PropertyDetailSheetWidget> {
  bool _isFavorited = false;
  bool _isTogglingFavorite = false;
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final ids = await SupabaseService.instance.getFavoritePropertyIds();
      if (mounted) {
        setState(() => _isFavorited = ids.contains(widget.property.id));
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    setState(() {
      _isTogglingFavorite = true;
      _isFavorited = !_isFavorited;
    });
    try {
      await SupabaseService.instance.toggleFavorite(widget.property.id);
    } catch (_) {
      if (mounted) setState(() => _isFavorited = !_isFavorited);
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
    if (mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorited ? loc.favoriteAdded : loc.favoriteRemoved,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _shareProperty() {
    sharePropertyLink(
      context,
      propertyId: widget.property.id,
      title: PropertyCardCopy.title(context, widget.property),
      priceLine: PropertyCardCopy.price(context, widget.property),
    );
  }

  void _openFullReport() {
    openPropertyReport(
      context,
      propertyMap: widget.property.toDetailMap(),
      popSheetFirst: true,
    );
  }

  void _contactSales() {
    Navigator.pop(context);
    context.push('/messages');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final p = widget.property;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: PageView.builder(
                          itemCount: p.gallery.length,
                          onPageChanged: (i) =>
                              setState(() => _galleryIndex = i),
                          itemBuilder: (_, i) => CustomImageWidget(
                            imageUrl: p.gallery[i],
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            semanticLabel: p.semanticLabel,
                          ),
                        ),
                      ),
                      if (p.gallery.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(p.gallery.length, (i) {
                              final active = i == _galleryIndex;
                              return Container(
                                width: active ? 8 : 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: active ? 1 : 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                      PositionedDirectional(
                        top: 12,
                        end: 16,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ImageActionButton(
                              icon: Icons.share_outlined,
                              tooltip: loc.shareProperty,
                              onTap: _shareProperty,
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _ImageActionButton(
                              icon: _isFavorited
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              tooltip: _isFavorited
                                  ? loc.savedProperty
                                  : loc.unsavedProperty,
                              onTap: _isTogglingFavorite ? null : _toggleFavorite,
                              theme: theme,
                              iconColor: _isFavorited
                                  ? AppTheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                              loading: _isTogglingFavorite,
                            ),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        top: 12,
                        start: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: p.listingTypeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            PropertyCardCopy.listing(context, p),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    PropertyCardCopy.title(context, p),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      CustomIconWidget(
                                        iconName: 'location_on',
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          p.localizedAddress(loc.language),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  PropertyCardCopy.price(context, p),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                if (p.area > 0)
                                  Text(
                                    '${loc.sqmPrice}: ${(p.price / p.area).toStringAsFixed(0)} ${p.currency}/m²',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                if (p.isVerified)
                                  Row(
                                    children: [
                                      CustomIconWidget(
                                        iconName: 'verified',
                                        color: AppTheme.primary,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        loc.verified,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (p.tags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: p.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  PropertyCardCopy.tag(context, p, tag),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: 'square_foot',
                                label: loc.propertyAreaShort,
                                value: '${p.area.toInt()} m²',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: 'bed',
                                label: loc.bedrooms,
                                value: p.bedrooms > 0
                                    ? '${p.bedrooms}'
                                    : loc.informationUnavailable,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: 'bathtub',
                                label: loc.bathrooms,
                                value: p.bathrooms > 0
                                    ? '${p.bathrooms}'
                                    : loc.informationUnavailable,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: 'category',
                                label: loc.propertyTypeLabel,
                                value: PropertyCardCopy.type(context, p),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton.icon(
                                onPressed: _openFullReport,
                                icon: const Icon(Icons.open_in_full, size: 20),
                                label: Text(loc.moreDetails),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _contactSales,
                                icon: const Icon(Icons.phone_outlined, size: 20),
                                label: Text(loc.contactSalesShort),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  minimumSize: const Size.fromHeight(48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  const _ImageActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.theme,
    this.iconColor,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final ThemeData theme;
  final Color? iconColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor ?? theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: icon,
            color: AppTheme.primary.withAlpha(179),
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
