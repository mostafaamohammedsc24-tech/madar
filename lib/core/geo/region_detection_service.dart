import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../currency/currency_registry.dart';
import '../geo/country_registry.dart';
import '../geo/madar_country.dart';
import '../localization/app_localizations.dart';

/// Result of automatic region detection from device location.
class RegionDetectionResult {
  const RegionDetectionResult({
    required this.country,
    required this.suggestedLanguage,
    required this.suggestedCurrencyCode,
    this.latitude,
    this.longitude,
  });

  final MadarCountry country;
  final AppLanguage suggestedLanguage;
  final String suggestedCurrencyCode;
  final double? latitude;
  final double? longitude;
}

/// Detects country, language, and currency hints from GPS + locale.
class RegionDetectionService {
  static const _arabicCountryCodes = {
    'IQ', 'SA', 'AE', 'JO', 'KW', 'QA', 'BH', 'OM', 'EG', 'LB', 'SY', 'YE',
    'LY', 'SD', 'MA', 'DZ', 'TN', 'PS',
  };

  static const _kurdishCountryCodes = <String>{};

  Future<RegionDetectionResult?> detectFromCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;

      final iso = placemarks.first.isoCountryCode?.toUpperCase();
      final country = CountryRegistry.findByIso(iso) ?? CountryRegistry.fallback;

      return RegionDetectionResult(
        country: country,
        suggestedLanguage: _languageForCountry(country.isoCode),
        suggestedCurrencyCode: CurrencyRegistry.defaultCurrencyForCountry(
          country.isoCode,
        ),
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('[RegionDetection] failed: $e');
      return null;
    }
  }

  RegionDetectionResult fallbackFromDeviceLocale() {
    final locale = PlatformDispatcher.instance.locale;
    final iso = locale.countryCode?.toUpperCase();
    final country = CountryRegistry.findByIso(iso) ?? CountryRegistry.fallback;
    return RegionDetectionResult(
      country: country,
      suggestedLanguage: _languageForCountry(country.isoCode),
      suggestedCurrencyCode: CurrencyRegistry.defaultCurrencyForCountry(
        country.isoCode,
      ),
    );
  }

  AppLanguage _languageForCountry(String isoCode) {
    if (_kurdishCountryCodes.contains(isoCode)) {
      return AppLanguage.kurdish;
    }
    if (_arabicCountryCodes.contains(isoCode)) {
      return AppLanguage.arabic;
    }
    return AppLanguage.arabic;
  }
}
