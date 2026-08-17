import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shared colors for map pins, badges, and search filter chips.
class ListingFilterTheme {
  ListingFilterTheme._();

  static Color colorForFilter(String option) {
    switch (option) {
      case 'Sale':
        return AppTheme.saleColor;
      case 'Rent':
        return AppTheme.rentColor;
      case 'Mortgage':
        return AppTheme.mortgageColor;
      case 'Land':
        return AppTheme.landColor;
      case 'Commercial':
        return AppTheme.commercialColor;
      case 'Investment':
        return AppTheme.investmentColor;
      default:
        return AppTheme.primary;
    }
  }

  /// Pin color from property type + listing type (matches map markers).
  static Color pinColor({
    required String propertyType,
    required String listingType,
  }) {
    switch (propertyType) {
      case 'land':
      case 'agricultural':
        return AppTheme.landColor;
      case 'commercial':
        return AppTheme.commercialColor;
      case 'investment':
        return AppTheme.investmentColor;
    }
    switch (listingType) {
      case 'rent':
        return AppTheme.rentColor;
      case 'mortgage':
        return AppTheme.mortgageColor;
      case 'investment':
        return AppTheme.investmentColor;
      default:
        return AppTheme.saleColor;
    }
  }
}
