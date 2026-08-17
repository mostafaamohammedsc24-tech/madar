import '../enums/transaction_enums.dart';

/// Configurable workflow definition per country + transaction type.
/// Steps are not hard-coded forever — country packs can differ.
class TransactionWorkflowDefinition {
  const TransactionWorkflowDefinition({
    required this.id,
    required this.countryCode,
    required this.transactionType,
    required this.name,
    required this.steps,
    this.skipDeed = false,
    this.releaseConditions = const [],
    this.metadata = const {},
  });

  final String id;
  final String countryCode;
  final DealTransactionType transactionType;
  final String name;
  final List<WorkflowStepDefinition> steps;
  final bool skipDeed;
  final List<String> releaseConditions;
  final Map<String, dynamic> metadata;

  static TransactionWorkflowDefinition iraqResidentialSale() =>
      const TransactionWorkflowDefinition(
        id: 'iq_residential_sale',
        countryCode: 'IQ',
        transactionType: DealTransactionType.sale,
        name: 'Iraq Residential Sale',
        steps: [
          WorkflowStepDefinition(
            key: 'identity',
            titleKey: 'stepIdentity',
            order: 1,
          ),
          WorkflowStepDefinition(
            key: 'documents',
            titleKey: 'stepDocuments',
            order: 2,
          ),
          WorkflowStepDefinition(
            key: 'contract',
            titleKey: 'stepContract',
            order: 3,
          ),
          WorkflowStepDefinition(
            key: 'escrow',
            titleKey: 'stepEscrow',
            order: 4,
          ),
          WorkflowStepDefinition(
            key: 'deed',
            titleKey: 'stepDeed',
            order: 5,
          ),
          WorkflowStepDefinition(
            key: 'settlement',
            titleKey: 'stepSettlement',
            order: 6,
          ),
        ],
        releaseConditions: [
          'deed_verified',
          'buyer_proof_uploaded',
          'lawyer_verified',
        ],
      );

  static TransactionWorkflowDefinition iraqAgriculturalSale() =>
      const TransactionWorkflowDefinition(
        id: 'iq_agricultural_sale',
        countryCode: 'IQ',
        transactionType: DealTransactionType.agricultural,
        name: 'Iraq Agricultural Sale',
        skipDeed: true,
        steps: [
          WorkflowStepDefinition(
            key: 'identity',
            titleKey: 'stepIdentity',
            order: 1,
          ),
          WorkflowStepDefinition(
            key: 'documents',
            titleKey: 'stepDocuments',
            order: 2,
          ),
          WorkflowStepDefinition(
            key: 'contract',
            titleKey: 'stepContract',
            order: 3,
          ),
          WorkflowStepDefinition(
            key: 'escrow',
            titleKey: 'stepEscrow',
            order: 4,
          ),
          WorkflowStepDefinition(
            key: 'agricultural_transfer',
            titleKey: 'stepAgriculturalTransfer',
            order: 5,
          ),
          WorkflowStepDefinition(
            key: 'settlement',
            titleKey: 'stepSettlement',
            order: 6,
          ),
        ],
        releaseConditions: [
          'buyer_moved_confirmed',
          'buyer_approved',
          'lawyer_verified',
        ],
      );
}

class WorkflowStepDefinition {
  const WorkflowStepDefinition({
    required this.key,
    required this.titleKey,
    required this.order,
    this.requiredRoles = const [],
  });

  final String key;
  final String titleKey;
  final int order;
  final List<TransactionRole> requiredRoles;
}

/// Human-readable numbering config per country.
class TransactionNumberingConfig {
  const TransactionNumberingConfig({
    required this.countryCode,
    required this.prefix,
    this.includeBranch = true,
    this.includeType = true,
    this.includeYear = true,
    this.sequencePadding = 6,
  });

  final String countryCode;
  final String prefix;
  final bool includeBranch;
  final bool includeType;
  final bool includeYear;
  final int sequencePadding;

  /// Example: IQ-BGD-SALE-2026-000184
  String format({
    required String branchCode,
    required String typeCode,
    required int year,
    required int sequence,
  }) {
    final parts = <String>[prefix];
    if (includeBranch) parts.add(branchCode.toUpperCase());
    if (includeType) parts.add(typeCode.toUpperCase());
    if (includeYear) parts.add('$year');
    parts.add(sequence.toString().padLeft(sequencePadding, '0'));
    return parts.join('-');
  }

  static const iraq = TransactionNumberingConfig(
    countryCode: 'IQ',
    prefix: 'IQ',
  );
}
