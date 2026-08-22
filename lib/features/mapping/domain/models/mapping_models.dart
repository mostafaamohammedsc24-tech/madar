import 'dart:math' as math;

import '../enums/mapping_enums.dart';

class MappingStaff {
  const MappingStaff({
    required this.id,
    required this.employeeId,
    required this.displayName,
    this.countryCode = 'IQ',
    this.department = 'هندسة العقارات',
    this.specialization = 'مخططات طوابق ورسم مكاني',
    this.languages = const ['ar', 'en', 'ku'],
  });

  final String id;
  final String employeeId;
  final String displayName;
  final String countryCode;
  final String department;
  final String specialization;
  final List<String> languages;
}

class NamedI18n {
  const NamedI18n({required this.ar, required this.en, required this.ku});
  final String ar;
  final String en;
  final String ku;
  String of(String lang) {
    switch (lang) {
      case 'ku':
        return ku;
      case 'en':
        return en;
      default:
        return ar;
    }
  }
}

class MappingPoint {
  const MappingPoint({required this.x, required this.y});
  final double x;
  final double y;
}

class MappingRoom {
  const MappingRoom({
    required this.id,
    required this.names,
    required this.kind,
    required this.floorId,
    required this.polygon,
    this.lengthM,
    this.widthM,
    this.heightM,
    this.measuredAreaM2,
    this.wallThicknessM = 0.20,
    this.notes,
    this.photoIds = const [],
    this.tourPointIds = const [],
    this.locked = false,
    this.hidden = false,
  });

  final String id;
  final NamedI18n names;
  final RoomKind kind;
  final String floorId;
  final List<MappingPoint> polygon;
  final double? lengthM;
  final double? widthM;
  final double? heightM;
  final double? measuredAreaM2;
  final double wallThicknessM;
  final String? notes;
  final List<String> photoIds;
  final List<String> tourPointIds;
  final bool locked;
  final bool hidden;

  double get calculatedAreaM2 {
    if (lengthM != null && widthM != null) return lengthM! * widthM!;
    if (polygon.length < 3) return 0;
    var sum = 0.0;
    for (var i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];
      sum += a.x * b.y - b.x * a.y;
    }
    return sum.abs() / 2;
  }

  double? get areaDifference {
    if (measuredAreaM2 == null) return null;
    return (calculatedAreaM2 - measuredAreaM2!).abs();
  }

  bool get needsMeasurementReview {
    final d = areaDifference;
    if (d == null) return false;
    return d > math.max(1.0, calculatedAreaM2 * 0.08);
  }

  MappingRoom copyWith({
    NamedI18n? names,
    List<MappingPoint>? polygon,
    double? lengthM,
    double? widthM,
    double? heightM,
    double? measuredAreaM2,
    List<String>? photoIds,
    List<String>? tourPointIds,
    bool? locked,
    bool? hidden,
    String? notes,
  }) {
    return MappingRoom(
      id: id,
      names: names ?? this.names,
      kind: kind,
      floorId: floorId,
      polygon: polygon ?? this.polygon,
      lengthM: lengthM ?? this.lengthM,
      widthM: widthM ?? this.widthM,
      heightM: heightM ?? this.heightM,
      measuredAreaM2: measuredAreaM2 ?? this.measuredAreaM2,
      wallThicknessM: wallThicknessM,
      notes: notes ?? this.notes,
      photoIds: photoIds ?? this.photoIds,
      tourPointIds: tourPointIds ?? this.tourPointIds,
      locked: locked ?? this.locked,
      hidden: hidden ?? this.hidden,
    );
  }
}

class MappingWall {
  const MappingWall({
    required this.id,
    required this.kind,
    required this.start,
    required this.end,
    required this.thicknessM,
  });
  final String id;
  final WallKind kind;
  final MappingPoint start;
  final MappingPoint end;
  final double thicknessM;
}

class MappingDoor {
  const MappingDoor({
    required this.id,
    required this.kind,
    required this.widthM,
    required this.heightM,
    required this.fromRoomId,
    this.toRoomId,
    this.direction = 'in',
    required this.at,
  });
  final String id;
  final DoorKind kind;
  final double widthM;
  final double heightM;
  final String fromRoomId;
  final String? toRoomId;
  final String direction;
  final MappingPoint at;
}

class MappingWindow {
  const MappingWindow({
    required this.id,
    required this.kind,
    required this.widthM,
    required this.heightM,
    required this.roomId,
    this.orientation = 'N',
    required this.at,
  });
  final String id;
  final WindowKind kind;
  final double widthM;
  final double heightM;
  final String roomId;
  final String orientation;
  final MappingPoint at;
}

class MappingStair {
  const MappingStair({
    required this.id,
    required this.fromFloorId,
    required this.toFloorId,
    required this.steps,
    required this.widthM,
    required this.at,
  });
  final String id;
  final String fromFloorId;
  final String toFloorId;
  final int steps;
  final double widthM;
  final MappingPoint at;
}

class InteractivePoint {
  const InteractivePoint({
    required this.id,
    required this.roomId,
    required this.floorId,
    required this.at,
    this.tourPointId,
    this.photoGroupId,
    this.description,
  });
  final String id;
  final String roomId;
  final String floorId;
  final MappingPoint at;
  final String? tourPointId;
  final String? photoGroupId;
  final String? description;
}

class MappingFloor {
  const MappingFloor({
    required this.id,
    required this.kind,
    required this.number,
    required this.names,
    required this.areaM2,
    required this.ceilingHeightM,
    required this.status,
    this.rooms = const [],
    this.walls = const [],
    this.doors = const [],
    this.windows = const [],
    this.stairs = const [],
    this.points = const [],
    this.notes,
    this.sourceFile,
  });

  final String id;
  final FloorKind kind;
  final int number;
  final NamedI18n names;
  final double areaM2;
  final double ceilingHeightM;
  final MappingPlanStatus status;
  final List<MappingRoom> rooms;
  final List<MappingWall> walls;
  final List<MappingDoor> doors;
  final List<MappingWindow> windows;
  final List<MappingStair> stairs;
  final List<InteractivePoint> points;
  final String? notes;
  final String? sourceFile;

  MappingFloor copyWith({
    List<MappingRoom>? rooms,
    List<MappingWall>? walls,
    List<MappingDoor>? doors,
    List<MappingWindow>? windows,
    List<MappingStair>? stairs,
    List<InteractivePoint>? points,
    MappingPlanStatus? status,
    String? notes,
    String? sourceFile,
  }) {
    return MappingFloor(
      id: id,
      kind: kind,
      number: number,
      names: names,
      areaM2: areaM2,
      ceilingHeightM: ceilingHeightM,
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      walls: walls ?? this.walls,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      stairs: stairs ?? this.stairs,
      points: points ?? this.points,
      notes: notes ?? this.notes,
      sourceFile: sourceFile ?? this.sourceFile,
    );
  }
}

class BuildingMetrics {
  const BuildingMetrics({
    required this.lengthM,
    required this.widthM,
    required this.footprintM2,
    required this.totalBuiltM2,
    required this.usableM2,
    required this.landM2,
    required this.frontSetbackM,
    required this.rearSetbackM,
    required this.sideSetbackM,
    required this.streetWidthM,
    this.north = 'N',
    this.entranceDir = 'E',
    this.streetDir = 'E',
  });

  final double lengthM;
  final double widthM;
  final double footprintM2;
  final double totalBuiltM2;
  final double usableM2;
  final double landM2;
  final double frontSetbackM;
  final double rearSetbackM;
  final double sideSetbackM;
  final double streetWidthM;
  final String north;
  final String entranceDir;
  final String streetDir;
}

class MappingPhoto {
  const MappingPhoto({required this.id, required this.label, required this.roomHint});
  final String id;
  final String label;
  final String roomHint;
}

class TourPoint {
  const TourPoint({required this.id, required this.label});
  final String id;
  final String label;
}

class MappingVersion {
  const MappingVersion({
    required this.number,
    required this.createdBy,
    required this.at,
    required this.reason,
    required this.changes,
    required this.status,
    this.approved = false,
  });
  final int number;
  final String createdBy;
  final DateTime at;
  final String reason;
  final String changes;
  final MappingPlanStatus status;
  final bool approved;
}

class MappingCorrection {
  const MappingCorrection({
    required this.id,
    required this.issue,
    required this.requestedBy,
    required this.at,
    required this.priority,
    this.response,
  });
  final String id;
  final String issue;
  final String requestedBy;
  final DateTime at;
  final MappingPriority priority;
  final String? response;
}

class MappingNote {
  const MappingNote({required this.id, required this.body, required this.author, required this.at});
  final String id;
  final String body;
  final String author;
  final DateTime at;
}

class MappingMessage {
  const MappingMessage({
    required this.id,
    required this.channel,
    required this.kind,
    required this.body,
    required this.author,
    required this.at,
  });
  final String id;
  final MappingChannel channel;
  final MessageKind kind;
  final String body;
  final String author;
  final DateTime at;
}

class MappingAudit {
  const MappingAudit({
    required this.id,
    required this.action,
    required this.employeeId,
    required this.employeeName,
    required this.at,
    required this.propertyId,
    required this.requestId,
  });
  final String id;
  final String action;
  final String employeeId;
  final String employeeName;
  final DateTime at;
  final String propertyId;
  final String requestId;
}

class ValidationItem {
  const ValidationItem({required this.ok, required this.label, this.warning = false});
  final bool ok;
  final String label;
  final bool warning;
}

class MappingJob {
  const MappingJob({
    required this.id,
    required this.propertyId,
    required this.requestNumber,
    required this.address,
    required this.propertyType,
    required this.country,
    required this.city,
    required this.areaLabel,
    required this.publisher,
    required this.informationEmployee,
    required this.photographer,
    required this.assignedEngineer,
    required this.engineerId,
    required this.status,
    required this.requiredAction,
    required this.priority,
    required this.assignedAt,
    required this.deadline,
    required this.metrics,
    required this.floors,
    required this.photos,
    required this.tourPoints,
    this.structures = const [],
    this.versions = const [],
    this.corrections = const [],
    this.notes = const [],
    this.messages = const [],
    this.audit = const [],
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.livingAreas = 0,
    this.hasKitchen = true,
    this.hasGarage = false,
    this.hasGarden = false,
    this.hasBalcony = false,
    this.hasRoof = false,
    this.hasBasement = false,
    this.photoCount = 0,
    this.tourReady = false,
    this.infoNotes,
    this.photoNotes,
    this.blockedReason,
    this.sync = SyncState.synced,
    this.unitLabel,
    this.buildingPlan = false,
  });

  final String id;
  final String propertyId;
  final String requestNumber;
  final String address;
  final String propertyType;
  final String country;
  final String city;
  final String areaLabel;
  final String publisher;
  final String informationEmployee;
  final String photographer;
  final String assignedEngineer;
  final String engineerId;
  final MappingPlanStatus status;
  final MappingWorkAction requiredAction;
  final MappingPriority priority;
  final DateTime assignedAt;
  final DateTime deadline;
  final BuildingMetrics metrics;
  final List<MappingFloor> floors;
  final List<MappingPhoto> photos;
  final List<TourPoint> tourPoints;
  final List<String> structures;
  final List<MappingVersion> versions;
  final List<MappingCorrection> corrections;
  final List<MappingNote> notes;
  final List<MappingMessage> messages;
  final List<MappingAudit> audit;
  final int bedrooms;
  final int bathrooms;
  final int livingAreas;
  final bool hasKitchen;
  final bool hasGarage;
  final bool hasGarden;
  final bool hasBalcony;
  final bool hasRoof;
  final bool hasBasement;
  final int photoCount;
  final bool tourReady;
  final String? infoNotes;
  final String? photoNotes;
  final String? blockedReason;
  final SyncState sync;
  final String? unitLabel;
  final bool buildingPlan;

  bool get isArchived => status == MappingPlanStatus.archived || status == MappingPlanStatus.published;

  MappingJob copyWith({
    MappingPlanStatus? status,
    MappingWorkAction? requiredAction,
    MappingPriority? priority,
    List<MappingFloor>? floors,
    List<MappingVersion>? versions,
    List<MappingCorrection>? corrections,
    List<MappingNote>? notes,
    List<MappingMessage>? messages,
    List<MappingAudit>? audit,
    SyncState? sync,
    String? blockedReason,
  }) {
    return MappingJob(
      id: id,
      propertyId: propertyId,
      requestNumber: requestNumber,
      address: address,
      propertyType: propertyType,
      country: country,
      city: city,
      areaLabel: areaLabel,
      publisher: publisher,
      informationEmployee: informationEmployee,
      photographer: photographer,
      assignedEngineer: assignedEngineer,
      engineerId: engineerId,
      status: status ?? this.status,
      requiredAction: requiredAction ?? this.requiredAction,
      priority: priority ?? this.priority,
      assignedAt: assignedAt,
      deadline: deadline,
      metrics: metrics,
      floors: floors ?? this.floors,
      photos: photos,
      tourPoints: tourPoints,
      structures: structures,
      versions: versions ?? this.versions,
      corrections: corrections ?? this.corrections,
      notes: notes ?? this.notes,
      messages: messages ?? this.messages,
      audit: audit ?? this.audit,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      livingAreas: livingAreas,
      hasKitchen: hasKitchen,
      hasGarage: hasGarage,
      hasGarden: hasGarden,
      hasBalcony: hasBalcony,
      hasRoof: hasRoof,
      hasBasement: hasBasement,
      photoCount: photoCount,
      tourReady: tourReady,
      infoNotes: infoNotes,
      photoNotes: photoNotes,
      blockedReason: blockedReason ?? this.blockedReason,
      sync: sync ?? this.sync,
      unitLabel: unitLabel,
      buildingPlan: buildingPlan,
    );
  }
}
