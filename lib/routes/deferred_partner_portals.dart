import 'package:go_router/go_router.dart';

import '../features/employee/core/routing/employee_routes.dart';
import '../features/office/routing/office_routes.dart';

/// Partner portal routes (eager load — no deferred chunks on web).
List<RouteBase> buildDeferredEmployeeRoutes() => buildEmployeeRoutes();

List<RouteBase> buildDeferredOfficeRoutes() => buildOfficeRoutes();

List<RouteBase> buildDeferredPartnerPortalRoutes() => [
      ...buildDeferredEmployeeRoutes(),
      ...buildDeferredOfficeRoutes(),
    ];
