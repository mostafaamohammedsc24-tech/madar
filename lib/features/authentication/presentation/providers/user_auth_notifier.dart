import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

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
  }) : _repository = repository ?? SupabaseUserAuthRepository(),
       _storage = storage ?? AuthSessionStorage(),
       _faceVerification = faceVerificationService ?? StubFaceVerificationService();

  final UserAuthRepository _repository;
  final AuthSessionStorage _storage;
  final FaceVerificationService _faceVerification;

  UserAuthState _state = UserAuthState();
  Timer? _resendTimer;
  StreamSubscription<bool>? _sessionSubscription;

  UserAuthState get state => _state;

  Future<void> initialize() async {
    _setState(_state.copyWith(status: UserAuthStatus.initializing, isBusy: true));

    final draft = await _storage.loadPhoneDraft();
    if (draft.countryIso != null) {
      _state = _state.copyWith(
        selectedCountry: authCountryByIso(draft.countryIso!),
        phoneNumber: draft.phone ?? '',
      );
    }

    _sessionSubscription ??= _repository.watchAuthSession().listen((_) {
      _restoreSession();
    });

    await _restoreSession();
  }

  Future<void> _restoreSession() async {
    final userId = _repository.currentUserId;
    if (userId == null || !_repository.hasActiveSession) {
      _setState(
        _state.copyWith(
          status: UserAuthStatus.unauthenticated,
          isBusy: false,
          clearMessage: true,
        ),
      );
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

    final locationStatus = await _storage.getLocationStatus(userId);
    final faceStatus = await _storage.getFaceStatus(userId);

    UserAuthStatus nextStatus;
    if (locationStatus == LocationPermissionStatus.notRequested) {
      nextStatus = UserAuthStatus.awaitingLocationPermission;
    } else if (faceStatus == FaceVerificationStatus.none) {
      nextStatus = UserAuthStatus.awaitingFaceVerification;
    } else {
      await _storage.markOnboardingComplete(userId);
      nextStatus = UserAuthStatus.authenticated;
    }

    _setState(
      _state.copyWith(
        status: nextStatus,
        userId: userId,
        locationStatus: locationStatus,
        faceVerificationStatus: faceStatus,
        isBusy: false,
        clearMessage: true,
      ),
    );
  }

  void selectCountry(AuthCountry country) {
    _setState(_state.copyWith(selectedCountry: country, clearMessage: true));
  }

  void updatePhoneNumber(String value) {
    _setState(_state.copyWith(phoneNumber: value, clearMessage: true));
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

      _stopResendCountdown();
      _setState(
        _state.copyWith(
          status: UserAuthStatus.awaitingLocationPermission,
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

  Future<void> requestLocationPermission() async {
    final userId = _state.userId;
    if (userId == null) return;

    _setState(_state.copyWith(isBusy: true, clearMessage: true));

    LocationPermissionStatus result = LocationPermissionStatus.denied;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        result = LocationPermissionStatus.denied;
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          result = LocationPermissionStatus.granted;
        } else if (permission == LocationPermission.deniedForever) {
          result = LocationPermissionStatus.denied;
        }
      }
    } catch (e) {
      debugPrint('[UserAuth] location permission error: $e');
      result = LocationPermissionStatus.denied;
    }

    await _storage.saveLocationStatus(userId, result);
    _setState(
      _state.copyWith(
        status: UserAuthStatus.awaitingFaceVerification,
        locationStatus: result,
        isBusy: false,
      ),
    );
  }

  Future<void> skipLocationPermission() async {
    final userId = _state.userId;
    if (userId == null) return;

    await _storage.saveLocationStatus(
      userId,
      LocationPermissionStatus.skipped,
    );
    _setState(
      _state.copyWith(
        status: UserAuthStatus.awaitingFaceVerification,
        locationStatus: LocationPermissionStatus.skipped,
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
          await _completeOnboarding(userId);
          _setState(
            _state.copyWith(
              isBusy: false,
              faceVerificationStatus: FaceVerificationStatus.skipped,
            ),
          );
        case FaceVerificationResult.failure:
          await _storage.saveFaceStatus(userId, FaceVerificationStatus.failed);
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
    await _completeOnboarding(userId);
    _setState(
      _state.copyWith(
        faceVerificationStatus: FaceVerificationStatus.skipped,
        clearMessage: true,
      ),
    );
  }

  Future<void> signOut() async {
    final userId = _state.userId;
    _stopResendCountdown();
    await _repository.signOut();
    if (userId != null) {
      await _storage.clearUserData(userId);
    }
    MixpanelService.instance.reset();
    _setState(
      UserAuthState(status: UserAuthStatus.unauthenticated),
    );
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
