import 'package:country_picker/country_picker.dart';

import 'madar_country.dart';

/// ISO 3166 country catalog backed by [country_picker].
class CountryRegistry {
  CountryRegistry._();

  static final CountryService _service = CountryService();

  static List<MadarCountry> get all =>
      _service.getAll().map(MadarCountry.fromPickerCountry).toList();

  static MadarCountry? findByIso(String? isoCode) {
    if (isoCode == null || isoCode.isEmpty) return null;
    final country = _service.findByCode(isoCode.toUpperCase());
    return country == null ? null : MadarCountry.fromPickerCountry(country);
  }

  static MadarCountry get fallback => findByIso('IQ')!;

  static List<MadarCountry> search(String query, {String languageCode = 'en'}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((c) {
      return c.isoCode.toLowerCase().contains(q) ||
          c.dialCode.contains(q) ||
          c.nameEn.toLowerCase().contains(q) ||
          (c.nameAr?.contains(query) ?? false) ||
          (c.nameKu?.contains(query) ?? false);
    }).toList();
  }

  static const List<String> favoriteIsoCodes = [
    'IQ',
    'SA',
    'AE',
    'JO',
    'KW',
    'QA',
    'BH',
    'OM',
    'US',
    'GB',
  ];
}
