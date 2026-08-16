import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

/// Shared deposits list used by Finance and Bank with permission-gated data.
class FinanceDepositsScreen extends StatefulWidget {
  const FinanceDepositsScreen({super.key});

  @override
  State<FinanceDepositsScreen> createState() => _FinanceDepositsScreenState();
}

class _FinanceDepositsScreenState extends State<FinanceDepositsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<EmployeeAuthNotifier>().repository;
    setState(() => _loading = true);
    final awaiting = await repo.listTransactions(
      financialStatus: 'awaiting_deposit',
    );
    final partial = await repo.listTransactions(
      financialStatus: 'partially_deposited',
    );
    if (!mounted) return;
    setState(() {
      _items = [...awaiting, ...partial];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(loc.empEmptyDeposits)),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final t = _items[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        title: Text(t['transaction_number']?.toString() ?? ''),
                        subtitle: Text(
                          '${t['financial_status']} · '
                          '${loc.empRequiredDeposit}: ${t['required_escrow_amount'] ?? '—'} · '
                          '${loc.empDeposited}: ${t['deposited_escrow_amount'] ?? 0}',
                        ),
                        onTap: () => context.push(
                          '/employee/finance/transaction/${t['id']}',
                          extra: t,
                        ),
                      );
                    },
                  ),
          );
  }
}
