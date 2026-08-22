import '../presentation/providers/field_auth_notifier.dart';
import '../../authentication/routing/auth_globals.dart';

final fieldAuthNotifier = FieldAuthNotifier();

void wireFieldAuthIntoRouter() {
  authRouterRefresh.attachField(fieldAuthNotifier);
}

const fieldLoginRoute = '/field-login';
const fieldWorkRoute = '/field/work';

bool isFieldShell(String location) => location == '/field' || location.startsWith('/field/');

String? resolveFieldAuthRedirect({required FieldAuthStatus status, required String matchedLocation}) {
  final onShell = isFieldShell(matchedLocation);
  final onLogin = matchedLocation == fieldLoginRoute;
  switch (status) {
    case FieldAuthStatus.initializing:
      if (onShell || onLogin) return fieldLoginRoute;
      return null;
    case FieldAuthStatus.authenticated:
      if (onLogin) return fieldWorkRoute;
      return null;
    case FieldAuthStatus.unauthenticated:
      if (onShell) return fieldLoginRoute;
      return null;
  }
}
