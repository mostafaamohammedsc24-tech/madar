import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/property/presentation/screens/property_report_screen.dart';
import '../presentation/analytics/property_analytics_screen.dart';
import '../presentation/messages/messages_screen.dart';

/// Eager route builders (deferred loading disabled for web static hosting).
Widget buildDeferredPropertyReport(Map<String, dynamic> property) {
  return ProviderScope(
    child: PropertyReportScreen(property: property),
  );
}

Widget buildDeferredMessagesScreen() => const MessagesScreen();

Widget buildDeferredAnalyticsScreen() => const PropertyAnalyticsScreen();
