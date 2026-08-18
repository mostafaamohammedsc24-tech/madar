import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/property_data.dart';
import 'property_card_copy.dart';

/// Zillow-style listing card: photo carousel with Showcase badge, heart and
/// Madar watermark overlays, then price / specs / address rows.
class PropertyCard extends StatefulWidget {
  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onMore,
  });

  final PropertyData property;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  int _photoIndex = 0;
  bool _liked = false;

  List<String> get _photos {
    final urls = <String>[];
    final media = widget.property.rawData['property_media_v3'];
    if (media is List) {
      for (final item in media) {
        if (item is Map) {
          final url =
              item['media_url']?.toString() ?? item['url']?.toString() ?? '';
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 215,
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
                          child:
                              const Icon(Icons.home_work_outlined, size: 40),
                        ),
                      ),
                    ),
                  // Showcase badge — top start
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            p.isFeatured
                                ? loc.showcaseBadge
                                : PropertyCardCopy.listing(context, p),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Heart — top end, white circle
                  PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: GestureDetector(
                      onTap: () => setState(() => _liked = !_liked),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.white,
                        child: Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: _liked
                              ? const Color(0xFFC8102E)
                              : const Color(0xFF212121),
                        ),
                      ),
                    ),
                  ),
                  // Madar watermark — bottom end
                  PositionedDirectional(
                    bottom: 10,
                    end: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'MADAR',
                        style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  // Carousel dots — bottom center
                  if (photos.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photos.length.clamp(0, 8), (i) {
                          final active = i == _photoIndex;
                          return Container(
                            width: active ? 8 : 7,
                            height: active ? 8 : 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          PropertyCardCopy.price(context, p),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                            height: 1.15,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onMore ?? widget.onTap,
                        icon: const Icon(
                          Icons.more_horiz,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _SpecsLine(property: p),
                  const SizedBox(height: 5),
                  Text(
                    PropertyCardCopy.address(context, p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A4A4A),
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

class _SpecsLine extends StatelessWidget {
  const _SpecsLine({required this.property});

  final PropertyData property;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final p = property;
    const numStyle = TextStyle(
      fontWeight: FontWeight.w700,
      color: Color(0xFF111111),
    );
    const labelStyle = TextStyle(color: Color(0xFF4A4A4A));
    const pipeStyle = TextStyle(color: Color(0xFFBDBDBD));

    final spans = <InlineSpan>[];
    void pipe() {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' | ', style: pipeStyle));
    }

    if (p.bedrooms > 0) {
      spans
        ..add(TextSpan(text: '${p.bedrooms}', style: numStyle))
        ..add(TextSpan(text: ' ${loc.bedsShort}', style: labelStyle));
    }
    if (p.bathrooms > 0) {
      pipe();
      spans
        ..add(TextSpan(text: '${p.bathrooms}', style: numStyle))
        ..add(TextSpan(text: ' ${loc.bathsShort}', style: labelStyle));
    }
    if (p.area > 0) {
      pipe();
      spans
        ..add(TextSpan(text: p.area.toStringAsFixed(0), style: numStyle))
        ..add(TextSpan(text: ' ${loc.areaUnitM2}', style: labelStyle));
    }
    pipe();
    spans.add(
      TextSpan(text: PropertyCardCopy.listing(context, p), style: labelStyle),
    );

    return Text.rich(
      TextSpan(style: const TextStyle(fontSize: 14), children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
