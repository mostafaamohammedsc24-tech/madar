/// Room-level dimensions in meters / m² — only shown when publisher provides data.
class RoomDimensions {
  const RoomDimensions({
    required this.name,
    this.lengthM,
    this.widthM,
    this.areaSqm,
    this.ceilingHeightM,
    this.roomKey,
    this.linkedMediaIds = const [],
    this.linked3dPointId,
  });

  final String name;
  final double? lengthM;
  final double? widthM;
  final double? areaSqm;
  final double? ceilingHeightM;
  final String? roomKey;
  final List<String> linkedMediaIds;
  final String? linked3dPointId;

  bool get hasAny =>
      lengthM != null || widthM != null || areaSqm != null || ceilingHeightM != null;

  String formatDimensions() {
    if (lengthM != null && widthM != null) {
      return '${lengthM!.toStringAsFixed(1)}m × ${widthM!.toStringAsFixed(1)}m';
    }
    return '';
  }
}

/// Site and building dimensions — metric only.
class PropertyDimensions {
  const PropertyDimensions({
    this.landLengthM,
    this.landWidthM,
    this.buildingLengthM,
    this.buildingWidthM,
    this.frontageM,
    this.rearWidthM,
    this.sideLengthM,
    this.streetWidthM,
    this.setbackM,
    this.buildingHeightM,
    this.ceilingHeightM,
    this.rooms = const [],
  });

  final double? landLengthM;
  final double? landWidthM;
  final double? buildingLengthM;
  final double? buildingWidthM;
  final double? frontageM;
  final double? rearWidthM;
  final double? sideLengthM;
  final double? streetWidthM;
  final double? setbackM;
  final double? buildingHeightM;
  final double? ceilingHeightM;
  final List<RoomDimensions> rooms;

  bool get hasSite =>
      landLengthM != null ||
      landWidthM != null ||
      buildingLengthM != null ||
      buildingWidthM != null ||
      frontageM != null ||
      rearWidthM != null ||
      sideLengthM != null ||
      streetWidthM != null ||
      setbackM != null ||
      buildingHeightM != null ||
      ceilingHeightM != null;

  bool get hasRooms => rooms.any((r) => r.hasAny);

  bool get hasAny => hasSite || hasRooms;
}

class PropertyConstruction {
  const PropertyConstruction({
    this.yearBuilt,
    this.constructionStatus,
    this.lastRenovation,
    this.lastMaintenance,
    this.constructionMaterial,
    this.structureType,
    this.foundationType,
    this.roofType,
    this.exteriorMaterial,
    this.interiorMaterial,
  });

  final int? yearBuilt;
  final String? constructionStatus;
  final String? lastRenovation;
  final String? lastMaintenance;
  final String? constructionMaterial;
  final String? structureType;
  final String? foundationType;
  final String? roofType;
  final String? exteriorMaterial;
  final String? interiorMaterial;

  bool get hasAny =>
      yearBuilt != null ||
      (constructionStatus?.isNotEmpty ?? false) ||
      (lastRenovation?.isNotEmpty ?? false) ||
      (lastMaintenance?.isNotEmpty ?? false) ||
      (constructionMaterial?.isNotEmpty ?? false) ||
      (structureType?.isNotEmpty ?? false) ||
      (foundationType?.isNotEmpty ?? false) ||
      (roofType?.isNotEmpty ?? false) ||
      (exteriorMaterial?.isNotEmpty ?? false) ||
      (interiorMaterial?.isNotEmpty ?? false);
}

class PropertyBuilderInfo {
  const PropertyBuilderInfo({
    this.companyName,
    this.companyId,
    this.contractorName,
    this.projectName,
    this.developer,
    this.constructionCompany,
    this.architect,
    this.engineeringOffice,
  });

  final String? companyName;
  final String? companyId;
  final String? contractorName;
  final String? projectName;
  final String? developer;
  final String? constructionCompany;
  final String? architect;
  final String? engineeringOffice;

  bool get hasAny =>
      (companyName?.isNotEmpty ?? false) ||
      (companyId?.isNotEmpty ?? false) ||
      (contractorName?.isNotEmpty ?? false) ||
      (projectName?.isNotEmpty ?? false) ||
      (developer?.isNotEmpty ?? false) ||
      (constructionCompany?.isNotEmpty ?? false) ||
      (architect?.isNotEmpty ?? false) ||
      (engineeringOffice?.isNotEmpty ?? false);
}

class PropertyListingMeta {
  const PropertyListingMeta({
    this.listingId,
    this.propertyNumberId,
    this.publisherName,
    this.publishedAt,
    this.views,
    this.saves,
    this.shares,
    this.statusLabel,
  });

  final String? listingId;
  /// Stable 8-digit property identifier from database.
  final String? propertyNumberId;
  final String? publisherName;
  final DateTime? publishedAt;
  final int? views;
  final int? saves;
  final int? shares;
  final String? statusLabel;

  bool get hasAny =>
      (listingId?.isNotEmpty ?? false) ||
      (propertyNumberId?.isNotEmpty ?? false) ||
      (publisherName?.isNotEmpty ?? false) ||
      publishedAt != null ||
      views != null ||
      saves != null ||
      shares != null;
}

class PropertyVerificationFlags {
  const PropertyVerificationFlags({
    this.propertyVerified = false,
    this.locationVerified = false,
    this.informationVerified = false,
    this.documentsVerified = false,
    this.photosVerified = false,
  });

  final bool propertyVerified;
  final bool locationVerified;
  final bool informationVerified;
  final bool documentsVerified;
  final bool photosVerified;

  bool get hasAny =>
      propertyVerified ||
      locationVerified ||
      informationVerified ||
      documentsVerified ||
      photosVerified;
}

class PropertyMarketAnalytics {
  const PropertyMarketAnalytics({
    this.averagePriceInArea,
    this.averagePricePerSqm,
    this.averageRent,
    this.averageRentalYield,
    this.priceTrend,
    this.demand,
    this.listingsCount,
    this.daysOnMarket,
  });

  final String? averagePriceInArea;
  final String? averagePricePerSqm;
  final String? averageRent;
  final double? averageRentalYield;
  final String? priceTrend;
  final String? demand;
  final int? listingsCount;
  final int? daysOnMarket;

  bool get hasAny =>
      averagePriceInArea != null ||
      averagePricePerSqm != null ||
      averageRent != null ||
      averageRentalYield != null ||
      (priceTrend?.isNotEmpty ?? false) ||
      (demand?.isNotEmpty ?? false) ||
      listingsCount != null ||
      daysOnMarket != null;
}

/// Interactive floor plan overlay — room boxes are publisher-defined (0–1 coords).
class FloorPlanRoom {
  const FloorPlanRoom({
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.roomKey,
    this.linked3dPointId,
    this.linkedMediaCategory,
  });

  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? roomKey;
  final String? linked3dPointId;
  final String? linkedMediaCategory;
}

class PropertyFloorPlan {
  const PropertyFloorPlan({
    this.imageUrl,
    this.floors = const [],
    this.rooms = const [],
  });

  final String? imageUrl;
  final List<String> floors;
  final List<FloorPlanRoom> rooms;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasInteractiveRooms => rooms.isNotEmpty;
  bool get hasAny => hasImage || hasInteractiveRooms;
}
