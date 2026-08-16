import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/currency/currency_registry.dart';
import '../core/geo/country_registry.dart';
import '../core/geo/madar_country.dart';

/// Active market country + preferred currency persisted across the app.
class CountryContextProvider extends ChangeNotifier {
  MadarCountry _activeCountry = CountryRegistry.fallback;
  String _currencyCode = CountryRegistry.fallback.defaultCurrencyCode;
  bool _currencyOverridden = false;

  MadarCountry get activeCountry => _activeCountry;
  String get activeCountryCode => _activeCountry.isoCode;
  String get activeCurrency => _currencyCode;
  String get activeCurrencySymbol =>
      CurrencyRegistry.findByCode(_currencyCode)?.symbol ?? _currencyCode;

  /// @deprecated Use [activeCountry] — kept for legacy call sites.
  String get activeFlag => _activeCountry.isoCode;
  String get activeCountryName => _activeCountry.nameEn;

  bool get isCurrencyOverridden => _currencyOverridden;

  CountryContextProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('active_country_code');
      final currency = prefs.getString('user_currency_code');
      final overridden = prefs.getBool('user_currency_overridden') ?? false;

      if (savedCode != null) {
        _activeCountry = CountryRegistry.findByIso(savedCode) ?? _activeCountry;
      }
      if (currency != null) {
        _currencyCode = currency;
      } else {
        _currencyCode = _activeCountry.defaultCurrencyCode;
      }
      _currencyOverridden = overridden;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setCountry(MadarCountry country, {bool updateCurrency = true}) async {
    if (_activeCountry.isoCode == country.isoCode && !updateCurrency) return;
    _activeCountry = country;
    if (!_currencyOverridden || updateCurrency) {
      _currencyCode = country.defaultCurrencyCode;
      if (updateCurrency) _currencyOverridden = false;
    }
    notifyListeners();
    await _persist();
  }

  /// Legacy adapter for code still passing [AppCountry]-shaped data.
  Future<void> setCountryByCode(String isoCode, {bool updateCurrency = true}) async {
    final country = CountryRegistry.findByIso(isoCode);
    if (country != null) {
      await setCountry(country, updateCurrency: updateCurrency);
    }
  }

  Future<void> setCurrency(String code, {bool overridden = true}) async {
    _currencyCode = code.toUpperCase();
    _currencyOverridden = overridden;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_country_code', _activeCountry.isoCode);
      await prefs.setString('user_country_code', _activeCountry.isoCode);
      await prefs.setString('user_currency_code', _currencyCode);
      await prefs.setBool('user_currency_overridden', _currencyOverridden);
    } catch (_) {}
  }
}

/// @deprecated Use [MadarCountry] via [CountryContextProvider].
typedef AppCountry = MadarCountry;

/// @deprecated Use [CountryRegistry.all].
List<MadarCountry> get kSupportedCountries => CountryRegistry.all
    .where((c) => CountryRegistry.favoriteIsoCodes.contains(c.isoCode))
    .toList();
