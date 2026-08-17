import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/enums/media_category.dart';
import '../../domain/models/property_media.dart';
import 'media_category_labels.dart';
import 'property_fullscreen_gallery.dart';

class PropertyMediaGalleryView extends StatefulWidget {
  const PropertyMediaGalleryView({
    super.key,
    required this.gallery,
    this.onOpen3d,
    this.onOpen360,
    this.onOpenFloorPlan,
  });

  final PropertyMediaGallery gallery;
  final VoidCallback? onOpen3d;
  final VoidCallback? onOpen360;
  final VoidCallback? onOpenFloorPlan;

  @override
  State<PropertyMediaGalleryView> createState() =>
      _PropertyMediaGalleryViewState();
}

class _PropertyMediaGalleryViewState extends State<PropertyMediaGalleryView> {
  late final PageController _controller;
  int _index = 0;
  MediaCategory? _filter;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<PropertyMediaItem> get _visible {
    final photos = widget.gallery.photos;
    if (_filter == null) return photos.isNotEmpty ? photos : widget.gallery.items;
    return widget.gallery.byCategory(_filter!);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = _visible;
    if (items.isEmpty) {
      return Container(
        height: 280,
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.home_work_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final categories = widget.gallery.availableCategories;

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  return GestureDetector(
                    onTap: () => PropertyFullscreenGallery.open(
                      context,
                      items: items,
                      initialIndex: i,
                    ),
                    child: Image.network(
                      items[i].url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_index + 1}/${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 12,
                end: 12,
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (widget.gallery.has3dTour)
                      _MediaChip(
                        label: loc.tour3d,
                        onTap: widget.onOpen3d,
                      ),
                    if (widget.gallery.has360Tour)
                      _MediaChip(
                        label: loc.virtualTour,
                        onTap: widget.onOpen360,
                      ),
                    if (widget.gallery.hasFloorPlan)
                      _MediaChip(
                        label: loc.floorPlan,
                        onTap: widget.onOpenFloorPlan,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (categories.length > 1)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _CategoryChip(
                  label: loc.all,
                  selected: _filter == null,
                  onTap: () => setState(() {
                    _filter = null;
                    _index = 0;
                    _controller.jumpToPage(0);
                  }),
                ),
                ...categories.map(
                  (c) => _CategoryChip(
                    label: _categoryLabel(loc, c),
                    selected: _filter == c,
                    onTap: () => setState(() {
                      _filter = c;
                      _index = 0;
                      _controller.jumpToPage(0);
                    }),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _categoryLabel(AppLocalizations loc, MediaCategory c) {
    return loc.labelForMediaCategory(c);
  }
}

class _MediaChip extends StatelessWidget {
  const _MediaChip({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
