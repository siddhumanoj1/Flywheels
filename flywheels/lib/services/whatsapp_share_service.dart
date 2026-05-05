import 'package:url_launcher/url_launcher.dart';

abstract final class WhatsappShareService {
  static Future<bool> share({
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
