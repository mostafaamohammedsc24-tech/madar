enum LegalPriority { normal, priority, urgent, blocked }

enum LegalWorkAction {
  reviewTransaction,
  reviewDocuments,
  missingDocuments,
  prepareContract,
  awaitBuyerConfirmation,
  awaitSellerConfirmation,
  otpPending,
  facePending,
  signaturePending,
  readyToExecute,
  urgentIssue,
  handoff,
}

enum LegalContractStage {
  identityVerification,
  requiredDocuments,
  contractPreparation,
  contractConfirmation,
  otpVerification,
  faceVerification,
  electronicSignature,
  contractExecuted,
  nextDepartment,
}

enum LegalDocumentStatus {
  required,
  requested,
  uploaded,
  underReview,
  approved,
  rejected,
  replacementRequired,
  expired,
  notApplicable,
}

enum PartyConfirmation { pending, viewed, confirmed, rejected }

enum VerificationWatch { pending, verified, failed }

enum SignatureWatch { pending, signed }

enum LegalNoteVisibility { internal, customer }

enum LegalMessageChannel {
  buyer,
  seller,
  legalTeam,
  closing,
  support,
  finance,
}

enum ContractVersionStatus {
  draft,
  revised,
  readyToSend,
  sent,
  rejected,
  approved,
  executed,
  locked,
}

LegalPriority legalPriorityFromWire(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'priority':
      return LegalPriority.priority;
    case 'urgent':
      return LegalPriority.urgent;
    case 'blocked':
      return LegalPriority.blocked;
    default:
      return LegalPriority.normal;
  }
}

String legalPriorityWire(LegalPriority p) {
  switch (p) {
    case LegalPriority.normal:
      return 'normal';
    case LegalPriority.priority:
      return 'priority';
    case LegalPriority.urgent:
      return 'urgent';
    case LegalPriority.blocked:
      return 'blocked';
  }
}

LegalDocumentStatus legalDocumentStatusFromWire(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'requested':
      return LegalDocumentStatus.requested;
    case 'uploaded':
      return LegalDocumentStatus.uploaded;
    case 'under_review':
      return LegalDocumentStatus.underReview;
    case 'approved':
      return LegalDocumentStatus.approved;
    case 'rejected':
      return LegalDocumentStatus.rejected;
    case 'replacement_required':
    case 'needs_replacement':
      return LegalDocumentStatus.replacementRequired;
    case 'expired':
      return LegalDocumentStatus.expired;
    case 'not_applicable':
      return LegalDocumentStatus.notApplicable;
    default:
      return LegalDocumentStatus.required;
  }
}

String legalDocumentStatusWire(LegalDocumentStatus s) {
  switch (s) {
    case LegalDocumentStatus.required:
      return 'required';
    case LegalDocumentStatus.requested:
      return 'requested';
    case LegalDocumentStatus.uploaded:
      return 'uploaded';
    case LegalDocumentStatus.underReview:
      return 'under_review';
    case LegalDocumentStatus.approved:
      return 'approved';
    case LegalDocumentStatus.rejected:
      return 'rejected';
    case LegalDocumentStatus.replacementRequired:
      return 'replacement_required';
    case LegalDocumentStatus.expired:
      return 'expired';
    case LegalDocumentStatus.notApplicable:
      return 'not_applicable';
  }
}
