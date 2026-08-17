import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Property type / listing type icon mapping for map pins and cards.
class PropertyTypeIcon extends StatelessWidget {
  const PropertyTypeIcon({
    super.key,
    required this.type,
    this.listingType,
    this.size = 20,
    this.color,
  });

  final String type;
  final String? listingType;
  final double size;
  final Color? color;

  static Color colorForType(String type, {String? listingType}) {
    final normalized = type.toLowerCase();
    switch (normalized) {
      case 'rent':
        return AppTheme.rentColor;
      case 'mortgage':
        return AppTheme.mortgageColor;
      case 'land':
        return AppTheme.landColor;
      case 'commercial':
        return AppTheme.commercialColor;
      case 'investment':
        return AppTheme.investmentColor;
      case 'building':
      case 'apartment':
        return AppTheme.primary;
      default:
        if (listingType?.toLowerCase() == 'rent') return AppTheme.rentColor;
        return AppTheme.saleColor;
    }
  }

  static IconData iconForType(String type, {String? listingType}) {
    final normalized = type.toLowerCase();
    switch (normalized) {
      case 'rent':
        return Icons.key_outlined;
      case 'mortgage':
        return Icons.account_balance_outlined;
      case 'land':
        return Icons.landscape_outlined;
      case 'commercial':
        return Icons.storefront_outlined;
      case 'investment':
        return Icons.trending_up_outlined;
      case 'building':
        return Icons.apartment_outlined;
      case 'apartment':
        return Icons.home_outlined;
      case 'villa':
        return Icons.villa_outlined;
      case 'office':
        return Icons.business_outlined;
      default:
        if (listingType?.toLowerCase() == 'rent') return Icons.key_outlined;
        return Icons.home_work_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? colorForType(type, listingType: listingType);
    return Icon(
      iconForType(type, listingType: listingType),
      size: size,
      color: resolvedColor,
    );
  }
}
