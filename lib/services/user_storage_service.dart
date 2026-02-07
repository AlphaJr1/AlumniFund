import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Device metadata
class DeviceInfo {
  final String fingerprint;
  final DateTime addedAt;

  DeviceInfo({
    required this.fingerprint,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'fingerprint': fingerprint,
        'addedAt': addedAt.toIso8601String(),
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        fingerprint: json['fingerprint'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

/// Model untuk user data
class UserData {
  final String userId;
  final String displayName; // Primary identifier
  final List<String> fingerprints; // Multiple devices (legacy)
  final List<DeviceInfo> devices; // Device metadata
  final DateTime createdAt;
  final DateTime lastSeen;

  UserData({
    required this.userId,
    required this.displayName,
    required this.fingerprints,
    List<DeviceInfo>? devices,
    required this.createdAt,
    required this.lastSeen,
  }) : devices = devices ?? [];

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'fingerprints': fingerprints,
        'devices': devices.map((d) => d.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory UserData.fromJson(Map<String, dynamic> json) {
    final fingerprints = (json['fingerprints'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
    
    // Parse devices if available, otherwise create from fingerprints
    List<DeviceInfo> devices = [];
    if (json['devices'] != null) {
      devices = (json['devices'] as List<dynamic>)
          .map((e) => DeviceInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      // Migrate old data
      final now = DateTime.now();
      devices = fingerprints
          .map((fp) => DeviceInfo(fingerprint: fp, addedAt: now))
          .toList();
    }

    return UserData(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      fingerprints: fingerprints,
      devices: devices,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );
  }

  UserData copyWith({
    String? userId,
    String? displayName,
    List<String>? fingerprints,
    List<DeviceInfo>? devices,
    DateTime? createdAt,
    DateTime? lastSeen,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      fingerprints: fingerprints ?? this.fingerprints,
      devices: devices ?? this.devices,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  // Helper: Get primary fingerprint (first one)
  String get primaryFingerprint =>
      fingerprints.isNotEmpty ? fingerprints.first : '';

  // Helper: Check if fingerprint exists
  bool hasFingerprint(String fingerprint) =>
      fingerprints.contains(fingerprint);

  // Helper: Add new fingerprint with timestamp
  UserData addFingerprint(String fingerprint) {
    if (hasFingerprint(fingerprint)) return this;
    
    final newDevices = List<DeviceInfo>.from(devices)
      ..add(DeviceInfo(fingerprint: fingerprint, addedAt: DateTime.now()));
    
    return copyWith(
      fingerprints: [...fingerprints, fingerprint],
      devices: newDevices,
      lastSeen: DateTime.now(),
    );
  }

  // Helper: Remove fingerprint
  UserData removeFingerprint(String fingerprint) {
    return copyWith(
      fingerprints: fingerprints.where((fp) => fp != fingerprint).toList(),
      devices: devices.where((d) => d.fingerprint != fingerprint).toList(),
    );
  }
}

/// Service untuk manage user data di local storage
/// Menggunakan SharedPreferences sebagai mock IndexedDB
/// (Flutter web akan compile ke browser's localStorage/IndexedDB)
class UserStorageService {
  static const String _userDataKey = 'brand_user_data';
  static const String _mockUsersKey = 'brand_mock_users'; // For testing

  /// Get user data dari storage
  Future<UserData?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userDataKey);
    
    if (jsonString == null) return null;
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserData.fromJson(json);
    } catch (e) {
      // Invalid data, clear it
      await clearUserData();
      return null;
    }
  }

  /// Save user data ke storage
  Future<void> saveUserData(UserData userData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(userData.toJson());
    await prefs.setString(_userDataKey, jsonString);
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen() async {
    final userData = await getUserData();
    if (userData != null) {
      final updated = userData.copyWith(lastSeen: DateTime.now());
      await saveUserData(updated);
    }
  }

  /// Clear user data (untuk testing/logout)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  /// Check if user data exists
  Future<bool> hasUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userDataKey);
  }

  // ============ MOCK FIRESTORE FUNCTIONS (untuk testing) ============
  // NOTE: SharedPreferences is isolated per browser profile.
  // In production, this will use real Firestore which IS shared across devices.
  // For testing multiple devices, you need to manually verify the logic works.

  /// Mock: Get all users (simulate Firestore query)
  Future<List<UserData>> getMockUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_mockUsersKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => UserData.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Mock: Find user by fingerprint (simulate Firestore query)
  Future<UserData?> findUserByFingerprint(String fingerprint) async {
    // print('🔍 [Storage] Finding user by fingerprint: ${fingerprint.substring(0, 16)}...');
    final users = await getMockUsers();
    try {
      final user = users.firstWhere((user) => user.hasFingerprint(fingerprint));
      // print('✅ [Storage] User found: ${user.displayName}');
      return user;
    } catch (e) {
      // print('❌ [Storage] No user found with this fingerprint');
      return null;
    }
  }

  /// Mock: Find user by display name (simulate Firestore query)
  Future<UserData?> findUserByName(String displayName) async {
    // print('🔍 [Storage] Finding user by name: $displayName');
    final users = await getMockUsers();
    try {
      final user = users.firstWhere(
        (user) => user.displayName.toLowerCase() == displayName.toLowerCase(),
      );
      // print('✅ [Storage] User found: ${user.displayName} with ${user.fingerprints.length} device(s)');
      return user;
    } catch (e) {
      // print('❌ [Storage] No user found with this name');
      return null;
    }
  }

  /// Mock: Save user to "Firestore" (SharedPreferences for now)
  Future<void> saveMockUser(UserData userData) async {
    final users = await getMockUsers();

    // Remove existing user with same ID
    users.removeWhere((user) => user.userId == userData.userId);

    // Add new/updated user
    users.add(userData);

    // Save back
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_mockUsersKey, jsonString);
    // print('✅ [Storage] User saved to mock database');
  }

  /// Mock: Clear all mock users (untuk testing)
  Future<void> clearMockUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mockUsersKey);
    // print('✅ [Storage] Mock database cleared');
  }

  /// Get total mock users count
  Future<int> getMockUsersCount() async {
    final users = await getMockUsers();
    return users.length;
  }
}
