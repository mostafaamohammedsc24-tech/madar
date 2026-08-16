/// Abstraction for user phone authentication (Supabase or future providers).
abstract class UserAuthRepository {
  bool get hasActiveSession;

  String? get currentUserId;

  Future<void> sendPhoneOtp(String fullPhoneNumber);

  Future<String> verifyPhoneOtp({
    required String fullPhoneNumber,
    required String otp,
  });

  Future<void> signOut();

  Stream<bool> watchAuthSession();
}
