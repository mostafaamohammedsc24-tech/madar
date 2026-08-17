import '../enums/media_category.dart';

class PropertyMediaItem {
  const PropertyMediaItem({
    required this.id,
    required this.url,
    required this.kind,
    this.category = MediaCategory.other,
    this.caption,
    this.sortOrder = 0,
    this.thumbnailUrl,
    this.externalProvider,
    this.externalId,
    this.roomKey,
  });

  final String id;
  final String url;
  final MediaKind kind;
  final MediaCategory category;
  final String? caption;
  final int sortOrder;
  final String? thumbnailUrl;
  /// Abstraction for future 360/3D providers (Matterport, Kuula, etc.).
  final String? externalProvider;
  final String? externalId;
  /// Links media to floor-plan room / gallery filter.
  final String? roomKey;
}

class PropertyMediaGallery {
  const PropertyMediaGallery({this.items = const []});

  final List<PropertyMediaItem> items;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  List<PropertyMediaItem> get photos =>
      items.where((i) => i.kind == MediaKind.photo).toList();

  PropertyMediaItem? get primaryPhoto {
    final photos = this.photos;
    if (photos.isEmpty) return items.isNotEmpty ? items.first : null;
    return photos.first;
  }

  bool get has3dTour => items.any((i) => i.kind == MediaKind.tour3d);
  bool get has360Tour => items.any((i) => i.kind == MediaKind.tour360);
  bool get hasFloorPlan => items.any((i) => i.kind == MediaKind.floorPlan);
  bool get hasVideo => items.any((i) => i.kind == MediaKind.video);

  PropertyMediaItem? get tour3d {
    for (final i in items) {
      if (i.kind == MediaKind.tour3d) return i;
    }
    return null;
  }

  PropertyMediaItem? get tour360 {
    for (final i in items) {
      if (i.kind == MediaKind.tour360) return i;
    }
    return null;
  }

  List<MediaCategory> get availableCategories {
    final set = <MediaCategory>{};
    for (final i in photos) {
      set.add(i.category);
    }
    return set.toList();
  }

  List<PropertyMediaItem> byCategory(MediaCategory category) =>
      photos.where((i) => i.category == category).toList();
}
