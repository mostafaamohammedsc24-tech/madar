import 'package:flutter/material.dart';

import '../../../../core/localization/legal_strings.dart';
import '../../domain/enums/legal_enums.dart';
import '../theme/legal_theme.dart';

class LegalStatusChip extends StatelessWidget {
  const LegalStatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final LegalTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      LegalTone.success => (LegalTheme.successSoft, LegalTheme.success),
      LegalTone.warning => (LegalTheme.warningSoft, LegalTheme.warning),
      LegalTone.danger => (LegalTheme.dangerSoft, LegalTheme.danger),
      LegalTone.active => (LegalTheme.activeSoft, LegalTheme.active),
      LegalTone.neutral => (LegalTheme.surfaceLow, LegalTheme.muted),
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.$2.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: colors.$2, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            if (icon != null) ...[
              Icon(icon, size: 12, color: colors.$2),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: LegalTheme.ibm(size: 11, weight: FontWeight.w600, color: colors.$2),
            ),
          ],
        ),
      ),
    );
  }
}

enum LegalTone { success, warning, danger, active, neutral }

LegalTone toneForDoc(LegalDocumentStatus s) {
  switch (s) {
    case LegalDocumentStatus.approved:
      return LegalTone.success;
    case LegalDocumentStatus.rejected:
    case LegalDocumentStatus.expired:
      return LegalTone.danger;
    case LegalDocumentStatus.underReview:
    case LegalDocumentStatus.uploaded:
    case LegalDocumentStatus.requested:
    case LegalDocumentStatus.replacementRequired:
      return LegalTone.warning;
    case LegalDocumentStatus.required:
      return LegalTone.active;
    case LegalDocumentStatus.notApplicable:
      return LegalTone.neutral;
  }
}

LegalTone toneForPriority(LegalPriority p) {
  switch (p) {
    case LegalPriority.urgent:
      return LegalTone.danger;
    case LegalPriority.priority:
      return LegalTone.warning;
    case LegalPriority.blocked:
      return LegalTone.neutral;
    case LegalPriority.normal:
      return LegalTone.active;
  }
}

String labelDoc(LegalStrings s, LegalDocumentStatus st) {
  switch (st) {
    case LegalDocumentStatus.required:
      return s.required;
    case LegalDocumentStatus.requested:
      return 'مطلوب رفعه';
    case LegalDocumentStatus.uploaded:
      return 'مرفوع';
    case LegalDocumentStatus.underReview:
      return 'قيد المراجعة';
    case LegalDocumentStatus.approved:
      return s.approve;
    case LegalDocumentStatus.rejected:
      return s.rejected;
    case LegalDocumentStatus.replacementRequired:
      return s.requestReplacement;
    case LegalDocumentStatus.expired:
      return 'منتهٍ';
    case LegalDocumentStatus.notApplicable:
      return 'غير منطبق';
  }
}

String labelPriority(LegalStrings s, LegalPriority p) {
  switch (p) {
    case LegalPriority.normal:
      return s.priNormal;
    case LegalPriority.priority:
      return s.priPriority;
    case LegalPriority.urgent:
      return s.priUrgent;
    case LegalPriority.blocked:
      return s.priBlocked;
  }
}

String labelAction(LegalStrings s, LegalWorkAction a) {
  switch (a) {
    case LegalWorkAction.reviewTransaction:
      return s.actionReviewTx;
    case LegalWorkAction.reviewDocuments:
      return s.actionReviewDocs;
    case LegalWorkAction.missingDocuments:
      return s.actionMissing;
    case LegalWorkAction.prepareContract:
      return s.actionPrepare;
    case LegalWorkAction.awaitBuyerConfirmation:
      return s.actionBuyer;
    case LegalWorkAction.awaitSellerConfirmation:
      return s.actionSeller;
    case LegalWorkAction.otpPending:
      return s.actionOtp;
    case LegalWorkAction.facePending:
      return s.actionFace;
    case LegalWorkAction.signaturePending:
      return s.actionSign;
    case LegalWorkAction.readyToExecute:
      return s.actionExecute;
    case LegalWorkAction.urgentIssue:
      return s.actionUrgent;
    case LegalWorkAction.handoff:
      return s.stageCompleted;
  }
}

String labelStage(LegalStrings s, LegalContractStage st) {
  switch (st) {
    case LegalContractStage.identityVerification:
      return s.stageIdentity;
    case LegalContractStage.requiredDocuments:
      return s.stageDocuments;
    case LegalContractStage.contractPreparation:
      return s.stagePrep;
    case LegalContractStage.contractConfirmation:
      return s.stageConfirm;
    case LegalContractStage.otpVerification:
      return s.stageOtp;
    case LegalContractStage.faceVerification:
      return s.stageFace;
    case LegalContractStage.electronicSignature:
      return s.stageSign;
    case LegalContractStage.contractExecuted:
      return s.stageExecuted;
    case LegalContractStage.nextDepartment:
      return s.stageNext;
  }
}
