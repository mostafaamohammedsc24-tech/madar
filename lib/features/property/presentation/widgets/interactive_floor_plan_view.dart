import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/property_extended.dart';
import '../../domain/models/property_media.dart';

class InteractiveFloorPlanView extends StatefulWidget {
  const InteractiveFloorPlanView({
    super.key,
    required this.plan,
    required this.media,
    this.onOpen3d,
    this.onOpenPhotos,
  });

  final PropertyFloorPlan plan;
  final PropertyMediaGallery media;
  final void Function(String pointId)? onOpen3d;
  final void Function(List<PropertyMediaItem> photos)? onOpenPhotos;

  @override
  State<InteractiveFloorPlanView> createState() =>
      _InteractiveFloorPlanViewState();
}

class _InteractiveFloorPlanViewState extends State<InteractiveFloorPlanView> {
  String? _selectedRoom;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final imageUrl = widget.plan.imageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Text(
        loc.informationUnavailable,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.map_outlined),
                      ),
                    ),
                  ),
                  ...widget.plan.rooms.map((room) {
                    final selected = _selectedRoom == room.name;
                    return Positioned(
                      left: room.x * constraints.maxWidth,
                      top: room.y * constraints.maxHeight,
                      width: room.width * constraints.maxWidth,
                      height: room.height * constraints.maxHeight,
                      child: Material(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.35)
                            : theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => _onRoomTap(room),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                room.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
        if (_selectedRoom != null) ...[
          const SizedBox(height: 10),
          Text(
            _selectedRoom!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  void _onRoomTap(FloorPlanRoom room) {
    setState(() => _selectedRoom = room.name);
    final loc = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  room.name,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                if (room.linked3dPointId != null &&
                    widget.onOpen3d != null)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onOpen3d!(room.linked3dPointId!);
                    },
                    icon: const Icon(Icons.view_in_ar_outlined),
                    label: Text(loc.tour3d),
                  ),
                if (room.linkedMediaCategory != null ||
                    room.roomKey != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      final photos = _photosForRoom(room);
                      Navigator.pop(ctx);
                      if (photos.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.informationUnavailable)),
                        );
                        return;
                      }
                      widget.onOpenPhotos?.call(photos);
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(loc.viewDetails),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<PropertyMediaItem> _photosForRoom(FloorPlanRoom room) {
    final cat = room.linkedMediaCategory?.toLowerCase() ?? room.roomKey ?? '';
    if (cat.isEmpty) return widget.media.photos;
    return widget.media.photos
        .where(
          (p) =>
              p.roomKey == room.roomKey ||
              p.category.name.toLowerCase().contains(cat.replaceAll(' ', '_')),
        )
        .toList();
  }
}
