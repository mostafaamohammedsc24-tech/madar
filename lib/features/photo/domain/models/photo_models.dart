import '../enums/photo_enums.dart';

class PhotoStaff {
  const PhotoStaff({
    required this.id,
    required this.employeeId,
    required this.displayName,
    this.department = 'تصوير العقارات',
    this.specialization = 'تصوير ميداني وجولات ثلاثية الأبعاد',
  });
  final String id;
  final String employeeId;
  final String displayName;
  final String department;
  final String specialization;
}

class ShotRequirement {
  const ShotRequirement({required this.type, this.done = false});
  final ShotType type;
  final bool done;
}

class PhotoRoom {
  const PhotoRoom({
    required this.id,
    required this.floor,
    required this.name,
    required this.requiredShots,
    this.notes,
  });
  final String id;
  final String floor;
  final String name;
  final List<ShotRequirement> requiredShots;
  final String? notes;
  int get doneShots => requiredShots.where((s) => s.done).length;
  int get totalShots => requiredShots.length;
}

class PhotoAsset {
  const PhotoAsset({
    required this.id,
    required this.label,
    required this.category,
    required this.roomId,
    required this.shot,
    required this.sequence,
    required this.visibility,
    required this.status,
    required this.at,
    this.qualityWarning,
    this.duplicateOf,
    this.tourPointId,
    this.color = 0xFF3D5A80,
    this.replacedId,
  });
  final String id;
  final String label;
  final PhotoCategory category;
  final String roomId;
  final ShotType shot;
  final int sequence;
  final MediaVisibility visibility;
  final MediaStatus status;
  final DateTime at;
  final String? qualityWarning;
  final String? duplicateOf;
  final String? tourPointId;
  final int color;
  final String? replacedId;
}

class TourPoint {
  const TourPoint({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.status,
    this.panoId,
    this.photoIds = const [],
  });
  final String id;
  final String roomId;
  final String roomName;
  final String status;
  final String? panoId;
  final List<String> photoIds;
}

class PhotoCorrection {
  const PhotoCorrection({
    required this.id,
    required this.room,
    required this.reason,
    required this.requestedBy,
    required this.at,
    required this.priority,
    this.response,
  });
  final String id;
  final String room;
  final String reason;
  final String requestedBy;
  final DateTime at;
  final PhotoPriority priority;
  final String? response;
}

class PhotoMessage {
  const PhotoMessage({
    required this.id,
    required this.channel,
    required this.body,
    required this.author,
    required this.at,
  });
  final String id;
  final PhotoChannel channel;
  final String body;
  final String author;
  final DateTime at;
}

class PhotoAudit {
  const PhotoAudit({
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

class PhotoJob {
  const PhotoJob({
    required this.id,
    required this.propertyId,
    required this.requestNumber,
    required this.address,
    required this.propertyType,
    required this.lat,
    required this.lng,
    required this.publisher,
    required this.informationOfficer,
    required this.floorPlanEngineer,
    required this.assignedName,
    required this.assignedId,
    required this.status,
    required this.requiredAction,
    required this.priority,
    required this.assignedAt,
    required this.visitAt,
    required this.specialInstructions,
    required this.infoStream,
    required this.planStream,
    required this.publishStream,
    required this.rooms,
    required this.assets,
    required this.points,
    this.corrections = const [],
    this.messages = const [],
    this.audit = const [],
    this.story = const [],
    this.arrivalAt,
    this.sync = SyncState.synced,
    this.device = 'Insta360 X4',
    this.tourName = 'جولة العقار',
    this.queued = 0,
    this.failed = 0,
    this.processing = 0,
  });

  final String id;
  final String propertyId;
  final String requestNumber;
  final String address;
  final String propertyType;
  final double lat;
  final double lng;
  final String publisher;
  final String informationOfficer;
  final String floorPlanEngineer;
  final String assignedName;
  final String assignedId;
  final PhotoJobStatus status;
  final PhotoWorkAction requiredAction;
  final PhotoPriority priority;
  final DateTime assignedAt;
  final DateTime visitAt;
  final String specialInstructions;
  final StreamStatus infoStream;
  final StreamStatus planStream;
  final StreamStatus publishStream;
  final List<PhotoRoom> rooms;
  final List<PhotoAsset> assets;
  final List<TourPoint> points;
  final List<PhotoCorrection> corrections;
  final List<PhotoMessage> messages;
  final List<PhotoAudit> audit;
  final List<String> story;
  final DateTime? arrivalAt;
  final SyncState sync;
  final String device;
  final String tourName;
  final int queued;
  final int failed;
  final int processing;

  bool get isLocked => status == PhotoJobStatus.approved || status == PhotoJobStatus.archived;

  int get requiredPhotoCount => rooms.fold(0, (a, r) => a + r.totalShots);
  int get donePhotoCount => rooms.fold(0, (a, r) => a + r.doneShots);
  int get panoCount => assets.where((a) => a.category == PhotoCategory.pano360).length;
  int get publicCount => assets.where((a) => a.visibility == MediaVisibility.public_).length;
  int get internalCount => assets.where((a) => a.visibility != MediaVisibility.public_).length;

  PhotoJob copyWith({
    PhotoJobStatus? status,
    PhotoWorkAction? requiredAction,
    List<PhotoRoom>? rooms,
    List<PhotoAsset>? assets,
    List<TourPoint>? points,
    List<PhotoCorrection>? corrections,
    List<PhotoMessage>? messages,
    List<PhotoAudit>? audit,
    DateTime? arrivalAt,
    SyncState? sync,
    int? queued,
    int? failed,
    int? processing,
  }) {
    return PhotoJob(
      id: id,
      propertyId: propertyId,
      requestNumber: requestNumber,
      address: address,
      propertyType: propertyType,
      lat: lat,
      lng: lng,
      publisher: publisher,
      informationOfficer: informationOfficer,
      floorPlanEngineer: floorPlanEngineer,
      assignedName: assignedName,
      assignedId: assignedId,
      status: status ?? this.status,
      requiredAction: requiredAction ?? this.requiredAction,
      priority: priority,
      assignedAt: assignedAt,
      visitAt: visitAt,
      specialInstructions: specialInstructions,
      infoStream: infoStream,
      planStream: planStream,
      publishStream: publishStream,
      rooms: rooms ?? this.rooms,
      assets: assets ?? this.assets,
      points: points ?? this.points,
      corrections: corrections ?? this.corrections,
      messages: messages ?? this.messages,
      audit: audit ?? this.audit,
      story: story,
      arrivalAt: arrivalAt ?? this.arrivalAt,
      sync: sync ?? this.sync,
      device: device,
      tourName: tourName,
      queued: queued ?? this.queued,
      failed: failed ?? this.failed,
      processing: processing ?? this.processing,
    );
  }
}
