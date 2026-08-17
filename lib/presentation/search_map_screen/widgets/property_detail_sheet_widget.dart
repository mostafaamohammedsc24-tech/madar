import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../search_map_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorited
                ? 'تمت الإضافة إلى المفضلة ❤️'
                : 'تمت الإزالة من المفضلة',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      Positioned(
                        top: 12,
                        right: 16,
                        child: GestureDetector(
                          onTap: _toggleFavorite,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isFavorited
                                  ? AppTheme.error.withAlpha(20)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(26),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isTogglingFavorite
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.error,
                                      ),
                                    )
                                  : CustomIconWidget(
                                      iconName: _isFavorited
                                          ? 'favorite'
                                          : 'favorite_border',
                                      color: _isFavorited
                                          ? AppTheme.error
                                          : const Color(0xFF757575),
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 16,
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
                            p.listingTypeLabel,
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
                                    p.title,
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
                                          p.address,
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
                                  p.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
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
                                      const Text(
                                        'Verified',
                                        style: TextStyle(
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
                                  tag,
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
                                label: 'Area',
                                value: '${p.area.toInt()} m²',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: 'bed',
                                label: 'Bedrooms',
                                value: p.bedrooms > 0 ? '${p.bedrooms}' : 'N/A',
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
                                label: 'Bathrooms',
                                value: p.bathrooms > 0
                                    ? '${p.bathrooms}'
                                    : 'N/A',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: 'category',
                                label: 'Type',
                                value: p.type.toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(
                                    color: AppTheme.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: CustomIconWidget(
                                  iconName: 'phone',
                                  color: AppTheme.primary,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Contact',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push(
                                    '/property-detail',
                                    extra: widget.property.toDetailMap(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: CustomIconWidget(
                                  iconName: 'open_in_full',
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: const Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
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
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
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
