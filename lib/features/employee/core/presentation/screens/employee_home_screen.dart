import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../domain/employee_permissions.dart';
import '../providers/employee_auth_notifier.dart';
import '../shell/employee_nav_config.dart';
import 'employee_work_screen.dart';
import '../../../sales/data/sales_repository.dart';
import '../../../hr/data/hr_repository.dart';

/// Role Home — greeting + focus metrics + today's tasks (not an ERP dashboard).
class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  Map<String, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCounts());
  }

  Future<void> _loadCounts() async {
    final auth = context.read<EmployeeAuthNotifier>();
    final emp = auth.employee;
    if (emp == null) return;
    Map<String, int> counts = const {};
    try {
      switch (emp.department.departmentCode) {
        case EmployeeDepartmentCode.sales:
          counts = await SalesRepository(auth.repository).homeCounts();
          break;
        case EmployeeDepartmentCode.hr:
          counts = await HrRepository(auth.repository).directoryCounts();
          break;
        default:
          counts = const {};
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _counts = counts);
  }

  List<WorkQueueItem> _enrichedQueues(
    List<WorkQueueItem> base,
  ) {
    if (_counts.isEmpty) return base;
    return base.map((q) {
      final route = q.route;
      int? c;
      if (route.contains('/sales/leads')) c = _counts['leads'];
      if (route.contains('/sales/followups')) c = _counts['followups'];
      if (route.contains('/sales/deals')) c = _counts['deals'];
      if (route.contains('/hr/employees') && !route.contains('create')) {
        c = _counts['total'];
      }
      return WorkQueueItem(
        title: q.title,
        count: c ?? q.count,
        route: q.route,
        subtitle: q.subtitle,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<EmployeeAuthNotifier>().employee;
    if (employee == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? loc.empGoodMorning
        : (hour < 18 ? loc.empGoodAfternoon : loc.empGoodEvening);
    final queues = _enrichedQueues(workQueuesFor(employee, loc)).take(5).toList();

    return RefreshIndicator(
      onRefresh: _loadCounts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            '$greet,',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            employee.fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${employee.jobTitle ?? employee.role.nameEn} · ${employee.employeeCode}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.empFocusToday,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final q in queues.take(4))
                _FocusStat(
                  label: q.title,
                  value: '${q.count}',
                  onTap: () => context.push(q.route),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.empTodaysTasks,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/employee/work'),
                child: Text(loc.empOpenWork),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...queues.map(
            (q) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(q.title),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => context.push(q.route),
            ),
          ),
          if (queues.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                loc.empNoWorkQueues,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (employee.department.departmentCode ==
              EmployeeDepartmentCode.unknown)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                loc.empNoWorkspace,
                style: theme.textTheme.bodyLarge,
              ),
            ),
        ],
      ),
    );
  }
}

class _FocusStat extends StatelessWidget {
  const _FocusStat({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final tileW = width >= 900 ? 160.0 : (width - 44) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: tileW,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
