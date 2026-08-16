import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/domain/employee_models.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class OmDashboardScreen extends StatefulWidget {
  const OmDashboardScreen({super.key});

  @override
  State<OmDashboardScreen> createState() => _OmDashboardScreenState();
}

class _OmDashboardScreenState extends State<OmDashboardScreen> {
  bool _loading = true;
  OfficeMgmtDashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<EmployeeAuthNotifier>().repository;
    setState(() => _loading = true);
    final stats = await repo.officeMgmtDashboardStats();
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
            loc.empOmWorkspace,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.empOmWorkspaceSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (s != null)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Tile(loc.empStatActiveOffices, '${s.activeOffices}'),
                _Tile(loc.empStatPendingOfficeRequests, '${s.pendingRequests}'),
                _Tile(loc.empStatNewPropertyReports, '${s.newPropertyReports}'),
                _Tile(loc.empStatAwaitingPhotography, '${s.awaitingPhotography}'),
                _Tile(loc.empStatActiveOfficeTx, '${s.activeOfficeTransactions}'),
              ],
            ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () => context.go('/employee/om/offices'),
            child: Text(loc.empManageOffices),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value);
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
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
