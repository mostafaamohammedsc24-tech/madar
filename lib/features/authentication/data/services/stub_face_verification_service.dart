import '../../domain/services/face_verification_service.dart';

/// Placeholder until a real face verification provider is integrated.
class StubFaceVerificationService implements FaceVerificationService {
  @override
  bool get isAvailable => false;

  @override
  Future<FaceVerificationResult> enroll() async {
    return FaceVerificationResult.unavailable;
  }
}
