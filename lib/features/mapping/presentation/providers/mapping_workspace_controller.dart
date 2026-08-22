import 'package:flutter/foundation.dart';

import '../../data/mapping_case_seed.dart';
import '../../domain/enums/mapping_enums.dart';
import '../../domain/models/mapping_models.dart';

class MappingWorkspaceController extends ChangeNotifier {
  final List<MappingJob> _jobs = [];
  String _search = '';
  MappingWorkAction? _action;
  bool loaded = false;
  SyncState sync = SyncState.synced;

  String? selectedFloorId;
  String? selectedRoomId;
  String? selectedTool = 'select';
  bool showGrid = true;
  bool snap = true;
  final List<List<MappingFloor>> _undo = [];
  final List<List<MappingFloor>> _redo = [];

  String get search => _search;
  MappingWorkAction? get actionFilter => _action;
  int get unreadCount =>
      _jobs.where((j) => j.requiredAction == MappingWorkAction.correctionRequested || j.priority == MappingPriority.urgent).length;

  Future<void> load() async {
    if (loaded) return;
    _jobs
      ..clear()
      ..addAll(MappingCaseSeed.assignedQueue());
    loaded = true;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  void setAction(MappingWorkAction? a) {
    _action = a;
    notifyListeners();
  }

  List<MappingJob> get actionable {
    final list = _filter(_jobs.where((j) => j.status != MappingPlanStatus.published && j.status != MappingPlanStatus.archived).toList());
    list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return list;
  }

  List<MappingJob> get allFiltered => _filter(_jobs);
  List<MappingJob> get archive =>
      _filter(_jobs.where((j) => j.status == MappingPlanStatus.published || j.status == MappingPlanStatus.archived).toList());

  List<MappingJob> _filter(List<MappingJob> input) {
    var list = input;
    if (_action != null) list = list.where((j) => j.requiredAction == _action).toList();
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((j) {
      final blob = [j.propertyId, j.requestNumber, j.address, j.propertyType, j.city, j.status.name].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  MappingJob? byId(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id || j.propertyId == id);
    } catch (_) {
      return null;
    }
  }

  void _replace(MappingJob j) {
    final i = _jobs.indexWhere((x) => x.id == j.id);
    if (i >= 0) _jobs[i] = j;
    notifyListeners();
  }

  void audit(MappingJob j, String action) {
    final ev = MappingAudit(
      id: '${j.id}-$action-${DateTime.now().microsecondsSinceEpoch}',
      action: action,
      employeeId: j.engineerId,
      employeeName: j.assignedEngineer,
      at: DateTime.now(),
      propertyId: j.propertyId,
      requestId: j.requestNumber,
    );
    _replace(j.copyWith(audit: [...j.audit, ev], sync: SyncState.synced));
  }

  void _pushUndo(MappingJob j) {
    _undo.add(j.floors.map((f) => f).toList());
    if (_undo.length > 40) _undo.removeAt(0);
    _redo.clear();
  }

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void undo(String jobId) {
    final j = byId(jobId);
    if (j == null || _undo.isEmpty) return;
    _redo.add(j.floors);
    _replace(j.copyWith(floors: _undo.removeLast()));
  }

  void redo(String jobId) {
    final j = byId(jobId);
    if (j == null || _redo.isEmpty) return;
    _undo.add(j.floors);
    _replace(j.copyWith(floors: _redo.removeLast()));
  }

  MappingFloor? floorOf(MappingJob j) {
    if (j.floors.isEmpty) return null;
    final id = selectedFloorId;
    if (id == null) return j.floors.first;
    try {
      return j.floors.firstWhere((f) => f.id == id);
    } catch (_) {
      return j.floors.first;
    }
  }

  void selectFloor(String id) {
    selectedFloorId = id;
    selectedRoomId = null;
    notifyListeners();
  }

  void selectRoom(String? id) {
    selectedRoomId = id;
    notifyListeners();
  }

  void setTool(String tool) {
    selectedTool = tool;
    notifyListeners();
  }

  void toggleGrid() {
    showGrid = !showGrid;
    notifyListeners();
  }

  void toggleSnap() {
    snap = !snap;
    notifyListeners();
  }

  void addRoomRect(String jobId, {required double x, required double y, required double w, required double h, required RoomKind kind}) {
    final j = byId(jobId);
    if (j == null || j.isArchived) return;
    var floor = floorOf(j);
    if (floor == null) return;
    _pushUndo(j);
    final id = 'r-${DateTime.now().microsecondsSinceEpoch}';
    final room = MappingRoom(
      id: id,
      names: NamedI18n(ar: 'غرفة', en: 'Room', ku: 'ژوور'),
      kind: kind,
      floorId: floor.id,
      polygon: [
        MappingPoint(x: x, y: y),
        MappingPoint(x: x + w, y: y),
        MappingPoint(x: x + w, y: y + h),
        MappingPoint(x: x, y: y + h),
      ],
      lengthM: w,
      widthM: h,
      heightM: floor.ceilingHeightM,
      measuredAreaM2: w * h,
    );
    floor = floor.copyWith(rooms: [...floor.rooms, room]);
    final floors = j.floors.map((f) => f.id == floor!.id ? floor : f).toList();
    _replace(j.copyWith(floors: floors, sync: SyncState.saved));
    selectedRoomId = id;
    audit(byId(jobId)!, 'room_created');
  }

  void moveRoom(String jobId, String roomId, double dx, double dy) {
    final j = byId(jobId);
    if (j == null) return;
    var floor = floorOf(j);
    if (floor == null) return;
    final rooms = floor.rooms.map((r) {
      if (r.id != roomId || r.locked) return r;
      return r.copyWith(
        polygon: r.polygon.map((p) => MappingPoint(x: p.x + dx, y: p.y + dy)).toList(),
      );
    }).toList();
    floor = floor.copyWith(rooms: rooms);
    _replace(j.copyWith(floors: j.floors.map((f) => f.id == floor!.id ? floor : f).toList(), sync: SyncState.saving));
  }

  void setRoomDims(String jobId, String roomId, {double? length, double? width, double? height, double? measured}) {
    final j = byId(jobId);
    if (j == null) return;
    _pushUndo(j);
    final floors = j.floors.map((f) {
      return f.copyWith(
        rooms: f.rooms.map((r) {
          if (r.id != roomId) return r;
          return r.copyWith(lengthM: length, widthM: width, heightM: height, measuredAreaM2: measured);
        }).toList(),
      );
    }).toList();
    _replace(j.copyWith(floors: floors));
    audit(byId(jobId)!, 'dimension_changed');
  }

  void connectPhoto(String jobId, String roomId, String photoId) {
    final j = byId(jobId);
    if (j == null) return;
    final floors = j.floors.map((f) {
      return f.copyWith(
        rooms: f.rooms.map((r) {
          if (r.id != roomId) return r;
          if (r.photoIds.contains(photoId)) return r;
          return r.copyWith(photoIds: [...r.photoIds, photoId]);
        }).toList(),
      );
    }).toList();
    _replace(j.copyWith(floors: floors));
    audit(j, 'photo_connected');
  }

  void connectTour(String jobId, String roomId, String tourId) {
    final j = byId(jobId);
    if (j == null) return;
    final floors = j.floors.map((f) {
      return f.copyWith(
        rooms: f.rooms.map((r) {
          if (r.id != roomId) return r;
          if (r.tourPointIds.contains(tourId)) return r;
          return r.copyWith(tourPointIds: [...r.tourPointIds, tourId]);
        }).toList(),
      );
    }).toList();
    _replace(j.copyWith(floors: floors));
    audit(j, '3d_point_connected');
  }

  void attachSource(String jobId, String fileName) {
    final j = byId(jobId);
    if (j == null) return;
    var floor = floorOf(j);
    if (floor == null) return;
    floor = floor.copyWith(sourceFile: fileName);
    _replace(j.copyWith(floors: j.floors.map((f) => f.id == floor!.id ? floor : f).toList()));
    audit(j, 'floor_plan_uploaded');
  }

  void addNote(String jobId, String body) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(notes: [
      ...j.notes,
      MappingNote(id: 'n-${DateTime.now().microsecondsSinceEpoch}', body: body, author: j.engineerId, at: DateTime.now()),
    ]));
  }

  void addMessage(String jobId, MappingChannel ch, String body) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(messages: [
      ...j.messages,
      MappingMessage(
        id: 'm-${DateTime.now().microsecondsSinceEpoch}',
        channel: ch,
        kind: MessageKind.text,
        body: '${j.propertyId} · ${j.requestNumber}\n$body',
        author: j.engineerId,
        at: DateTime.now(),
      ),
    ]));
  }

  void respondCorrection(String jobId, String corrId, String response) {
    final j = byId(jobId);
    if (j == null) return;
    final corrs = j.corrections.map((c) {
      if (c.id != corrId) return c;
      return MappingCorrection(id: c.id, issue: c.issue, requestedBy: c.requestedBy, at: c.at, priority: c.priority, response: response);
    }).toList();
    _replace(j.copyWith(corrections: corrs));
    audit(j, 'correction_completed');
  }

  List<ValidationItem> validate(MappingJob j) {
    final items = <ValidationItem>[];
    items.add(ValidationItem(ok: j.floors.isNotEmpty, label: 'تعريف طابق واحد على الأقل'));
    items.add(ValidationItem(ok: j.metrics.totalBuiltM2 > 0, label: 'مساحة البناء مسجَّلة'));
    items.add(ValidationItem(ok: j.metrics.landM2 > 0, label: 'مساحة الأرض مسجَّلة'));
    var roomsOk = true;
    var dimsOk = true;
    var heightOk = true;
    var photosOk = true;
    var tourOk = true;
    var geomOk = true;
    for (final f in j.floors) {
      if (f.rooms.isEmpty) roomsOk = false;
      for (final r in f.rooms) {
        if (r.lengthM == null || r.widthM == null) dimsOk = false;
        if (r.heightM == null) heightOk = false;
        if (r.needsMeasurementReview) geomOk = false;
        if (r.kind == RoomKind.living || r.kind == RoomKind.kitchen) {
          if (r.photoIds.isEmpty) photosOk = false;
          if (j.tourReady && r.tourPointIds.isEmpty) tourOk = false;
        }
        if (r.polygon.length < 3) geomOk = false;
      }
    }
    items.add(ValidationItem(ok: roomsOk, label: 'كل طابق يحتوي غرفاً'));
    items.add(ValidationItem(ok: dimsOk, label: 'أبعاد الغرف مكتملة (م)'));
    items.add(ValidationItem(ok: heightOk, label: 'ارتفاع السقف لكل غرفة', warning: !heightOk));
    items.add(ValidationItem(ok: geomOk, label: 'الهندسة والقياس متوافقان', warning: !geomOk));
    items.add(ValidationItem(ok: photosOk, label: 'ربط صور الغرف الرئيسية'));
    items.add(ValidationItem(ok: tourOk, label: 'ربط نقاط الجولة الثلاثية للغرف الرئيسية', warning: !tourOk));
    items.add(ValidationItem(ok: j.floors.every((f) => f.number >= -1), label: 'رقم الطابق موجود'));
    items.add(ValidationItem(ok: j.corrections.every((c) => c.response != null) || j.corrections.isEmpty, label: 'طلبات التصحيح مُجابة'));
    return items;
  }

  bool canSubmit(MappingJob j) {
    final v = validate(j);
    return v.where((i) => !i.warning).every((i) => i.ok) && j.status != MappingPlanStatus.published;
  }

  void submitToPublisher(String jobId) {
    final j = byId(jobId);
    if (j == null || !canSubmit(j)) return;
    final next = j.copyWith(
      status: MappingPlanStatus.readyForReview,
      requiredAction: MappingWorkAction.readyToSubmit,
      versions: [
        ...j.versions,
        MappingVersion(
          number: j.versions.length + 1,
          createdBy: j.engineerId,
          at: DateTime.now(),
          reason: 'تسليم للناشر',
          changes: 'تقرير هندسي ونسخة للمراجعة',
          status: MappingPlanStatus.readyForReview,
        ),
      ],
    );
    _replace(next);
    audit(next, 'submitted');
  }

  /// Engineer prepares data only — cannot publish the public listing.
  bool get engineerMayPublishListing => false;

  String measurementReport(MappingJob j) {
    final buf = StringBuffer()
      ..writeln('مدار — تقرير القياسات الهندسية')
      ..writeln('${j.propertyId} · ${j.requestNumber}')
      ..writeln('العنوان: ${j.address}')
      ..writeln('مساحة الأرض: ${j.metrics.landM2} م²')
      ..writeln('مسقط البناء: ${j.metrics.footprintM2} م²')
      ..writeln('إجمالي البناء: ${j.metrics.totalBuiltM2} م²')
      ..writeln('المساحة الصافية: ${j.metrics.usableM2} م²')
      ..writeln('ارتداد أمامي: ${j.metrics.frontSetbackM} م')
      ..writeln('عرض الشارع: ${j.metrics.streetWidthM} م')
      ..writeln('الشمال: ${j.metrics.north}');
    for (final f in j.floors) {
      buf.writeln('— ${f.names.ar} ${f.areaM2} م² —');
      for (final r in f.rooms) {
        buf.writeln('${r.names.ar}: ${r.calculatedAreaM2.toStringAsFixed(1)} م² · ${r.lengthM ?? '—'}×${r.widthM ?? '—'} م · سقف ${r.heightM ?? '—'} م');
      }
    }
    return buf.toString();
  }
}
