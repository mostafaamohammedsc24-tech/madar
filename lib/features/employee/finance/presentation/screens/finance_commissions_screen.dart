import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class FinanceCommissionsScreen extends StatefulWidget {
  const FinanceCommissionsScreen({super.key});

  @override
  State<FinanceCommissionsScreen> createState() =>
      _FinanceCommissionsScreenState();
}

class _FinanceCommissionsScreenState extends State<FinanceCommissionsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rules = [];
  List<Map<String, dynamic>> _fees = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<EmployeeAuthNotifier>().repository;
    setState(() => _loading = true);
    final rules = await repo.listCommissionRules();
    final fees = await repo.listFeeDefinitions();
    if (!mounted) return;
    setState(() {
      _rules = rules;
      _fees = fees;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(loc.empCommissionRules, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            loc.empCommissionRulesHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (_rules.isEmpty)
            Text(loc.empEmptyRules)
          else
            ..._rules.map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${r['country_code']} · ${r['transaction_type']} · '
                  '${r['property_source']} / ${r['buyer_source']}',
                ),
                subtitle: Text(
                  'Office ${(r['office_share'] as num?)?.toDouble() ?? 0} · '
                  'Company ${(r['company_share'] as num?)?.toDouble() ?? 0}',
                ),
              ),
            ),
          const SizedBox(height: 28),
          Text(loc.empFeeEngine, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_fees.isEmpty)
            Text(loc.empEmptyFees)
          else
            ..._fees.map(
              (f) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(f['name']?.toString() ?? ''),
                subtitle: Text(
                  '${f['fee_type']} · ${f['country_code']} · payer: ${f['payer']}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
