/// Result of a face verification attempt.
enum FaceVerificationResult { success, cancelled, unavailable, failure }

/// Abstraction for face verification providers (to be wired when backend exists).
abstract class FaceVerificationService {
  /// Whether a real verification provider is configured.
  bool get isAvailable;

  /// Starts face enrollment / verification flow.
  Future<FaceVerificationResult> enroll();
}
