import 'package:flutter/foundation.dart';

import '../../data/photo_case_seed.dart';
import '../../domain/enums/photo_enums.dart';
import '../../domain/models/photo_models.dart';

class PhotoWorkspaceController extends ChangeNotifier {
  final List<PhotoJob> _jobs = [];
  String _search = '';
  PhotoWorkAction? _action;
  String? activeRoomId;
  bool loaded = false;
  SyncState sync = SyncState.synced;

  String get search => _search;
  PhotoWorkAction? get actionFilter => _action;
  int get unreadCount =>
      _jobs.where((j) => j.requiredAction == PhotoWorkAction.correctionRequested).length;

  Future<void> load() async {
    if (loaded) return;
    _jobs
      ..clear()
      ..addAll(PhotoCaseSeed.queue());
    loaded = true;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  void setAction(PhotoWorkAction? a) {
    _action = a;
    notifyListeners();
  }

  void selectRoom(String? id) {
    activeRoomId = id;
    notifyListeners();
  }

  List<PhotoJob> _filter(List<PhotoJob> input) {
    var list = input;
    if (_action != null) list = list.where((j) => j.requiredAction == _action).toList();
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((j) {
      final blob = [j.propertyId, j.requestNumber, j.address, j.propertyType].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  List<PhotoJob> get actionable {
    final list = _filter(_jobs.where((j) => j.status != PhotoJobStatus.approved && j.status != PhotoJobStatus.archived).toList());
    list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return list;
  }

  List<PhotoJob> get allFiltered => _filter(_jobs);
  List<PhotoJob> get archive =>
      _filter(_jobs.where((j) => j.status == PhotoJobStatus.approved || j.status == PhotoJobStatus.archived).toList());
  List<PhotoAsset> get allMedia => _jobs.expand((j) => j.assets).toList();
  List<PhotoJob> get tours => _jobs.where((j) => j.points.isNotEmpty).toList();

  PhotoJob? byId(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id || j.propertyId == id);
    } catch (_) {
      return null;
    }
  }

  void _replace(PhotoJob j) {
    final i = _jobs.indexWhere((x) => x.id == j.id);
    if (i >= 0) _jobs[i] = j;
    notifyListeners();
  }

  void audit(PhotoJob j, String action) {
    _replace(j.copyWith(
      audit: [
        ...j.audit,
        PhotoAudit(
          id: '${j.id}-$action-${DateTime.now().microsecondsSinceEpoch}',
          action: action,
          employeeId: j.assignedId,
          employeeName: j.assignedName,
          at: DateTime.now(),
          propertyId: j.propertyId,
          requestId: j.requestNumber,
        ),
      ],
      sync: SyncState.synced,
    ));
  }

  int photoPercent(PhotoJob j) {
    if (j.requiredPhotoCount == 0) return 0;
    return ((j.donePhotoCount / j.requiredPhotoCount) * 100).round();
  }

  int tourPercent(PhotoJob j) {
    if (j.rooms.isEmpty) return 0;
    final covered = j.points.map((p) => p.roomId).toSet().length;
    return ((covered / j.rooms.length) * 100).round().clamp(0, 100);
  }

  int packagePercent(PhotoJob j) {
    return ((photoPercent(j) * 0.7) + (tourPercent(j) * 0.3)).round();
  }

  void confirmArrival(String jobId) {
    final j = byId(jobId);
    if (j == null || j.isLocked) return;
    _replace(j.copyWith(
      arrivalAt: DateTime.now(),
      status: PhotoJobStatus.inProgress,
      requiredAction: PhotoWorkAction.capturing,
      sync: SyncState.saved,
    ));
    audit(byId(jobId)!, 'arrival_confirmed');
  }

  void captureShot(String jobId, String roomId, ShotType type) {
    final j = byId(jobId);
    if (j == null || j.isLocked) return;
    final rooms = j.rooms.map((r) {
      if (r.id != roomId) return r;
      return PhotoRoom(
        id: r.id,
        floor: r.floor,
        name: r.name,
        notes: r.notes,
        requiredShots: r.requiredShots
            .map((s) => s.type == type ? ShotRequirement(type: s.type, done: true) : s)
            .toList(),
      );
    }).toList();
    final seq = j.assets.length + 1;
    final asset = PhotoAsset(
      id: 'IMG-${3800 + seq}',
      label: 'IMG-${3800 + seq}',
      category: roomId == 'street' || roomId == 'facade' || roomId == 'garden' ? PhotoCategory.exterior : PhotoCategory.interior,
      roomId: roomId,
      shot: type,
      sequence: seq,
      visibility: MediaVisibility.public_,
      status: MediaStatus.uploaded,
      at: DateTime.now(),
      color: 0xFF003EC7,
    );
    _replace(j.copyWith(rooms: rooms, assets: [...j.assets, asset], queued: j.queued, sync: SyncState.saving));
    audit(byId(jobId)!, 'photo_captured');
  }

  void markInternal(String jobId, String assetId) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(
      assets: j.assets
          .map((a) => a.id == assetId
              ? PhotoAsset(
                  id: a.id,
                  label: a.label,
                  category: a.category,
                  roomId: a.roomId,
                  shot: a.shot,
                  sequence: a.sequence,
                  visibility: MediaVisibility.internal,
                  status: MediaStatus.internal,
                  at: a.at,
                  qualityWarning: a.qualityWarning,
                  color: a.color,
                  tourPointId: a.tourPointId,
                )
              : a)
          .toList(),
    ));
  }

  void addTourPoint(String jobId) {
    final j = byId(jobId);
    if (j == null || j.isLocked) return;
    final missing = j.rooms.where((r) => !j.points.any((p) => p.roomId == r.id)).toList();
    if (missing.isEmpty) return;
    final r = missing.first;
    _replace(j.copyWith(points: [
      ...j.points,
      TourPoint(id: 'P-${(j.points.length + 1).toString().padLeft(2, '0')}', roomId: r.id, roomName: r.name, status: 'جديد'),
    ]));
    audit(byId(jobId)!, '3d_point_added');
  }

  void addPano(String jobId, String roomId) {
    final j = byId(jobId);
    if (j == null || j.isLocked) return;
    final seq = j.assets.length + 1;
    _replace(j.copyWith(assets: [
      ...j.assets,
      PhotoAsset(
        id: '360-${seq.toString().padLeft(3, '0')}',
        label: '360-${seq.toString().padLeft(3, '0')}',
        category: PhotoCategory.pano360,
        roomId: roomId,
        shot: ShotType.wide,
        sequence: seq,
        visibility: MediaVisibility.public_,
        status: MediaStatus.processing,
        at: DateTime.now(),
        color: 0xFF001452,
      ),
    ], processing: j.processing + 1));
    audit(byId(jobId)!, '360_capture_added');
  }

  void respondCorrection(String jobId, String id, String response) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(
      corrections: j.corrections
          .map((c) => c.id == id
              ? PhotoCorrection(id: c.id, room: c.room, reason: c.reason, requestedBy: c.requestedBy, at: c.at, priority: c.priority, response: response)
              : c)
          .toList(),
    ));
    audit(j, 'correction_completed');
  }

  void addMessage(String jobId, PhotoChannel ch, String body) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(messages: [
      ...j.messages,
      PhotoMessage(id: 'm-${DateTime.now().microsecondsSinceEpoch}', channel: ch, body: '${j.propertyId} · ${j.requestNumber}\n$body', author: j.assignedId, at: DateTime.now()),
    ]));
  }

  bool canSubmit(PhotoJob j) {
    if (j.isLocked) return false;
    if (j.arrivalAt == null) return false;
    if (j.corrections.any((c) => c.response == null)) return false;
    if (j.failed > 0) return false;
    return photoPercent(j) >= 70;
  }

  void submit(String jobId) {
    final j = byId(jobId);
    if (j == null || !canSubmit(j)) return;
    _replace(j.copyWith(status: PhotoJobStatus.submitted, requiredAction: PhotoWorkAction.submitted));
    audit(byId(jobId)!, 'media_submitted');
  }

  bool get mayPublishListing => false;
}
