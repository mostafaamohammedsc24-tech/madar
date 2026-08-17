import '../../authentication/routing/auth_globals.dart';
import '../presentation/providers/office_auth_notifier.dart';

/// Global office auth — separate domain from end-user OTP auth.
final officeAuthNotifier = OfficeAuthNotifier();

void wireOfficeAuthIntoRouter() {
  authRouterRefresh.attachOffice(officeAuthNotifier);
}
