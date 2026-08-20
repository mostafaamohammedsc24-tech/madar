import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/otp_delivery_service.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/repositories/user_auth_repository.dart';

class SupabaseUserAuthRepository implements UserAuthRepository {
  SupabaseUserAuthRepository({
    SupabaseService? service,
    OtpDeliveryService? otpDelivery,
  })  : _service = service ?? SupabaseService.instance,
        _otpDelivery = otpDelivery ?? OtpDeliveryService();

  final SupabaseService _service;
  final OtpDeliveryService _otpDelivery;

  /// When true, verify uses managed `otp-delivery` instead of Supabase Auth SMS OTP.
  bool _managedOtp = false;

  /// Last successful delivery channel (`whatsapp` | `sms` | `legacy`).
  @override
  String? lastDeliveryChannel;

  SupabaseClient? get _client {
    try {
      return _service.client;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get hasActiveSession {
    try {
      return _service.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  @override
  String? get currentUserId {
    try {
      return _service.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> sendPhoneOtp(
    String fullPhoneNumber, {
    OtpDeliveryChannel channel = OtpDeliveryChannel.auto,
  }) async {
    final client = _client;

    if (client == null) {
      throw AuthRepositoryException(
        'Authentication service is unavailable. Please try again later.',
      );
    }

    // Primary path: managed OTP via WhatsApp (Twilio SMS fallback on server).
    final managed = await _otpDelivery.send(
      phoneE164: fullPhoneNumber,
      channel: channel,
    );
    if (managed.success) {
      _managedOtp = true;
      lastDeliveryChannel = managed.channel ?? 'whatsapp';
      return;
    }

    if (managed.message == 'function_unavailable' ||
        managed.message == 'service_unavailable') {
      // Legacy fallback: Supabase Auth SMS (dashboard provider).
      debugPrint(
        '[UserAuth] otp-delivery unavailable (${managed.message}); '
        'falling back to Supabase Auth SMS',
      );
      try {
        await client.auth.signInWithOtp(phone: fullPhoneNumber);
        _managedOtp = false;
        lastDeliveryChannel = 'legacy';
        return;
      } on AuthException catch (e) {
        throw AuthRepositoryException(_mapAuthError(e.message));
      } catch (e) {
        debugPrint('[UserAuth] sendPhoneOtp legacy error: $e');
        throw AuthRepositoryException(
          'Unable to send verification code. Check your connection and try again.',
        );
      }
    }

    throw AuthRepositoryException(
      'Unable to send verification code. Check your connection and try again.',
    );
  }

  @override
  Future<String> verifyPhoneOtp({
    required String fullPhoneNumber,
    required String otp,
  }) async {
    final client = _client;
    if (client == null) {
      throw AuthRepositoryException(
        'Authentication service is unavailable. Please try again later.',
      );
    }

    if (_managedOtp) {
      final result = await _otpDelivery.verify(
        phoneE164: fullPhoneNumber,
        code: otp,
      );
      if (!result.success || result.hashedToken == null) {
        throw AuthRepositoryException(_mapManagedVerify(result.message));
      }
      try {
        final response = await client.auth.verifyOTP(
          tokenHash: result.hashedToken!,
          type: OtpType.magiclink,
        );
        final userId = response.user?.id ??
            result.userId ??
            client.auth.currentUser?.id;
        if (userId == null) {
          throw AuthRepositoryException(
            'Verification succeeded but session could not be established.',
          );
        }
        return userId;
      } on AuthException catch (e) {
        throw AuthRepositoryException(_mapAuthError(e.message));
      }
    }

    try {
      final response = await client.auth.verifyOTP(
        phone: fullPhoneNumber,
        token: otp,
        type: OtpType.sms,
      );
      final userId = response.user?.id ?? client.auth.currentUser?.id;
      if (userId == null) {
        throw AuthRepositoryException(
          'Verification succeeded but session could not be established.',
        );
      }
      return userId;
    } on AuthException catch (e) {
      throw AuthRepositoryException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AuthRepositoryException) rethrow;
      debugPrint('[UserAuth] verifyPhoneOtp error: $e');
      throw AuthRepositoryException(
        'Unable to verify the code. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _service.signOut();
    } catch (e) {
      debugPrint('[UserAuth] signOut error: $e');
    }
  }

  @override
  Stream<bool> watchAuthSession() {
    final client = _client;
    if (client == null) {
      return Stream.value(false);
    }
    return client.auth.onAuthStateChange.map(
      (event) => event.session != null,
    );
  }

  String _mapManagedVerify(String? message) {
    switch (message) {
      case 'expired':
        return 'The verification code has expired. Request a new one.';
      case 'too_many_attempts':
        return 'Too many attempts. Please wait before trying again.';
      case 'invalid':
        return 'The verification code is incorrect.';
      default:
        return 'Unable to verify the code. Please try again.';
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid') ||
        lower.contains('otp') ||
        lower.contains('token')) {
      return 'The verification code is incorrect.';
    }
    if (lower.contains('expired')) {
      return 'The verification code has expired. Request a new one.';
    }
    if (lower.contains('rate') || lower.contains('too many')) {
      return 'Too many attempts. Please wait before trying again.';
    }
    if (lower.contains('phone')) {
      return 'This phone number is not valid. Check the number and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

class AuthRepositoryException implements Exception {
  AuthRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
