import '../../../../core/localization/closing_strings.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart';
import '../../domain/enums/closing_enums.dart';
import '../../domain/models/closing_models.dart';

ClosingTimelineLabel timelineLabel(ClosingTimelineStage s) {
  switch (s) {
    case ClosingTimelineStage.identity:
      return ClosingTimelineLabel.identity;
    case ClosingTimelineStage.documents:
      return ClosingTimelineLabel.documents;
    case ClosingTimelineStage.contract:
      return ClosingTimelineLabel.contract;
    case ClosingTimelineStage.contractConfirmation:
      return ClosingTimelineLabel.confirm;
    case ClosingTimelineStage.otp:
      return ClosingTimelineLabel.otp;
    case ClosingTimelineStage.face:
      return ClosingTimelineLabel.face;
    case ClosingTimelineStage.signature:
      return ClosingTimelineLabel.sign;
    case ClosingTimelineStage.escrow:
      return ClosingTimelineLabel.escrow;
    case ClosingTimelineStage.taxSettlement:
      return ClosingTimelineLabel.tax;
    case ClosingTimelineStage.government:
      return ClosingTimelineLabel.gov;
    case ClosingTimelineStage.ownershipTransfer:
      return ClosingTimelineLabel.transfer;
    case ClosingTimelineStage.ownershipDocument:
      return ClosingTimelineLabel.deed;
    case ClosingTimelineStage.finalSettlement:
      return ClosingTimelineLabel.settle;
    case ClosingTimelineStage.closed:
      return ClosingTimelineLabel.closed;
  }
}

LegalTone toneForClosingPriority(ClosingPriority p) {
  switch (p) {
    case ClosingPriority.urgent:
      return LegalTone.danger;
    case ClosingPriority.priority:
      return LegalTone.warning;
    case ClosingPriority.blocked:
      return LegalTone.danger;
    case ClosingPriority.normal:
      return LegalTone.active;
  }
}

String labelPriority(ClosingStrings s, ClosingPriority p) {
  switch (p) {
    case ClosingPriority.normal:
      return s.priN;
    case ClosingPriority.priority:
      return s.priP;
    case ClosingPriority.urgent:
      return s.priU;
    case ClosingPriority.blocked:
      return s.priB;
  }
}

String labelAction(ClosingStrings s, ClosingWorkAction a) {
  switch (a) {
    case ClosingWorkAction.reviewAssigned:
      return _arEnKu(s, 'مراجعة المعاملة المعيَّنة', 'Review assigned transaction', 'پێداچوونەوەی مامەڵەی دیاریکراو');
    case ClosingWorkAction.escrowPending:
      return _arEnKu(s, 'متابعة إيداع الضمان', 'Monitor escrow deposit', 'چاودێری پارەدانی ئێسکرۆ');
    case ClosingWorkAction.bankConfirmationPending:
      return _arEnKu(s, 'بانتظار تأكيد البنك', 'Bank confirmation pending', 'چاوەڕوانی پشتڕاستی بانک');
    case ClosingWorkAction.taxPending:
      return _arEnKu(s, 'متابعة دفع الضرائب', 'Tax payment pending', 'چاودێری باج');
    case ClosingWorkAction.ownershipDocumentPending:
      return _arEnKu(s, 'مراجعة مستند حكومي مرفوع', 'Review uploaded ownership document', 'پێداچوونەوەی بەڵگەنامەی حکومی');
    case ClosingWorkAction.governmentPending:
      return _arEnKu(s, 'متابعة إجراء حكومي', 'Government procedure pending', 'چاودێری ڕێکاری حکومی');
    case ClosingWorkAction.transferAppointmentPending:
      return _arEnKu(s, 'تنسيق موعد نقل الملكية', 'Coordinate ownership-transfer appointment', 'ڕێکخستنی کاتی گواستنەوە');
    case ClosingWorkAction.ownershipDocVerification:
      return _arEnKu(s, 'توثيق سند الملكية الجديد', 'Verify new ownership document', 'پشتڕاستی بەڵگەنامەی خاوەنداری');
    case ClosingWorkAction.agriculturalSpecial:
      return _arEnKu(s, 'إجراء خاص للعقار الزراعي', 'Agricultural-property special procedure', 'ڕێکاری تایبەتی کشتوکاڵی');
    case ClosingWorkAction.settlementPending:
      return _arEnKu(s, 'متابعة التسوية النهائية', 'Final settlement pending', 'چاودێری پێکدادانی کۆتایی');
    case ClosingWorkAction.readyToClose:
      return _arEnKu(s, 'المعاملة جاهزة للإغلاق', 'Transaction ready to close', 'مامەڵە ئامادەیە بۆ داخستن');
    case ClosingWorkAction.blocked:
      return _arEnKu(s, 'معاملة متوقفة — تصعيد', 'Blocked transaction — escalate', 'مامەڵەی وەستاو');
    case ClosingWorkAction.urgent:
      return _arEnKu(s, 'معاملة عاجلة', 'Urgent transaction', 'مامەڵەی فوری');
    case ClosingWorkAction.archived:
      return _arEnKu(s, 'مؤرشفة', 'Archived', 'ئەرشیفکراو');
  }
}

String labelEscrow(ClosingStrings s, EscrowWatchStatus st) {
  switch (st) {
    case EscrowWatchStatus.awaitingDeposit:
      return _arEnKu(s, 'بانتظار الإيداع', 'Awaiting deposit', 'چاوەڕوانی پارەدان');
    case EscrowWatchStatus.depositSubmitted:
      return _arEnKu(s, 'تم تقديم الإيداع', 'Deposit submitted', 'پارەدان نێردرا');
    case EscrowWatchStatus.bankVerificationPending:
      return _arEnKu(s, 'تحقق البنك معلّق', 'Bank verification pending', 'پشتڕاستی بانک چاوەڕوانە');
    case EscrowWatchStatus.depositConfirmed:
      return _arEnKu(s, 'الإيداع مؤكد', 'Deposit confirmed', 'پارەدان پشتڕاست');
    case EscrowWatchStatus.depositDiscrepancy:
      return _arEnKu(s, 'اختلاف في الإيداع', 'Deposit discrepancy', 'جیاوازی پارەدان');
  }
}

LegalTone toneForEscrow(EscrowWatchStatus st) {
  switch (st) {
    case EscrowWatchStatus.depositConfirmed:
      return LegalTone.success;
    case EscrowWatchStatus.depositDiscrepancy:
      return LegalTone.danger;
    case EscrowWatchStatus.awaitingDeposit:
    case EscrowWatchStatus.depositSubmitted:
    case EscrowWatchStatus.bankVerificationPending:
      return LegalTone.warning;
  }
}

String labelGov(ClosingStrings s, GovProcedureStatus st) {
  switch (st) {
    case GovProcedureStatus.notStarted:
      return _arEnKu(s, 'لم يبدأ', 'Not started', 'دەستپێنەکراو');
    case GovProcedureStatus.preparing:
      return _arEnKu(s, 'قيد التجهيز', 'Preparing', 'ئامادەکردن');
    case GovProcedureStatus.documentsRequired:
      return _arEnKu(s, 'مستندات مطلوبة', 'Documents required', 'بەڵگەنامە پێویستە');
    case GovProcedureStatus.submitted:
      return _arEnKu(s, 'مقدَّم', 'Submitted', 'نێردراو');
    case GovProcedureStatus.underReview:
      return _arEnKu(s, 'قيد المراجعة', 'Under review', 'لە پێداچوونەوە');
    case GovProcedureStatus.approved:
      return _arEnKu(s, 'موافق عليه', 'Approved', 'پەسەندکراو');
    case GovProcedureStatus.rejected:
      return _arEnKu(s, 'مرفوض', 'Rejected', 'ڕەتکراوە');
    case GovProcedureStatus.requiresCorrection:
      return _arEnKu(s, 'يتطلب تصحيحاً', 'Requires correction', 'پێویستی بە چاکسازی');
    case GovProcedureStatus.appointmentRequired:
      return _arEnKu(s, 'يلزم موعد', 'Appointment required', 'کات پێویستە');
    case GovProcedureStatus.completed:
      return _arEnKu(s, 'مكتمل', 'Completed', 'تەواو');
    case GovProcedureStatus.blocked:
      return _arEnKu(s, 'متوقف', 'Blocked', 'وەستاو');
  }
}

LegalTone toneForGov(GovProcedureStatus st) {
  switch (st) {
    case GovProcedureStatus.completed:
    case GovProcedureStatus.approved:
      return LegalTone.success;
    case GovProcedureStatus.rejected:
    case GovProcedureStatus.blocked:
      return LegalTone.danger;
    case GovProcedureStatus.underReview:
    case GovProcedureStatus.submitted:
    case GovProcedureStatus.requiresCorrection:
    case GovProcedureStatus.appointmentRequired:
    case GovProcedureStatus.documentsRequired:
    case GovProcedureStatus.preparing:
      return LegalTone.warning;
    case GovProcedureStatus.notStarted:
      return LegalTone.neutral;
  }
}

String labelDeed(ClosingStrings s, DeedReviewStatus st) {
  switch (st) {
    case DeedReviewStatus.uploaded:
      return _arEnKu(s, 'مرفوع', 'Uploaded', 'بارکراو');
    case DeedReviewStatus.underReview:
      return _arEnKu(s, 'قيد المراجعة', 'Under review', 'لە پێداچوونەوە');
    case DeedReviewStatus.approved:
      return _arEnKu(s, 'معتمد', 'Approved', 'پەسەند');
    case DeedReviewStatus.rejected:
      return _arEnKu(s, 'مرفوض', 'Rejected', 'ڕەتکراوە');
    case DeedReviewStatus.correctionRequired:
      return _arEnKu(s, 'تصحيح مطلوب', 'Correction required', 'چاکسازی پێویست');
    case DeedReviewStatus.notRequired:
      return _arEnKu(s, 'غير مطلوب', 'Not required', 'پێویست نییە');
  }
}

LegalTone toneForDeed(DeedReviewStatus st) {
  switch (st) {
    case DeedReviewStatus.approved:
    case DeedReviewStatus.notRequired:
      return LegalTone.success;
    case DeedReviewStatus.rejected:
      return LegalTone.danger;
    case DeedReviewStatus.uploaded:
    case DeedReviewStatus.underReview:
    case DeedReviewStatus.correctionRequired:
      return LegalTone.warning;
  }
}

String labelChannel(ClosingStrings s, ChannelDept d) {
  switch (d) {
    case ChannelDept.bank:
      return s.bank;
    case ChannelDept.finance:
      return s.navFinance;
    case ChannelDept.legalTeam:
      return s.internalChat;
    case ChannelDept.contractLawyer:
      return s.contractLawyer;
    case ChannelDept.buyer:
      return s.buyer;
    case ChannelDept.seller:
      return s.seller;
    case ChannelDept.compliance:
      return _arEnKu(s, 'الامتثال', 'Compliance', 'پابەندبوون');
    case ChannelDept.support:
      return _arEnKu(s, 'الدعم', 'Support', 'پشتگیری');
    case ChannelDept.management:
      return _arEnKu(s, 'الإدارة', 'Management', 'بەڕێوەبردن');
    case ChannelDept.government:
      return s.gov;
  }
}

String _arEnKu(ClosingStrings s, String ar, String en, String ku) {
  switch (s.lang.name) {
    case 'arabic':
      return ar;
    case 'kurdish':
      return ku;
    default:
      return en;
  }
}

String fmtWhen(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

bool deadlineSoon(ClosingCase c) {
  if (c.deadline == null) return false;
  return c.deadline!.difference(DateTime.now()) < const Duration(hours: 24);
}
