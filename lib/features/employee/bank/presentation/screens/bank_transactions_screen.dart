import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class BankTransactionsScreen extends StatefulWidget {
  const BankTransactionsScreen({super.key});

  @override
  State<BankTransactionsScreen> createState() => _BankTransactionsScreenState();
}

class _BankTransactionsScreenState extends State<BankTransactionsScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

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
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: loc.empBankSearchHint,
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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final t = _items[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        title: Text(t['transaction_number']?.toString() ?? ''),
                        subtitle: Text(
                          '${loc.empRequiredDeposit}: ${t['required_escrow_amount'] ?? '—'} · '
                          '${t['financial_status'] ?? ''}',
                        ),
                        onTap: () => context.push(
                          '/employee/bank/transaction/${t['id']}',
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
