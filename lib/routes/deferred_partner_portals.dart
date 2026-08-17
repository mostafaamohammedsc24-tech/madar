import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/employee/core/routing/employee_routes.dart';
import '../features/office/routing/office_routes.dart';
import 'deferred_route.dart';

Widget _employeeGate(Widget Function() builder) => DeferredRouteLoader(
      loadLibrary: loadEmployeePortalLibrary,
      loading: const RouteLoadingShell(
        message: 'Loading employee workspace…',
      ),
      builder: builder,
    );

Widget _officeGate(Widget Function() builder) => DeferredRouteLoader(
      loadLibrary: loadOfficePortalLibrary,
      loading: const RouteLoadingShell(
        message: 'Loading office workspace…',
      ),
      builder: builder,
    );

/// Employee portal routes — screens deferred until first visit.
List<RouteBase> buildDeferredEmployeeRoutes() {
  return buildEmployeeRoutes(gate: _employeeGate);
}

/// Office portal routes — screens deferred until first visit.
List<RouteBase> buildDeferredOfficeRoutes() {
  return buildOfficeRoutes(gate: _officeGate);
}

/// All partner (office + employee) routes for GoRouter registration.
List<RouteBase> buildDeferredPartnerPortalRoutes() => [
      ...buildDeferredEmployeeRoutes(),
      ...buildDeferredOfficeRoutes(),
    ];
