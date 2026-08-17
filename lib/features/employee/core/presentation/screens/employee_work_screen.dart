import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../domain/employee_models.dart';
import '../../domain/employee_permissions.dart';
import '../providers/employee_auth_notifier.dart';
import '../shell/employee_nav_config.dart';

/// Contextual Work hub — queues and tools for the current role only.
class EmployeeWorkScreen extends StatelessWidget {
  const EmployeeWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<EmployeeAuthNotifier>().employee;
    if (employee == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final queues = workQueuesFor(employee, loc);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          loc.empWorkTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          loc.empWorkSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          loc.empTodaysWork,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...queues.map(
          (q) => _QueueTile(
            title: q.title,
            subtitle: q.subtitle,
            count: q.count,
            onTap: () => context.push(q.route),
          ),
        ),
        if (queues.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              loc.empNoWorkQueues,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

List<WorkQueueItem> workQueuesFor(
  EmployeeAccount employee,
  AppLocalizations loc,
) {
  switch (employee.department.departmentCode) {
    case EmployeeDepartmentCode.finance:
      return [
        WorkQueueItem(
          title: loc.empStatTodaysOps,
          count: 0,
          route: '/employee/finance/transactions',
        ),
        WorkQueueItem(
          title: loc.empStatPendingDeposits,
          count: 0,
          route: '/employee/finance/deposits',
        ),
        WorkQueueItem(
          title: loc.empNavSettlements,
          count: 0,
          route: '/employee/finance/settlements',
        ),
        if (employee.can(EmployeePermission.financialRules))
          WorkQueueItem(
            title: loc.empNavCommissions,
            count: 0,
            route: '/employee/finance/commissions',
          ),
        if (employee.can(EmployeePermission.auditView))
          WorkQueueItem(
            title: loc.empNavAudit,
            count: 0,
            route: '/employee/audit',
          ),
      ];
    case EmployeeDepartmentCode.bank:
      return [
        WorkQueueItem(
          title: loc.empNavOperations,
          count: 0,
          route: '/employee/bank/transactions',
        ),
        WorkQueueItem(
          title: loc.empNavDeposits,
          count: 0,
          route: '/employee/bank/deposits',
        ),
        WorkQueueItem(
          title: loc.empNavReceipts,
          count: 0,
          route: '/employee/bank/receipts',
        ),
      ];
    case EmployeeDepartmentCode.officeManagement:
      return [
        WorkQueueItem(
          title: loc.empNavOffices,
          count: 0,
          route: '/employee/om/offices',
        ),
        WorkQueueItem(
          title: loc.empNavReports,
          count: 0,
          route: '/employee/om/reports',
        ),
        WorkQueueItem(
          title: loc.empNavPhotography,
          count: 0,
          route: '/employee/om/photography',
        ),
        WorkQueueItem(
          title: loc.empNavChats,
          count: 0,
          route: '/employee/om/conversations',
        ),
      ];
    case EmployeeDepartmentCode.publishing:
      return [
        const WorkQueueItem(
          title: 'Publishing requests',
          count: 0,
          route: '/employee/publishing/requests',
        ),
        const WorkQueueItem(
          title: 'New request',
          count: 0,
          route: '/employee/publishing/create',
        ),
      ];
    case EmployeeDepartmentCode.information:
      return [
        const WorkQueueItem(
          title: 'My field visits',
          count: 0,
          route: '/employee/information/assigned',
        ),
      ];
    case EmployeeDepartmentCode.photography:
      return [
        const WorkQueueItem(
          title: "Today's shoots",
          count: 0,
          route: '/employee/media/assigned',
        ),
      ];
    case EmployeeDepartmentCode.engineering:
      return [
        const WorkQueueItem(
          title: 'Floor plans pending',
          count: 0,
          route: '/employee/engineering/assigned',
        ),
      ];
    case EmployeeDepartmentCode.sales:
      return [
        const WorkQueueItem(
          title: 'Leads',
          count: 0,
          route: '/employee/sales/leads',
        ),
        const WorkQueueItem(
          title: 'Follow-ups',
          count: 0,
          route: '/employee/sales/followups',
        ),
        const WorkQueueItem(
          title: 'Property requests',
          count: 0,
          route: '/employee/publishing/create',
        ),
        const WorkQueueItem(
          title: 'Deals / handoff',
          count: 0,
          route: '/employee/sales/deals',
        ),
      ];
    case EmployeeDepartmentCode.contractLawyer:
      return [
        const WorkQueueItem(
          title: 'Contracts to prepare',
          count: 0,
          route: '/employee/legal/contracts',
        ),
        const WorkQueueItem(
          title: 'Awaiting signature',
          count: 0,
          route: '/employee/legal/contracts?filter=awaiting_signature',
        ),
      ];
    case EmployeeDepartmentCode.transactionLawyer:
      return [
        const WorkQueueItem(
          title: 'Active transactions',
          count: 0,
          route: '/employee/legal/transactions',
        ),
        const WorkQueueItem(
          title: 'Ownership transfers',
          count: 0,
          route: '/employee/legal/ownership',
        ),
      ];
    case EmployeeDepartmentCode.hr:
      return [
        const WorkQueueItem(
          title: 'Employees',
          count: 0,
          route: '/employee/hr/employees',
        ),
        const WorkQueueItem(
          title: 'Add employee',
          count: 0,
          route: '/employee/hr/employees/create',
        ),
        const WorkQueueItem(
          title: 'Organization',
          count: 0,
          route: '/employee/hr/organization',
        ),
      ];
    case EmployeeDepartmentCode.closing:
      return [
        const WorkQueueItem(
          title: 'Closing cases',
          count: 0,
          route: '/employee/closing/cases',
        ),
      ];
    case EmployeeDepartmentCode.support:
      return [
        const WorkQueueItem(
          title: 'Open tickets',
          count: 0,
          route: '/employee/support/tickets',
        ),
      ];
    case EmployeeDepartmentCode.quality:
      return [
        const WorkQueueItem(
          title: 'Review queue',
          count: 0,
          route: '/employee/publishing/requests',
        ),
      ];
    case EmployeeDepartmentCode.compliance:
    case EmployeeDepartmentCode.systemAdmin:
    case EmployeeDepartmentCode.executive:
      return [
        WorkQueueItem(
          title: loc.empNavAudit,
          count: 0,
          route: '/employee/audit',
        ),
      ];
    case EmployeeDepartmentCode.unknown:
      return const [];
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.title,
    required this.count,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
