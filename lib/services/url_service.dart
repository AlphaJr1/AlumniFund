/// Utility class untuk generate URLs
class UrlService {
  /// Generate WhatsApp URL dengan pre-filled message
  ///
  /// Example:
  /// ```dart
  /// final url = UrlService.generateWhatsAppUrl(
  ///   phoneNumber: '+6281377707700',
  ///   targetMonth: 'Mei 2026',
  /// );
  /// ```
  static String generateWhatsAppUrl({
    required String phoneNumber,
    required String targetMonth,
  }) {
    // Remove any spaces or special characters from phone number
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Get current date
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    // Create pre-filled message
    final message = '''
Halo Admin! 🎓

Saya baru saja transfer untuk Target Wisuda $targetMonth:

💰 Nominal: Rp _____
📅 Tanggal Transfer: $dateStr
🏦 Dari Bank: _____

Mohon divalidasi ya! Terima kasih 😊
''';

    // URL encode the message
    final encodedMessage = Uri.encodeComponent(message);

    // Generate WhatsApp URL
    return 'https://wa.me/$cleanedPhone?text=$encodedMessage';
  }

  /// Generate WhatsApp URL untuk custom message
  ///
  /// Example:
  /// ```dart
  /// final url = UrlService.generateWhatsAppUrlCustom(
  ///   phoneNumber: '+6281377707700',
  ///   message: 'Halo, saya ingin bertanya...',
  /// );
  /// ```
  static String generateWhatsAppUrlCustom({
    required String phoneNumber,
    required String message,
  }) {
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/$cleanedPhone?text=$encodedMessage';
  }

  /// Open URL in browser (untuk web)
  /// Note: Untuk Flutter web, gunakan url_launcher package
  static Future<void> openUrl(String url) async {
    // This will be implemented with url_launcher in actual usage
    // For now, just a placeholder
    throw UnimplementedError('Use url_launcher package to open URL');
  }
}
