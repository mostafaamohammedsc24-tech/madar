import 'package:flutter/foundation.dart';

import '../../data/closing_case_seed.dart';
import '../../domain/enums/closing_enums.dart';
import '../../domain/models/closing_models.dart';

class ClosingWorkspaceController extends ChangeNotifier {
  final List<ClosingCase> _cases = [];
  String _search = '';
  ClosingPriority? _priority;
  int _page = 0;
  static const pageSize = 40;
  bool loaded = false;

  String get search => _search;
  ClosingPriority? get priorityFilter => _priority;
  int get unreadCount =>
      _cases.where((c) => c.lifecycle != ClosingLifecycle.completed && (c.priority == ClosingPriority.urgent || c.priority == ClosingPriority.blocked)).length;

  List<ClosingCase> pageOf(List<ClosingCase> list) {
    final start = _page * pageSize;
    if (start >= list.length) return list;
    return list.skip(start).take(pageSize).toList();
  }

  Future<void> load() async {
    if (loaded) return;
    _cases
      ..clear()
      ..addAll(ClosingCaseSeed.assignedQueue());
    loaded = true;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    _page = 0;
    notifyListeners();
  }

  void setPriority(ClosingPriority? p) {
    _priority = p;
    _page = 0;
    notifyListeners();
  }

  List<ClosingCase> get actionable {
    final list = _filter(_cases.where((c) => c.lifecycle != ClosingLifecycle.completed).toList());
    list.sort((a, b) {
      final p = b.priority.index.compareTo(a.priority.index);
      if (p != 0) return p;
      return (a.deadline ?? DateTime(2099)).compareTo(b.deadline ?? DateTime(2099));
    });
    return list;
  }

  List<ClosingCase> get allFiltered => _filter(_cases);
  List<ClosingCase> get archive =>
      _filter(_cases.where((c) => c.lifecycle == ClosingLifecycle.completed).toList());

  List<ClosingCase> _filter(List<ClosingCase> input) {
    var list = input;
    if (_priority != null) list = list.where((c) => c.priority == _priority).toList();
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((c) {
      final blob = [
        c.transactionNumber,
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
        c.statusLabel,
        c.countryCode,
      ].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  ClosingCase? byId(String id) {
    try {
      return _cases.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void _replace(ClosingCase c) {
    final i = _cases.indexWhere((x) => x.id == c.id);
    if (i >= 0) _cases[i] = c;
    notifyListeners();
  }

  void audit(ClosingCase c, String action, String result) {
    final ev = ClosingAudit(
      id: '${c.id}-$action-${DateTime.now().microsecondsSinceEpoch}',
      action: action,
      result: result,
      employeeId: c.lawyerEmployeeId,
      employeeName: c.assignedLawyer,
      at: DateTime.now(),
      transactionNumber: c.transactionNumber,
    );
    _replace(c.copyWith(audit: [...c.audit, ev], lastActivity: DateTime.now()));
  }

  /// Bank workflow origin only — not a lawyer action.
  void applyBankConfirmationFromBank(String caseId, {required String amount, required String receipt, required String employee}) {
    final c = byId(caseId);
    if (c == null) return;
    if (c.lifecycle != ClosingLifecycle.escrowPending) return;
    final next = c.copyWith(
      escrow: c.escrow.copyWith(
        status: EscrowWatchStatus.depositConfirmed,
        confirmedAmount: amount,
        receiptId: receipt,
        bankEmployee: employee,
        confirmedAt: DateTime.now(),
      ),
      lifecycle: ClosingLifecycle.escrowConfirmed,
      timelineStage: ClosingTimelineStage.taxSettlement,
      requiredAction: ClosingWorkAction.taxPending,
      statusLabel: 'الضمان مؤكد — ضرائب معلّقة',
      responsibleDepartment: 'المالية',
    );
    _replace(next);
    audit(next, 'bank_confirmation_received', receipt);
  }

  void requestFinanceAdjustment(String caseId, String reason) {
    final c = byId(caseId);
    if (c == null) return;
    _replace(c.copyWith(
      messages: [
        ...c.messages,
        ClosingMessage(
          id: 'fin-$caseId-${DateTime.now().microsecondsSinceEpoch}',
          channel: ChannelDept.finance,
          body: '${c.transactionNumber}\nطلب تعديل مالي: $reason',
          author: c.lawyerEmployeeId,
          at: DateTime.now(),
          internal: true,
        ),
      ],
    ));
    audit(c, 'finance_adjustment_requested', reason);
  }

  void setProcedureStatus(String caseId, String procId, GovProcedureStatus status, {String? note, String? rejection}) {
    final c = byId(caseId);
    if (c == null || c.isClosed) return;
    final procs = c.procedures.map((p) {
      if (p.id != procId) return p;
      return p.copyWith(status: status, notes: note, rejectionReason: rejection, submittedAt: DateTime.now());
    }).toList();
    var life = c.lifecycle;
    var action = c.requiredAction;
    var stage = c.timelineStage;
    if (status == GovProcedureStatus.completed &&
        procs.every((p) => p.status == GovProcedureStatus.completed)) {
      life = ClosingLifecycle.ownershipTransferPending;
      action = ClosingWorkAction.transferAppointmentPending;
      stage = ClosingTimelineStage.ownershipTransfer;
    }
    final next = c.copyWith(procedures: procs, lifecycle: life, requiredAction: action, timelineStage: stage);
    _replace(next);
    audit(next, 'government_procedure_${status.name}', procId);
  }

  void setDeedStatus(String caseId, String docId, DeedReviewStatus status, {String? reason}) {
    final c = byId(caseId);
    if (c == null || c.isClosed) return;
    final docs = c.documents.map((d) {
      if (d.id != docId) return d;
      return d.copyWith(
        status: status,
        versions: [
          ...d.versions,
          ClosingDocVersion(version: d.versions.length + 1, status: status, at: DateTime.now(), reason: reason),
        ],
      );
    }).toList();
    var life = c.lifecycle;
    var action = c.requiredAction;
    var stage = c.timelineStage;
    final deedOk = docs.where((d) => d.kind == 'deed').every((d) => d.status == DeedReviewStatus.approved) ||
        c.workflow.skipOwnershipDocument;
    if (status == DeedReviewStatus.approved && deedOk) {
      life = ClosingLifecycle.ownershipDocumentVerified;
      action = ClosingWorkAction.settlementPending;
      stage = ClosingTimelineStage.finalSettlement;
    }
    final next = c.copyWith(documents: docs, lifecycle: life, requiredAction: action, timelineStage: stage);
    _replace(next);
    audit(next, 'document_${status.name}', reason ?? docId);
  }

  void escalate(String caseId, ChannelDept dept, String reason) {
    final c = byId(caseId);
    if (c == null) return;
    final next = c.copyWith(
      priority: ClosingPriority.urgent,
      messages: [
        ...c.messages,
        ClosingMessage(
          id: 'esc-$caseId',
          channel: dept,
          body: '${c.transactionNumber}\nتصعيد: $reason',
          author: c.lawyerEmployeeId,
          at: DateTime.now(),
          internal: true,
        ),
      ],
    );
    _replace(next);
    audit(next, 'escalated', '${dept.name}: $reason');
  }

  Map<String, bool> closingChecklist(ClosingCase c) {
    final deedOk = c.workflow.skipOwnershipDocument ||
        c.documents.any((d) => d.kind == 'deed' && d.status == DeedReviewStatus.approved) ||
        c.lifecycle.index >= ClosingLifecycle.ownershipDocumentVerified.index;
    return {
      'contract': true,
      'escrow': c.escrow.status == EscrowWatchStatus.depositConfirmed,
      'tax': c.finance.taxPaid || c.lifecycle.index >= ClosingLifecycle.governmentProcedures.index,
      'gov': c.procedures.isEmpty || c.procedures.every((p) => p.status == GovProcedureStatus.completed) || c.lifecycle.index >= ClosingLifecycle.ownershipTransferPending.index,
      'transfer': c.lifecycle.index >= ClosingLifecycle.ownershipTransferCompleted.index || c.lifecycle.index >= ClosingLifecycle.ownershipDocumentPending.index || c.lifecycle == ClosingLifecycle.finalReview,
      'deed': deedOk || c.lifecycle == ClosingLifecycle.finalReview,
      'settlement': c.finance.settlementComplete || c.lifecycle == ClosingLifecycle.finalReview,
      'receipts': c.receipts.isNotEmpty || c.lifecycle == ClosingLifecycle.finalReview,
      'final': c.blockedReason == null && c.priority != ClosingPriority.blocked,
    };
  }

  bool canClose(ClosingCase c) {
    if (c.isClosed) return false;
    return closingChecklist(c).values.every((v) => v) &&
        (c.lifecycle == ClosingLifecycle.finalReview || c.requiredAction == ClosingWorkAction.readyToClose);
  }

  void completePhysicalTransfer(String caseId) {
    final c = byId(caseId);
    if (c == null || c.isClosed) return;
    if (c.lifecycle.index < ClosingLifecycle.ownershipTransferPending.index) return;
    final skipDeed = c.workflow.skipOwnershipDocument;
    final next = c.copyWith(
      lifecycle: skipDeed ? ClosingLifecycle.ownershipDocumentVerified : ClosingLifecycle.ownershipDocumentPending,
      timelineStage: skipDeed ? ClosingTimelineStage.finalSettlement : ClosingTimelineStage.ownershipDocument,
      requiredAction: skipDeed ? ClosingWorkAction.settlementPending : ClosingWorkAction.ownershipDocVerification,
      statusLabel: skipDeed ? 'النقل مكتمل — بانتظار التسوية' : 'النقل مكتمل — بانتظار سند الملكية',
      responsibleDepartment: skipDeed ? 'المالية' : 'محامي الإغلاق',
      appointment: c.appointment.copyWith(status: 'completed'),
    );
    _replace(next);
    audit(next, 'ownership_transfer_completed', c.appointment.mode);
  }

  void closeTransaction(String caseId) {
    final c = byId(caseId);
    if (c == null || !canClose(c)) return;
    final next = c.copyWith(
      lifecycle: ClosingLifecycle.completed,
      timelineStage: ClosingTimelineStage.closed,
      requiredAction: ClosingWorkAction.archived,
      statusLabel: 'معاملة مكتملة',
      responsibleDepartment: 'الأرشيف',
      closedAt: DateTime.now(),
      finalOwner: c.buyer.name,
      priority: ClosingPriority.normal,
    );
    _replace(next);
    audit(next, 'transaction_closed', 'completed');
  }

  void addNote(String caseId, bool internal, String body) {
    final c = byId(caseId);
    if (c == null) return;
    _replace(c.copyWith(notes: [
      ...c.notes,
      ClosingNote(id: 'n-${DateTime.now().microsecondsSinceEpoch}', internal: internal, body: body, author: c.lawyerEmployeeId, at: DateTime.now()),
    ]));
  }

  void addMessage(String caseId, ChannelDept ch, String body, {bool internal = false}) {
    final c = byId(caseId);
    if (c == null) return;
    _replace(c.copyWith(messages: [
      ...c.messages,
      ClosingMessage(
        id: 'm-${DateTime.now().microsecondsSinceEpoch}',
        channel: ch,
        body: '${c.transactionNumber}\n${c.propertyId}\n$body',
        author: c.lawyerEmployeeId,
        at: DateTime.now(),
        internal: internal,
      ),
    ]));
  }

  String finalReport(ClosingCase c) {
    final buf = StringBuffer()
      ..writeln('مدار — تقرير المعاملة النهائي')
      ..writeln(c.transactionNumber)
      ..writeln('المشتري: ${c.buyer.name}')
      ..writeln('البائع: ${c.seller.name}')
      ..writeln('العقار: ${c.propertyId} — ${c.propertyAddress}')
      ..writeln('النوع: ${c.transactionType}')
      ..writeln('العقد: ${c.handoff.contractId} ${c.handoff.executedVersion}')
      ..writeln('الضمان: ${c.escrow.status.name} ${c.escrow.receiptId ?? ''}')
      ..writeln('المالية: ${c.finance.clearance}')
      ..writeln('المالك النهائي: ${c.finalOwner ?? c.buyer.name}')
      ..writeln('— الإجراءات —');
    for (final p in c.procedures) {
      buf.writeln('${p.name} / ${p.authority} / ${p.status.name}');
    }
    buf.writeln('— التدقيق —');
    for (final a in c.audit) {
      buf.writeln('${a.at} ${a.employeeId} ${a.action} ${a.result}');
    }
    return buf.toString();
  }
}
