import '../presentation/providers/office_auth_notifier.dart';

const officeLoginRoute = '/office-login';
const officeHomeRoute = '/office/home';
const employeePortalRoute = '/employee-portal';

const officeShellPrefixes = [
  '/office/home',
  '/office/properties',
  '/office/transactions',
  '/office/leads',
  '/office/conversations',
  '/office/more',
  '/office/create-transaction',
  '/office/transaction',
  '/office/chat',
  '/office/report-property',
  '/office/notifications',
  '/office/performance',
  '/office/profile',
  '/office/documents',
  '/office/support',
  '/office/history',
];

bool _isOfficeShell(String location) {
  if (location == '/office' || location.startsWith('/office/')) {
    return location != officeLoginRoute;
  }
  return false;
}

/// Office-domain redirect. Returns null when this domain does not claim the route.
String? resolveOfficeAuthRedirect({
  required OfficeAuthStatus status,
  required String matchedLocation,
}) {
  final onOfficeShell = _isOfficeShell(matchedLocation);
  final onOfficeLogin = matchedLocation == officeLoginRoute;

  switch (status) {
    case OfficeAuthStatus.initializing:
      if (onOfficeShell || onOfficeLogin) return officeLoginRoute;
      return null;

    case OfficeAuthStatus.authenticated:
      if (onOfficeLogin) return officeHomeRoute;
      return null;

    case OfficeAuthStatus.unauthenticated:
      if (onOfficeShell) return officeLoginRoute;
      return null;
  }
}
