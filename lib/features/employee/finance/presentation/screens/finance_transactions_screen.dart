import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class FinanceTransactionsScreen extends StatefulWidget {
  const FinanceTransactionsScreen({super.key});

  @override
  State<FinanceTransactionsScreen> createState() =>
      _FinanceTransactionsScreenState();
}

class _FinanceTransactionsScreenState extends State<FinanceTransactionsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<EmployeeAuthNotifier>().repository;
    setState(() => _loading = true);
    final list = await repo.listTransactions(query: _search.text);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: loc.empSearchTransactions,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(child: Text(loc.empEmptyTransactions)),
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
                              title: Text(
                                t['transaction_number']?.toString() ?? '—',
                              ),
                              subtitle: Text(
                                '${t['transaction_type'] ?? ''} · '
                                '${t['financial_status'] ?? t['lifecycle_state'] ?? ''}\n'
                                '${loc.empSalePrice}: ${t['sale_price'] ?? '—'} · '
                                '${loc.empRequiredDeposit}: ${t['required_escrow_amount'] ?? '—'}',
                              ),
                              isThreeLine: true,
                              onTap: () => context.push(
                                '/employee/finance/transaction/${t['id']}',
                                extra: t,
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}
