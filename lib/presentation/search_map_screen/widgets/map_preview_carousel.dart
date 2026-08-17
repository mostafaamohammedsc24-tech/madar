import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/property_data.dart';

/// Floating horizontal property preview that sits above the map bottom sheet.
class MapPreviewCarousel extends StatefulWidget {
  const MapPreviewCarousel({
    required this.properties,
    required this.initialIndex,
    required this.onPageChanged,
    required this.onOpen,
    required this.onClose,
    super.key,
  });

  final List<PropertyData> properties;
  final int initialIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<PropertyData> onOpen;
  final VoidCallback onClose;

  @override
  State<MapPreviewCarousel> createState() => _MapPreviewCarouselState();
}

class _MapPreviewCarouselState extends State<MapPreviewCarousel> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.properties.length - 1);
    _controller = PageController(viewportFraction: 0.92, initialPage: _index);
  }

  @override
  void didUpdateWidget(MapPreviewCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex &&
        widget.initialIndex != _index &&
        _controller.hasClients) {
      _index = widget.initialIndex.clamp(0, widget.properties.length - 1);
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.properties.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF212121),
            ),
          ),
        ),
        SizedBox(
          height: 286,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.properties.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              widget.onPageChanged(i);
            },
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _PreviewCard(
                  property: widget.properties[i],
                  onOpen: () => widget.onOpen(widget.properties[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatefulWidget {
  const _PreviewCard({required this.property, required this.onOpen});

  final PropertyData property;
  final VoidCallback onOpen;

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  final _imageController = PageController();
  int _imageIndex = 0;
  bool _saved = false;

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final p = widget.property;
    final images = p.gallery;
    final badge = p.isFeatured
        ? loc.featured
        : p.listingTypeLabel;

    return GestureDetector(
      onTap: widget.onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _imageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (context, i) {
                      return Image.network(
                        images[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.home_work_outlined),
                        ),
                      );
                    },
                  ),
                  PositionedDirectional(
                    top: 10,
                    start: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: IconButton(
                      onPressed: () => setState(() => _saved = !_saved),
                      icon: Icon(
                        _saved ? Icons.favorite : Icons.favorite_border,
                        color: _saved ? Colors.red : Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          final active = i == _imageIndex;
                          return Container(
                            width: active ? 8 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.formattedPrice,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (p.bedrooms > 0) ...[
                        const Icon(Icons.bed_outlined, size: 16),
                        const SizedBox(width: 4),
                        Text('${p.bedrooms}'),
                        const SizedBox(width: 12),
                      ],
                      if (p.bathrooms > 0) ...[
                        const Icon(Icons.bathtub_outlined, size: 16),
                        const SizedBox(width: 4),
                        Text('${p.bathrooms}'),
                        const SizedBox(width: 12),
                      ],
                      const Icon(Icons.square_foot, size: 16),
                      const SizedBox(width: 4),
                      Text('${p.area.toStringAsFixed(0)} m²'),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          p.type,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
