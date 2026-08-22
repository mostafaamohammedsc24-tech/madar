import '../domain/models/user_auth_state.dart';

/// Resolves redirects for user authentication routes.
String? resolveUserAuthRedirect({
  required UserAuthState state,
  required String matchedLocation,
}) {
  const authRoute = '/auth';
  const mainRoute = '/search-map-screen';

  // Partner / office / employee entry — not part of user OTP shell.
  if (matchedLocation.startsWith('/office') ||
      matchedLocation == '/office-login' ||
      matchedLocation == '/employee-portal' ||
      matchedLocation == '/legal-login' ||
      matchedLocation.startsWith('/legal') ||
      matchedLocation == '/closing-login' ||
      matchedLocation.startsWith('/closing') ||
      matchedLocation == '/mapping-login' ||
      matchedLocation.startsWith('/mapping')) {
    return null;
  }

  const protectedShellRoutes = {
    '/search-map-screen',
    '/transactions-screen',
    '/my-properties-screen',
    '/messages-screen',
    '/profile-screen',
  };

  switch (state.status) {
    case UserAuthStatus.initializing:
      return matchedLocation == authRoute ? null : authRoute;

    case UserAuthStatus.authenticated:
      if (matchedLocation == authRoute || matchedLocation == '/') {
        return mainRoute;
      }
      return null;

    case UserAuthStatus.unauthenticated:
    case UserAuthStatus.awaitingOtpVerification:
    case UserAuthStatus.awaitingLocationPermission:
    case UserAuthStatus.awaitingRegionSetup:
    case UserAuthStatus.awaitingFaceVerification:
    case UserAuthStatus.failure:
      if (protectedShellRoutes.contains(matchedLocation) ||
          matchedLocation == '/') {
        return authRoute;
      }
      return null;
  }
}
