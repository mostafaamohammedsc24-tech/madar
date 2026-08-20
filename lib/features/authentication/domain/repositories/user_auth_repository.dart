import '../../../../services/otp_delivery_service.dart';

/// Abstraction for user phone authentication (Supabase or future providers).
abstract class UserAuthRepository {
  bool get hasActiveSession;

  String? get currentUserId;

  /// Last delivery channel after a successful [sendPhoneOtp], if known.
  String? get lastDeliveryChannel => null;

  Future<void> sendPhoneOtp(
    String fullPhoneNumber, {
    OtpDeliveryChannel channel = OtpDeliveryChannel.auto,
  });

  Future<String> verifyPhoneOtp({
    required String fullPhoneNumber,
    required String otp,
  });

  Future<void> signOut();

  Stream<bool> watchAuthSession();
}
