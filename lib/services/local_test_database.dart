import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple file-based mock database untuk testing
/// Dengan fitur export/import untuk share data across browser profiles
class LocalTestDatabase {
  static const String _mockUsersKey = 'brand_mock_users_v2';

  /// Export database ke JSON string
  static Future<String> exportToJson() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_mockUsersKey);

    if (jsonString == null) {
      return '[]';
    }

    print('✅ [TestDB] Exported database');
    return jsonString;
  }

  /// Import database dari JSON string
  static Future<void> importFromJson(String jsonString) async {
    try {
      // Validate JSON
      final List<dynamic> users = jsonDecode(jsonString);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mockUsersKey, jsonString);

      print('✅ [TestDB] Imported ${users.length} users');
    } catch (e) {
      print('❌ [TestDB] Import failed: $e');
      rethrow;
    }
  }

  /// Download database sebagai file (untuk browser)
  static String generateDownloadLink(String jsonData) {
    // Create data URL
    final bytes = utf8.encode(jsonData);
    final base64 = base64Encode(bytes);
    return 'data:application/json;base64,$base64';
  }

  /// Clear database
  static Future<void> clearDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mockUsersKey);
    print('✅ [TestDB] Database cleared');
  }

  /// Get database stats
  static Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_mockUsersKey);

    if (jsonString == null) {
      return {'totalUsers': 0, 'totalDevices': 0};
    }

    try {
      final List<dynamic> users = jsonDecode(jsonString);
      int totalDevices = 0;

      for (final user in users) {
        final fingerprints = user['fingerprints'] as List<dynamic>;
        totalDevices += fingerprints.length;
      }

      return {
        'totalUsers': users.length,
        'totalDevices': totalDevices,
      };
    } catch (e) {
      return {'totalUsers': 0, 'totalDevices': 0};
    }
  }
}
