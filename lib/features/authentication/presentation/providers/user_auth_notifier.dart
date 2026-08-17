import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/geo/country_registry.dart';
import '../../../../core/geo/region_detection_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/mixpanel_service.dart';
import '../../data/local/auth_session_storage.dart';
import '../../data/repositories/supabase_user_auth_repository.dart';
import '../../data/services/stub_face_verification_service.dart';
import '../../domain/models/auth_country.dart';
import '../../domain/models/user_auth_state.dart';
import '../../domain/repositories/user_auth_repository.dart';
import '../../domain/services/face_verification_service.dart';

/// Manages the full user authentication lifecycle.
class UserAuthNotifier extends ChangeNotifier {
  UserAuthNotifier({
    UserAuthRepository? repository,
    AuthSessionStorage? storage,
    FaceVerificationService? faceVerificationService,
    RegionDetectionService? regionDetection,
  }) : _repository = repository ?? SupabaseUserAuthRepository(),
       _storage = storage ?? AuthSessionStorage(),
       _faceVerification = faceVerificationService ?? StubFaceVerificationService(),
       _regionDetection = regionDetection ?? RegionDetectionService();

  final UserAuthRepository _repository;
  final AuthSessionStorage _storage;
  final FaceVerificationService _faceVerification;
  final RegionDetectionService _regionDetection;

  UserAuthState _state = UserAuthState();
  Timer? _resendTimer;
  StreamSubscription<bool>? _sessionSubscription;

  UserAuthState get state => _state;

  Future<void> initialize() async {
    _setState(_state.copyWith(status: UserAuthStatus.initializing, isBusy: true));

    _sessionSubscription ??= _repository.watchAuthSession().listen((_) {
      _restoreSession();
    });

    final userId = _repository.currentUserId;
    if (userId != null && _repository.hasActiveSession) {
      await _restoreSession();
      return;
    }

    await _initializePreAuthFlow();
  }

  Future<void> _initializePreAuthFlow() async {
    final draft = await _storage.loadPhoneDraft();
    final preAuthRegion = await _storage.loadPreAuthRegion();
    final regionComplete = await _storage.isPreAuthRegionComplete();
    final locationHandled = await _storage.isPreAuthLocationHandled();

    var country = CountryRegistry.fallback;
    var language = AppLanguage.english;
    var currency = country.defaultCurrencyCode;

    if (regionComplete && preAuthRegion.countryIso != null) {
      country = CountryRegistry.findByIso(preAuthRegion.countryIso!) ?? country;
      language = _languageFromCode(preAuthRegion.language);
      currency = preAuthRegion.currency ?? country.defaultCurrencyCode;
    }

    _state = _state.copyWith(
      selectedCountry: draft.countryIso != null
          ? authCountryByIso(draft.countryIso!)
          : country,
      phoneNumber: draft.phone ?? '',
      selectedLanguage: language,
      selectedCurrencyCode: currency,
    );

    final UserAuthStatus nextStatus;
    if (regionComplete) {
      nextStatus = UserAuthStatus.unauthenticated;
    } else if (locationHandled) {
      nextStatus = UserAuthStatus.awaitingRegionSetup;
    } else {
      nextStatus = UserAuthStatus.awaitingLocationPermission;
    }

    _setState(
      _state.copyWith(status: nextStatus, isBusy: false, clearMessage: true),
    );
  }

  Future<void> _restoreSession() async {
    final userId = _repository.currentUserId;
    if (userId == null || !_repository.hasActiveSession) {
      await _initializePreAuthFlow();
      return;
    }

    final onboardingComplete = await _storage.isOnboardingComplete(userId);
    if (onboardingComplete) {
      _setState(
        _state.copyWith(
          status: UserAuthStatus.authenticated,
          userId: userId,
          isBusy: false,
          clearMessage: true,
        ),
      );
      return;
    }

    final faceStatus = await _storage.getFaceStatus(userId);
    final nextStatus = faceStatus == FaceVerificationStatus.none
        ? UserAuthStatus.awaitingFaceVerification
        : UserAuthStatus.authenticated;

    if (nextStatus == UserAuthStatus.authenticated) {
      await _storage.markOnboardingComplete(userId);
    }

    _setState(
      _state.copyWith(
        status: nextStatus,
        userId: userId,
        faceVerificationStatus: faceStatus,
        isBusy: false,
        clearMessage: true,
      ),
    );
  }

  void selectCountry(AuthCountry country) {
    _setState(_state.copyWith(selectedCountry: country, clearMessage: true));
  }

  void selectLanguage(AppLanguage language) {
    _setState(_state.copyWith(selectedLanguage: language, clearMessage: true));
  }

  void selectCurrency(String code) {
    _setState(
      _state.copyWith(selectedCurrencyCode: code.toUpperCase(), clearMessage: true),
    );
  }

  void updatePhoneNumber(String value) {
    _setState(_state.copyWith(phoneNumber: value, clearMessage: true));
  }

  Future<void> requestLocationPermission() async {
    _setState(_state.copyWith(isBusy: true, clearMessage: true));

    LocationPermissionStatus result = LocationPermissionStatus.denied;
    RegionDetectionResult? detected;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          result = LocationPermissionStatus.granted;
          detected = await _regionDetection.detectFromCurrentLocation();
        } else if (permission == LocationPermission.deniedForever) {
          result = LocationPermissionStatus.denied;
        }
      }
    } catch (e) {
      debugPrint('[UserAuth] location permission error: $e');
      result = LocationPermissionStatus.denied;
    }

    await _storage.markPreAuthLocationHandled();
    final region = detected ?? _regionDetection.fallbackFromDeviceLocale();

    _setState(
      _state.copyWith(
        status: UserAuthStatus.awaitingRegionSetup,
        locationStatus: result,
        selectedCountry: region.country,
        selectedLanguage: region.suggestedLanguage,
        selectedCurrencyCode: region.suggestedCurrencyCode,
        detectedLatitude: region.latitude,
        detectedLongitude: region.longitude,
        isBusy: false,
      ),
    );
  }

  Future<void> skipLocationPermission() async {
    _setState(_state.copyWith(isBusy: true, clearMessage: true));
    await _storage.markPreAuthLocationHandled();
    final region = _regionDetection.fallbackFromDeviceLocale();

    _setState(
      _state.copyWith(
        status: UserAuthStatus.awaitingRegionSetup,
        locationStatus: LocationPermissionStatus.skipped,
        selectedCountry: region.country,
        selectedLanguage: region.suggestedLanguage,
        selectedCurrencyCode: region.suggestedCurrencyCode,
        isBusy: false,
        clearMessage: true,
      ),
    );
  }

  Future<void> confirmRegionSetup() async {
    _setState(_state.copyWith(isBusy: true, clearMessage: true));

    await _storage.savePreAuthRegion(
      countryIso: _state.selectedCountry.isoCode,
      languageCode: _languageCode(_state.selectedLanguage),
      currencyCode: _state.selectedCurrencyCode,
    );

    _setState(
      _state.copyWith(
        status: UserAuthStatus.unauthenticated,
        isBusy: false,
        clearMessage: true,
      ),
    );
  }

  Future<void> sendOtp() async {
    final digits = _state.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _state.selectedCountry.minPhoneLength) return;

    _setState(_state.copyWith(isBusy: true, clearMessage: true));

    try {
      await _storage.savePhoneDraft(
        countryIso: _state.selectedCountry.isoCode,
        phoneNumber: _state.phoneNumber,
      );

      MixpanelService.instance.trackAuthStarted(
        country: _state.selectedCountry.nameEn,
        countryCode: _state.selectedCountry.dialCode,
      );

      await _repository.sendPhoneOtp(_state.fullPhoneNumber);

      MixpanelService.instance.trackOtpSent(
        countryCode: _state.selectedCountry.dialCode,
      );

      _startResendCountdown();
      _setState(
        _state.copyWith(
          status: UserAuthStatus.awaitingOtpVerification,
          isBusy: false,
        ),
      );
    } on AuthRepositoryException catch (e) {
      _setState(
        _state.copyWith(
          isBusy: false,
          userMessage: e.message,
        ),
      );
    } catch (e) {
      debugPrint('[UserAuth] sendOtp unexpected: $e');
      _setState(
        _state.copyWith(
          isBusy: false,
          userMessage:
              'Unable to send verification code. Check your connection and try again.',
        ),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (otp.length < 6) return;

    _setState(_state.copyWith(isBusy: true, clearMessage: true));

    try {
      final userId = await _repository.verifyPhoneOtp(
        fullPhoneNumber: _state.fullPhoneNumber,
        otp: otp,
      );

      MixpanelService.instance.trackOtpVerified(
        countryCode: _state.selectedCountry.dialCode,
      );
      MixpanelService.instance.trackLoginCompleted(
        userId: userId,
        country: _state.selectedCountry.nameEn,
      );
      MixpanelService.instance.identify(userId);

      await _syncUserProfile(userId);

      _stopResendCountdown();
      _setState(
        _state.copyWith(
          status: UserAuthStatus.awaitingFaceVerification,
          userId: userId,
          isBusy: false,
        ),
      );
    } on AuthRepositoryException catch (e) {
      _setState(
        _state.copyWith(
          isBusy: false,
          userMessage: e.message,
        ),
      );
    } catch (e) {
      debugPrint('[UserAuth] verifyOtp unexpected: $e');
      _setState(
        _state.copyWith(
          isBusy: false,
          userMessage: 'Unable to verify the code. Please try again.',
        ),
      );
    }
  }

  Future<void> _syncUserProfile(String userId) async {
    try {
      await SupabaseService.instance.upsertUserProfileFromAuth(
        userId: userId,
        phone: _state.phoneNumber,
        phoneCountryCode: _state.selectedCountry.dialCode,
        countryCode: _state.selectedCountry.isoCode,
        preferredLanguage: _languageCode(_state.selectedLanguage),
        preferredCurrency: _state.selectedCurrencyCode,
        latitude: _state.detectedLatitude,
        longitude: _state.detectedLongitude,
        locationPermission: _state.locationStatus.name,
      );
    } catch (e) {
      debugPrint('[UserAuth] profile sync failed: $e');
    }
  }

  Future<void> resendOtp() async {
    if (!_state.canResendOtp) return;
    await sendOtp();
  }

  void goBackToPhoneEntry() {
    _stopResendCountdown();
    _setState(
      _state.copyWith(
        status: UserAuthStatus.unauthenticated,
        clearMessage: true,
      ),
    );
  }

  Future<void> setupFaceVerification() async {
    final userId = _state.userId;
    if (userId == null) return;

    _setState(_state.copyWith(isBusy: true, clearMessage: true));

    if (!_faceVerification.isAvailable) {
      await _storage.saveFaceStatus(userId, FaceVerificationStatus.skipped);
      await _completeOnboarding(userId);
      _setState(
        _state.copyWith(
          isBusy: false,
          faceVerificationStatus: FaceVerificationStatus.skipped,
          userMessage: null,
        ),
      );
      return;
    }

    try {
      final result = await _faceVerification.enroll();
      switch (result) {
        case FaceVerificationResult.success:
          await _storage.saveFaceStatus(
            userId,
            FaceVerificationStatus.completed,
          );
          await _updateFaceVerificationRemote(userId, 'verified');
          await _completeOnboarding(userId);
          _setState(
            _state.copyWith(
              isBusy: false,
              faceVerificationStatus: FaceVerificationStatus.completed,
            ),
          );
        case FaceVerificationResult.cancelled:
          _setState(_state.copyWith(isBusy: false));
        case FaceVerificationResult.unavailable:
          await _storage.saveFaceStatus(userId, FaceVerificationStatus.skipped);
          await _updateFaceVerificationRemote(userId, 'skipped');
          await _completeOnboarding(userId);
          _setState(
            _state.copyWith(
              isBusy: false,
              faceVerificationStatus: FaceVerificationStatus.skipped,
            ),
          );
        case FaceVerificationResult.failure:
          await _storage.saveFaceStatus(userId, FaceVerificationStatus.failed);
          await _updateFaceVerificationRemote(userId, 'failed');
          _setState(
            _state.copyWith(
              isBusy: false,
              faceVerificationStatus: FaceVerificationStatus.failed,
              userMessage:
                  'Face verification could not be completed. You can try again or skip for now.',
            ),
          );
      }
    } catch (e) {
      debugPrint('[UserAuth] face verification error: $e');
      _setState(
        _state.copyWith(
          isBusy: false,
          userMessage:
              'Face verification is temporarily unavailable. You can skip for now.',
        ),
      );
    }
  }

  Future<void> skipFaceVerification() async {
    final userId = _state.userId;
    if (userId == null) return;

    await _storage.saveFaceStatus(userId, FaceVerificationStatus.skipped);
    await _updateFaceVerificationRemote(userId, 'skipped');
    await _completeOnboarding(userId);
    _setState(
      _state.copyWith(
        faceVerificationStatus: FaceVerificationStatus.skipped,
        clearMessage: true,
      ),
    );
  }

  Future<void> _updateFaceVerificationRemote(
    String userId,
    String status,
  ) async {
    try {
      await SupabaseService.instance.updateUserProfile({
        'face_verification_status': status,
      });
    } catch (e) {
      debugPrint('[UserAuth] face status sync failed: $e');
    }
  }

  Future<void> signOut() async {
    final userId = _state.userId;
    _stopResendCountdown();
    await _repository.signOut();
    if (userId != null) {
      await _storage.clearUserData(userId);
    }
    MixpanelService.instance.reset();
    await _initializePreAuthFlow();
  }

  Future<void> _completeOnboarding(String userId) async {
    await _storage.markOnboardingComplete(userId);
    _setState(
      _state.copyWith(
        status: UserAuthStatus.authenticated,
        userId: userId,
      ),
    );
  }

  AppLanguage _languageFromCode(String? code) {
    switch (code) {
      case 'ar':
        return AppLanguage.arabic;
      case 'ku':
        return AppLanguage.kurdish;
      default:
        return AppLanguage.english;
    }
  }

  String _languageCode(AppLanguage language) {
    switch (language) {
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.kurdish:
        return 'ku';
      case AppLanguage.english:
        return 'en';
    }
  }

  void _startResendCountdown({int seconds = 60}) {
    _stopResendCountdown();
    _setState(_state.copyWith(otpResendSeconds: seconds));
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _state.otpResendSeconds - 1;
      if (next <= 0) {
        timer.cancel();
        _setState(_state.copyWith(otpResendSeconds: 0));
      } else {
        _setState(_state.copyWith(otpResendSeconds: next));
      }
    });
  }

  void _stopResendCountdown() {
    _resendTimer?.cancel();
    _resendTimer = null;
    if (_state.otpResendSeconds != 0) {
      _state = _state.copyWith(otpResendSeconds: 0);
    }
  }

  void _setState(UserAuthState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
