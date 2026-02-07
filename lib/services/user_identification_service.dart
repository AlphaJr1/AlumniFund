import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// Service untuk generate browser fingerprint
/// Mock implementation - nanti bisa diganti dengan library JS
class UserIdentificationService {
  /// Generate enhanced fingerprint berdasarkan device/hardware info
  /// Fokus pada data yang STABIL antar browser profile
  Future<String> generateFingerprint() async {
    // Collect device-level data (stable across browser profiles)
    final screenSize = '${PlatformDispatcher.instance.views.first.physicalSize}';
    final screenPixelRatio = '${PlatformDispatcher.instance.views.first.devicePixelRatio}';
    final platform = defaultTargetPlatform.toString();
    final locale = PlatformDispatcher.instance.locale.toString();
    
    // Additional hardware hints (available in web)
    final hardwareConcurrency = kIsWeb ? 'web-cores' : 'mobile-cores';
    final timezone = DateTime.now().timeZoneOffset.inHours.toString();
    
    // Combine all signals - prioritize hardware over browser-specific
    final rawData = [
      platform,           // OS (Windows/Mac/Linux)
      screenSize,         // Physical screen resolution (device-specific)
      screenPixelRatio,   // Pixel ratio (device-specific)
      timezone,           // Timezone (location-based, stable)
      hardwareConcurrency, // CPU cores (device-specific)
      locale,             // System locale
    ].join('-');
    
    // print('🔍 [Fingerprint] Raw data: $rawData');
    
    // Hash untuk create fingerprint
    final bytes = utf8.encode(rawData);
    final digest = sha256.convert(bytes);
    
    final fingerprint = digest.toString();
    // print('🔍 [Fingerprint] Generated: ${fingerprint.substring(0, 16)}...');
    
    return fingerprint;
  }

  /// Generate mock fingerprint yang bisa dikontrol untuk testing
  /// Tambahkan random seed untuk simulate different devices
  Future<String> generateMockFingerprint({String? seed}) async {
    if (seed != null) {
      final bytes = utf8.encode('mock-fingerprint-$seed');
      final digest = sha256.convert(bytes);
      return digest.toString();
    }
    
    // Random fingerprint untuk testing
    final random = Random().nextInt(999999);
    final bytes = utf8.encode('mock-fingerprint-$random');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Simulate fingerprint generation delay (real library takes ~50-200ms)
  Future<void> simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
