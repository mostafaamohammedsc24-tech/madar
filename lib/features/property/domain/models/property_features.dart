class PropertyFacts {
  const PropertyFacts({
    this.propertyType,
    this.buildingType,
    this.unitType,
    this.bedrooms,
    this.bathrooms,
    this.livingRooms,
    this.floors,
    this.floorNumber,
    this.totalFloors,
    this.parkingSpaces,
    this.yearBuilt,
    this.yearRenovated,
    this.orientation,
    this.hasElevator,
    this.isFurnished,
    this.hasBalcony,
    this.hasGarden,
    this.hasPool,
  });

  final String? propertyType;
  final String? buildingType;
  final String? unitType;
  final int? bedrooms;
  final int? bathrooms;
  final int? livingRooms;
  final int? floors;
  final int? floorNumber;
  final int? totalFloors;
  final int? parkingSpaces;
  final int? yearBuilt;
  final int? yearRenovated;
  final String? orientation;
  final bool? hasElevator;
  final bool? isFurnished;
  final bool? hasBalcony;
  final bool? hasGarden;
  final bool? hasPool;

  bool get hasAny =>
      propertyType != null ||
      bedrooms != null ||
      bathrooms != null ||
      yearBuilt != null ||
      parkingSpaces != null ||
      floorNumber != null;
}

/// Flexible feature bags — publisher can add keys over time via JSONB.
class PropertyFeatureBag {
  const PropertyFeatureBag({this.entries = const {}});

  final Map<String, dynamic> entries;

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;

  List<MapEntry<String, dynamic>> get displayEntries =>
      entries.entries.where((e) {
        final v = e.value;
        if (v == null) return false;
        if (v is bool) return v;
        if (v is String) return v.isNotEmpty;
        return true;
      }).toList();
}

class PropertyFeatures {
  const PropertyFeatures({
    this.interior = const PropertyFeatureBag(),
    this.exterior = const PropertyFeatureBag(),
    this.utilities = const PropertyFeatureBag(),
    this.energy = const PropertyFeatureBag(),
    this.building = const PropertyFeatureBag(),
    this.renovation = const PropertyFeatureBag(),
    this.developmentPotential = const PropertyFeatureBag(),
    this.amenityTags = const [],
  });

  final PropertyFeatureBag interior;
  final PropertyFeatureBag exterior;
  final PropertyFeatureBag utilities;
  final PropertyFeatureBag energy;
  final PropertyFeatureBag building;
  final PropertyFeatureBag renovation;
  final PropertyFeatureBag developmentPotential;
  final List<String> amenityTags;

  bool get hasInterior => interior.isNotEmpty;
  bool get hasExterior => exterior.isNotEmpty;
  bool get hasUtilities => utilities.isNotEmpty;
  bool get hasEnergy => energy.isNotEmpty;
  bool get hasBuilding => building.isNotEmpty;
  bool get hasRenovation => renovation.isNotEmpty;
  bool get hasDevelopmentPotential => developmentPotential.isNotEmpty;
}
