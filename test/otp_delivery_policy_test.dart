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

  group('seed phone detection helpers', () {
    bool isSeedPhone(String phone) {
      final clean = phone.replaceAll(RegExp(r'\D'), '');
      return clean == '7740080310' || clean == '9647740080310';
    }

    test('accepts Iraq seed local and E.164 forms', () {
      expect(isSeedPhone('+9647740080310'), isTrue);
      expect(isSeedPhone('7740080310'), isTrue);
      expect(isSeedPhone('9647740080310'), isTrue);
      expect(isSeedPhone('+9647900000000'), isFalse);
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
