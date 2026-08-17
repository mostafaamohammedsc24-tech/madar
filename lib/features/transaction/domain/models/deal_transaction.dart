import '../enums/transaction_enums.dart';
import '../workflows/transaction_state_machine.dart';
import '../workflows/transaction_workflow.dart';

class DealTransaction {
  const DealTransaction({
    required this.id,
    required this.transactionNumber,
    required this.state,
    required this.type,
    required this.countryCode,
    required this.currencyCode,
    this.workflowId,
    this.propertyId,
    this.propertyAddressSnapshot,
    this.salePrice,
    this.buyerUserId,
    this.sellerUserId,
    this.buyerPhone,
    this.sellerPhone,
    this.buyerName,
    this.sellerName,
    this.lawyerUserId,
    this.buyerBarcodeUploaded = false,
    this.sellerBarcodeUploaded = false,
    this.buyerIdentityVerified = false,
    this.sellerIdentityVerified = false,
    this.buyerSignedContract = false,
    this.sellerSignedContract = false,
    this.currentStepKey,
    this.updatedAt,
    this.createdAt,
    this.resumeState,
    this.raw = const {},
  });

  final String id;
  final String transactionNumber;
  final TransactionState state;
  final DealTransactionType type;
  final String countryCode;
  final String currencyCode;
  final String? workflowId;
  final String? propertyId;
  final String? propertyAddressSnapshot;
  final double? salePrice;
  final String? buyerUserId;
  final String? sellerUserId;
  final String? buyerPhone;
  final String? sellerPhone;
  final String? buyerName;
  final String? sellerName;
  final String? lawyerUserId;
  final bool buyerBarcodeUploaded;
  final bool sellerBarcodeUploaded;
  final bool buyerIdentityVerified;
  final bool sellerIdentityVerified;
  final bool buyerSignedContract;
  final bool sellerSignedContract;
  final String? currentStepKey;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final TransactionState? resumeState;
  final Map<String, dynamic> raw;

  bool get bothBarcodesUploaded =>
      buyerBarcodeUploaded && sellerBarcodeUploaded;

  bool get bothIdentitiesVerified =>
      buyerIdentityVerified && sellerIdentityVerified;

  bool get bothSignedContract => buyerSignedContract && sellerSignedContract;

  int get barcodeProgressCount =>
      (buyerBarcodeUploaded ? 1 : 0) + (sellerBarcodeUploaded ? 1 : 0);

  TransactionListBucket get listBucket => state.listBucket;

  int get progressStepIndex =>
      const TransactionStateMachine().userFacingStepIndex(state);

  double get progressFraction {
    final step = progressStepIndex;
    if (state == TransactionState.completed) return 1;
    return ((step + 1) / 6).clamp(0.0, 1.0);
  }

  TransactionRole? roleForUser(String? userId) {
    if (userId == null) return null;
    if (userId == buyerUserId) return TransactionRole.buyer;
    if (userId == sellerUserId) return TransactionRole.seller;
    if (userId == lawyerUserId) return TransactionRole.companyLawyer;
    return null;
  }

  factory DealTransaction.fromMap(Map<String, dynamic> d) {
    return DealTransaction(
      id: d['id']?.toString() ?? '',
      transactionNumber: d['transaction_number'] as String? ??
          d['reference_number'] as String? ??
          d['id']?.toString() ??
          '',
      state: TransactionState.fromWire(
        d['lifecycle_state'] as String? ?? d['status'] as String?,
      ),
      type: DealTransactionType.fromWire(d['transaction_type'] as String?),
      countryCode: d['country_code'] as String? ?? 'IQ',
      currencyCode: d['currency_code'] as String? ?? 'IQD',
      workflowId: d['workflow_id'] as String?,
      propertyId: d['property_id']?.toString(),
      propertyAddressSnapshot: d['property_address_snapshot'] as String?,
      salePrice: (d['total_amount'] as num?)?.toDouble() ??
          (d['sale_price'] as num?)?.toDouble(),
      buyerUserId: d['buyer_user_id']?.toString(),
      sellerUserId: d['seller_user_id']?.toString(),
      buyerPhone: d['buyer_phone'] as String?,
      sellerPhone: d['seller_phone'] as String?,
      buyerName: d['buyer_name'] as String?,
      sellerName: d['seller_name'] as String?,
      lawyerUserId: d['lawyer_user_id']?.toString(),
      buyerBarcodeUploaded: d['buyer_barcode_uploaded'] as bool? ?? false,
      sellerBarcodeUploaded: d['seller_barcode_uploaded'] as bool? ?? false,
      buyerIdentityVerified: d['buyer_identity_verified'] as bool? ?? false,
      sellerIdentityVerified: d['seller_identity_verified'] as bool? ?? false,
      buyerSignedContract: d['buyer_signed_contract'] as bool? ?? false,
      sellerSignedContract: d['seller_signed_contract'] as bool? ?? false,
      currentStepKey: d['current_step_key'] as String?,
      updatedAt: _date(d['updated_at']),
      createdAt: _date(d['created_at']),
      resumeState: d['resume_state'] != null
          ? TransactionState.fromWire(d['resume_state'] as String?)
          : null,
      raw: d,
    );
  }

  static DateTime? _date(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class TransactionBarcodeRecord {
  const TransactionBarcodeRecord({
    required this.id,
    required this.transactionId,
    required this.barcodeCode,
    this.buyerRedeemedAt,
    this.sellerRedeemedAt,
    this.buyerRedeemedByUserId,
    this.sellerRedeemedByUserId,
    this.expiresAt,
  });

  final String id;
  final String transactionId;
  final String barcodeCode;
  final DateTime? buyerRedeemedAt;
  final DateTime? sellerRedeemedAt;
  final String? buyerRedeemedByUserId;
  final String? sellerRedeemedByUserId;
  final DateTime? expiresAt;

  bool get bothRedeemed => buyerRedeemedAt != null && sellerRedeemedAt != null;

  factory TransactionBarcodeRecord.fromMap(Map<String, dynamic> d) {
    return TransactionBarcodeRecord(
      id: d['id']?.toString() ?? '',
      transactionId: d['transaction_id']?.toString() ?? '',
      barcodeCode: d['barcode_code'] as String? ?? '',
      buyerRedeemedAt: DealTransaction._date(d['buyer_redeemed_at']),
      sellerRedeemedAt: DealTransaction._date(d['seller_redeemed_at']),
      buyerRedeemedByUserId: d['buyer_redeemed_by_user_id']?.toString(),
      sellerRedeemedByUserId: d['seller_redeemed_by_user_id']?.toString(),
      expiresAt: DealTransaction._date(d['expires_at']),
    );
  }
}

class TransactionDocumentRequirement {
  const TransactionDocumentRequirement({
    required this.id,
    required this.transactionId,
    required this.name,
    required this.requiredFor,
    required this.status,
    this.description,
    this.deadline,
    this.rejectionReason,
    this.storagePath,
  });

  final String id;
  final String transactionId;
  final String name;
  final PartySide requiredFor;
  final DocumentRequirementStatus status;
  final String? description;
  final DateTime? deadline;
  final String? rejectionReason;
  final String? storagePath;
}

class TransactionAuditEvent {
  const TransactionAuditEvent({
    required this.id,
    required this.transactionId,
    required this.eventType,
    required this.message,
    required this.createdAt,
    this.actorUserId,
    this.actorRole,
    this.metadata = const {},
  });

  final String id;
  final String transactionId;
  final String eventType;
  final String message;
  final DateTime createdAt;
  final String? actorUserId;
  final TransactionRole? actorRole;
  final Map<String, dynamic> metadata;

  factory TransactionAuditEvent.fromMap(Map<String, dynamic> d) {
    return TransactionAuditEvent(
      id: d['id']?.toString() ?? '',
      transactionId: d['transaction_id']?.toString() ?? '',
      eventType: d['event_type'] as String? ?? '',
      message: d['message'] as String? ?? '',
      createdAt: DealTransaction._date(d['created_at']) ?? DateTime.now(),
      actorUserId: d['actor_user_id']?.toString(),
      actorRole: d['actor_role'] != null
          ? TransactionRole.fromWire(d['actor_role'] as String?)
          : null,
      metadata: d['metadata'] is Map
          ? Map<String, dynamic>.from(d['metadata'] as Map)
          : const {},
    );
  }
}

/// Configurable commission — never hardcode 1% in business logic.
class CommissionRule {
  const CommissionRule({
    required this.id,
    required this.countryCode,
    required this.transactionType,
    required this.buyerRate,
    required this.sellerRate,
    this.propertyType,
    this.effectiveFrom,
    this.effectiveTo,
  });

  final String id;
  final String countryCode;
  final DealTransactionType transactionType;
  final double buyerRate;
  final double sellerRate;
  final String? propertyType;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
}

class TaxRule {
  const TaxRule({
    required this.id,
    required this.countryCode,
    required this.transactionType,
    this.propertyType,
    this.partyType,
    this.rate,
    this.fixedAmount,
    this.currencyCode,
    this.effectiveFrom,
    this.effectiveTo,
  });

  final String id;
  final String countryCode;
  final DealTransactionType transactionType;
  final String? propertyType;
  final String? partyType;
  final double? rate;
  final double? fixedAmount;
  final String? currencyCode;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
}

class EscrowAccountConfig {
  const EscrowAccountConfig({
    required this.id,
    required this.countryCode,
    required this.bankName,
    required this.currencyCode,
    required this.accountLabel,
    this.status = 'active',
  });

  final String id;
  final String countryCode;
  final String bankName;
  final String currencyCode;
  final String accountLabel;
  final String status;
}

/// Abstraction for furniture / beautification company — no fake API.
class ExternalServiceNotification {
  const ExternalServiceNotification({
    required this.id,
    required this.transactionId,
    required this.serviceKey,
    required this.payload,
    required this.status,
    this.createdAt,
    this.sentAt,
  });

  final String id;
  final String transactionId;
  /// e.g. furniture_beautification
  final String serviceKey;
  final Map<String, dynamic> payload;
  /// pending | sent | failed | skipped
  final String status;
  final DateTime? createdAt;
  final DateTime? sentAt;
}

class BarcodeRedemptionResult {
  const BarcodeRedemptionResult({
    required this.success,
    required this.transaction,
    required this.bothPartiesVerified,
    this.message,
    this.waitingForOtherParty = false,
  });

  final bool success;
  final DealTransaction? transaction;
  final bool bothPartiesVerified;
  final String? message;
  final bool waitingForOtherParty;
}

class TransactionCenterItem {
  const TransactionCenterItem({
    required this.transaction,
    required this.workflow,
  });

  final DealTransaction transaction;
  final TransactionWorkflowDefinition workflow;
}
