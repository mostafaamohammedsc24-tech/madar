import '../presentation/providers/closing_auth_notifier.dart';
import '../../authentication/routing/auth_globals.dart';

final closingAuthNotifier = ClosingAuthNotifier();

void wireClosingAuthIntoRouter() {
  authRouterRefresh.attachClosing(closingAuthNotifier);
}

const closingLoginRoute = '/closing-login';
const closingWorkRoute = '/closing/work';

bool isClosingShell(String location) {
  return location == '/closing' || location.startsWith('/closing/');
}

String? resolveClosingAuthRedirect({
  required ClosingAuthStatus status,
  required String matchedLocation,
}) {
  final onShell = isClosingShell(matchedLocation);
  final onLogin = matchedLocation == closingLoginRoute;

  switch (status) {
    case ClosingAuthStatus.initializing:
      if (onShell || onLogin) return closingLoginRoute;
      return null;
    case ClosingAuthStatus.authenticated:
      if (onLogin) return closingWorkRoute;
      return null;
    case ClosingAuthStatus.unauthenticated:
      if (onShell) return closingLoginRoute;
      return null;
  }
}
