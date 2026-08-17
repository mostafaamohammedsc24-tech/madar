import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class FinanceOfficesAccountsScreen extends StatefulWidget {
  const FinanceOfficesAccountsScreen({super.key});

  @override
  State<FinanceOfficesAccountsScreen> createState() =>
      _FinanceOfficesAccountsScreenState();
}

class _FinanceOfficesAccountsScreenState
    extends State<FinanceOfficesAccountsScreen> {
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
    final list = await repo.listOfficeAccounts();
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

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(loc.empEmptyOffices)),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final row = _items[i];
                      final o = row['office'] as Map<String, dynamic>;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        title: Text(o['name']?.toString() ?? ''),
                        subtitle: Text(
                          '${o['office_code']} · '
                          '${loc.empTransactions}: ${row['transactions']} · '
                          '${loc.empOfficeCommission}: ${row['office_commission']}',
                        ),
                      );
                    },
                  ),
          );
  }
}
