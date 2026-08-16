import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../transaction/domain/enums/transaction_enums.dart';
import '../../../transaction/domain/models/deal_transaction.dart';
import '../../../transaction/domain/workflows/transaction_workflow.dart';

/// Read-only monitoring — office cannot advance lawyer/finance/bank stages.
class OfficeTransactionMonitorScreen extends StatelessWidget {
  const OfficeTransactionMonitorScreen({
    super.key,
    required this.transaction,
  });

  final Map<String, dynamic> transaction;

  TransactionWorkflowDefinition _workflowFor(DealTransaction deal) {
    if (deal.workflowId == 'iq_agricultural_sale' ||
        deal.type == DealTransactionType.agricultural) {
      return TransactionWorkflowDefinition.iraqAgriculturalSale();
    }
    return TransactionWorkflowDefinition.iraqResidentialSale();
  }

  String _responsibleForStep(String key) {
    switch (key) {
      case 'identity':
      case 'documents':
      case 'contract':
      case 'deed':
      case 'agricultural_transfer':
        return 'Company Lawyer';
      case 'escrow':
        return 'Finance / Bank';
      case 'settlement':
        return 'Finance Department';
      default:
        return 'Office Management';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final deal = DealTransaction.fromMap(transaction);
    final workflow = _workflowFor(deal);
    final steps = workflow.steps;
    final currentKey = deal.currentStepKey;
    final currentIdx = currentKey == null
        ? deal.progressStepIndex.clamp(0, steps.length - 1)
        : steps.indexWhere((s) => s.key == currentKey);
    final activeIdx = currentIdx < 0 ? 0 : currentIdx;
    final responsible = deal.state == TransactionState.completed
        ? '—'
        : _responsibleForStep(steps[activeIdx.clamp(0, steps.length - 1)].key);

    String stepLabel(String key) {
      switch (key) {
        case 'barcode':
          return loc.officeStepBarcode;
        case 'identity':
          return loc.stepIdentity;
        case 'documents':
          return loc.stepDocuments;
        case 'contract':
          return loc.stepContract;
        case 'escrow':
          return loc.stepEscrow;
        case 'deed':
          return loc.stepDeed;
        case 'agricultural_transfer':
          return loc.stepAgriculturalTransfer;
        case 'settlement':
          return loc.stepSettlement;
        default:
          return key.replaceAll('_', ' ');
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          deal.transactionNumber.isNotEmpty
              ? deal.transactionNumber
              : loc.officeNavTransactions,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${loc.officeStatus}: ${deal.state.name}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${loc.officeLastUpdated}: ${deal.updatedAt?.toLocal().toString().split('.').first ?? '—'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${loc.officeCurrentResponsibility}: $responsible',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text(loc.officeProgress, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          // Barcode gate derived from real flags
          _StepRow(
            done: deal.bothBarcodesUploaded,
            active: !deal.bothBarcodesUploaded &&
                deal.state != TransactionState.completed,
            label: loc.officeStepBarcode,
          ),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final done = deal.state == TransactionState.completed ||
                (deal.bothBarcodesUploaded && i < activeIdx);
            final active = deal.bothBarcodesUploaded &&
                i == activeIdx &&
                deal.state != TransactionState.completed;
            return _StepRow(
              done: done,
              active: active,
              label: stepLabel(step.key),
            );
          }),
          if (deal.state == TransactionState.completed) ...[
            const SizedBox(height: 16),
            Text(
              loc.transactionCompleted,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.success,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              loc.officeMonitorReadOnlyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (deal.salePrice != null) ...[
            const SizedBox(height: 20),
            Text(
              loc.officeExpectedCommission,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              loc.officeCommissionHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.done,
    required this.active,
    required this.label,
  });

  final bool done;
  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : active
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
            size: 20,
            color: done
                ? AppTheme.success
                : active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
