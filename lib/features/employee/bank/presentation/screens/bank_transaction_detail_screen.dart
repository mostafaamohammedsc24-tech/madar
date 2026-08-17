import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/domain/employee_permissions.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class BankTransactionDetailScreen extends StatefulWidget {
  const BankTransactionDetailScreen({super.key, required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  State<BankTransactionDetailScreen> createState() =>
      _BankTransactionDetailScreenState();
}

class _BankTransactionDetailScreenState
    extends State<BankTransactionDetailScreen> {
  final _otpCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String? _maskedPhone;
  bool _verified = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _verified = widget.transaction['buyer_identity_verified'] == true;
    _amountCtrl.text =
        widget.transaction['required_escrow_amount']?.toString() ?? '';
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<EmployeeAuthNotifier>();
    setState(() => _busy = true);
    final res = await auth.repository.requestBuyerOtp(
      widget.transaction['id'].toString(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _maskedPhone = res.phoneMasked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? '${loc.empOtpSent} ${res.phoneMasked ?? ''}'
              : (res.message ?? loc.empActionFailed),
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<EmployeeAuthNotifier>();
    setState(() => _busy = true);
    final res = await auth.repository.verifyBuyerOtp(
      transactionId: widget.transaction['id'].toString(),
      otp: _otpCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _verified = res.success;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success ? loc.empIdentityConfirmed : (res.message ?? loc.empActionFailed),
        ),
      ),
    );
  }

  Future<void> _confirmDeposit() async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<EmployeeAuthNotifier>();
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || _refCtrl.text.trim().isEmpty) return;
    final required =
        (widget.transaction['required_escrow_amount'] as num?)?.toDouble();
    final allowPartial = auth.can(EmployeePermission.bankPartialDeposit) &&
        required != null &&
        amount < required;

    setState(() => _busy = true);
    final res = await auth.repository.confirmDeposit(
      transactionId: widget.transaction['id'].toString(),
      actualAmount: amount,
      referenceNumber: _refCtrl.text.trim(),
      depositDate: DateTime.now(),
      allowPartial: allowPartial,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? '${loc.empDepositConfirmed} (${res.status})'
              : (res.message ?? loc.empActionFailed),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = widget.transaction;
    final auth = context.watch<EmployeeAuthNotifier>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          t['transaction_number']?.toString() ?? '',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('${loc.empBuyer}: ${t['buyer_phone'] ?? '—'}'),
        Text('${loc.empSeller}: ${t['seller_phone'] ?? '—'}'),
        Text('${loc.empRequiredDeposit}: ${t['required_escrow_amount'] ?? '—'}'),
        Text('${loc.empDeposited}: ${t['deposited_escrow_amount'] ?? 0}'),
        Text('${loc.empStatus}: ${t['financial_status'] ?? ''}'),
        const SizedBox(height: 24),
        if (auth.can(EmployeePermission.bankVerify)) ...[
          Text(loc.empVerifyBuyer, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_verified)
            Text(
              loc.empIdentityConfirmed,
              style: TextStyle(color: theme.colorScheme.primary),
            )
          else ...[
            FilledButton.tonal(
              onPressed: _busy ? null : _sendOtp,
              child: Text(loc.empSendOtp),
            ),
            if (_maskedPhone != null) ...[
              const SizedBox(height: 8),
              Text('${loc.empOtpSent}: $_maskedPhone'),
              const SizedBox(height: 8),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.empEnterOtp,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _verifyOtp,
                child: Text(loc.empConfirmOtp),
              ),
            ],
          ],
          const SizedBox(height: 28),
        ],
        if (auth.can(EmployeePermission.bankDepositConfirm)) ...[
          Text(loc.empConfirmDeposit, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.empActualDeposited,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _refCtrl,
            decoration: InputDecoration(
              labelText: loc.empReferenceNumber,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (_busy || !_verified) ? null : _confirmDeposit,
            child: Text(loc.empConfirmDeposit),
          ),
          if (!_verified)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                loc.empVerifyBeforeDeposit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
