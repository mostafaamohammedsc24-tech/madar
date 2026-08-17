import 'package:country_picker/country_picker.dart';

import '../currency/currency_registry.dart';
import '../localization/app_localizations.dart';

/// Unified country model used across auth, profile, and search.
class MadarCountry {
  const MadarCountry({
    required this.isoCode,
    required this.dialCode,
    required this.nameEn,
    this.nameAr,
    this.nameKu,
    required this.defaultCurrencyCode,
  });

  final String isoCode;
  final String dialCode;
  final String nameEn;
  final String? nameAr;
  final String? nameKu;
  final String defaultCurrencyCode;

  String get e164Prefix => dialCode.startsWith('+') ? dialCode : '+$dialCode';

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr ?? nameEn;
      case 'ku':
        return nameKu ?? nameAr ?? nameEn;
      default:
        return nameEn;
    }
  }

  String localizedNameFromLoc(AppLocalizations loc) =>
      localizedName(loc.languageCode);

  factory MadarCountry.fromPickerCountry(Country country) {
    final iso = country.countryCode.toUpperCase();
    return MadarCountry(
      isoCode: iso,
      dialCode: '+${country.phoneCode}',
      nameEn: country.name,
      defaultCurrencyCode: CurrencyRegistry.defaultCurrencyForCountry(iso),
    );
  }

  MadarCountry copyWith({
    String? isoCode,
    String? dialCode,
    String? nameEn,
    String? nameAr,
    String? nameKu,
    String? defaultCurrencyCode,
  }) {
    return MadarCountry(
      isoCode: isoCode ?? this.isoCode,
      dialCode: dialCode ?? this.dialCode,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      nameKu: nameKu ?? this.nameKu,
      defaultCurrencyCode: defaultCurrencyCode ?? this.defaultCurrencyCode,
    );
  }
}
