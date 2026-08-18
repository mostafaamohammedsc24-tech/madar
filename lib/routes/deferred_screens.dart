import 'package:flutter/widgets.dart';

import '../features/property/presentation/screens/property_report_screen.dart';
import '../presentation/analytics/property_analytics_screen.dart';
import '../presentation/messages/messages_screen.dart';

/// Eager route builders (deferred loading disabled for web static hosting).
Widget buildDeferredPropertyReport(Map<String, dynamic> property) {
  return PropertyReportScreen(property: property);
}

Widget buildDeferredMessagesScreen() => const MessagesScreen();

Widget buildDeferredAnalyticsScreen() => const PropertyAnalyticsScreen();
