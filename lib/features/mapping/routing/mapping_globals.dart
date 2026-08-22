import '../presentation/providers/mapping_auth_notifier.dart';
import '../../authentication/routing/auth_globals.dart';

final mappingAuthNotifier = MappingAuthNotifier();

void wireMappingAuthIntoRouter() {
  authRouterRefresh.attachMapping(mappingAuthNotifier);
}

const mappingLoginRoute = '/mapping-login';
const mappingWorkRoute = '/mapping/work';

bool isMappingShell(String location) {
  return location == '/mapping' || location.startsWith('/mapping/');
}

String? resolveMappingAuthRedirect({
  required MappingAuthStatus status,
  required String matchedLocation,
}) {
  final onShell = isMappingShell(matchedLocation);
  final onLogin = matchedLocation == mappingLoginRoute;

  switch (status) {
    case MappingAuthStatus.initializing:
      if (onShell || onLogin) return mappingLoginRoute;
      return null;
    case MappingAuthStatus.authenticated:
      if (onLogin) return mappingWorkRoute;
      return null;
    case MappingAuthStatus.unauthenticated:
      if (onShell) return mappingLoginRoute;
      return null;
  }
}
