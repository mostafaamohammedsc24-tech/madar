import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../services/publisher_seed.dart';
import '../../domain/employee_models.dart';
import '../../domain/employee_permissions.dart';
import '../../../publishing/presentation/screens/publisher_work_screen.dart';
import '../../../bank/presentation/screens/bank_work_screen.dart';
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
    if (employee.isPublishing) {
      return const PublisherWorkScreen();
    }
    if (employee.isBank) {
      return const BankWorkScreen();
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
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cross-role tools',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.qr_code_scanner),
          title: Text(loc.scanBarcode),
          subtitle: const Text('Read published deal & property barcodes'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/barcode-reader'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_tree_outlined),
          title: const Text('Deal workflow'),
          subtitle: const Text('Office → lawyers → finance → closing → publish'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/deal-workflow'),
        ),
        const SizedBox(height: 12),
        Text(
          'My queues',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        ...queues.map(
          (q) => _QueueTile(
            title: q.title,
            count: q.count,
            subtitle: q.subtitle,
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
        WorkQueueItem(
          title: 'Properties workspace',
          count: PublisherSeed.assets().length,
          route: '/employee/publishing/properties',
        ),
        WorkQueueItem(
          title: 'Publishing requests',
          count: PublisherSeed.assets().length,
          route: '/employee/publishing/requests',
        ),
        const WorkQueueItem(
          title: 'New request',
          count: 0,
          route: '/employee/publishing/create',
        ),
        WorkQueueItem(
          title: 'Ready to publish',
          count: PublisherSeed.assets()
              .where((a) => a.pipelineStatus == 'ready_for_publication')
              .length,
          route: '/employee/publishing/requests',
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
        const WorkQueueItem(
          title: 'Start closing',
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
        const WorkQueueItem(
          title: 'Urgent',
          count: 0,
          route: '/employee/support/tickets',
        ),
      ];
    case EmployeeDepartmentCode.quality:
      return [
        const WorkQueueItem(
          title: 'Review queue',
          count: 0,
          route: '/employee/quality/queue',
        ),
      ];
    case EmployeeDepartmentCode.compliance:
      return [
        const WorkQueueItem(
          title: 'Compliance cases',
          count: 0,
          route: '/employee/compliance/cases',
        ),
        WorkQueueItem(
          title: loc.empNavAudit,
          count: 0,
          route: '/employee/audit',
        ),
      ];
    case EmployeeDepartmentCode.systemAdmin:
      return [
        const WorkQueueItem(
          title: 'System configuration',
          count: 0,
          route: '/employee/system/admin',
        ),
        WorkQueueItem(
          title: loc.empNavAudit,
          count: 0,
          route: '/employee/audit',
        ),
      ];
    case EmployeeDepartmentCode.executive:
      return [
        const WorkQueueItem(
          title: 'Executive overview',
          count: 0,
          route: '/employee/executive/overview',
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
