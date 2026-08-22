import '../presentation/providers/legal_auth_notifier.dart';
import '../../authentication/routing/auth_globals.dart';

final legalAuthNotifier = LegalAuthNotifier();

void wireLegalAuthIntoRouter() {
  authRouterRefresh.attachLegal(legalAuthNotifier);
}

const legalLoginRoute = '/legal-login';
const legalWorkRoute = '/legal/work';

bool isLegalShell(String location) {
  return location == '/legal' || location.startsWith('/legal/');
}

String? resolveLegalAuthRedirect({
  required LegalAuthStatus status,
  required String matchedLocation,
}) {
  final onShell = isLegalShell(matchedLocation);
  final onLogin = matchedLocation == legalLoginRoute;

  switch (status) {
    case LegalAuthStatus.initializing:
      if (onShell || onLogin) return legalLoginRoute;
      return null;
    case LegalAuthStatus.authenticated:
      if (onLogin) return legalWorkRoute;
      return null;
    case LegalAuthStatus.unauthenticated:
      if (onShell) return legalLoginRoute;
      return null;
  }
}
