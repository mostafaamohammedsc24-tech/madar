import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/property_data.dart';
import 'property_card_copy.dart';

/// Full-width listing card used in the expanded map sheet.
class PropertyListingCard extends StatefulWidget {
  const PropertyListingCard({
    super.key,
    required this.property,
    required this.onTap,
  });

  final PropertyData property;
  final VoidCallback onTap;

  @override
  State<PropertyListingCard> createState() => _PropertyListingCardState();
}

class _PropertyListingCardState extends State<PropertyListingCard> {
  int _photoIndex = 0;

  List<String> get _photos {
    final urls = <String>[];
    final media = widget.property.rawData['property_media_v3'];
    if (media is List) {
      for (final item in media) {
        if (item is Map) {
          final url = item['media_url']?.toString() ??
              item['url']?.toString() ??
              '';
          if (url.isNotEmpty) urls.add(url);
        }
      }
    }
    if (urls.isEmpty && widget.property.imageUrl.isNotEmpty) {
      urls.add(widget.property.imageUrl);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final p = widget.property;
    final photos = _photos;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              height: 210,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photos.isEmpty)
                    ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.home_work_outlined, size: 40),
                    )
                  else
                    PageView.builder(
                      itemCount: photos.length,
                      onPageChanged: (i) => setState(() => _photoIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.home_work_outlined, size: 40),
                        ),
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
                        color: Colors.black.withValues(alpha: 0.78),
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
                  const PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: Icon(
                      Icons.favorite_border,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photos.length.clamp(0, 8), (i) {
                          final active = i == _photoIndex;
                          return Container(
                            width: active ? 7 : 6,
                            height: active ? 7 : 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.45),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          PropertyCardCopy.price(context, p),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: const Color(0xFF101828),
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onTap,
                        icon: const Icon(Icons.more_horiz, color: Color(0xFF667085)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF344054),
                        fontSize: 14,
                      ),
                      children: [
                        if (p.bedrooms > 0) ...[
                          TextSpan(
                            text: '${p.bedrooms}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' ${loc.bedsShort}'),
                        ],
                        if (p.bathrooms > 0) ...[
                          if (p.bedrooms > 0) const TextSpan(text: '  |  '),
                          TextSpan(
                            text: '${p.bathrooms}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' ${loc.bathsShort}'),
                        ],
                        if (p.area > 0) ...[
                          if (p.bedrooms > 0 || p.bathrooms > 0)
                            const TextSpan(text: '  |  '),
                          TextSpan(
                            text: p.area.toStringAsFixed(0),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' ${loc.areaUnitM2}'),
                        ],
                        const TextSpan(text: '  |  '),
                        TextSpan(text: PropertyCardCopy.listing(context, p)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    PropertyCardCopy.address(context, p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF344054),
                      fontSize: 14,
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
