import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Country model used throughout the app
class AppCountry {
  final String code;
  final String dialCode;
  final String flag;
  final String nameEn;
  final String nameAr;
  final String currency;
  final String currencySymbol;

  const AppCountry({
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.nameEn,
    required this.nameAr,
    required this.currency,
    required this.currencySymbol,
  });
}

/// All supported countries in Madar
const List<AppCountry> kSupportedCountries = [
  AppCountry(
    code: 'IQ',
    dialCode: '+964',
    flag: '🇮🇶',
    nameEn: 'Iraq',
    nameAr: 'العراق',
    currency: 'IQD',
    currencySymbol: 'د.ع',
  ),
  AppCountry(
    code: 'SA',
    dialCode: '+966',
    flag: '🇸🇦',
    nameEn: 'Saudi Arabia',
    nameAr: 'السعودية',
    currency: 'SAR',
    currencySymbol: 'ر.س',
  ),
  AppCountry(
    code: 'AE',
    dialCode: '+971',
    flag: '🇦🇪',
    nameEn: 'UAE',
    nameAr: 'الإمارات',
    currency: 'AED',
    currencySymbol: 'د.إ',
  ),
  AppCountry(
    code: 'JO',
    dialCode: '+962',
    flag: '🇯🇴',
    nameEn: 'Jordan',
    nameAr: 'الأردن',
    currency: 'JOD',
    currencySymbol: 'د.أ',
  ),
  AppCountry(
    code: 'KW',
    dialCode: '+965',
    flag: '🇰🇼',
    nameEn: 'Kuwait',
    nameAr: 'الكويت',
    currency: 'KWD',
    currencySymbol: 'د.ك',
  ),
  AppCountry(
    code: 'QA',
    dialCode: '+974',
    flag: '🇶🇦',
    nameEn: 'Qatar',
    nameAr: 'قطر',
    currency: 'QAR',
    currencySymbol: 'ر.ق',
  ),
  AppCountry(
    code: 'BH',
    dialCode: '+973',
    flag: '🇧🇭',
    nameEn: 'Bahrain',
    nameAr: 'البحرين',
    currency: 'BHD',
    currencySymbol: 'د.ب',
  ),
  AppCountry(
    code: 'OM',
    dialCode: '+968',
    flag: '🇴🇲',
    nameEn: 'Oman',
    nameAr: 'عُمان',
    currency: 'OMR',
    currencySymbol: 'ر.ع',
  ),
];

/// CountryContextProvider — persists the active country context
/// across the entire app via SharedPreferences.
class CountryContextProvider extends ChangeNotifier {
  AppCountry _activeCountry = kSupportedCountries.first; // Iraq default

  AppCountry get activeCountry => _activeCountry;
  String get activeCountryCode => _activeCountry.code;
  String get activeCountryName => _activeCountry.nameEn;
  String get activeFlag => _activeCountry.flag;
  String get activeCurrency => _activeCountry.currency;
  String get activeCurrencySymbol => _activeCountry.currencySymbol;

  CountryContextProvider() {
    _loadSavedCountry();
  }

  Future<void> _loadSavedCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('active_country_code');
      if (savedCode != null) {
        final found = kSupportedCountries.where((c) => c.code == savedCode);
        if (found.isNotEmpty) {
          _activeCountry = found.first;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> setCountry(AppCountry country) async {
    if (_activeCountry.code == country.code) return;
    _activeCountry = country;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_country_code', country.code);
    } catch (_) {}
  }
}
