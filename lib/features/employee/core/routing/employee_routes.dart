import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'employee_portal_library.dart' as portal;
import 'employee_globals.dart';

List<RouteBase> buildEmployeeRoutes({
  Widget Function(Widget Function() builder)? gate,
}) {
  Widget gated(Widget Function() builder) =>
      gate != null ? gate(builder) : builder();

  Widget wrap(Widget child) => provider.ChangeNotifierProvider.value(
        value: employeeAuthNotifier,
        child: child,
      );

  return [
    GoRoute(
      path: '/employee-login',
      builder: (context, state) => wrap(
        gated(() => portal.EmployeeLoginScreen()),
      ),
    ),
    GoRoute(
      path: '/employee-portal',
      redirect: (context, state) =>
          employeeAuthNotifier.isAuthenticated
              ? '/employee/home'
              : '/employee-login',
    ),
    ShellRoute(
      builder: (context, state, child) => wrap(
        gated(() => portal.EmployeeShell(child: child)),
      ),
      routes: [
        GoRoute(
          path: '/employee/home',
          builder: (context, state) =>
              gated(() => portal.EmployeeHomeScreen()),
        ),
        GoRoute(
          path: '/employee/work',
          builder: (context, state) =>
              gated(() => portal.EmployeeWorkScreen()),
        ),
        GoRoute(
          path: '/employee/messages',
          builder: (context, state) =>
              gated(() => portal.EmployeeMessagesScreen()),
        ),
        GoRoute(
          path: '/employee/profile',
          builder: (context, state) =>
              gated(() => portal.EmployeeProfileScreen()),
        ),
        GoRoute(
          path: '/employee/notifications',
          builder: (context, state) =>
              gated(() => portal.EmployeeNotificationsScreen()),
        ),
        GoRoute(
          path: '/employee/search',
          builder: (context, state) =>
              gated(() => portal.EmployeeSearchScreen()),
        ),
        GoRoute(
          path: '/employee/audit',
          builder: (context, state) =>
              gated(() => portal.EmployeeAuditScreen()),
        ),
        GoRoute(
          path: '/employee/finance/transactions',
          builder: (context, state) =>
              gated(() => portal.FinanceTransactionsScreen()),
        ),
        GoRoute(
          path: '/employee/finance/deposits',
          builder: (context, state) =>
              gated(() => portal.FinanceDepositsScreen()),
        ),
        GoRoute(
          path: '/employee/finance/offices',
          builder: (context, state) =>
              gated(() => portal.FinanceOfficesAccountsScreen()),
        ),
        GoRoute(
          path: '/employee/finance/commissions',
          builder: (context, state) =>
              gated(() => portal.FinanceCommissionsScreen()),
        ),
        GoRoute(
          path: '/employee/finance/settlements',
          builder: (context, state) =>
              gated(() => portal.FinanceSettlementsScreen()),
        ),
        GoRoute(
          path: '/employee/finance/transaction/:id',
          builder: (context, state) {
            final tx = state.extra as Map<String, dynamic>? ??
                {'id': state.pathParameters['id']};
            return gated(
              () => portal.FinanceTransactionDetailScreen(transaction: tx),
            );
          },
        ),
        GoRoute(
          path: '/employee/bank/transactions',
          builder: (context, state) =>
              gated(() => portal.BankTransactionsScreen()),
        ),
        GoRoute(
          path: '/employee/bank/deposits',
          builder: (context, state) =>
              gated(() => portal.FinanceDepositsScreen()),
        ),
        GoRoute(
          path: '/employee/bank/receipts',
          builder: (context, state) =>
              gated(() => portal.BankReceiptsScreen()),
        ),
        GoRoute(
          path: '/employee/bank/transaction/:id',
          builder: (context, state) {
            final tx = state.extra as Map<String, dynamic>? ??
                {'id': state.pathParameters['id']};
            return gated(
              () => portal.BankTransactionDetailScreen(transaction: tx),
            );
          },
        ),
        GoRoute(
          path: '/employee/om/offices',
          builder: (context, state) => gated(() => portal.OmOfficesScreen()),
        ),
        GoRoute(
          path: '/employee/om/offices/create',
          builder: (context, state) =>
              gated(() => portal.OmCreateOfficeScreen()),
        ),
        GoRoute(
          path: '/employee/om/reports',
          builder: (context, state) => gated(() => portal.OmReportsScreen()),
        ),
        GoRoute(
          path: '/employee/om/photography',
          builder: (context, state) =>
              gated(() => portal.OmPhotographyScreen()),
        ),
        GoRoute(
          path: '/employee/om/conversations',
          builder: (context, state) =>
              gated(() => portal.OmConversationsScreen()),
        ),
        GoRoute(
          path: '/employee/publishing/requests',
          builder: (context, state) =>
              gated(() => portal.PublishingRequestsScreen()),
        ),
        GoRoute(
          path: '/employee/publishing/create',
          builder: (context, state) =>
              gated(() => portal.PublishingCreateRequestScreen()),
        ),
        GoRoute(
          path: '/employee/publishing/property/:id',
          builder: (context, state) => gated(
            () => portal.PropertyCommandCenterScreen(
              propertyAssetId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/employee/information/assigned',
          builder: (context, state) => gated(
            () => portal.PublishingRequestsScreen(assignedOnly: true),
          ),
        ),
        GoRoute(
          path: '/employee/information/property/:id',
          builder: (context, state) => gated(
            () => portal.InformationReportScreen(
              propertyAssetId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/employee/media/assigned',
          builder: (context, state) => gated(
            () => portal.PublishingRequestsScreen(assignedOnly: true),
          ),
        ),
        GoRoute(
          path: '/employee/media/property/:id',
          builder: (context, state) => gated(
            () => portal.MediaWorkspaceScreen(
              propertyAssetId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/employee/engineering/assigned',
          builder: (context, state) => gated(
            () => portal.PublishingRequestsScreen(assignedOnly: true),
          ),
        ),
        GoRoute(
          path: '/employee/engineering/property/:id',
          builder: (context, state) => gated(
            () => portal.EngineeringWorkspaceScreen(
              propertyAssetId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/employee/sales/leads',
          builder: (context, state) => gated(() => portal.SalesLeadsScreen()),
        ),
        GoRoute(
          path: '/employee/sales/followups',
          builder: (context, state) =>
              gated(() => portal.SalesFollowUpsScreen()),
        ),
        GoRoute(
          path: '/employee/sales/deals',
          builder: (context, state) => gated(() => portal.SalesDealsScreen()),
        ),
        GoRoute(
          path: '/employee/legal/contracts',
          builder: (context, state) {
            final filter = state.uri.queryParameters['filter'];
            return gated(
              () => portal.ContractListScreen(statusFilter: filter),
            );
          },
        ),
        GoRoute(
          path: '/employee/legal/contracts/:id',
          builder: (context, state) => gated(
            () => portal.ContractWorkspaceScreen(
              contractId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/employee/legal/transactions',
          builder: (context, state) =>
              gated(() => portal.TransactionLawyerScreen()),
        ),
        GoRoute(
          path: '/employee/legal/transactions/:id',
          builder: (context, state) => gated(
            () => portal.TransactionTimelineScreen(
              transactionId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/employee/legal/ownership',
          builder: (context, state) =>
              gated(() => portal.OwnershipTransfersScreen()),
        ),
        GoRoute(
          path: '/employee/hr/employees',
          builder: (context, state) => gated(() => portal.HrEmployeesScreen()),
        ),
        GoRoute(
          path: '/employee/hr/employees/create',
          builder: (context, state) =>
              gated(() => portal.HrCreateEmployeeScreen()),
        ),
        GoRoute(
          path: '/employee/hr/organization',
          builder: (context, state) =>
              gated(() => portal.HrOrganizationScreen()),
        ),
        GoRoute(
          path: '/employee/closing/cases',
          builder: (context, state) =>
              gated(() => portal.ClosingCasesScreen()),
        ),
        GoRoute(
          path: '/employee/support/tickets',
          builder: (context, state) =>
              gated(() => portal.SupportTicketsScreen()),
        ),
        GoRoute(
          path: '/employee/quality/queue',
          builder: (context, state) =>
              gated(() => portal.QualityReviewScreen()),
        ),
        GoRoute(
          path: '/employee/compliance/cases',
          builder: (context, state) =>
              gated(() => portal.ComplianceCasesScreen()),
        ),
        GoRoute(
          path: '/employee/system/admin',
          builder: (context, state) =>
              gated(() => portal.SystemAdminScreen()),
        ),
        GoRoute(
          path: '/employee/executive/overview',
          builder: (context, state) =>
              gated(() => portal.ExecutiveDashboardScreen()),
        ),
      ],
    ),
  ];
}
