import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/property_detail/zillow_property_detail_screen.dart';

class PropertyReportScreen extends ConsumerStatefulWidget {
  const PropertyReportScreen({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  ConsumerState<PropertyReportScreen> createState() =>
      _PropertyReportScreenState();
}

class _PropertyReportScreenState extends ConsumerState<PropertyReportScreen> {
  @override
  Widget build(BuildContext context) {
    return ZillowPropertyDetailScreen(propertyData: widget.property);
  }
}
