enum MediaCategory {
  exterior,
  livingRoom,
  kitchen,
  bedroom,
  masterBedroom,
  bathroom,
  garden,
  pool,
  garage,
  roof,
  view,
  street,
  commercialArea,
  land,
  building,
  floorPlan,
  document,
  renovationBefore,
  renovationAfter,
  other;

  static MediaCategory fromString(String? raw) {
    switch ((raw ?? '').toLowerCase().replaceAll(' ', '_')) {
      case 'exterior':
        return MediaCategory.exterior;
      case 'living_room':
      case 'livingroom':
        return MediaCategory.livingRoom;
      case 'kitchen':
        return MediaCategory.kitchen;
      case 'bedroom':
        return MediaCategory.bedroom;
      case 'master_bedroom':
        return MediaCategory.masterBedroom;
      case 'bathroom':
        return MediaCategory.bathroom;
      case 'garden':
        return MediaCategory.garden;
      case 'pool':
        return MediaCategory.pool;
      case 'garage':
        return MediaCategory.garage;
      case 'roof':
        return MediaCategory.roof;
      case 'view':
        return MediaCategory.view;
      case 'street':
        return MediaCategory.street;
      case 'commercial_area':
        return MediaCategory.commercialArea;
      case 'land':
        return MediaCategory.land;
      case 'building':
        return MediaCategory.building;
      case 'floor_plan':
      case 'floorplan':
        return MediaCategory.floorPlan;
      case 'document':
        return MediaCategory.document;
      case 'renovation_before':
      case 'before':
        return MediaCategory.renovationBefore;
      case 'renovation_after':
      case 'after':
        return MediaCategory.renovationAfter;
      default:
        return MediaCategory.other;
    }
  }
}

enum MediaKind {
  photo,
  video,
  tour360,
  tour3d,
  floorPlan,
  document;

  static MediaKind fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'video':
        return MediaKind.video;
      case '360':
      case 'tour360':
      case 'panorama':
        return MediaKind.tour360;
      case '3d':
      case 'tour3d':
        return MediaKind.tour3d;
      case 'floor_plan':
      case 'floorplan':
        return MediaKind.floorPlan;
      case 'document':
        return MediaKind.document;
      default:
        return MediaKind.photo;
    }
  }
}
