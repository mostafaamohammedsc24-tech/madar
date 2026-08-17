import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user_auth_state.dart';

/// Persists onboarding progress per user so returning users skip completed steps.
class AuthSessionStorage {
  static const _locationPrefix = 'auth_location_';
  static const _facePrefix = 'auth_face_';
  static const _onboardingPrefix = 'auth_onboarding_complete_';
  static const _lastCountryIso = 'auth_last_country_iso';
  static const _lastPhone = 'auth_last_phone';

  Future<bool> isOnboardingComplete(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_onboardingPrefix$userId') ?? false;
  }

  Future<void> markOnboardingComplete(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_onboardingPrefix$userId', true);
  }

  Future<LocationPermissionStatus> getLocationStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('$_locationPrefix$userId');
    return _parseLocation(value);
  }

  Future<void> saveLocationStatus(
    String userId,
    LocationPermissionStatus status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_locationPrefix$userId', status.name);
  }

  Future<FaceVerificationStatus> getFaceStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('$_facePrefix$userId');
    return _parseFace(value);
  }

  Future<void> saveFaceStatus(
    String userId,
    FaceVerificationStatus status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_facePrefix$userId', status.name);
  }

  Future<void> savePhoneDraft({
    required String countryIso,
    required String phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCountryIso, countryIso);
    await prefs.setString(_lastPhone, phoneNumber);
  }

  Future<({String? countryIso, String? phone})> loadPhoneDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      countryIso: prefs.getString(_lastCountryIso),
      phone: prefs.getString(_lastPhone),
    );
  }

  Future<void> clearUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_onboardingPrefix$userId');
    await prefs.remove('$_locationPrefix$userId');
    await prefs.remove('$_facePrefix$userId');
  }

  LocationPermissionStatus _parseLocation(String? value) {
    return LocationPermissionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LocationPermissionStatus.notRequested,
    );
  }

  FaceVerificationStatus _parseFace(String? value) {
    return FaceVerificationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FaceVerificationStatus.none,
    );
  }
}
