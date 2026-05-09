import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class WhatsappShareService {
  static Future<bool> share({
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = _normalizeIndianNumber(phone);
    if (normalizedPhone.isEmpty || message.trim().isEmpty) return false;
    final uri = Uri.parse(
      'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(message)}',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sharePdf({
    required String filePath,
    required String fileName,
    required String message,
  }) async {
    try {
      final result = await SharePlus.instance
          .share(
            ShareParams(
              text: message,
              subject: fileName,
              files: [
                XFile(filePath, mimeType: 'application/pdf', name: fileName),
              ],
              fileNameOverrides: [fileName],
              downloadFallbackEnabled: true,
            ),
          )
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => const ShareResult(
              'share-sheet-opened',
              ShareResultStatus.success,
            ),
          );
      return result.status != ShareResultStatus.dismissed;
    } catch (_) {
      return false;
    }
  }

  static String _normalizeIndianNumber(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) {
      return '91$digits';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    }
    return digits;
  }
}
