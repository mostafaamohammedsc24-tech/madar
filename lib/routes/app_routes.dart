import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/domain/models/user_auth_state.dart';
import '../features/authentication/presentation/screens/user_auth_flow_screen.dart';
import '../features/authentication/routing/auth_globals.dart';
import '../features/authentication/routing/auth_redirect.dart';
import '../features/property/presentation/screens/property_report_screen.dart';
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
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.auth,
  refreshListenable: authRouterRefresh,
  redirect: (context, state) {
    final authRedirect = resolveUserAuthRedirect(
      state: authRouterRefresh.notifier.state,
      matchedLocation: state.matchedLocation,
    );
    if (authRedirect != null) return authRedirect;
    if (state.matchedLocation == '/') {
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
      path: AppRoutes.propertyDetail,
      pageBuilder: (context, state) {
        final property = state.extra as Map<String, dynamic>? ?? {};
        return CustomTransitionPage(
          key: state.pageKey,
          child: ProviderScope(child: PropertyReportScreen(property: property)),
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
