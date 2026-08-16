import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficePerformanceScreen extends StatefulWidget {
  const OfficePerformanceScreen({super.key});

  @override
  State<OfficePerformanceScreen> createState() =>
      _OfficePerformanceScreenState();
}

class _OfficePerformanceScreenState extends State<OfficePerformanceScreen> {
  bool _loading = true;
  int _properties = 0;
  int _buyers = 0;
  int _transactions = 0;
  int _completed = 0;
  int _reports = 0;
  int _activeProps = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _loading = true);
    final assigned = await repo.loadOfficeAssignedProperties();
    final referrals = await repo.listReferrals();
    final txs = await repo.listOfficeTransactions();
    final reports = await repo.listReports();
    if (!mounted) return;
    setState(() {
      _properties = assigned.length;
      _activeProps = assigned
          .where((e) => (e['status'] as String?) == 'active')
          .length;
      _buyers = referrals.length;
      _transactions = txs.length;
      _completed = txs
          .where(
            (t) =>
                (t['lifecycle_state'] as String? ?? t['status'] as String? ?? '')
                    .toLowerCase() ==
                'completed',
          )
          .length;
      _reports = reports.length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final conversion = _transactions == 0
        ? 0.0
        : (_completed / _transactions) * 100;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text(loc.officePerformance)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _Metric(label: loc.officePerfProperties, value: '$_properties'),
                      _Metric(label: loc.officePerfBuyers, value: '$_buyers'),
                      _Metric(label: loc.officePerfTransactions, value: '$_transactions'),
                      _Metric(
                        label: loc.officePerfCompletion,
                        value: '${conversion.toStringAsFixed(0)}%',
                      ),
                      _Metric(label: loc.officePerfActive, value: '$_activeProps'),
                      _Metric(label: loc.officePerfLeads, value: '$_reports'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(loc.officePerfCompletion, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_transactions == 0)
                          ? 0
                          : _completed / _transactions,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_completed / $_transactions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
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
