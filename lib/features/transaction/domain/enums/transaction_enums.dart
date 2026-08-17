/// Canonical transaction lifecycle states.
/// Backend is source of truth; UI must not invent transitions.
enum TransactionState {
  created,
  waitingForParties,
  partiesVerified,
  documentsRequired,
  documentsReview,
  contractDraft,
  contractPendingSignature,
  contractExecuted,
  escrowPending,
  escrowConfirmed,
  deedPending,
  deedVerified,
  settlementPending,
  settlementCompleted,
  completed,
  rejected,
  cancelled,
  onHold,
  expired,
  disputed;

  static TransactionState fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'created':
        return TransactionState.created;
      case 'in_progress':
      case 'active':
        return TransactionState.escrowPending;
      case 'waiting_for_parties':
        return TransactionState.waitingForParties;
      case 'parties_verified':
        return TransactionState.partiesVerified;
      case 'documents_required':
        return TransactionState.documentsRequired;
      case 'documents_review':
        return TransactionState.documentsReview;
      case 'contract_draft':
        return TransactionState.contractDraft;
      case 'contract_pending_signature':
        return TransactionState.contractPendingSignature;
      case 'contract_executed':
        return TransactionState.contractExecuted;
      case 'escrow_pending':
        return TransactionState.escrowPending;
      case 'escrow_confirmed':
        return TransactionState.escrowConfirmed;
      case 'deed_pending':
        return TransactionState.deedPending;
      case 'deed_verified':
        return TransactionState.deedVerified;
      case 'settlement_pending':
        return TransactionState.settlementPending;
      case 'settlement_completed':
        return TransactionState.settlementCompleted;
      case 'completed':
        return TransactionState.completed;
      case 'rejected':
        return TransactionState.rejected;
      case 'cancelled':
        return TransactionState.cancelled;
      case 'on_hold':
        return TransactionState.onHold;
      case 'expired':
        return TransactionState.expired;
      case 'disputed':
        return TransactionState.disputed;
      default:
        return TransactionState.created;
    }
  }

  String get wireValue {
    switch (this) {
      case TransactionState.created:
        return 'created';
      case TransactionState.waitingForParties:
        return 'waiting_for_parties';
      case TransactionState.partiesVerified:
        return 'parties_verified';
      case TransactionState.documentsRequired:
        return 'documents_required';
      case TransactionState.documentsReview:
        return 'documents_review';
      case TransactionState.contractDraft:
        return 'contract_draft';
      case TransactionState.contractPendingSignature:
        return 'contract_pending_signature';
      case TransactionState.contractExecuted:
        return 'contract_executed';
      case TransactionState.escrowPending:
        return 'escrow_pending';
      case TransactionState.escrowConfirmed:
        return 'escrow_confirmed';
      case TransactionState.deedPending:
        return 'deed_pending';
      case TransactionState.deedVerified:
        return 'deed_verified';
      case TransactionState.settlementPending:
        return 'settlement_pending';
      case TransactionState.settlementCompleted:
        return 'settlement_completed';
      case TransactionState.completed:
        return 'completed';
      case TransactionState.rejected:
        return 'rejected';
      case TransactionState.cancelled:
        return 'cancelled';
      case TransactionState.onHold:
        return 'on_hold';
      case TransactionState.expired:
        return 'expired';
      case TransactionState.disputed:
        return 'disputed';
    }
  }

  bool get isTerminal =>
      this == TransactionState.completed ||
      this == TransactionState.cancelled ||
      this == TransactionState.rejected ||
      this == TransactionState.expired;

  bool get isActive =>
      !isTerminal &&
      this != TransactionState.onHold &&
      this != TransactionState.disputed;

  /// User-facing list buckets.
  TransactionListBucket get listBucket {
    if (this == TransactionState.completed) {
      return TransactionListBucket.completed;
    }
    if (this == TransactionState.cancelled ||
        this == TransactionState.rejected ||
        this == TransactionState.expired) {
      return TransactionListBucket.cancelled;
    }
    if (this == TransactionState.onHold || this == TransactionState.disputed) {
      return TransactionListBucket.onHold;
    }
    return TransactionListBucket.active;
  }
}

enum TransactionListBucket { active, completed, cancelled, onHold }

/// Transaction types — drive workflow selection.
enum DealTransactionType {
  sale,
  rent,
  mortgage,
  landSale,
  agricultural,
  commercial,
  other;

  static DealTransactionType fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'sale':
      case 'residential_sale':
        return DealTransactionType.sale;
      case 'rent':
        return DealTransactionType.rent;
      case 'mortgage':
        return DealTransactionType.mortgage;
      case 'land_sale':
      case 'land':
        return DealTransactionType.landSale;
      case 'agricultural':
      case 'agricultural_sale':
        return DealTransactionType.agricultural;
      case 'commercial':
      case 'commercial_sale':
        return DealTransactionType.commercial;
      default:
        return DealTransactionType.other;
    }
  }

  String get wireValue {
    switch (this) {
      case DealTransactionType.sale:
        return 'sale';
      case DealTransactionType.rent:
        return 'rent';
      case DealTransactionType.mortgage:
        return 'mortgage';
      case DealTransactionType.landSale:
        return 'land_sale';
      case DealTransactionType.agricultural:
        return 'agricultural';
      case DealTransactionType.commercial:
        return 'commercial';
      case DealTransactionType.other:
        return 'other';
    }
  }
}

/// RBAC roles for the transaction system.
/// Company Lawyer is NOT a traditional real-estate broker.
enum TransactionRole {
  buyer,
  seller,
  companyLawyer,
  office,
  finance,
  bankOfficer,
  salesTeam,
  legalTeam,
  systemAdmin;

  static TransactionRole fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'buyer':
        return TransactionRole.buyer;
      case 'seller':
        return TransactionRole.seller;
      case 'company_lawyer':
      case 'lawyer':
      case 'agent': // legacy label → company lawyer
        return TransactionRole.companyLawyer;
      case 'office':
        return TransactionRole.office;
      case 'finance':
        return TransactionRole.finance;
      case 'bank_officer':
      case 'bank':
        return TransactionRole.bankOfficer;
      case 'sales_team':
      case 'sales':
        return TransactionRole.salesTeam;
      case 'legal_team':
        return TransactionRole.legalTeam;
      case 'system_admin':
      case 'admin':
        return TransactionRole.systemAdmin;
      default:
        return TransactionRole.buyer;
    }
  }

  String get wireValue {
    switch (this) {
      case TransactionRole.buyer:
        return 'buyer';
      case TransactionRole.seller:
        return 'seller';
      case TransactionRole.companyLawyer:
        return 'company_lawyer';
      case TransactionRole.office:
        return 'office';
      case TransactionRole.finance:
        return 'finance';
      case TransactionRole.bankOfficer:
        return 'bank_officer';
      case TransactionRole.salesTeam:
        return 'sales_team';
      case TransactionRole.legalTeam:
        return 'legal_team';
      case TransactionRole.systemAdmin:
        return 'system_admin';
    }
  }

  bool get isStaff =>
      this != TransactionRole.buyer && this != TransactionRole.seller;
}

enum DocumentRequirementStatus {
  required,
  uploaded,
  underReview,
  approved,
  rejected,
  needsReplacement,
  expired;

  static DocumentRequirementStatus fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'uploaded':
        return DocumentRequirementStatus.uploaded;
      case 'under_review':
        return DocumentRequirementStatus.underReview;
      case 'approved':
        return DocumentRequirementStatus.approved;
      case 'rejected':
        return DocumentRequirementStatus.rejected;
      case 'needs_replacement':
        return DocumentRequirementStatus.needsReplacement;
      case 'expired':
        return DocumentRequirementStatus.expired;
      default:
        return DocumentRequirementStatus.required;
    }
  }

  String get wireValue {
    switch (this) {
      case DocumentRequirementStatus.required:
        return 'required';
      case DocumentRequirementStatus.uploaded:
        return 'uploaded';
      case DocumentRequirementStatus.underReview:
        return 'under_review';
      case DocumentRequirementStatus.approved:
        return 'approved';
      case DocumentRequirementStatus.rejected:
        return 'rejected';
      case DocumentRequirementStatus.needsReplacement:
        return 'needs_replacement';
      case DocumentRequirementStatus.expired:
        return 'expired';
    }
  }
}

enum PartySide { buyer, seller, both }
