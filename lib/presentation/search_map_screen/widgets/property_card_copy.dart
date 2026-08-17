import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../providers/country_context_provider.dart';
import '../models/property_data.dart';

/// Localized title / price / badges for listing cards.
abstract final class PropertyCardCopy {
  static AppLocalizations loc(BuildContext context) =>
      AppLocalizations.of(context);

  static String title(BuildContext context, PropertyData p) =>
      p.localizedTitle(loc(context).language);

  static String address(BuildContext context, PropertyData p) =>
      p.localizedAddress(loc(context).language);

  static String price(BuildContext context, PropertyData p) {
    final currency = context.watch<CountryContextProvider>().activeCurrency;
    return p.displayPrice(currency, language: loc(context).language);
  }

  static String listing(BuildContext context, PropertyData p) =>
      p.listingLabel(loc(context));

  static String type(BuildContext context, PropertyData p) =>
      p.typeLabel(loc(context));

  static String tag(BuildContext context, PropertyData p, String raw) =>
      p.localizedTag(loc(context), raw);
}
