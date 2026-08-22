import '../enums/field_enums.dart';

class FieldStaff {
  const FieldStaff({
    required this.id,
    required this.employeeId,
    required this.displayName,
    this.countryCode = 'IQ',
    this.department = 'استخبارات العقار',
    this.specialization = 'جمع معلومات ميدانية',
  });
  final String id;
  final String employeeId;
  final String displayName;
  final String countryCode;
  final String department;
  final String specialization;
}

class SourcedValue {
  const SourcedValue({required this.value, required this.origin, this.confirmed = true});
  final String value;
  final DataOrigin origin;
  final bool confirmed;
}

class FieldRoom {
  const FieldRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.floor,
    this.lengthM,
    this.widthM,
    this.heightM,
    this.condition = RoomCondition.good,
    this.flooring,
    this.photoRef,
    this.notes,
  });
  final String id;
  final String name;
  final String type;
  final String floor;
  final double? lengthM;
  final double? widthM;
  final double? heightM;
  final RoomCondition condition;
  final String? flooring;
  final String? photoRef;
  final String? notes;
  double? get areaM2 => (lengthM != null && widthM != null) ? lengthM! * widthM! : null;
}

class NearbyPlace {
  const NearbyPlace({required this.name, required this.kind, required this.distanceM, this.verified = false});
  final String name;
  final String kind;
  final int distanceM;
  final bool verified;
}

class FutureProject {
  const FutureProject({
    required this.name,
    required this.type,
    required this.status,
    required this.source,
    required this.verified,
    this.distanceM,
    this.expected,
  });
  final String name;
  final String type;
  final String status;
  final String source;
  final bool verified;
  final int? distanceM;
  final String? expected;
}

class RenovationRecord {
  const RenovationRecord({required this.year, required this.areas, required this.type, this.contractor, this.notes});
  final int year;
  final String areas;
  final String type;
  final String? contractor;
  final String? notes;
}

class InspectionItem {
  const InspectionItem({required this.id, required this.label, required this.condition, this.note, this.photoRef});
  final String id;
  final String label;
  final RoomCondition condition;
  final String? note;
  final String? photoRef;
}

class FieldConflict {
  const FieldConflict({required this.id, required this.field, required this.left, required this.right, this.resolved = false, this.resolution});
  final String id;
  final String field;
  final String left;
  final String right;
  final bool resolved;
  final String? resolution;
}

class VoiceNote {
  const VoiceNote({
    required this.id,
    required this.body,
    required this.at,
    this.transcription,
    this.transcriptionConfirmed = false,
  });
  final String id;
  final String body;
  final DateTime at;
  final String? transcription;
  final bool transcriptionConfirmed;
}

class FieldCorrection {
  const FieldCorrection({
    required this.id,
    required this.field,
    required this.reason,
    required this.requestedBy,
    required this.at,
    required this.priority,
    this.response,
  });
  final String id;
  final String field;
  final String reason;
  final String requestedBy;
  final DateTime at;
  final FieldPriority priority;
  final String? response;
}

class FieldVersion {
  const FieldVersion({required this.number, required this.by, required this.at, required this.reason, required this.status});
  final int number;
  final String by;
  final DateTime at;
  final String reason;
  final FieldReportStatus status;
}

class FieldMessage {
  const FieldMessage({required this.id, required this.channel, required this.body, required this.author, required this.at});
  final String id;
  final FieldChannel channel;
  final String body;
  final String author;
  final DateTime at;
}

class FieldAudit {
  const FieldAudit({
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

class FieldJob {
  const FieldJob({
    required this.id,
    required this.propertyId,
    required this.requestNumber,
    required this.address,
    required this.propertyType,
    required this.subtype,
    required this.country,
    required this.governorate,
    required this.city,
    required this.district,
    required this.street,
    required this.lat,
    required this.lng,
    required this.publisher,
    required this.photographer,
    required this.floorPlanEngineer,
    required this.assignedName,
    required this.assignedId,
    required this.status,
    required this.requiredAction,
    required this.priority,
    required this.assignedAt,
    required this.visitAt,
    required this.specialInstructions,
    required this.photoStream,
    required this.planStream,
    required this.publishStream,
    this.landAreaM2,
    this.ownerClaimedBuiltM2,
    this.measuredBuiltM2,
    this.floors = 0,
    this.units = 1,
    this.streetWidthM,
    this.frontageM,
    this.yearBuilt,
    this.developer,
    this.contractor,
    this.rooms = const [],
    this.nearby = const [],
    this.projects = const [],
    this.renovations = const [],
    this.inspection = const [],
    this.conflicts = const [],
    this.voice = const [],
    this.corrections = const [],
    this.versions = const [],
    this.messages = const [],
    this.audit = const [],
    this.whatsSpecial = const [],
    this.internalRisks = const [],
    this.amenities = const [],
    this.utilities = const [],
    this.ownerPrice,
    this.rentalNote,
    this.arrivalAt,
    this.arrivalLat,
    this.arrivalLng,
    this.sync = SyncState.synced,
  });

  final String id;
  final String propertyId;
  final String requestNumber;
  final String address;
  final String propertyType;
  final String subtype;
  final String country;
  final String governorate;
  final String city;
  final String district;
  final String street;
  final double lat;
  final double lng;
  final String publisher;
  final String photographer;
  final String floorPlanEngineer;
  final String assignedName;
  final String assignedId;
  final FieldReportStatus status;
  final FieldWorkAction requiredAction;
  final FieldPriority priority;
  final DateTime assignedAt;
  final DateTime visitAt;
  final String specialInstructions;
  final StreamStatus photoStream;
  final StreamStatus planStream;
  final StreamStatus publishStream;
  final double? landAreaM2;
  final double? ownerClaimedBuiltM2;
  final double? measuredBuiltM2;
  final int floors;
  final int units;
  final double? streetWidthM;
  final double? frontageM;
  final int? yearBuilt;
  final String? developer;
  final String? contractor;
  final List<FieldRoom> rooms;
  final List<NearbyPlace> nearby;
  final List<FutureProject> projects;
  final List<RenovationRecord> renovations;
  final List<InspectionItem> inspection;
  final List<FieldConflict> conflicts;
  final List<VoiceNote> voice;
  final List<FieldCorrection> corrections;
  final List<FieldVersion> versions;
  final List<FieldMessage> messages;
  final List<FieldAudit> audit;
  final List<String> whatsSpecial;
  final List<String> internalRisks;
  final List<String> amenities;
  final List<String> utilities;
  final String? ownerPrice;
  final String? rentalNote;
  final DateTime? arrivalAt;
  final double? arrivalLat;
  final double? arrivalLng;
  final SyncState sync;

  bool get isLocked => status == FieldReportStatus.approved || status == FieldReportStatus.archived;

  FieldJob copyWith({
    FieldReportStatus? status,
    FieldWorkAction? requiredAction,
    List<FieldRoom>? rooms,
    List<FieldConflict>? conflicts,
    List<VoiceNote>? voice,
    List<FieldCorrection>? corrections,
    List<FieldVersion>? versions,
    List<FieldMessage>? messages,
    List<FieldAudit>? audit,
    List<String>? whatsSpecial,
    DateTime? arrivalAt,
    double? arrivalLat,
    double? arrivalLng,
    double? measuredBuiltM2,
    SyncState? sync,
  }) {
    return FieldJob(
      id: id,
      propertyId: propertyId,
      requestNumber: requestNumber,
      address: address,
      propertyType: propertyType,
      subtype: subtype,
      country: country,
      governorate: governorate,
      city: city,
      district: district,
      street: street,
      lat: lat,
      lng: lng,
      publisher: publisher,
      photographer: photographer,
      floorPlanEngineer: floorPlanEngineer,
      assignedName: assignedName,
      assignedId: assignedId,
      status: status ?? this.status,
      requiredAction: requiredAction ?? this.requiredAction,
      priority: priority,
      assignedAt: assignedAt,
      visitAt: visitAt,
      specialInstructions: specialInstructions,
      photoStream: photoStream,
      planStream: planStream,
      publishStream: publishStream,
      landAreaM2: landAreaM2,
      ownerClaimedBuiltM2: ownerClaimedBuiltM2,
      measuredBuiltM2: measuredBuiltM2 ?? this.measuredBuiltM2,
      floors: floors,
      units: units,
      streetWidthM: streetWidthM,
      frontageM: frontageM,
      yearBuilt: yearBuilt,
      developer: developer,
      contractor: contractor,
      rooms: rooms ?? this.rooms,
      nearby: nearby,
      projects: projects,
      renovations: renovations,
      inspection: inspection,
      conflicts: conflicts ?? this.conflicts,
      voice: voice ?? this.voice,
      corrections: corrections ?? this.corrections,
      versions: versions ?? this.versions,
      messages: messages ?? this.messages,
      audit: audit ?? this.audit,
      whatsSpecial: whatsSpecial ?? this.whatsSpecial,
      internalRisks: internalRisks,
      amenities: amenities,
      utilities: utilities,
      ownerPrice: ownerPrice,
      rentalNote: rentalNote,
      arrivalAt: arrivalAt ?? this.arrivalAt,
      arrivalLat: arrivalLat ?? this.arrivalLat,
      arrivalLng: arrivalLng ?? this.arrivalLng,
      sync: sync ?? this.sync,
    );
  }
}
