import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../../core/domain/employee_models.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  bool _loading = true;
  FinanceDashboardStats? _stats;
  String _range = 'today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  DateTime? get _from {
    final now = DateTime.now();
    switch (_range) {
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month, 1);
      case 'today':
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  Future<void> _load() async {
    final repo = context.read<EmployeeAuthNotifier>().repository;
    setState(() => _loading = true);
    final stats = await repo.financeDashboardStats(from: _from);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = _stats;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            loc.empFinanceControlCenter,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.empFinanceControlSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final r in [
                ('today', loc.empRangeToday),
                ('week', loc.empRangeWeek),
                ('month', loc.empRangeMonth),
              ])
                ChoiceChip(
                  label: Text(r.$2),
                  selected: _range == r.$1,
                  onSelected: (_) {
                    setState(() => _range = r.$1);
                    _load();
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (s != null)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(loc.empStatTodaysOps, '${s.todaysOps}'),
                _MetricTile(loc.empStatPendingDeposits, '${s.pendingDeposits}'),
                _MetricTile(loc.empStatConfirmedDeposits, '${s.confirmedDeposits}'),
                _MetricTile(loc.empStatUnpaid, '${s.unpaid}'),
                _MetricTile(loc.empStatOverdue, '${s.overdue}'),
                _MetricTile(loc.empStatAwaitingSettlement, '${s.awaitingSettlement}'),
                _MetricTile(
                  loc.empStatOfficeDue,
                  s.officeAmountsDue.toStringAsFixed(0),
                ),
                _MetricTile(
                  loc.empStatRevenue,
                  s.companyRevenue.toStringAsFixed(0),
                ),
                _MetricTile(loc.empStatPendingTransfers, '${s.pendingTransfers}'),
              ],
            ),
          const SizedBox(height: 28),
          FilledButton.tonal(
            onPressed: () => context.go('/employee/finance/transactions'),
            child: Text(loc.empOpenFinancialMonitor),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final tileW = width >= 900 ? (width - 280) / 3 - 16 : (width - 52) / 2;
    return SizedBox(
      width: tileW.clamp(140, 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
