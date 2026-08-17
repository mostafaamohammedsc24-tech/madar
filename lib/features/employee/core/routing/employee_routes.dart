import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import '../presentation/screens/employee_audit_screen.dart';
import '../presentation/screens/employee_home_screen.dart';
import '../presentation/screens/employee_login_screen.dart';
import '../presentation/screens/employee_notifications_screen.dart';
import '../presentation/screens/employee_profile_screen.dart';
import '../presentation/screens/employee_search_screen.dart';
import '../presentation/shell/employee_shell.dart';
import '../../finance/presentation/screens/finance_commissions_screen.dart';
import '../../finance/presentation/screens/finance_deposits_screen.dart';
import '../../finance/presentation/screens/finance_offices_accounts_screen.dart';
import '../../finance/presentation/screens/finance_settlements_screen.dart';
import '../../finance/presentation/screens/finance_transaction_detail_screen.dart';
import '../../finance/presentation/screens/finance_transactions_screen.dart';
import '../../bank/presentation/screens/bank_receipts_screen.dart';
import '../../bank/presentation/screens/bank_transaction_detail_screen.dart';
import '../../bank/presentation/screens/bank_transactions_screen.dart';
import '../../office_management/presentation/screens/om_conversations_screen.dart';
import '../../office_management/presentation/screens/om_create_office_screen.dart';
import '../../office_management/presentation/screens/om_offices_screen.dart';
import '../../office_management/presentation/screens/om_photography_screen.dart';
import '../../office_management/presentation/screens/om_reports_screen.dart';
import '../../publishing/presentation/screens/engineering_workspace_screen.dart';
import '../../publishing/presentation/screens/information_report_screen.dart';
import '../../publishing/presentation/screens/media_workspace_screen.dart';
import '../../publishing/presentation/screens/property_command_center_screen.dart';
import '../../publishing/presentation/screens/publishing_create_request_screen.dart';
import '../../publishing/presentation/screens/publishing_requests_screen.dart';
import 'employee_globals.dart';

List<RouteBase> buildEmployeeRoutes() {
  Widget wrap(Widget child) => provider.ChangeNotifierProvider.value(
        value: employeeAuthNotifier,
        child: child,
      );

  return [
    GoRoute(
      path: '/employee-login',
      builder: (context, state) => wrap(const EmployeeLoginScreen()),
    ),
    // Legacy entry from partner strip
    GoRoute(
      path: '/employee-portal',
      redirect: (context, state) =>
          employeeAuthNotifier.isAuthenticated
              ? '/employee/home'
              : '/employee-login',
    ),
    ShellRoute(
      builder: (context, state, child) => wrap(EmployeeShell(child: child)),
      routes: [
        GoRoute(
          path: '/employee/home',
          builder: (context, state) => const EmployeeHomeScreen(),
        ),
        GoRoute(
          path: '/employee/profile',
          builder: (context, state) => const EmployeeProfileScreen(),
        ),
        GoRoute(
          path: '/employee/notifications',
          builder: (context, state) => const EmployeeNotificationsScreen(),
        ),
        GoRoute(
          path: '/employee/search',
          builder: (context, state) => const EmployeeSearchScreen(),
        ),
        GoRoute(
          path: '/employee/audit',
          builder: (context, state) => const EmployeeAuditScreen(),
        ),
        // Finance
        GoRoute(
          path: '/employee/finance/transactions',
          builder: (context, state) => const FinanceTransactionsScreen(),
        ),
        GoRoute(
          path: '/employee/finance/deposits',
          builder: (context, state) => const FinanceDepositsScreen(),
        ),
        GoRoute(
          path: '/employee/finance/offices',
          builder: (context, state) => const FinanceOfficesAccountsScreen(),
        ),
        GoRoute(
          path: '/employee/finance/commissions',
          builder: (context, state) => const FinanceCommissionsScreen(),
        ),
        GoRoute(
          path: '/employee/finance/settlements',
          builder: (context, state) => const FinanceSettlementsScreen(),
        ),
        GoRoute(
          path: '/employee/finance/transaction/:id',
          builder: (context, state) {
            final tx = state.extra as Map<String, dynamic>? ??
                {'id': state.pathParameters['id']};
            return FinanceTransactionDetailScreen(transaction: tx);
          },
        ),
        // Bank
        GoRoute(
          path: '/employee/bank/transactions',
          builder: (context, state) => const BankTransactionsScreen(),
        ),
        GoRoute(
          path: '/employee/bank/deposits',
          builder: (context, state) => const FinanceDepositsScreen(),
        ),
        GoRoute(
          path: '/employee/bank/receipts',
          builder: (context, state) => const BankReceiptsScreen(),
        ),
        GoRoute(
          path: '/employee/bank/transaction/:id',
          builder: (context, state) {
            final tx = state.extra as Map<String, dynamic>? ??
                {'id': state.pathParameters['id']};
            return BankTransactionDetailScreen(transaction: tx);
          },
        ),
        // Office management
        GoRoute(
          path: '/employee/om/offices',
          builder: (context, state) => const OmOfficesScreen(),
        ),
        GoRoute(
          path: '/employee/om/offices/create',
          builder: (context, state) => const OmCreateOfficeScreen(),
        ),
        GoRoute(
          path: '/employee/om/reports',
          builder: (context, state) => const OmReportsScreen(),
        ),
        GoRoute(
          path: '/employee/om/photography',
          builder: (context, state) => const OmPhotographyScreen(),
        ),
        GoRoute(
          path: '/employee/om/conversations',
          builder: (context, state) => const OmConversationsScreen(),
        ),
        // Publishing ops
        GoRoute(
          path: '/employee/publishing/requests',
          builder: (context, state) => const PublishingRequestsScreen(),
        ),
        GoRoute(
          path: '/employee/publishing/create',
          builder: (context, state) => const PublishingCreateRequestScreen(),
        ),
        GoRoute(
          path: '/employee/publishing/property/:id',
          builder: (context, state) => PropertyCommandCenterScreen(
            propertyAssetId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/employee/information/assigned',
          builder: (context, state) =>
              const PublishingRequestsScreen(assignedOnly: true),
        ),
        GoRoute(
          path: '/employee/information/property/:id',
          builder: (context, state) => InformationReportScreen(
            propertyAssetId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/employee/media/assigned',
          builder: (context, state) =>
              const PublishingRequestsScreen(assignedOnly: true),
        ),
        GoRoute(
          path: '/employee/media/property/:id',
          builder: (context, state) => MediaWorkspaceScreen(
            propertyAssetId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/employee/engineering/assigned',
          builder: (context, state) =>
              const PublishingRequestsScreen(assignedOnly: true),
        ),
        GoRoute(
          path: '/employee/engineering/property/:id',
          builder: (context, state) => EngineeringWorkspaceScreen(
            propertyAssetId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
  ];
}
