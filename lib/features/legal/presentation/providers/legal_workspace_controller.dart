import 'package:flutter/foundation.dart';

import '../../data/legal_case_seed.dart';
import '../../data/legal_clause_library.dart';
import '../../domain/enums/legal_enums.dart';
import '../../domain/models/legal_models.dart';

class LegalWorkspaceController extends ChangeNotifier {
  LegalWorkspaceController();

  final List<LegalCase> _cases = [];
  final List<LegalNotification> _notifications = [];
  String _search = '';
  LegalPriority? _priorityFilter;
  LegalWorkAction? _actionFilter;
  int _page = 0;
  static const pageSize = 40;
  bool _loaded = false;

  bool get loaded => _loaded;
  String get search => _search;
  LegalPriority? get priorityFilter => _priorityFilter;
  LegalWorkAction? get actionFilter => _actionFilter;
  List<LegalNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> load() async {
    if (_loaded) return;
    _cases
      ..clear()
      ..addAll(LegalCaseSeed.assignedQueue());
    _notifications
      ..clear()
      ..addAll(_buildNotifications());
    _loaded = true;
    notifyListeners();
  }

  List<LegalNotification> _buildNotifications() {
    final out = <LegalNotification>[];
    for (final c in _cases) {
      if (c.requiredAction == LegalWorkAction.reviewTransaction) {
        out.add(LegalNotification(
          id: 'n-${c.id}-assign',
          kind: 'assigned',
          title: 'معاملة جديدة مسندة',
          body: c.transactionNumber,
          at: c.lastActivity,
          caseId: c.id,
        ));
      }
      if (c.documents.any((d) => d.status == LegalDocumentStatus.uploaded || d.status == LegalDocumentStatus.underReview)) {
        out.add(LegalNotification(
          id: 'n-${c.id}-docs',
          kind: 'documents_uploaded',
          title: 'مستندات بانتظار المراجعة',
          body: c.transactionNumber,
          at: c.lastActivity,
          caseId: c.id,
        ));
      }
      if (c.buyer.confirmation == PartyConfirmation.confirmed) {
        out.add(LegalNotification(
          id: 'n-${c.id}-bc',
          kind: 'buyer_confirmed',
          title: 'أكد المشتري العقد',
          body: c.transactionNumber,
          at: c.lastActivity,
          caseId: c.id,
        ));
      }
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  void setSearch(String q) {
    _search = q;
    _page = 0;
    notifyListeners();
  }

  void setPriorityFilter(LegalPriority? p) {
    _priorityFilter = p;
    _page = 0;
    notifyListeners();
  }

  void setActionFilter(LegalWorkAction? a) {
    _actionFilter = a;
    _page = 0;
    notifyListeners();
  }

  List<LegalCase> get actionable {
    return _filter(_cases.where((c) => !c.handoffComplete).toList())
      ..sort((a, b) {
        final p = b.priority.index.compareTo(a.priority.index);
        if (p != 0) return p;
        final da = a.deadline ?? DateTime(2099);
        final db = b.deadline ?? DateTime(2099);
        return da.compareTo(db);
      });
  }

  List<LegalCase> pageOf(List<LegalCase> source) {
    final start = _page * pageSize;
    if (start >= source.length) return const [];
    final end = (start + pageSize).clamp(0, source.length);
    return source.sublist(start, end);
  }

  bool get hasMore {
    final n = _filter(_cases).length;
    return (_page + 1) * pageSize < n;
  }

  void nextPage() {
    if (hasMore) {
      _page++;
      notifyListeners();
    }
  }

  List<LegalCase> get allFiltered => _filter(_cases);

  List<LegalCase> get archiveCases =>
      _filter(_cases.where((c) => c.handoffComplete || c.stage == LegalContractStage.nextDepartment || c.stage == LegalContractStage.contractExecuted).toList());

  List<LegalCase> _filter(List<LegalCase> input) {
    var list = input;
    if (_priorityFilter != null) {
      list = list.where((c) => c.priority == _priorityFilter).toList();
    }
    if (_actionFilter != null) {
      list = list.where((c) => c.requiredAction == _actionFilter).toList();
    }
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((c) {
      final blob = [
        c.transactionNumber,
        c.contractNumber,
        c.propertyId,
        c.propertyAddress,
        c.buyer.phone,
        c.seller.phone,
        c.buyer.madarUserId,
        c.seller.madarUserId,
        c.buyer.name,
        c.seller.name,
        c.barcode ?? '',
        c.officeName,
        c.transactionType,
        c.statusLabel,
        c.lastActivity.toIso8601String(),
      ].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  LegalCase? byId(String id) {
    try {
      return _cases.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void _replace(LegalCase updated) {
    final i = _cases.indexWhere((c) => c.id == updated.id);
    if (i >= 0) _cases[i] = updated;
    notifyListeners();
  }

  void audit(LegalCase c, String action, String result) {
    final ev = LegalAuditEvent(
      id: '${c.id}-$action-${DateTime.now().microsecondsSinceEpoch}',
      action: action,
      result: result,
      lawyerId: c.lawyerEmployeeId,
      at: DateTime.now(),
      transactionNumber: c.transactionNumber,
    );
    _replace(c.copyWith(audit: [...c.audit, ev], lastActivity: DateTime.now()));
  }

  void markNotificationRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i < 0) return;
    final n = _notifications[i];
    _notifications[i] = LegalNotification(
      id: n.id,
      kind: n.kind,
      title: n.title,
      body: n.body,
      at: n.at,
      caseId: n.caseId,
      read: true,
    );
    notifyListeners();
  }

  void setDocumentStatus({
    required String caseId,
    required String docId,
    required LegalDocumentStatus status,
    String? reason,
    String? note,
  }) {
    final c = byId(caseId);
    if (c == null) return;
    final docs = c.documents.map((d) {
      if (d.id != docId) return d;
      final versions = [
        ...d.versions,
        LegalDocVersion(
          version: d.versions.length + 1,
          status: status,
          createdAt: DateTime.now(),
          rejectionReason: reason,
          previewLabel: d.name,
        ),
      ];
      return d.copyWith(status: status, notes: note ?? d.notes, versions: versions);
    }).toList();
    var updated = c.copyWith(documents: docs);
    audit(updated, 'document_${status.name}', reason ?? status.name);
  }

  void addRequirement({
    required String caseId,
    required String name,
    required String party,
    required bool required,
    String? notes,
  }) {
    final c = byId(caseId);
    if (c == null) return;
    final req = LegalDocumentReq(
      id: 'req-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      party: party,
      required: required,
      status: LegalDocumentStatus.requested,
      notes: notes,
    );
    final updated = c.copyWith(documents: [...c.documents, req]);
    _replace(updated);
    audit(updated, 'document_requested', name);
  }

  void setReviewCheck(String caseId, LegalReviewChecks checks) {
    final c = byId(caseId);
    if (c == null) return;
    _replace(c.copyWith(review: checks));
  }

  void saveDraft(String caseId, List<LegalContractSection> sections, String notes) {
    final c = byId(caseId);
    if (c == null) return;
    if (c.currentContract?.locked == true) return;
    final nextV = (c.currentContract?.version ?? 0) + 1;
    final ver = LegalContractVersion(
      version: nextV,
      status: ContractVersionStatus.draft,
      createdBy: c.lawyerEmployeeId,
      createdAt: DateTime.now(),
      modifiedBy: c.lawyerEmployeeId,
      modifiedAt: DateTime.now(),
      changeNotes: notes,
      sections: sections,
    );
    final updated = c.copyWith(contracts: [...c.contracts, ver]);
    _replace(updated);
    audit(updated, 'contract_version_created', 'V$nextV');
  }

  void insertClause(String caseId, String sectionId, AuthorizedClause clause) {
    final c = byId(caseId);
    if (c == null || c.currentContract == null || c.currentContract!.locked) return;
    final cur = c.currentContract!;
    final sections = cur.sections.map((s) {
      if (s.id != sectionId) return s;
      final insert =
          '\n\n[${clause.id} / ${clause.templateRef}]\n${clause.titleAr}\nالنص من القالب المعتمد لدى الإدارة القانونية.';
      return s.copyWith(body: '${s.body}$insert', clauseId: clause.id);
    }).toList();
    final contracts = [...c.contracts];
    contracts[contracts.length - 1] = cur.copyWith(
      sections: sections,
      modifiedAt: DateTime.now(),
      changeNotes: 'إدراج بند ${clause.id}',
    );
    final updated = c.copyWith(contracts: contracts);
    _replace(updated);
    audit(updated, 'clause_inserted', clause.id);
  }

  List<String> validateBeforeSend(LegalCase c) {
    final warnings = <String>[];
    if (c.price != c.authorizedAmount) {
      warnings.add('سعر العقار في العقد يختلف عن المبلغ المعتمد في المعاملة.');
    }
    if (c.buyer.identityStatus != VerificationWatch.verified) {
      warnings.add('هوية المشتري غير موثّقة.');
    }
    if (c.seller.identityStatus != VerificationWatch.verified) {
      warnings.add('هوية البائع غير موثّقة.');
    }
    final criticalRejected = c.documents.any(
      (d) => d.required && d.status == LegalDocumentStatus.rejected,
    );
    if (criticalRejected) warnings.add('يوجد مستند إلزامي مرفوض.');
    final missing = c.documents.any(
      (d) =>
          d.required &&
          d.status != LegalDocumentStatus.approved &&
          d.status != LegalDocumentStatus.notApplicable,
    );
    if (missing) warnings.add('المستندات الإلزامية غير مكتملة.');
    if (!c.review.allRequired) warnings.add('قائمة المراجعة القانونية غير مكتملة.');
    return warnings;
  }

  bool canApproveSend(LegalCase c) {
    return validateBeforeSend(c).isEmpty && !c.handoffComplete;
  }

  void approveAndSend(String caseId) {
    final c = byId(caseId);
    if (c == null || !canApproveSend(c) || c.currentContract == null) return;
    final cur = c.currentContract!;
    final sent = cur.copyWith(
      status: ContractVersionStatus.sent,
      sentToBuyer: true,
      sentToSeller: true,
      modifiedAt: DateTime.now(),
    );
    final contracts = [...c.contracts];
    contracts[contracts.length - 1] = sent;
    final updated = c.copyWith(
      contracts: contracts,
      stage: LegalContractStage.contractConfirmation,
      requiredAction: LegalWorkAction.awaitBuyerConfirmation,
      statusLabel: 'بانتظار تأكيد الطرفين',
      messages: [
        ...c.messages,
        LegalChatMessage(
          id: 'm-b-$caseId',
          channel: LegalMessageChannel.buyer,
          body: 'عقد ${c.contractNumber} — مراجعة العقد. المشتري: ${c.buyer.name}. العقار: ${c.propertyId}. مرفق PDF.',
          author: c.lawyerEmployeeId,
          at: DateTime.now(),
        ),
        LegalChatMessage(
          id: 'm-s-$caseId',
          channel: LegalMessageChannel.seller,
          body: 'عقد ${c.contractNumber} — مراجعة العقد. البائع: ${c.seller.name}. العقار: ${c.propertyId}. مرفق PDF.',
          author: c.lawyerEmployeeId,
          at: DateTime.now(),
        ),
      ],
    );
    _replace(updated);
    audit(updated, 'contract_approved_sent', 'buyer+seller');
  }

  void executeIfReady(String caseId) {
    final c = byId(caseId);
    if (c == null) return;
    final ready = c.buyer.confirmation == PartyConfirmation.confirmed &&
        c.seller.confirmation == PartyConfirmation.confirmed &&
        c.buyer.otpStatus == VerificationWatch.verified &&
        c.seller.otpStatus == VerificationWatch.verified &&
        c.buyer.faceStatus == VerificationWatch.verified &&
        c.seller.faceStatus == VerificationWatch.verified &&
        c.buyer.signatureStatus == SignatureWatch.signed &&
        c.seller.signatureStatus == SignatureWatch.signed;
    if (!ready) return;
    final cur = c.currentContract;
    List<LegalContractVersion> contracts = c.contracts;
    if (cur != null) {
      contracts = [...c.contracts];
      contracts[contracts.length - 1] = cur.copyWith(
        status: ContractVersionStatus.executed,
        locked: true,
        modifiedAt: DateTime.now(),
        changeNotes: 'تنفيذ وإقفال',
      );
    }
    final updated = c.copyWith(
      contracts: contracts,
      stage: LegalContractStage.nextDepartment,
      requiredAction: LegalWorkAction.handoff,
      statusLabel: 'مرحلة العقد مكتملة',
      handoffComplete: true,
      handoffTarget: 'closing',
    );
    _replace(updated);
    audit(updated, 'contract_executed', 'locked');
    audit(updated, 'handoff', 'closing_lawyer');
  }

  void addNote(String caseId, LegalNoteVisibility vis, String body) {
    final c = byId(caseId);
    if (c == null) return;
    final n = LegalNote(
      id: 'note-${DateTime.now().microsecondsSinceEpoch}',
      visibility: vis,
      body: body,
      author: c.lawyerEmployeeId,
      at: DateTime.now(),
    );
    _replace(c.copyWith(notes: [...c.notes, n]));
  }

  void addMessage(String caseId, LegalMessageChannel channel, String body) {
    final c = byId(caseId);
    if (c == null) return;
    final m = LegalChatMessage(
      id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
      channel: channel,
      body: body,
      author: c.lawyerEmployeeId,
      at: DateTime.now(),
      internal: channel == LegalMessageChannel.legalTeam,
    );
    _replace(c.copyWith(messages: [...c.messages, m]));
  }

  String contractPlainText(LegalCase c, {int? version}) {
    final ver = version == null
        ? c.currentContract
        : c.contracts.cast<LegalContractVersion?>().firstWhere(
            (v) => v!.version == version,
            orElse: () => c.currentContract,
          );
    if (ver == null) return '';
    final buf = StringBuffer()
      ..writeln('مدار')
      ..writeln('عقد ${c.contractNumber}')
      ..writeln('معاملة ${c.transactionNumber}')
      ..writeln('الإصدار ${ver.label}')
      ..writeln('التاريخ ${ver.modifiedAt}')
      ..writeln('—')
      ..writeln('المشتري: ${c.buyer.name}')
      ..writeln('البائع: ${c.seller.name}')
      ..writeln('العقار: ${c.propertyId} — ${c.propertyAddress}')
      ..writeln('الثمن المعتمد: ${c.authorizedAmount}')
      ..writeln('—');
    for (final s in ver.sections) {
      buf.writeln(s.title);
      buf.writeln(s.body);
      buf.writeln();
    }
    buf.writeln('مناطق التوقيع: المشتري / البائع');
    return buf.toString();
  }

  String diff(LegalContractVersion a, LegalContractVersion b) {
    final buf = StringBuffer();
    final mapA = {for (final s in a.sections) s.id: s.body};
    final mapB = {for (final s in b.sections) s.id: s.body};
    for (final id in ContractStructureCatalog.sectionIds) {
      final left = mapA[id] ?? '';
      final right = mapB[id] ?? '';
      if (left == right) continue;
      buf.writeln('— ${ContractStructureCatalog.title(id, 'ar')} —');
      buf.writeln('السابق:\n$left');
      buf.writeln('الحالي:\n$right');
      buf.writeln();
    }
    return buf.isEmpty ? 'لا اختلاف في النص.' : buf.toString();
  }
}
