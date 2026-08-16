/// Placeholder for future office authentication — not implemented in this phase.
abstract class OfficeAuthRepository {
  Future<bool> signIn({
    required String officeCode,
    required String secretCode,
  });

  Future<void> signOut();
}

/// Placeholder for future employee authentication — not implemented in this phase.
abstract class EmployeeAuthRepository {
  Future<bool> signInWithPhone({
    required String fullPhoneNumber,
    required String otp,
  });

  Future<void> signOut();
}
