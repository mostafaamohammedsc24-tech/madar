import '../../../authentication/routing/auth_globals.dart';
import '../presentation/providers/employee_auth_notifier.dart';

final employeeAuthNotifier = EmployeeAuthNotifier();

void wireEmployeeAuthIntoRouter() {
  authRouterRefresh.attachEmployee(employeeAuthNotifier);
}
