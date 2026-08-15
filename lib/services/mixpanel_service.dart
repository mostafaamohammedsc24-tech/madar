import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// Mixpanel Analytics Service — singleton wrapper for tracking events
/// across the Madar app: auth, property search, transactions, onboarding.
class MixpanelService {
  static MixpanelService? _instance;
  Mixpanel? _mixpanel;

  MixpanelService._();

  static MixpanelService get instance {
    _instance ??= MixpanelService._();
    return _instance!;
  }

  // ── Initialization ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      const token = String.fromEnvironment('MIXPANEL_TOKEN', defaultValue: '');
      if (token.isEmpty) {
        debugPrint('[Mixpanel] No token configured — analytics disabled');
        return;
      }
      _mixpanel = await Mixpanel.init(token, trackAutomaticEvents: false);
      debugPrint('[Mixpanel] Initialized successfully');
    } catch (e) {
      debugPrint('[Mixpanel] Init failed: $e');
    }
  }

  // ── Identity ─────────────────────────────────────────────────────────────────

  void identify(String userId, {Map<String, dynamic>? properties}) {
    try {
      _mixpanel?.identify(userId);
      if (properties != null) {
        properties.forEach((key, value) {
          _mixpanel?.getPeople().set(key, value);
        });
      }
    } catch (e) {
      debugPrint('[Mixpanel] identify error: $e');
    }
  }

  void reset() {
    try {
      _mixpanel?.reset();
    } catch (e) {
      debugPrint('[Mixpanel] reset error: $e');
    }
  }

  // ── Event Tracking ────────────────────────────────────────────────────────────

  void track(String event, {Map<String, dynamic>? properties}) {
    try {
      _mixpanel?.track(event, properties: properties);
    } catch (e) {
      debugPrint('[Mixpanel] track error: $e');
    }
  }

  // ── Auth Events ───────────────────────────────────────────────────────────────

  void trackAuthStarted({
    required String country,
    required String countryCode,
  }) {
    track(
      'Auth Started',
      properties: {'country': country, 'country_code': countryCode},
    );
  }

  void trackOtpSent({required String countryCode}) {
    track('OTP Sent', properties: {'country_code': countryCode});
  }

  void trackOtpVerified({required String countryCode}) {
    track('OTP Verified', properties: {'country_code': countryCode});
  }

  void trackLoginCompleted({required String userId, required String country}) {
    identify(userId, properties: {'country': country, 'platform': 'mobile'});
    track(
      'Login Completed',
      properties: {'user_id': userId, 'country': country},
    );
  }

  void trackTwoFaCompleted({required String method}) {
    track('2FA Completed', properties: {'method': method});
  }

  void trackLogout() {
    track('Logout');
    reset();
  }

  // ── Country Context Events ────────────────────────────────────────────────────

  void trackCountryContextChanged({
    required String fromCountry,
    required String toCountry,
  }) {
    track(
      'Country Context Changed',
      properties: {'from_country': fromCountry, 'to_country': toCountry},
    );
    try {
      _mixpanel?.getPeople().set('active_country', toCountry);
    } catch (_) {}
  }

  // ── Property Search Events ────────────────────────────────────────────────────

  void trackPropertySearched({
    required String country,
    String? propertyType,
    String? priceRange,
    String? area,
  }) {
    track(
      'Property Searched',
      properties: {
        'country': country,
        if (propertyType != null) 'property_type': propertyType,
        if (priceRange != null) 'price_range': priceRange,
        if (area != null) 'area': area,
      },
    );
  }

  void trackPropertyViewed({
    required String propertyId,
    required String country,
    String? propertyType,
    double? price,
  }) {
    track(
      'Property Viewed',
      properties: {
        'property_id': propertyId,
        'country': country,
        if (propertyType != null) 'property_type': propertyType,
        if (price != null) 'price': price,
      },
    );
  }

  void trackPropertySaved({
    required String propertyId,
    required String country,
  }) {
    track(
      'Property Saved',
      properties: {'property_id': propertyId, 'country': country},
    );
  }

  // ── Transaction Events ────────────────────────────────────────────────────────

  void trackTransactionStarted({
    required String transactionId,
    required String type,
    required String country,
  }) {
    track(
      'Transaction Started',
      properties: {
        'transaction_id': transactionId,
        'transaction_type': type,
        'country': country,
      },
    );
  }

  void trackTransactionStageCompleted({
    required String transactionId,
    required int stageIndex,
    required String stageName,
  }) {
    track(
      'Transaction Stage Completed',
      properties: {
        'transaction_id': transactionId,
        'stage_index': stageIndex,
        'stage_name': stageName,
      },
    );
  }

  void trackTransactionCompleted({
    required String transactionId,
    required double amount,
    required String country,
  }) {
    track(
      'Transaction Completed',
      properties: {
        'transaction_id': transactionId,
        'amount': amount,
        'country': country,
      },
    );
  }

  // ── Employee Onboarding Events ────────────────────────────────────────────────

  void trackOnboardingStarted({
    required String employeeId,
    required String role,
  }) {
    track(
      'Employee Onboarding Started',
      properties: {'employee_id': employeeId, 'role': role},
    );
  }

  void trackOnboardingStepCompleted({
    required String employeeId,
    required int step,
    required String stepName,
  }) {
    track(
      'Onboarding Step Completed',
      properties: {
        'employee_id': employeeId,
        'step': step,
        'step_name': stepName,
      },
    );
  }

  void trackOnboardingCompleted({
    required String employeeId,
    required String role,
    required String country,
  }) {
    track(
      'Employee Onboarding Completed',
      properties: {'employee_id': employeeId, 'role': role, 'country': country},
    );
    try {
      _mixpanel?.getPeople().set('onboarding_completed', true);
      _mixpanel?.getPeople().set('employee_role', role);
    } catch (_) {}
  }
}
