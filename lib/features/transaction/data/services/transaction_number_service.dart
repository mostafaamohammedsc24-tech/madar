import '../../domain/enums/transaction_enums.dart';
import '../../domain/workflows/transaction_workflow.dart';

/// Draft payload for Company Lawyer to create a transaction.
/// Lawyer UI is staff-facing and not exposed in the consumer app shell.
class CreateTransactionDraft {
  const CreateTransactionDraft({
    required this.type,
    required this.countryCode,
    required this.buyerPhone,
    required this.sellerPhone,
    this.branchCode = 'BGD',
    this.propertyId,
    this.buyerPropertyId,
    this.sellerPropertyId,
    this.salePrice,
    this.currencyCode = 'IQD',
    this.workflowId,
  });

  final DealTransactionType type;
  final String countryCode;
  final String buyerPhone;
  final String sellerPhone;
  final String branchCode;
  final String? propertyId;
  final String? buyerPropertyId;
  final String? sellerPropertyId;
  final double? salePrice;
  final String currencyCode;
  final String? workflowId;

  String resolveWorkflowId() {
    if (workflowId != null) return workflowId!;
    if (type == DealTransactionType.agricultural) {
      return TransactionWorkflowDefinition.iraqAgriculturalSale().id;
    }
    return TransactionWorkflowDefinition.iraqResidentialSale().id;
  }
}

/// Formats human-readable transaction numbers using country config.
class TransactionNumberService {
  const TransactionNumberService();

  String formatIraqSale({
    required String branchCode,
    required DealTransactionType type,
    required int year,
    required int sequence,
  }) {
    return TransactionNumberingConfig.iraq.format(
      branchCode: branchCode,
      typeCode: type.wireValue.toUpperCase(),
      year: year,
      sequence: sequence,
    );
  }
}
