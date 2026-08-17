import 'package:url_launcher/url_launcher.dart';

/// Sales WhatsApp used by partner ads on My Properties.
abstract final class PartnerWhatsApp {
  static const e164 = '9647740080310';

  static Future<void> openChat() async {
    final uri = Uri.parse('https://wa.me/$e164');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
