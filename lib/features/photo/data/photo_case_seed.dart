import '../domain/enums/photo_enums.dart';
import '../domain/models/photo_models.dart';

class PhotoCaseSeed {
  static const name = 'أحمد الخالدي';
  static const id = 'PHO-015';

  static List<ShotRequirement> shots({bool wide = true, bool corner = true, bool feature = true, bool detail = false, bool window = false}) {
    return [
      ShotRequirement(type: ShotType.wide, done: wide),
      ShotRequirement(type: ShotType.corner, done: corner),
      ShotRequirement(type: ShotType.feature, done: feature),
      ShotRequirement(type: ShotType.detail, done: detail),
      ShotRequirement(type: ShotType.windowView, done: window),
    ];
  }

  static List<PhotoJob> queue() {
    final now = DateTime(2026, 8, 22, 16);

    final villaRooms = [
      PhotoRoom(id: 'street', floor: 'خارج', name: 'الشارع', requiredShots: shots(detail: true, window: true)),
      PhotoRoom(id: 'facade', floor: 'خارج', name: 'الواجهة', requiredShots: shots(detail: true)),
      PhotoRoom(id: 'entrance', floor: 'أرضي', name: 'المدخل', requiredShots: shots(detail: true)),
      PhotoRoom(id: 'living', floor: 'أرضي', name: 'المعيشة', requiredShots: shots(detail: true, window: true)),
      PhotoRoom(id: 'kitchen', floor: 'أرضي', name: 'المطبخ', requiredShots: shots(wide: true, corner: true, feature: false, detail: true, window: false)),
      PhotoRoom(id: 'br1', floor: 'أرضي', name: 'غرفة نوم 1', requiredShots: shots()),
      PhotoRoom(id: 'br2', floor: 'أول', name: 'غرفة نوم 2', requiredShots: shots(wide: true, corner: false, feature: false)),
      PhotoRoom(id: 'master', floor: 'أول', name: 'النوم الرئيسية', requiredShots: shots(detail: true, window: true)),
      PhotoRoom(id: 'bath1', floor: 'أرضي', name: 'حمام أرضي', requiredShots: shots(feature: false, detail: true)),
      PhotoRoom(id: 'bath2', floor: 'أول', name: 'حمام أول', requiredShots: shots(wide: false, corner: false, feature: false)),
      PhotoRoom(id: 'garden', floor: 'خارج', name: 'الحديقة', requiredShots: shots(detail: true)),
    ];

    PhotoAsset a(String id, String room, ShotType shot, PhotoCategory cat, int seq, int color, {MediaVisibility vis = MediaVisibility.public_, String? warn, String? pano}) {
      return PhotoAsset(
        id: id,
        label: id,
        category: cat,
        roomId: room,
        shot: shot,
        sequence: seq,
        visibility: vis,
        status: warn == null ? MediaStatus.uploaded : MediaStatus.needsReview,
        at: now.subtract(Duration(minutes: seq * 3)),
        qualityWarning: warn,
        color: color,
        tourPointId: pano,
      );
    }

    final villaAssets = [
      a('IMG-3801', 'street', ShotType.wide, PhotoCategory.exterior, 1, 0xFF4A6FA5),
      a('IMG-3802', 'facade', ShotType.wide, PhotoCategory.exterior, 2, 0xFF166088),
      a('IMG-3803', 'entrance', ShotType.entranceView, PhotoCategory.exterior, 3, 0xFF4B6584),
      a('IMG-3812', 'living', ShotType.wide, PhotoCategory.interior, 4, 0xFFC8A27A),
      a('IMG-3813', 'living', ShotType.corner, PhotoCategory.interior, 5, 0xFFD4B896, pano: 'P-04'),
      a('IMG-3820', 'kitchen', ShotType.wide, PhotoCategory.room, 6, 0xFF8D99AE, warn: 'إضاءة منخفضة — مراجعة موصى بها'),
      a('IMG-3840', 'panel', ShotType.detail, PhotoCategory.technical, 7, 0xFF2F3E46, vis: MediaVisibility.technical),
      a('360-004', 'living', ShotType.wide, PhotoCategory.pano360, 8, 0xFF003EC7, pano: 'P-04'),
    ];

    final points = [
      const TourPoint(id: 'P-01', roomId: 'entrance', roomName: 'المدخل', status: 'جاهز', photoIds: ['IMG-3803']),
      const TourPoint(id: 'P-02', roomId: 'living', roomName: 'المعيشة', status: 'جاهز', panoId: '360-004', photoIds: ['IMG-3812', 'IMG-3813']),
      const TourPoint(id: 'P-03', roomId: 'kitchen', roomName: 'المطبخ', status: 'ناقص', photoIds: ['IMG-3820']),
      const TourPoint(id: 'P-04', roomId: 'living', roomName: 'المعيشة — زاوية', status: 'جاهز', panoId: '360-004', photoIds: ['IMG-3813']),
      const TourPoint(id: 'P-05', roomId: 'master', roomName: 'النوم الرئيسية', status: 'جاهز'),
      const TourPoint(id: 'P-06', roomId: 'garden', roomName: 'الحديقة', status: 'جاهز'),
    ];

    PhotoJob job({
      required String pid,
      required String req,
      required String addr,
      required String type,
      required PhotoJobStatus st,
      required PhotoWorkAction act,
      required PhotoPriority pri,
      required DateTime visit,
      List<PhotoRoom> rooms = const [],
      List<PhotoAsset> assets = const [],
      List<TourPoint> pts = const [],
      List<PhotoCorrection> corr = const [],
      DateTime? arrival,
      int queued = 0,
      int failed = 0,
      int processing = 0,
      StreamStatus info = StreamStatus.inProgress,
      StreamStatus plan = StreamStatus.pending,
      StreamStatus pub = StreamStatus.waiting,
    }) {
      return PhotoJob(
        id: pid,
        propertyId: pid,
        requestNumber: req,
        address: addr,
        propertyType: type,
        lat: 33.3152,
        lng: 44.3661,
        publisher: 'نادر الشمري · PUB-011',
        informationOfficer: 'سارة اليوسف · INF-0020',
        floorPlanEngineer: 'يوسف الراوي · MAP-0042',
        assignedName: name,
        assignedId: id,
        status: st,
        requiredAction: act,
        priority: pri,
        assignedAt: now.subtract(const Duration(days: 1)),
        visitAt: visit,
        specialInstructions: 'تصوير غرف كاملة بعدسات واسعة. التفاصيل الكهربائية داخلية فقط. لا تنشر البطاقة العامة.',
        infoStream: info,
        planStream: plan,
        publishStream: pub,
        rooms: rooms,
        assets: assets,
        points: pts,
        corrections: corr,
        story: const ['الشارع', 'الواجهة', 'المدخل', 'المعيشة', 'المطبخ', 'الغرف', 'الحمامات', 'الحديقة'],
        arrivalAt: arrival,
        queued: queued,
        failed: failed,
        processing: processing,
        messages: [
          PhotoMessage(id: '$pid-m1', channel: PhotoChannel.publisher, body: 'أكمل زاوية النافذة في المطبخ قبل التسليم.', author: 'نادر الشمري', at: now.subtract(const Duration(hours: 1))),
        ],
        audit: [
          PhotoAudit(id: '$pid-a', action: 'assignment_opened', employeeId: id, employeeName: name, at: now.subtract(const Duration(days: 1)), propertyId: pid, requestId: req),
        ],
      );
    }

    return [
      job(
        pid: 'PR-IQ-BGD-1029',
        req: 'REQ-PHO-2026-5839',
        addr: 'المنصور، شارع 14 رمضان، بغداد',
        type: 'فيلا',
        st: PhotoJobStatus.correctionRequired,
        act: PhotoWorkAction.correctionRequested,
        pri: PhotoPriority.urgent,
        visit: now.subtract(const Duration(hours: 2)),
        rooms: villaRooms,
        assets: villaAssets,
        pts: points,
        arrival: now.subtract(const Duration(hours: 3)),
        queued: 7,
        processing: 19,
        plan: StreamStatus.inProgress,
        corr: [
          PhotoCorrection(
            id: 'cr1',
            room: 'المطبخ',
            reason: 'إعادة تصوير المطبخ وإضافة زاوية النافذة.',
            requestedBy: 'نادر الشمري · PUB-011',
            at: now.subtract(const Duration(hours: 1)),
            priority: PhotoPriority.urgent,
          ),
        ],
      ),
      job(
        pid: 'PR-IQ-BGD-1104',
        req: 'REQ-PHO-2026-5901',
        addr: 'الكرادة، شارع 42، بغداد',
        type: 'منزل',
        st: PhotoJobStatus.inProgress,
        act: PhotoWorkAction.capturing,
        pri: PhotoPriority.priority,
        visit: now.add(const Duration(hours: 1)),
        rooms: villaRooms.take(6).toList(),
        arrival: now.subtract(const Duration(minutes: 40)),
        queued: 3,
      ),
      job(
        pid: 'PR-IQ-BGD-1188',
        req: 'REQ-PHO-2026-5910',
        addr: 'الجادرية، بغداد',
        type: 'شقة',
        st: PhotoJobStatus.visitScheduled,
        act: PhotoWorkAction.scheduledVisit,
        pri: PhotoPriority.normal,
        visit: now.add(const Duration(days: 1)),
        rooms: villaRooms.where((r) => r.floor != 'خارج' || r.id == 'facade').toList(),
      ),
      job(
        pid: 'PR-IQ-BGD-1210',
        req: 'REQ-PHO-2026-5922',
        addr: 'الحارثية، بغداد',
        type: 'مكتب',
        st: PhotoJobStatus.assigned,
        act: PhotoWorkAction.newAssignment,
        pri: PhotoPriority.priority,
        visit: now.add(const Duration(days: 2)),
      ),
      job(
        pid: 'PR-IQ-BGD-0901',
        req: 'REQ-PHO-2026-5100',
        addr: 'الأعظمية، بغداد',
        type: 'شقة',
        st: PhotoJobStatus.approved,
        act: PhotoWorkAction.completed,
        pri: PhotoPriority.normal,
        visit: now.subtract(const Duration(days: 8)),
        rooms: villaRooms.take(5).toList(),
        assets: villaAssets,
        pts: points,
        arrival: now.subtract(const Duration(days: 8)),
        info: StreamStatus.completed,
        plan: StreamStatus.completed,
        pub: StreamStatus.completed,
      ),
    ];
  }
}
