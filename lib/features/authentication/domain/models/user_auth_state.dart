import 'auth_country.dart';

/// Lifecycle status for user authentication.
enum UserAuthStatus {
  /// Initial session check in progress.
  initializing,

  /// User is not signed in — show phone entry.
  unauthenticated,

  /// OTP has been sent — awaiting verification.
  awaitingOtpVerification,

  /// Phone verified — location onboarding pending.
  awaitingLocationPermission,

  /// Location handled — face verification setup pending.
  awaitingFaceVerification,

  /// Fully authenticated and onboarding complete.
  authenticated,

  /// Recoverable error state (network, invalid OTP, etc.).
  failure,
}

enum FaceVerificationStatus { none, skipped, completed, failed }

enum LocationPermissionStatus { notRequested, granted, denied, skipped }

/// Immutable snapshot of the user authentication flow.
class UserAuthState {
  UserAuthState({
    this.status = UserAuthStatus.initializing,
    AuthCountry? selectedCountry,
    this.phoneNumber = '',
    this.otpResendSeconds = 0,
    this.isBusy = false,
    this.userMessage,
    this.userId,
    this.locationStatus = LocationPermissionStatus.notRequested,
    this.faceVerificationStatus = FaceVerificationStatus.none,
  }) : selectedCountry = selectedCountry ?? authCountries.first;

  final UserAuthStatus status;
  final AuthCountry selectedCountry;
  final String phoneNumber;
  final int otpResendSeconds;
  final bool isBusy;
  final String? userMessage;
  final String? userId;
  final LocationPermissionStatus locationStatus;
  final FaceVerificationStatus faceVerificationStatus;

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
    AuthCountry? selectedCountry,
    String? phoneNumber,
    int? otpResendSeconds,
    bool? isBusy,
    String? userMessage,
    bool clearMessage = false,
    String? userId,
    LocationPermissionStatus? locationStatus,
    FaceVerificationStatus? faceVerificationStatus,
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
    );
  }
}
