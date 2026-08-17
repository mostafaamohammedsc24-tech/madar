import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import 'office_portal_library.dart' deferred as portal;
import 'office_globals.dart';

Future<void> loadOfficePortalLibrary() => portal.loadLibrary();

/// Office partner portal routes. Pass [gate] to defer-load screens on web.
List<RouteBase> buildOfficeRoutes({
  Widget Function(Widget Function() builder)? gate,
}) {
  Widget gated(Widget Function() builder) =>
      gate != null ? gate(builder) : builder();

  Widget wrap(Widget child) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: child,
      );

  return [
    GoRoute(
      path: '/office-login',
      builder: (context, state) => wrap(
        gated(() => portal.OfficeLoginScreen()),
      ),
    ),
    GoRoute(
      path: '/office/create-transaction',
      builder: (context, state) => wrap(
        gated(() => portal.OfficeCreateTransactionScreen()),
      ),
    ),
    GoRoute(
      path: '/office/transaction/:id',
      builder: (context, state) {
        final tx = state.extra as Map<String, dynamic>? ??
            {'id': state.pathParameters['id']};
        return wrap(
          gated(() => portal.OfficeTransactionMonitorScreen(transaction: tx)),
        );
      },
    ),
    GoRoute(
      path: '/office/chat/:id',
      builder: (context, state) => wrap(
        gated(
          () => portal.OfficeChatScreen(
            conversationId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/office/ai',
      builder: (context, state) => wrap(
        gated(() => portal.OfficeAiAssistantScreen()),
      ),
    ),
    GoRoute(
      path: '/office/report-property',
      builder: (context, state) => wrap(
        gated(() => portal.OfficeReportPropertyScreen()),
      ),
    ),
    GoRoute(
      path: '/office/notifications',
      builder: (context, state) => wrap(
        gated(() => portal.OfficeNotificationsScreen()),
      ),
    ),
    GoRoute(
      path: '/office/performance',
      builder: (context, state) => wrap(
        gated(() => portal.OfficePerformanceScreen()),
      ),
    ),
    GoRoute(
      path: '/office/profile',
      builder: (context, state) => wrap(
        gated(() => portal.OfficeProfileScreen()),
      ),
    ),
    GoRoute(
      path: '/office/documents',
      builder: (context, state) => wrap(
        gated(() => portal.OfficeDocumentsScreen()),
      ),
    ),
    GoRoute(
      path: '/office/support',
      builder: (context, state) => wrap(
        gated(() => portal.OfficeSupportScreen()),
      ),
    ),
    GoRoute(
      path: '/office/history',
      builder: (context, state) => wrap(
        gated(() => portal.OfficeHistoryScreen()),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return wrap(
          gated(() => portal.OfficeScaffold(navigationShell: navigationShell)),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/home',
              builder: (context, state) =>
                  gated(() => portal.OfficeHomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/properties',
              builder: (context, state) =>
                  gated(() => portal.OfficePropertiesScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/transactions',
              builder: (context, state) =>
                  gated(() => portal.OfficeTransactionsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/leads',
              builder: (context, state) =>
                  gated(() => portal.OfficeLeadsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/conversations',
              builder: (context, state) =>
                  gated(() => portal.OfficeConversationsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/more',
              builder: (context, state) =>
                  gated(() => portal.OfficeMoreScreen()),
            ),
          ],
        ),
      ],
    ),
  ];
}
