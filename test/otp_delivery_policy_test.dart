import 'package:flutter_test/flutter_test.dart';

import 'package:madar/services/otp_delivery_service.dart';

void main() {
  group('OtpDeliveryChannel', () {
    test('auto is primary default', () {
      expect(OtpDeliveryChannel.auto.name, 'auto');
      expect(OtpDeliveryChannel.whatsapp.name, 'whatsapp');
      expect(OtpDeliveryChannel.sms.name, 'sms');
    });
  });

  group('WhatsApp fallback policy', () {
    bool shouldFallbackToSms({
      required bool whatsappOk,
      required bool retryable,
      required String? errorCode,
      required String prefer,
    }) {
      if (prefer == 'sms') return true;
      if (whatsappOk) return false;
      if (prefer == 'whatsapp') return false;
      return retryable || errorCode == 'whatsapp_not_configured';
    }

    test('does not dual-send on WhatsApp success', () {
      expect(
        shouldFallbackToSms(
          whatsappOk: true,
          retryable: true,
          errorCode: null,
          prefer: 'auto',
        ),
        isFalse,
      );
    });

    test('falls back when WhatsApp not configured', () {
      expect(
        shouldFallbackToSms(
          whatsappOk: false,
          retryable: false,
          errorCode: 'whatsapp_not_configured',
          prefer: 'auto',
        ),
        isTrue,
      );
    });

    test('does not fall back on permanent WhatsApp failure', () {
      expect(
        shouldFallbackToSms(
          whatsappOk: false,
          retryable: false,
          errorCode: 'whatsapp_132001',
          prefer: 'auto',
        ),
        isFalse,
      );
    });

    test('falls back on retryable WhatsApp failure', () {
      expect(
        shouldFallbackToSms(
          whatsappOk: false,
          retryable: true,
          errorCode: 'whatsapp_network',
          prefer: 'auto',
        ),
        isTrue,
      );
    });
  });
}
