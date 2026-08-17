import '../../../../core/geo/country_registry.dart';
import '../../../../core/geo/madar_country.dart';

export '../../../../core/geo/madar_country.dart';

/// Backward-compatible alias — auth uses the unified [MadarCountry] model.
typedef AuthCountry = MadarCountry;

extension AuthCountryPhone on MadarCountry {
  String get phonePlaceholder {
    switch (isoCode) {
      case 'US':
      case 'CA':
        return 'XXX XXX XXXX';
      case 'GB':
        return '7XXX XXXXXX';
      case 'IQ':
        return '000 000 0000';
      default:
        return 'XXXXXXXXXX';
    }
  }

  int get minPhoneLength => 7;
  int get maxPhoneLength => 12;
}

MadarCountry authCountryByIso(String isoCode) {
  return CountryRegistry.findByIso(isoCode) ?? CountryRegistry.fallback;
}
