enum OfficeStatus { active, suspended, pending }

enum OfficePropertyStatus {
  pendingReview,
  ownerContacted,
  approved,
  active,
  sold,
  rented,
  archived,
}

enum OfficeReferralStatus {
  neu, // avoid keyword `new`
  contacting,
  qualified,
  negotiating,
  transactionCreated,
  completed,
  rejected,
  expired,
}

enum OfficeReportStatus {
  underReview,
  contactingOwner,
  ownerApproved,
  ownerDeclined,
}

OfficeStatus officeStatusFromWire(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'suspended':
      return OfficeStatus.suspended;
    case 'pending':
      return OfficeStatus.pending;
    default:
      return OfficeStatus.active;
  }
}

OfficeReferralStatus referralStatusFromWire(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'contacting':
      return OfficeReferralStatus.contacting;
    case 'qualified':
      return OfficeReferralStatus.qualified;
    case 'negotiating':
      return OfficeReferralStatus.negotiating;
    case 'transaction_created':
      return OfficeReferralStatus.transactionCreated;
    case 'completed':
      return OfficeReferralStatus.completed;
    case 'rejected':
      return OfficeReferralStatus.rejected;
    case 'expired':
      return OfficeReferralStatus.expired;
    default:
      return OfficeReferralStatus.neu;
  }
}

String referralStatusWire(OfficeReferralStatus s) {
  switch (s) {
    case OfficeReferralStatus.neu:
      return 'new';
    case OfficeReferralStatus.contacting:
      return 'contacting';
    case OfficeReferralStatus.qualified:
      return 'qualified';
    case OfficeReferralStatus.negotiating:
      return 'negotiating';
    case OfficeReferralStatus.transactionCreated:
      return 'transaction_created';
    case OfficeReferralStatus.completed:
      return 'completed';
    case OfficeReferralStatus.rejected:
      return 'rejected';
    case OfficeReferralStatus.expired:
      return 'expired';
  }
}
