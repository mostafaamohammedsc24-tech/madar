import '../../../../core/geo/country_registry.dart';
import '../../../../core/geo/madar_country.dart';
import '../../../../core/localization/app_localizations.dart';

/// Lifecycle status for user authentication.
enum UserAuthStatus {
  initializing,
  /// First launch — request location before anything else.
  awaitingLocationPermission,
  /// Confirm detected country, language, and currency.
  awaitingRegionSetup,
  /// Phone number entry.
  unauthenticated,
  awaitingOtpVerification,
  awaitingFaceVerification,
  authenticated,
  failure,
}

enum FaceVerificationStatus { none, skipped, completed, failed }

enum LocationPermissionStatus { notRequested, granted, denied, skipped }

/// Immutable snapshot of the user authentication flow.
class UserAuthState {
  UserAuthState({
    this.status = UserAuthStatus.initializing,
    MadarCountry? selectedCountry,
    this.phoneNumber = '',
    this.otpResendSeconds = 0,
    this.isBusy = false,
    this.userMessage,
    this.userId,
    this.locationStatus = LocationPermissionStatus.notRequested,
    this.faceVerificationStatus = FaceVerificationStatus.none,
    this.selectedLanguage = AppLanguage.english,
    this.selectedCurrencyCode = 'USD',
    this.detectedLatitude,
    this.detectedLongitude,
  }) : selectedCountry = selectedCountry ?? CountryRegistry.fallback;

  final UserAuthStatus status;
  final MadarCountry selectedCountry;
  final String phoneNumber;
  final int otpResendSeconds;
  final bool isBusy;
  final String? userMessage;
  final String? userId;
  final LocationPermissionStatus locationStatus;
  final FaceVerificationStatus faceVerificationStatus;
  final AppLanguage selectedLanguage;
  final String selectedCurrencyCode;
  final double? detectedLatitude;
  final double? detectedLongitude;

  String get fullPhoneNumber {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    return '${selectedCountry.e164Prefix}$digits';
  }

  String get maskedPhoneNumber {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return fullPhoneNumber;
    final visible = digits.substring(digits.length - 4);
    return '${selectedCountry.dialCode} ••• •• $visible';
  }

  bool get canResendOtp => otpResendSeconds <= 0 && !isBusy;

  UserAuthState copyWith({
    UserAuthStatus? status,
    MadarCountry? selectedCountry,
    String? phoneNumber,
    int? otpResendSeconds,
    bool? isBusy,
    String? userMessage,
    bool clearMessage = false,
    String? userId,
    LocationPermissionStatus? locationStatus,
    FaceVerificationStatus? faceVerificationStatus,
    AppLanguage? selectedLanguage,
    String? selectedCurrencyCode,
    double? detectedLatitude,
    double? detectedLongitude,
  }) {
    return UserAuthState(
      status: status ?? this.status,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpResendSeconds: otpResendSeconds ?? this.otpResendSeconds,
      isBusy: isBusy ?? this.isBusy,
      userMessage: clearMessage ? null : (userMessage ?? this.userMessage),
      userId: userId ?? this.userId,
      locationStatus: locationStatus ?? this.locationStatus,
      faceVerificationStatus:
          faceVerificationStatus ?? this.faceVerificationStatus,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedCurrencyCode: selectedCurrencyCode ?? this.selectedCurrencyCode,
      detectedLatitude: detectedLatitude ?? this.detectedLatitude,
      detectedLongitude: detectedLongitude ?? this.detectedLongitude,
    );
  }
}
