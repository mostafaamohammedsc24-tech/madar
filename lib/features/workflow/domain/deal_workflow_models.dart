import '../../transaction/domain/enums/transaction_enums.dart';

/// Who owns the current deal stage in the multi-role Madar pipeline.
enum WorkflowRoleOwner {
  office,
  buyerSeller,
  publisher,
  information,
  photography,
  engineering,
  contractLawyer,
  transactionLawyer,
  finance,
  bank,
  closing,
  system,
}

/// One visible stage in the cross-role deal workflow board.
class DealWorkflowStage {
  const DealWorkflowStage({
    required this.key,
    required this.titleEn,
    required this.titleAr,
    required this.owner,
    required this.state,
    this.subtitleEn,
    this.subtitleAr,
    this.routeHint,
  });

  final String key;
  final String titleEn;
  final String titleAr;
  final WorkflowRoleOwner owner;
  final TransactionState state;
  final String? subtitleEn;
  final String? subtitleAr;
  final String? routeHint;

  bool get isActive =>
      !state.isTerminal &&
      state != TransactionState.created &&
      state != TransactionState.completed;

  String title(String lang) => lang == 'ar' ? titleAr : titleEn;
  String? subtitle(String lang) =>
      lang == 'ar' ? subtitleAr : subtitleEn;
}

/// Resolved barcode payload used by the shared reader.
enum BarcodeKind {
  buyerDeal,
  sellerDeal,
  publishingAsset,
  transactionNumber,
  unknown,
}

class ResolvedBarcode {
  const ResolvedBarcode({
    required this.rawCode,
    required this.kind,
    this.transactionId,
    this.partySide,
    this.publishingAssetId,
    this.publicPropertyId,
    this.label,
    this.lifecycleState,
    this.workflowStages = const [],
  });

  final String rawCode;
  final BarcodeKind kind;
  final String? transactionId;
  final PartySide? partySide;
  final String? publishingAssetId;
  final String? publicPropertyId;
  final String? label;
  final TransactionState? lifecycleState;
  final List<DealWorkflowStage> workflowStages;
}

/// Canonical Madar multi-role pipeline after an office opens a deal.
abstract final class DealWorkflowBlueprint {
  static List<DealWorkflowStage> stagesFor(TransactionState current) {
    final order = <TransactionState>[
      TransactionState.waitingForParties,
      TransactionState.partiesVerified,
      TransactionState.documentsRequired,
      TransactionState.documentsReview,
      TransactionState.contractDraft,
      TransactionState.contractPendingSignature,
      TransactionState.contractExecuted,
      TransactionState.escrowPending,
      TransactionState.escrowConfirmed,
      TransactionState.deedPending,
      TransactionState.deedVerified,
      TransactionState.settlementPending,
      TransactionState.settlementCompleted,
      TransactionState.completed,
    ];

    DealWorkflowStage map(TransactionState s) {
      switch (s) {
        case TransactionState.waitingForParties:
          return DealWorkflowStage(
            key: 'barcode',
            titleEn: 'Scan party barcodes',
            titleAr: 'مسح باركود الأطراف',
            owner: WorkflowRoleOwner.buyerSeller,
            state: s,
            subtitleEn: 'Buyer & seller redeem office barcodes',
            subtitleAr: 'المشتري والبائع يفعلان باركود المكتب',
            routeHint: '/barcode-reader',
          );
        case TransactionState.partiesVerified:
          return DealWorkflowStage(
            key: 'verified',
            titleEn: 'Parties verified',
            titleAr: 'تم التحقق من الأطراف',
            owner: WorkflowRoleOwner.office,
            state: s,
            subtitleEn: 'Office monitors; documents requested',
            subtitleAr: 'المكتب يراقب ويطلب المستندات',
          );
        case TransactionState.documentsRequired:
        case TransactionState.documentsReview:
          return DealWorkflowStage(
            key: 'documents',
            titleEn: 'Documents',
            titleAr: 'المستندات',
            owner: WorkflowRoleOwner.transactionLawyer,
            state: s,
            subtitleEn: 'Lawyer reviews identity & deed docs',
            subtitleAr: 'المحامي يراجع الهوية والسندات',
            routeHint: '/employee/legal/transactions',
          );
        case TransactionState.contractDraft:
        case TransactionState.contractPendingSignature:
        case TransactionState.contractExecuted:
          return DealWorkflowStage(
            key: 'contract',
            titleEn: 'Contract',
            titleAr: 'العقد',
            owner: WorkflowRoleOwner.contractLawyer,
            state: s,
            subtitleEn: 'Contract lawyer drafts & collects signatures',
            subtitleAr: 'محامي العقود يعدّ ويُوقّع',
            routeHint: '/employee/legal/contracts',
          );
        case TransactionState.escrowPending:
        case TransactionState.escrowConfirmed:
          return DealWorkflowStage(
            key: 'escrow',
            titleEn: 'Finance & bank',
            titleAr: 'المالية والبنك',
            owner: WorkflowRoleOwner.finance,
            state: s,
            subtitleEn: 'Finance sets amounts · Bank confirms deposit',
            subtitleAr: 'المالية تحدد المبالغ · البنك يؤكد الإيداع',
            routeHint: '/employee/finance/transactions',
          );
        case TransactionState.deedPending:
        case TransactionState.deedVerified:
          return DealWorkflowStage(
            key: 'deed',
            titleEn: 'Ownership / deed',
            titleAr: 'نقل الملكية',
            owner: WorkflowRoleOwner.transactionLawyer,
            state: s,
            subtitleEn: 'Transaction lawyer completes transfer',
            subtitleAr: 'محامي المعاملة يكمل النقل',
            routeHint: '/employee/legal/ownership',
          );
        case TransactionState.settlementPending:
        case TransactionState.settlementCompleted:
          return DealWorkflowStage(
            key: 'settlement',
            titleEn: 'Settlement & closing',
            titleAr: 'التسوية والإغلاق',
            owner: WorkflowRoleOwner.closing,
            state: s,
            subtitleEn: 'Closing team settles commissions',
            subtitleAr: 'فريق الإغلاق يسوي العمولات',
            routeHint: '/employee/closing/cases',
          );
        case TransactionState.completed:
          return DealWorkflowStage(
            key: 'done',
            titleEn: 'Completed',
            titleAr: 'مكتمل',
            owner: WorkflowRoleOwner.system,
            state: s,
            subtitleEn: 'Deal closed · listing may publish',
            subtitleAr: 'أُغلقت الصفقة · يمكن نشر العقار',
            routeHint: '/employee/publishing/requests',
          );
        default:
          return DealWorkflowStage(
            key: s.wireValue,
            titleEn: s.wireValue,
            titleAr: s.wireValue,
            owner: WorkflowRoleOwner.system,
            state: s,
          );
      }
    }

    // Collapse related pairs into unique stage keys while keeping current highlighted.
    final seen = <String>{};
    final stages = <DealWorkflowStage>[];
    for (final s in order) {
      final stage = map(s);
      if (seen.add(stage.key)) stages.add(stage);
    }

    // Mark which stage is current by key of [current].
    final currentKey = map(current).key;
    return [
      for (final stage in stages)
        DealWorkflowStage(
          key: stage.key,
          titleEn: stage.titleEn,
          titleAr: stage.titleAr,
          owner: stage.owner,
          state: stage.key == currentKey ? current : stage.state,
          subtitleEn: stage.subtitleEn,
          subtitleAr: stage.subtitleAr,
          routeHint: stage.routeHint,
        ),
    ];
  }

  static WorkflowRoleOwner ownerFor(TransactionState state) {
    final stages = stagesFor(state);
    for (final s in stages) {
      if (s.state == state) return s.owner;
    }
    return stages.isEmpty ? WorkflowRoleOwner.system : stages.first.owner;
  }
}
