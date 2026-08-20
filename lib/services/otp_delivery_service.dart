import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

enum OtpDeliveryChannel { auto, whatsapp, sms }

/// Client for the `otp-delivery` Edge Function (WhatsApp primary, SMS fallback).
/// Twilio Verify (`TwilioVerifyService`) stays separate for bank/employee flows.
class OtpDeliveryService {
  OtpDeliveryService({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final res = await _supabase.client.functions.invoke(
        'otp-delivery',
        body: body,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'success': false, 'message': 'invalid_response'};
    } catch (e) {
      debugPrint('[OtpDelivery] invoke failed: $e');
      return {'success': false, 'message': 'function_unavailable'};
    }
  }

  Future<({bool success, String? channel, String? message})> send({
    required String phoneE164,
    OtpDeliveryChannel channel = OtpDeliveryChannel.auto,
  }) async {
    final r = await _invoke({
      'action': 'send',
      'phone': phoneE164,
      'channel': channel.name,
    });
    return (
      success: r['success'] == true,
      channel: r['channel']?.toString(),
      message: r['message']?.toString(),
    );
  }

  Future<
      ({
        bool success,
        String? userId,
        String? hashedToken,
        String? email,
        String? message,
      })> verify({
    required String phoneE164,
    required String code,
  }) async {
    final r = await _invoke({
      'action': 'verify',
      'phone': phoneE164,
      'code': code,
    });
    return (
      success: r['success'] == true,
      userId: r['user_id']?.toString(),
      hashedToken: r['hashed_token']?.toString(),
      email: r['email']?.toString(),
      message: r['message']?.toString(),
    );
  }

  Future<bool> preferChannel({
    required String phoneE164,
    required OtpDeliveryChannel channel,
  }) async {
    if (channel == OtpDeliveryChannel.auto) return false;
    final r = await _invoke({
      'action': 'prefer_channel',
      'phone': phoneE164,
      'channel': channel.name,
    });
    return r['success'] == true;
  }
}
