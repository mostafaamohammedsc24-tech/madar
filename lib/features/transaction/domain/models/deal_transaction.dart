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
    String? asString(dynamic v) {
      if (v == null) return null;
      if (v is String) {
        final t = v.trim();
        return t.isEmpty ? null : t;
      }
      return v.toString();
    }

    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', ''));
      return null;
    }

    bool asBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final t = v.toLowerCase().trim();
        return t == 'true' || t == '1' || t == 'yes';
      }
      return false;
    }

    return DealTransaction(
      id: asString(d['id']) ?? '',
      transactionNumber: asString(d['transaction_number']) ??
          asString(d['reference_number']) ??
          asString(d['id']) ??
          '',
      state: TransactionState.fromWire(
        asString(d['lifecycle_state']) ?? asString(d['status']),
      ),
      type: DealTransactionType.fromWire(asString(d['transaction_type'])),
      countryCode: asString(d['country_code']) ?? 'IQ',
      currencyCode: asString(d['currency_code']) ?? 'IQD',
      workflowId: asString(d['workflow_id']),
      propertyId: asString(d['property_id']),
      propertyAddressSnapshot: asString(d['property_address_snapshot']),
      salePrice: asDouble(d['total_amount']) ?? asDouble(d['sale_price']),
      buyerUserId: asString(d['buyer_user_id']),
      sellerUserId: asString(d['seller_user_id']),
      buyerPhone: asString(d['buyer_phone']),
      sellerPhone: asString(d['seller_phone']),
      buyerName: asString(d['buyer_name']),
      sellerName: asString(d['seller_name']),
      lawyerUserId: asString(d['lawyer_user_id']),
      buyerBarcodeUploaded: asBool(d['buyer_barcode_uploaded']),
      sellerBarcodeUploaded: asBool(d['seller_barcode_uploaded']),
      buyerIdentityVerified: asBool(d['buyer_identity_verified']),
      sellerIdentityVerified: asBool(d['seller_identity_verified']),
      buyerSignedContract: asBool(d['buyer_signed_contract']),
      sellerSignedContract: asBool(d['seller_signed_contract']),
      currentStepKey: asString(d['current_step_key']),
      updatedAt: _date(d['updated_at']),
      createdAt: _date(d['created_at']),
      resumeState: d['resume_state'] != null
          ? TransactionState.fromWire(asString(d['resume_state']))
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
