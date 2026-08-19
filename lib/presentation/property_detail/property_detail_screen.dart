import 'package:flutter/material.dart';

import 'zillow_property_detail_screen.dart';

export 'zillow_property_detail_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return ZillowPropertyDetailScreen(propertyData: property);
  }
}
