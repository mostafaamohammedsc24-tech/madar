enum ClosingPriority { normal, priority, urgent, blocked }

enum ClosingWorkAction {
  reviewAssigned,
  escrowPending,
  bankConfirmationPending,
  taxPending,
  ownershipDocumentPending,
  governmentPending,
  transferAppointmentPending,
  ownershipDocVerification,
  agriculturalSpecial,
  settlementPending,
  readyToClose,
  blocked,
  urgent,
  archived,
}

/// Full 14-step process. Closing lawyer owns stages from escrow onward.
enum ClosingTimelineStage {
  identity,
  documents,
  contract,
  contractConfirmation,
  otp,
  face,
  signature,
  escrow,
  taxSettlement,
  government,
  ownershipTransfer,
  ownershipDocument,
  finalSettlement,
  closed,
}

enum ClosingLifecycle {
  contractExecuted,
  escrowPending,
  escrowConfirmed,
  governmentProcedures,
  ownershipTransferPending,
  ownershipTransferCompleted,
  ownershipDocumentPending,
  ownershipDocumentVerified,
  financialSettlement,
  finalReview,
  completed,
}

enum EscrowWatchStatus {
  awaitingDeposit,
  depositSubmitted,
  bankVerificationPending,
  depositConfirmed,
  depositDiscrepancy,
}

enum GovProcedureStatus {
  notStarted,
  preparing,
  documentsRequired,
  submitted,
  underReview,
  approved,
  rejected,
  requiresCorrection,
  appointmentRequired,
  completed,
  blocked,
}

enum DeedReviewStatus {
  uploaded,
  underReview,
  approved,
  rejected,
  correctionRequired,
  notRequired,
}

enum ChannelDept { bank, finance, legalTeam, contractLawyer, buyer, seller, compliance, support, management, government }

ClosingPriority closingPriorityFromWire(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'priority':
      return ClosingPriority.priority;
    case 'urgent':
      return ClosingPriority.urgent;
    case 'blocked':
      return ClosingPriority.blocked;
    default:
      return ClosingPriority.normal;
  }
}
