class PropertyAsset {
  const PropertyAsset({
    required this.id,
    required this.publicPropertyId,
    required this.pipelineStatus,
    this.propertyType,
    this.transactionType,
    this.source,
    this.ownerName,
    this.ownerPhone,
    this.officeId,
    this.city,
    this.addressText,
    this.latitude,
    this.longitude,
    this.priority = 'normal',
    this.notes,
    this.informationPct = 0,
    this.photographyPct = 0,
    this.threeDPct = 0,
    this.floorPlanPct = 0,
    this.isPublished = false,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String publicPropertyId;
  final String pipelineStatus;
  final String? propertyType;
  final String? transactionType;
  final String? source;
  final String? ownerName;
  final String? ownerPhone;
  final String? officeId;
  final String? city;
  final String? addressText;
  final double? latitude;
  final double? longitude;
  final String priority;
  final String? notes;
  final int informationPct;
  final int photographyPct;
  final int threeDPct;
  final int floorPlanPct;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get overallPct {
    final sum = informationPct + photographyPct + threeDPct + floorPlanPct;
    return (sum / 4).round();
  }

  factory PropertyAsset.fromMap(Map<String, dynamic> d) {
    return PropertyAsset(
      id: d['id']?.toString() ?? '',
      publicPropertyId: d['public_property_id']?.toString() ?? '',
      pipelineStatus: d['pipeline_status'] as String? ?? 'request_created',
      propertyType: d['property_type'] as String?,
      transactionType: d['transaction_type'] as String?,
      source: d['source'] as String?,
      ownerName: d['owner_name'] as String?,
      ownerPhone: d['owner_phone'] as String?,
      officeId: d['office_id']?.toString(),
      city: d['city'] as String?,
      addressText: d['address_text'] as String?,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      priority: d['priority'] as String? ?? 'normal',
      notes: d['notes'] as String?,
      informationPct: (d['information_pct'] as num?)?.toInt() ?? 0,
      photographyPct: (d['photography_pct'] as num?)?.toInt() ?? 0,
      threeDPct: (d['three_d_pct'] as num?)?.toInt() ?? 0,
      floorPlanPct: (d['floor_plan_pct'] as num?)?.toInt() ?? 0,
      isPublished: d['is_published'] as bool? ?? false,
      publishedAt: d['published_at'] != null
          ? DateTime.tryParse(d['published_at'].toString())
          : null,
      createdAt: d['created_at'] != null
          ? DateTime.tryParse(d['created_at'].toString())
          : null,
      updatedAt: d['updated_at'] != null
          ? DateTime.tryParse(d['updated_at'].toString())
          : null,
    );
  }
}

class PublishingDashboardStats {
  const PublishingDashboardStats({
    required this.newRequests,
    required this.informationPending,
    required this.photographyPending,
    required this.floorPlanPending,
    required this.reviewRequired,
    required this.readyToPublish,
    required this.publishedToday,
    required this.needsAttention,
  });

  final int newRequests;
  final int informationPending;
  final int photographyPending;
  final int floorPlanPending;
  final int reviewRequired;
  final int readyToPublish;
  final int publishedToday;
  final int needsAttention;
}

class PropertyRoomDraft {
  PropertyRoomDraft({
    this.id,
    this.roomType = 'bedroom',
    this.roomName = '',
    this.floorLabel = 'ground',
    this.lengthM,
    this.widthM,
    this.heightM,
    this.windowsCount,
    this.doorsCount,
    this.flooring,
    this.condition,
    this.orientation,
    this.notes,
  });

  String? id;
  String roomType;
  String roomName;
  String floorLabel;
  double? lengthM;
  double? widthM;
  double? heightM;
  int? windowsCount;
  int? doorsCount;
  String? flooring;
  String? condition;
  String? orientation;
  String? notes;

  double? get areaM2 {
    if (lengthM == null || widthM == null) return null;
    return double.parse((lengthM! * widthM!).toStringAsFixed(2));
  }

  Map<String, dynamic> toInsert(String propertyAssetId) => {
        'property_asset_id': propertyAssetId,
        'room_type': roomType,
        'room_name': roomName,
        'floor_label': floorLabel,
        'length_m': lengthM,
        'width_m': widthM,
        'height_m': heightM,
        'area_m2': areaM2,
        'windows_count': windowsCount,
        'doors_count': doorsCount,
        'flooring': flooring,
        'condition': condition,
        'orientation': orientation,
        'notes': notes,
      };
}
