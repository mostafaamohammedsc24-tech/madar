import '../presentation/providers/employee_auth_notifier.dart';

const employeeLoginRoute = '/employee-login';
const employeeHomeRoute = '/employee/home';
const employeePortalLegacyRoute = '/employee-portal';

bool isEmployeeRoute(String location) {
  return location == employeeLoginRoute ||
      location == employeePortalLegacyRoute ||
      location.startsWith('/employee/');
}

String? resolveEmployeeAuthRedirect({
  required EmployeeAuthStatus status,
  required String matchedLocation,
}) {
  final onShell = matchedLocation.startsWith('/employee/') &&
      matchedLocation != employeeLoginRoute;
  final onLogin = matchedLocation == employeeLoginRoute ||
      matchedLocation == employeePortalLegacyRoute;

  switch (status) {
    case EmployeeAuthStatus.initializing:
      if (onShell) return employeeLoginRoute;
      return null;
    case EmployeeAuthStatus.authenticated:
      if (onLogin) return employeeHomeRoute;
      return null;
    case EmployeeAuthStatus.unauthenticated:
      if (onShell) return employeeLoginRoute;
      return null;
  }
}
