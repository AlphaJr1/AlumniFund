import 'dart:html' as html;
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service untuk generate anonymous user identifier
/// Menggunakan hybrid approach: localStorage UUID + browser fingerprint
class UserIdentifierService {
  static const String _storageKey = 'anonymous_user_id';

  /// Get or create anonymous user ID from localStorage
  String getAnonymousUserId() {
    // Check localStorage
    final stored = html.window.localStorage[_storageKey];
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    // Generate new UUID-like ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final newId = 'user_${timestamp}_$random';

    // Store in localStorage
    html.window.localStorage[_storageKey] = newId;
    return newId;
  }

  /// Generate browser fingerprint based on browser properties
  /// Returns null if fingerprinting fails
  String? getBrowserFingerprint() {
    try {
      final components = <String>[];

      // User agent
      components.add(html.window.navigator.userAgent ?? '');

      // Screen resolution
      final screen = html.window.screen;
      if (screen != null) {
        components.add('${screen.width}x${screen.height}');
      }

      // Timezone offset
      final timezoneOffset = DateTime.now().timeZoneOffset.inMinutes;
      components.add(timezoneOffset.toString());

      // Language
      components.add(html.window.navigator.language ?? '');

      // Platform
      components.add(html.window.navigator.platform ?? '');

      // Color depth
      if (screen != null) {
        components.add((screen.colorDepth ?? 24).toString());
      }

      // Combine all components
      final combined = components.join('|');

      // Generate hash (SHA-256)
      final bytes = utf8.encode(combined);
      final hash = sha256.convert(bytes);

      return hash.toString();
    } catch (e) {
      // Fingerprinting failed, return null
      return null;
    }
  }

  /// Get user agent string
  String? getUserAgent() {
    try {
      return html.window.navigator.userAgent;
    } catch (e) {
      return null;
    }
  }

  /// Get screen resolution as string
  String? getScreenResolution() {
    try {
      final screen = html.window.screen;
      if (screen != null) {
        return '${screen.width}x${screen.height}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get timezone as string
  String? getTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60);
      return 'UTC${hours >= 0 ? '+' : ''}$hours:${minutes.abs().toString().padLeft(2, '0')}';
    } catch (e) {
      return null;
    }
  }
}
