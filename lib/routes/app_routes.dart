import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;

import '../features/authentication/domain/models/user_auth_state.dart';
import '../features/authentication/presentation/screens/user_auth_flow_screen.dart';
import '../features/authentication/routing/auth_globals.dart';
import '../features/authentication/routing/auth_redirect.dart';
import '../features/office/presentation/screens/employee_portal_placeholder_screen.dart';
import '../features/office/presentation/screens/office_chat_screen.dart';
import '../features/office/presentation/screens/office_conversations_screen.dart';
import '../features/office/presentation/screens/office_create_transaction_screen.dart';
import '../features/office/presentation/screens/office_documents_screen.dart';
import '../features/office/presentation/screens/office_history_screen.dart';
import '../features/office/presentation/screens/office_home_screen.dart';
import '../features/office/presentation/screens/office_leads_screen.dart';
import '../features/office/presentation/screens/office_login_screen.dart';
import '../features/office/presentation/screens/office_more_screen.dart';
import '../features/office/presentation/screens/office_notifications_screen.dart';
import '../features/office/presentation/screens/office_performance_screen.dart';
import '../features/office/presentation/screens/office_profile_screen.dart';
import '../features/office/presentation/screens/office_properties_screen.dart';
import '../features/office/presentation/screens/office_report_property_screen.dart';
import '../features/office/presentation/screens/office_support_screen.dart';
import '../features/office/presentation/screens/office_transaction_monitor_screen.dart';
import '../features/office/presentation/screens/office_transactions_screen.dart';
import '../features/office/presentation/shell/office_scaffold.dart';
import '../features/office/routing/office_globals.dart';
import '../features/office/routing/office_redirect.dart';
import '../features/legal/presentation/screens/legal_case_screen.dart';
import '../features/legal/presentation/screens/legal_list_screens.dart';
import '../features/legal/presentation/screens/legal_login_screen.dart';
import '../features/legal/presentation/screens/legal_work_screen.dart';
import '../features/legal/presentation/shell/legal_scaffold.dart';
import '../features/legal/routing/legal_globals.dart';
import '../features/legal/routing/legal_workspace_globals.dart';
import '../features/closing/presentation/screens/closing_case_screen.dart';
import '../features/closing/presentation/screens/closing_list_screens.dart';
import '../features/closing/presentation/screens/closing_login_screen.dart';
import '../features/closing/presentation/screens/closing_work_screen.dart';
import '../features/closing/presentation/shell/closing_scaffold.dart';
import '../features/closing/routing/closing_globals.dart';
import '../features/closing/routing/closing_workspace_globals.dart';
import '../presentation/property_detail/zillow_property_detail_screen.dart';
import '../features/transaction/presentation/screens/transaction_center_screen.dart';
import '../presentation/analytics/property_analytics_screen.dart';
import '../presentation/reviews/ratings_reviews_screen.dart';
import '../presentation/messages/messages_screen.dart';
import '../presentation/my_properties_screen/my_properties_screen.dart';
import '../presentation/notifications/notification_center_screen.dart';
import '../presentation/profile/documents_archive_screen.dart';
import '../presentation/profile/edit_profile_screen.dart';
import '../presentation/profile/profile_screen.dart';
import '../presentation/profile/seller_commission_dashboard.dart';
import '../presentation/search_map_screen/search_map_screen.dart';
import '../presentation/transactions_screen/settlement_payout_receipt_screen.dart';
import '../widgets/app_scaffold.dart';
import '../presentation/auth/two_fa_verification_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String auth = '/auth';
  static const String searchMapScreen = '/search-map-screen';
  static const String transactionsScreen = '/transactions-screen';
  static const String myPropertiesScreen = '/my-properties-screen';
  static const String messagesScreen = '/messages-screen';
  static const String profileScreen = '/profile-screen';
  static const String propertyDetail = '/property-detail';
  static const String notificationCenter = '/notifications';
  static const String editProfile = '/edit-profile';
  static const String sellerCommission = '/seller-commission';
  static const String documentsArchive = '/documents-archive';
  static const String twoFaVerification = '/two-fa-verification';
  static const String settlementReceipt = '/settlement-receipt';
  static const String propertyAnalytics = '/property-analytics';
  static const String ratingsReviews = '/ratings-reviews';
  static const String officeLogin = '/office-login';
  static const String employeePortal = '/employee-portal';
  static const String officeHome = '/office/home';
  static const String legalLogin = '/legal-login';
  static const String legalWork = '/legal/work';
  static const String closingLogin = '/closing-login';
  static const String closingWork = '/closing/work';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.auth,
  refreshListenable: authRouterRefresh,
  redirect: (context, state) {
    final location = state.matchedLocation;

    final officeRedirect = resolveOfficeAuthRedirect(
      status: officeAuthNotifier.status,
      matchedLocation: location,
    );
    if (officeRedirect != null) return officeRedirect;

    // Office session owns its shell — do not bounce to user OTP auth.
    if (officeAuthNotifier.isAuthenticated &&
        (location.startsWith('/office') || location == AppRoutes.officeLogin)) {
      return null;
    }

    final legalRedirect = resolveLegalAuthRedirect(
      status: legalAuthNotifier.status,
      matchedLocation: location,
    );
    if (legalRedirect != null) return legalRedirect;

    if (legalAuthNotifier.isAuthenticated &&
        (location.startsWith('/legal') || location == AppRoutes.legalLogin)) {
      return null;
    }

    final closingRedirect = resolveClosingAuthRedirect(
      status: closingAuthNotifier.status,
      matchedLocation: location,
    );
    if (closingRedirect != null) return closingRedirect;

    if (closingAuthNotifier.isAuthenticated &&
        (location.startsWith('/closing') || location == AppRoutes.closingLogin)) {
      return null;
    }

    // Public partner entry points
    if (location == AppRoutes.officeLogin ||
        location == AppRoutes.employeePortal ||
        location == AppRoutes.legalLogin ||
        location == AppRoutes.closingLogin) {
      return null;
    }

    final authRedirect = resolveUserAuthRedirect(
      state: authRouterRefresh.notifier.state,
      matchedLocation: location,
    );
    if (authRedirect != null) return authRedirect;
    if (location == '/') {
      if (officeAuthNotifier.isAuthenticated) return AppRoutes.officeHome;
      if (legalAuthNotifier.isAuthenticated) return AppRoutes.legalWork;
      if (closingAuthNotifier.isAuthenticated) return AppRoutes.closingWork;
      return authRouterRefresh.notifier.state.status ==
              UserAuthStatus.authenticated
          ? AppRoutes.searchMapScreen
          : AppRoutes.auth;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.auth,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const UserAuthFlowScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.officeLogin,
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: const OfficeLoginScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.employeePortal,
      builder: (context, state) => const EmployeePortalPlaceholderScreen(),
    ),
    GoRoute(
      path: AppRoutes.legalLogin,
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: legalAuthNotifier,
        child: const LegalLoginScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.closingLogin,
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: closingAuthNotifier,
        child: const ClosingLoginScreen(),
      ),
    ),
    GoRoute(
      path: '/legal/transaction/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return provider.MultiProvider(
          providers: [
            provider.ChangeNotifierProvider.value(value: legalAuthNotifier),
            provider.ChangeNotifierProvider.value(value: legalWorkspaceController),
          ],
          child: LegalWorkspaceLoader(child: LegalCaseScreen(caseId: id)),
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return provider.MultiProvider(
          providers: [
            provider.ChangeNotifierProvider.value(value: legalAuthNotifier),
            provider.ChangeNotifierProvider.value(value: legalWorkspaceController),
          ],
          child: LegalWorkspaceLoader(
            child: LegalScaffold(navigationShell: navigationShell),
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/legal/work',
              builder: (context, state) => const LegalWorkScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/legal/transactions',
              builder: (context, state) => const LegalTransactionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/legal/contracts',
              builder: (context, state) => const LegalContractsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/legal/documents',
              builder: (context, state) => const LegalDocumentsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/legal/messages',
              builder: (context, state) => const LegalMessagesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/legal/archive',
              builder: (context, state) => const LegalArchiveScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/legal/profile',
              builder: (context, state) => const LegalProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/closing/transaction/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return provider.MultiProvider(
          providers: [
            provider.ChangeNotifierProvider.value(value: closingAuthNotifier),
            provider.ChangeNotifierProvider.value(value: closingWorkspaceController),
          ],
          child: ClosingWorkspaceLoader(child: ClosingCaseScreen(caseId: id)),
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return provider.MultiProvider(
          providers: [
            provider.ChangeNotifierProvider.value(value: closingAuthNotifier),
            provider.ChangeNotifierProvider.value(value: closingWorkspaceController),
          ],
          child: ClosingWorkspaceLoader(
            child: ClosingScaffold(navigationShell: navigationShell),
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/closing/work',
              builder: (context, state) => const ClosingWorkScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/closing/transactions',
              builder: (context, state) => const ClosingTransactionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/closing/finance',
              builder: (context, state) => const ClosingFinanceScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/closing/government',
              builder: (context, state) => const ClosingGovListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/closing/documents',
              builder: (context, state) => const ClosingDocumentsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/closing/messages',
              builder: (context, state) => const ClosingMessagesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/closing/archive',
              builder: (context, state) => const ClosingArchiveScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/closing/profile',
              builder: (context, state) => const ClosingProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/office/create-transaction',
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: const OfficeCreateTransactionScreen(),
      ),
    ),
    GoRoute(
      path: '/office/transaction/:id',
      builder: (context, state) {
        final tx = state.extra as Map<String, dynamic>? ??
            {'id': state.pathParameters['id']};
        return provider.ChangeNotifierProvider.value(
          value: officeAuthNotifier,
          child: OfficeTransactionMonitorScreen(transaction: tx),
        );
      },
    ),
    GoRoute(
      path: '/office/chat/:id',
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: OfficeChatScreen(
          conversationId: state.pathParameters['id'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/office/report-property',
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: const OfficeReportPropertyScreen(),
      ),
    ),
    GoRoute(
      path: '/office/notifications',
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: const OfficeNotificationsScreen(),
      ),
    ),
    GoRoute(
      path: '/office/performance',
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: const OfficePerformanceScreen(),
      ),
    ),
    GoRoute(
      path: '/office/profile',
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: const OfficeProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/office/documents',
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: const OfficeDocumentsScreen(),
      ),
    ),
    GoRoute(
      path: '/office/support',
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: const OfficeSupportScreen(),
      ),
    ),
    GoRoute(
      path: '/office/history',
      builder: (context, state) => provider.ChangeNotifierProvider.value(
        value: officeAuthNotifier,
        child: const OfficeHistoryScreen(),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return provider.ChangeNotifierProvider.value(
          value: officeAuthNotifier,
          child: OfficeScaffold(navigationShell: navigationShell),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/home',
              builder: (context, state) => const OfficeHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/properties',
              builder: (context, state) => const OfficePropertiesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/transactions',
              builder: (context, state) => const OfficeTransactionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/leads',
              builder: (context, state) => const OfficeLeadsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/conversations',
              builder: (context, state) => const OfficeConversationsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/office/more',
              builder: (context, state) => const OfficeMoreScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.propertyDetail,
      pageBuilder: (context, state) {
        final property = state.extra as Map<String, dynamic>? ?? {};
        return CustomTransitionPage(
          key: state.pageKey,
          child: ProviderScope(child: ZillowPropertyDetailScreen(propertyData: property)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 350),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.notificationCenter,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationCenterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      pageBuilder: (context, state) {
        final profile = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: EditProfileScreen(profile: profile),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.sellerCommission,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SellerCommissionDashboard(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.documentsArchive,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DocumentsArchiveScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.twoFaVerification,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const TwoFaVerificationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),
    GoRoute(
      path: AppRoutes.settlementReceipt,
      pageBuilder: (context, state) {
        final tx = state.extra as Map<String, dynamic>? ?? {};
        return CustomTransitionPage(
          key: state.pageKey,
          child: SettlementPayoutReceiptScreen(transaction: tx),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 350),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.propertyAnalytics,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PropertyAnalyticsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: AppRoutes.ratingsReviews,
      pageBuilder: (context, state) {
        final property = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: RatingsReviewsScreen(property: property),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 350),
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.searchMapScreen,
              builder: (context, state) => const SearchMapScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.transactionsScreen,
              builder: (context, state) => const TransactionCenterScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myPropertiesScreen,
              builder: (context, state) => const MyPropertiesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.messagesScreen,
              builder: (context, state) =>
                  const ProviderScope(child: MessagesScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
