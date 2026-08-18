import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/property_data.dart';
import 'property_card_copy.dart';

/// Full-width listing card used in the expanded map sheet.
class PropertyListingCard extends StatelessWidget {
  const PropertyListingCard({
    super.key,
    required this.property,
    required this.onTap,
  });

  final PropertyData property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final p = property;
    final publisher = p.rawData['publisher'];
    final photo = publisher is Map ? publisher['photo_url']?.toString() : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 188,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.home_work_outlined, size: 40),
                    ),
                  ),
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.isFeatured
                                ? loc.showcaseBadge
                                : PropertyCardCopy.listing(context, p),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withValues(alpha: 0.92),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PropertyCardCopy.price(context, p),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (p.bedrooms > 0) '${p.bedrooms} ${loc.bedsShort}',
                      if (p.bathrooms > 0) '${p.bathrooms} ${loc.bathsShort}',
                      if (p.area > 0)
                        '${p.area.toStringAsFixed(0)} ${loc.areaUnitM2}',
                      PropertyCardCopy.listing(context, p),
                    ].join('  |  '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    PropertyCardCopy.address(context, p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (photo != null && photo.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(photo),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            publisher is Map
                                ? (publisher['name']?.toString() ?? '')
                                : '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
