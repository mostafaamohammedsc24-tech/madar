import '../presentation/providers/photo_auth_notifier.dart';
import '../../authentication/routing/auth_globals.dart';

final photoAuthNotifier = PhotoAuthNotifier();

void wirePhotoAuthIntoRouter() {
  authRouterRefresh.attachPhoto(photoAuthNotifier);
}

const photoLoginRoute = '/photo-login';
const photoWorkRoute = '/photo/work';

bool isPhotoShell(String location) => location == '/photo' || location.startsWith('/photo/');

String? resolvePhotoAuthRedirect({required PhotoAuthStatus status, required String matchedLocation}) {
  final onShell = isPhotoShell(matchedLocation);
  final onLogin = matchedLocation == photoLoginRoute;
  switch (status) {
    case PhotoAuthStatus.initializing:
      if (onShell || onLogin) return photoLoginRoute;
      return null;
    case PhotoAuthStatus.authenticated:
      if (onLogin) return photoWorkRoute;
      return null;
    case PhotoAuthStatus.unauthenticated:
      if (onShell) return photoLoginRoute;
      return null;
  }
}
