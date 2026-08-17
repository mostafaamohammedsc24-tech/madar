import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/domain/employee_permissions.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class FinanceTransactionDetailScreen extends StatefulWidget {
  const FinanceTransactionDetailScreen({super.key, required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  State<FinanceTransactionDetailScreen> createState() =>
      _FinanceTransactionDetailScreenState();
}

class _FinanceTransactionDetailScreenState
    extends State<FinanceTransactionDetailScreen> {
  late final _escrow = TextEditingController(
    text: widget.transaction['required_escrow_amount']?.toString() ?? '',
  );
  late final _fees = TextEditingController(
    text: widget.transaction['company_fees']?.toString() ?? '',
  );
  late final _tax = TextEditingController(
    text: widget.transaction['tax_amount']?.toString() ?? '',
  );
  late final _commission = TextEditingController(
    text: widget.transaction['office_commission_amount']?.toString() ?? '',
  );
  late final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _escrow.dispose();
    _fees.dispose();
    _tax.dispose();
    _commission.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<EmployeeAuthNotifier>();
    if (!auth.can(EmployeePermission.financialEdit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.empForbidden)),
      );
      return;
    }
    setState(() => _busy = true);
    final ok = await auth.repository.updateTransactionFinancials(
      transactionId: widget.transaction['id'].toString(),
      requiredEscrow: double.tryParse(_escrow.text),
      companyFees: double.tryParse(_fees.text),
      taxAmount: double.tryParse(_tax.text),
      officeCommission: double.tryParse(_commission.text),
      financialStatus: 'amount_determined',
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? loc.empSaved : loc.empActionFailed),
      ),
    );
  }

  Future<void> _sendPaymentRequest() async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<EmployeeAuthNotifier>();
    final amount = double.tryParse(_escrow.text);
    if (amount == null) return;
    final ok = await auth.repository.createPaymentRequest(
      transactionId: widget.transaction['id'].toString(),
      amount: amount,
      reason: 'Escrow Deposit',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? loc.empPaymentRequestSent : loc.empActionFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = widget.transaction;
    final canEdit = context.watch<EmployeeAuthNotifier>().can(
      EmployeePermission.financialEdit,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          t['transaction_number']?.toString() ?? loc.empNavFinOps,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '${loc.empStatus}: ${t['financial_status'] ?? t['lifecycle_state']}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Text(loc.empFinancialTimeline, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...[
          'amount_calculated',
          'deposit_requested',
          'bank_notified',
          'deposit_confirmed',
          'taxes_calculated',
          'settlement_prepared',
          'funds_released',
        ].map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(step.replaceAll('_', ' ')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _escrow,
          enabled: canEdit,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: loc.empRequiredDeposit,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _fees,
          enabled: canEdit,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: loc.empCompanyFees,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tax,
          enabled: canEdit,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: loc.empTaxes,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commission,
          enabled: canEdit,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: loc.empOfficeCommission,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reason,
          enabled: canEdit,
          decoration: InputDecoration(
            labelText: loc.empChangeReason,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        if (canEdit)
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(loc.empSaveFinancials),
          ),
        const SizedBox(height: 8),
        if (canEdit)
          OutlinedButton(
            onPressed: _sendPaymentRequest,
            child: Text(loc.empSendPaymentRequest),
          ),
        const SizedBox(height: 12),
        Text(
          '${loc.empDeposited}: ${t['deposited_escrow_amount'] ?? 0}',
          style: theme.textTheme.bodyLarge,
        ),
        Text(
          '${loc.empSalePrice}: ${t['sale_price'] ?? '—'}',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
