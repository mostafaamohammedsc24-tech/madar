import 'package:flutter/foundation.dart';

import '../../data/field_case_seed.dart';
import '../../domain/enums/field_enums.dart';
import '../../domain/models/field_models.dart';

class FieldSectionScore {
  const FieldSectionScore({required this.id, required this.done, required this.total});
  final String id;
  final int done;
  final int total;
  bool get complete => total > 0 && done >= total;
}

class FieldWorkspaceController extends ChangeNotifier {
  final List<FieldJob> _jobs = [];
  String _search = '';
  FieldWorkAction? _action;
  bool loaded = false;
  SyncState sync = SyncState.synced;

  String get search => _search;
  FieldWorkAction? get actionFilter => _action;
  int get unreadCount =>
      _jobs.where((j) => j.requiredAction == FieldWorkAction.correctionRequested).length;

  Future<void> load() async {
    if (loaded) return;
    _jobs
      ..clear()
      ..addAll(FieldCaseSeed.queue());
    loaded = true;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  void setAction(FieldWorkAction? a) {
    _action = a;
    notifyListeners();
  }

  List<FieldJob> _filter(List<FieldJob> input) {
    var list = input;
    if (_action != null) list = list.where((j) => j.requiredAction == _action).toList();
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((j) {
      final blob = [j.propertyId, j.requestNumber, j.address, j.propertyType, j.city].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  List<FieldJob> get actionable {
    final list = _filter(_jobs.where((j) => j.status != FieldReportStatus.approved && j.status != FieldReportStatus.archived).toList());
    list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return list;
  }

  List<FieldJob> get allFiltered => _filter(_jobs);
  List<FieldJob> get archive =>
      _filter(_jobs.where((j) => j.status == FieldReportStatus.approved || j.status == FieldReportStatus.archived).toList());

  FieldJob? byId(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id || j.propertyId == id);
    } catch (_) {
      return null;
    }
  }

  void _replace(FieldJob j) {
    final i = _jobs.indexWhere((x) => x.id == j.id);
    if (i >= 0) _jobs[i] = j;
    notifyListeners();
  }

  void audit(FieldJob j, String action) {
    _replace(j.copyWith(
      audit: [
        ...j.audit,
        FieldAudit(
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

  List<FieldSectionScore> sections(FieldJob j) {
    return [
      FieldSectionScore(id: 'identity', done: j.propertyType.isNotEmpty ? 1 : 0, total: 1),
      FieldSectionScore(id: 'location', done: j.lat != 0 && j.address.isNotEmpty ? 1 : 0, total: 1),
      FieldSectionScore(id: 'land', done: j.landAreaM2 != null ? 1 : 0, total: 1),
      FieldSectionScore(id: 'building', done: j.measuredBuiltM2 != null ? 1 : 0, total: 1),
      FieldSectionScore(id: 'rooms', done: j.rooms.length, total: j.rooms.length < 4 ? 4 : j.rooms.length),
      FieldSectionScore(id: 'utilities', done: j.utilities.isNotEmpty ? 1 : 0, total: 1),
      FieldSectionScore(id: 'neighborhood', done: j.nearby.where((n) => n.verified).length, total: j.nearby.isEmpty ? 1 : j.nearby.length),
      FieldSectionScore(id: 'development', done: j.projects.where((p) => p.verified).length, total: j.projects.isEmpty ? 1 : j.projects.length),
      FieldSectionScore(id: 'inspection', done: j.inspection.length, total: j.inspection.isEmpty ? 5 : j.inspection.length),
    ];
  }

  int completionPercent(FieldJob j) {
    final s = sections(j);
    final total = s.fold<int>(0, (a, b) => a + b.total);
    final done = s.fold<int>(0, (a, b) => a + b.done.clamp(0, b.total));
    if (total == 0) return 0;
    return ((done / total) * 100).round();
  }

  int qualityPercent(FieldJob j) => completionPercent(j);

  int verifiedShare(FieldJob j) {
    final v = j.nearby.where((n) => n.verified).length + j.projects.where((p) => p.verified).length;
    final t = j.nearby.length + j.projects.length;
    if (t == 0) return 0;
    return ((v / t) * 100).round();
  }

  void confirmArrival(String jobId) {
    final j = byId(jobId);
    if (j == null || j.isLocked) return;
    _replace(j.copyWith(
      arrivalAt: DateTime.now(),
      arrivalLat: j.lat + 0.0002,
      arrivalLng: j.lng - 0.0001,
      status: FieldReportStatus.inProgress,
      requiredAction: FieldWorkAction.inProgress,
      sync: SyncState.saved,
    ));
    audit(byId(jobId)!, 'location_confirmed');
  }

  void addRoom(String jobId, [FieldRoom? room]) {
    final next = room ??
        FieldRoom(
          id: 'r-${DateTime.now().microsecondsSinceEpoch}',
          name: 'حمام',
          type: 'bathroom',
          floor: 'أول',
          lengthM: 2.4,
          widthM: 1.8,
          heightM: 2.6,
          condition: RoomCondition.good,
        );
    final j = byId(jobId);
    if (j == null || j.isLocked) return;
    _replace(j.copyWith(rooms: [...j.rooms, next], sync: SyncState.saving));
    audit(byId(jobId)!, 'room_added');
  }

  void setMeasuredArea(String jobId, double m2) {
    final j = byId(jobId);
    if (j == null || j.isLocked) return;
    var conflicts = [...j.conflicts];
    if (j.ownerClaimedBuiltM2 != null && (j.ownerClaimedBuiltM2! - m2).abs() > 5) {
      if (!conflicts.any((c) => c.field == 'مساحة البناء' && !c.resolved)) {
        conflicts.add(FieldConflict(
          id: 'c-${DateTime.now().microsecondsSinceEpoch}',
          field: 'مساحة البناء',
          left: 'المالك: ${j.ownerClaimedBuiltM2} م²',
          right: 'القياس: $m2 م²',
        ));
      }
    }
    _replace(j.copyWith(measuredBuiltM2: m2, conflicts: conflicts, sync: SyncState.saved));
    audit(byId(jobId)!, 'measurement_added');
  }

  void resolveConflict(String jobId, String id, String resolution) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(
      conflicts: j.conflicts
          .map((c) => c.id == id ? FieldConflict(id: c.id, field: c.field, left: c.left, right: c.right, resolved: true, resolution: resolution) : c)
          .toList(),
    ));
    audit(j, 'conflict_resolved');
  }

  void confirmTranscription(String jobId, String noteId) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(
      voice: j.voice
          .map((v) => v.id == noteId
              ? VoiceNote(id: v.id, body: v.body, at: v.at, transcription: v.transcription, transcriptionConfirmed: true)
              : v)
          .toList(),
    ));
  }

  void addVoice(String jobId, String text) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(voice: [
      ...j.voice,
      VoiceNote(id: 'vn-${DateTime.now().microsecondsSinceEpoch}', body: text, at: DateTime.now(), transcription: text, transcriptionConfirmed: true),
    ]));
    audit(j, 'voice_note_added');
  }

  void addMessage(String jobId, FieldChannel ch, String body) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(messages: [
      ...j.messages,
      FieldMessage(id: 'm-${DateTime.now().microsecondsSinceEpoch}', channel: ch, body: '${j.propertyId} · ${j.requestNumber}\n$body', author: j.assignedId, at: DateTime.now()),
    ]));
  }

  void respondCorrection(String jobId, String id, String response) {
    final j = byId(jobId);
    if (j == null) return;
    _replace(j.copyWith(
      corrections: j.corrections
          .map((c) => c.id == id
              ? FieldCorrection(id: c.id, field: c.field, reason: c.reason, requestedBy: c.requestedBy, at: c.at, priority: c.priority, response: response)
              : c)
          .toList(),
    ));
    audit(j, 'correction_completed');
  }

  bool canSubmit(FieldJob j) {
    if (j.isLocked) return false;
    if (j.arrivalAt == null) return false;
    if (j.measuredBuiltM2 == null) return false;
    if (j.rooms.length < 3) return false;
    if (j.conflicts.any((c) => !c.resolved)) return false;
    if (j.corrections.any((c) => c.response == null)) return false;
    return completionPercent(j) >= 70;
  }

  void submit(String jobId) {
    final j = byId(jobId);
    if (j == null || !canSubmit(j)) return;
    _replace(j.copyWith(
      status: FieldReportStatus.submitted,
      requiredAction: FieldWorkAction.submitted,
      versions: [
        ...j.versions,
        FieldVersion(number: j.versions.length + 1, by: j.assignedId, at: DateTime.now(), reason: 'تسليم لموظف النشر', status: FieldReportStatus.submitted),
      ],
    ));
    audit(byId(jobId)!, 'report_submitted');
  }

  bool get mayPublishListing => false;

  String reportText(FieldJob j) {
    final buf = StringBuffer()
      ..writeln('مدار — تقرير معلومات العقار')
      ..writeln('${j.propertyId} · ${j.requestNumber}')
      ..writeln(j.address)
      ..writeln('النوع: ${j.propertyType} / ${j.subtype}')
      ..writeln('الأرض: ${j.landAreaM2} م² · البناء المقاس: ${j.measuredBuiltM2 ?? '—'} م² · ادعاء المالك: ${j.ownerClaimedBuiltM2 ?? '—'} م²')
      ..writeln('الطوابق: ${j.floors} · الواجهة: ${j.frontageM} م · الشارع: ${j.streetWidthM} م')
      ..writeln('المطوّر: ${j.developer ?? '—'} · المقاول: ${j.contractor ?? '—'}')
      ..writeln('إكمال البيانات: ${completionPercent(j)}٪');
    for (final r in j.rooms) {
      buf.writeln('غرفة ${r.name}: ${r.lengthM ?? '—'}×${r.widthM ?? '—'} م · ${r.areaM2?.toStringAsFixed(1) ?? '—'} م²');
    }
    buf.writeln('ما يميز: ${j.whatsSpecial.join(' · ')}');
    buf.writeln('ملاحظات داخلية: ${j.internalRisks.join(' · ')}');
    return buf.toString();
  }
}
