import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/property/presentation/screens/property_report_screen.dart'
    deferred as property_report;
import '../presentation/messages/messages_screen.dart' deferred as messages;
import '../presentation/analytics/property_analytics_screen.dart'
    deferred as analytics;
import 'deferred_route.dart';

Future<void> loadPropertyReportLibrary() => property_report.loadLibrary();
Future<void> loadMessagesLibrary() => messages.loadLibrary();
Future<void> loadAnalyticsLibrary() => analytics.loadLibrary();

Widget buildDeferredPropertyReport(Map<String, dynamic> property) {
  return DeferredRouteLoader(
    loadLibrary: loadPropertyReportLibrary,
    loading: const RouteLoadingShell(),
    builder: () => ProviderScope(
      child: property_report.PropertyReportScreen(property: property),
    ),
  );
}

Widget buildDeferredMessagesScreen() {
  return DeferredRouteLoader(
    loadLibrary: loadMessagesLibrary,
    loading: const RouteLoadingShell(),
    builder: () => messages.MessagesScreen(),
  );
}

Widget buildDeferredAnalyticsScreen() {
  return DeferredRouteLoader(
    loadLibrary: loadAnalyticsLibrary,
    loading: const RouteLoadingShell(),
    builder: () => analytics.PropertyAnalyticsScreen(),
  );
}
