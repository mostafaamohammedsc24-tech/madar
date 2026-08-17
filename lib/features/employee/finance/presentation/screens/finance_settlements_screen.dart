import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class FinanceSettlementsScreen extends StatefulWidget {
  const FinanceSettlementsScreen({super.key});

  @override
  State<FinanceSettlementsScreen> createState() =>
      _FinanceSettlementsScreenState();
}

class _FinanceSettlementsScreenState extends State<FinanceSettlementsScreen> {
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
    final list = await repo.listOfficeSettlements();
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
                      Center(child: Text(loc.empEmptySettlements)),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final s = _items[i];
                      final office = s['offices'] as Map?;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        title: Text(
                          office?['name']?.toString() ??
                              s['office_id']?.toString() ??
                              '',
                        ),
                        subtitle: Text(
                          '${loc.empStatus}: ${s['status']} · '
                          '${loc.empAmountDue}: ${s['amount_due']} · '
                          '${loc.empAmountPaid}: ${s['amount_paid']}',
                        ),
                      );
                    },
                  ),
          );
  }
}
