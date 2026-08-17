import '../enums/data_provenance.dart';

enum NearbyPlaceCategory {
  education,
  healthcare,
  shopping,
  services,
  lifestyle,
  transportation,
  other,
}

class NearbyPlace {
  const NearbyPlace({
    required this.name,
    required this.category,
    this.distanceMeters,
    this.travelTimeMinutes,
    this.subtype,
    this.rating,
    this.isPublic,
    this.provenance = DataProvenance.external,
  });

  final String name;
  final NearbyPlaceCategory category;
  final double? distanceMeters;
  final int? travelTimeMinutes;
  final String? subtype;
  final double? rating;
  final bool? isPublic;
  final DataProvenance provenance;
}

class NeighborhoodIntel {
  const NeighborhoodIntel({
    this.summary,
    this.demandLevel,
    this.density,
    this.commercialActivity,
    this.accessibilityNotes,
    this.proximityToMainRoads,
    this.walkScore,
    this.transitScore,
    this.provenance = DataProvenance.estimated,
  });

  final String? summary;
  final String? demandLevel;
  final String? density;
  final String? commercialActivity;
  final String? accessibilityNotes;
  final String? proximityToMainRoads;
  final double? walkScore;
  final double? transitScore;
  final DataProvenance provenance;

  bool get hasAny =>
      (summary != null && summary!.isNotEmpty) ||
      demandLevel != null ||
      walkScore != null ||
      transitScore != null;
}

class TransportationInfo {
  const TransportationInfo({
    this.nearestMainRoad,
    this.highways = const [],
    this.transitOptions = const [],
    this.airportDistanceKm,
    this.cityCenterDistanceKm,
    this.estimatedTravelTimes = const {},
    this.provenance = DataProvenance.external,
  });

  final String? nearestMainRoad;
  final List<String> highways;
  final List<String> transitOptions;
  final double? airportDistanceKm;
  final double? cityCenterDistanceKm;
  final Map<String, int> estimatedTravelTimes;
  final DataProvenance provenance;

  bool get hasAny =>
      nearestMainRoad != null ||
      highways.isNotEmpty ||
      transitOptions.isNotEmpty ||
      airportDistanceKm != null;
}

enum ProjectImpact { positive, neutral, negative, unknown }

class FutureProject {
  const FutureProject({
    required this.id,
    required this.name,
    this.type,
    this.locationLabel,
    this.distanceMeters,
    this.status,
    this.expectedCompletion,
    this.developer,
    this.estimatedImpact = ProjectImpact.unknown,
    this.description,
    this.imageUrls = const [],
    this.source,
    this.provenance = DataProvenance.publisherProvided,
  });

  final String id;
  final String name;
  final String? type;
  final String? locationLabel;
  final double? distanceMeters;
  final String? status;
  final DateTime? expectedCompletion;
  final String? developer;
  final ProjectImpact estimatedImpact;
  final String? description;
  final List<String> imageUrls;
  final String? source;
  final DataProvenance provenance;
}

class ClimateRiskInfo {
  const ClimateRiskInfo({
    this.floodRisk,
    this.extremeHeat,
    this.wildfire,
    this.wind,
    this.waterRisk,
    this.notes,
    this.provenance = DataProvenance.estimated,
  });

  final String? floodRisk;
  final String? extremeHeat;
  final String? wildfire;
  final String? wind;
  final String? waterRisk;
  final String? notes;
  final DataProvenance provenance;

  bool get hasAny =>
      floodRisk != null ||
      extremeHeat != null ||
      wildfire != null ||
      waterRisk != null;
}

class PropertySurroundings {
  const PropertySurroundings({
    this.neighborhood,
    this.nearbyPlaces = const [],
    this.transportation,
    this.futureProjects = const [],
    this.investmentProjects = const [],
    this.infrastructureNotes = const [],
    this.climateRisk,
  });

  final NeighborhoodIntel? neighborhood;
  final List<NearbyPlace> nearbyPlaces;
  final TransportationInfo? transportation;
  final List<FutureProject> futureProjects;
  final List<FutureProject> investmentProjects;
  final List<String> infrastructureNotes;
  final ClimateRiskInfo? climateRisk;

  bool get hasNearby => nearbyPlaces.isNotEmpty;
  bool get hasFutureProjects => futureProjects.isNotEmpty;
  bool get hasInvestmentProjects => investmentProjects.isNotEmpty;
}
