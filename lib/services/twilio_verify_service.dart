import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// Client for the `twilio-verify` Supabase Edge Function.
/// Secrets never ship in the app — only the function holds Twilio credentials.
class TwilioVerifyService {
  TwilioVerifyService({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final res = await _supabase.client.functions.invoke(
        'twilio-verify',
        body: body,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'success': false, 'message': 'invalid_response'};
    } catch (e) {
      debugPrint('[TwilioVerify] invoke failed: $e');
      return {'success': false, 'message': 'function_unavailable'};
    }
  }

  Future<({bool configured, String authMode})> status() async {
    final r = await _invoke({'action': 'status'});
    return (
      configured: r['configured'] == true,
      authMode: r['auth_mode']?.toString() ?? 'none',
    );
  }

  Future<({bool success, String? serviceSid, String? message})>
      ensureService() async {
    final r = await _invoke({'action': 'ensure_service'});
    return (
      success: r['success'] == true,
      serviceSid: r['service_sid']?.toString(),
      message: r['message']?.toString(),
    );
  }

  /// Send SMS OTP via Twilio Verify. [phoneE164] must start with +.
  Future<({bool success, String? status, String? message})> sendSms(
    String phoneE164,
  ) async {
    final r = await _invoke({
      'action': 'send',
      'to': phoneE164,
      'channel': 'sms',
    });
    return (
      success: r['success'] == true,
      status: r['status']?.toString(),
      message: r['message']?.toString(),
    );
  }

  Future<({bool success, String? status, String? message})> checkCode({
    required String phoneE164,
    required String code,
  }) async {
    final r = await _invoke({
      'action': 'check',
      'to': phoneE164,
      'code': code,
    });
    return (
      success: r['success'] == true,
      status: r['status']?.toString(),
      message: r['message']?.toString(),
    );
  }
}
