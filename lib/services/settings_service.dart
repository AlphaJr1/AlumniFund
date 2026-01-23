import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/settings_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'dart:typed_data';

/// Service untuk handle settings operations
class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  /// Get current settings
  Future<AppSettings> getSettings() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.settings)
          .doc('app_config')
          .get();

      return AppSettings.fromFirestore(doc);
    } catch (e) {
      throw Exception('Gagal mengambil settings: $e');
    }
  }

  /// Update payment methods
  /// Supports multiple payment methods (bank + e-wallet)
  Future<void> updatePaymentMethods({
    required List<PaymentMethod> paymentMethods,
    required String updatedBy,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.settings)
          .doc('app_config')
          .update({
        'payment_methods': paymentMethods.map((m) => m.toMap()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': updatedBy,
      });
    } catch (e) {
      throw Exception('Gagal update payment methods: $e');
    }
  }

  /// Upload QR code dan update payment method
  /// QR code hanya 1 untuk semua payment methods
  Future<String> uploadQRCode({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final downloadUrl = await _storageService.uploadQRCode(
        imageBytes: imageBytes,
        fileName: fileName,
      );
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal upload QR code: $e');
    }
  }

  /// Update system configuration
  /// Also recalculates all target deadlines and amounts if config changed
  Future<void> updateSystemConfig({
    required SystemConfig systemConfig,
    required String updatedBy,
  }) async {
    try {
      // Get current settings to check what changed
      final currentSettings = await getSettings();
      final offsetChanged = currentSettings.systemConfig.deadlineOffsetDays !=
          systemConfig.deadlineOffsetDays;
      final allocationChanged =
          currentSettings.systemConfig.perPersonAllocation !=
              systemConfig.perPersonAllocation;

      // Update settings
      await _firestore
          .collection(FirestoreCollections.settings)
          .doc('app_config')
          .update({
        'system_config': systemConfig.toMap(),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': updatedBy,
      });

      // Recalculate targets if needed
      if (offsetChanged || allocationChanged) {
        await _recalculateAllTargets(
          newOffsetDays: systemConfig.deadlineOffsetDays,
          newPerPersonAllocation: systemConfig.perPersonAllocation,
          recalculateDeadline: offsetChanged,
          recalculateAmount: allocationChanged,
        );
      }
    } catch (e) {
      throw Exception('Gagal update system config: $e');
    }
  }

  /// Recalculate deadlines and/or amounts for all upcoming and active targets
  Future<void> _recalculateAllTargets({
    required int newOffsetDays,
    required double newPerPersonAllocation,
    required bool recalculateDeadline,
    required bool recalculateAmount,
  }) async {
    try {
      // Get all upcoming and active targets
      final targetsSnapshot = await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .where('status', whereIn: ['upcoming', 'active'])
          .get();

      final batch = _firestore.batch();
      int updatedCount = 0;

      for (var doc in targetsSnapshot.docs) {
        final data = doc.data();
        final graduates = data['graduates'] as List<dynamic>;

        if (graduates.isEmpty) continue;

        final Map<String, dynamic> updates = {
          'updated_at': FieldValue.serverTimestamp(),
        };

        // Recalculate deadline if offset changed
        if (recalculateDeadline) {
          // Find earliest graduate date
          DateTime? earliestDate;
          for (var grad in graduates) {
            final gradDate = (grad['date'] as Timestamp).toDate();
            if (earliestDate == null || gradDate.isBefore(earliestDate)) {
              earliestDate = gradDate;
            }
          }

          if (earliestDate != null) {
            final newDeadline = earliestDate.subtract(
              Duration(days: newOffsetDays),
            );
            updates['deadline'] = Timestamp.fromDate(newDeadline);
          }
        }

        // Recalculate target amount if allocation changed
        if (recalculateAmount) {
          final newTargetAmount = graduates.length * newPerPersonAllocation;
          updates['target_amount'] = newTargetAmount;
        }

        // Update target
        batch.update(doc.reference, updates);
        updatedCount++;
      }

      if (updatedCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Gagal recalculate targets: $e');
    }
  }

  /// Update admin configuration
  Future<void> updateAdminConfig({
    required AdminConfig adminConfig,
    required String updatedBy,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.settings)
          .doc('app_config')
          .update({
        'admin_config': adminConfig.toMap(),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': updatedBy,
      });
    } catch (e) {
      throw Exception('Gagal update admin config: $e');
    }
  }

  /// Export all data to JSON
  /// Returns JSON string dengan semua collections
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final Map<String, dynamic> exportData = {};

      // Helper function to convert Timestamp to ISO8601 string
      dynamic convertTimestamp(dynamic value) {
        if (value is Timestamp) {
          return value.toDate().toIso8601String();
        } else if (value is Map) {
          return value.map((k, v) => MapEntry(k, convertTimestamp(v)));
        } else if (value is List) {
          return value.map((item) => convertTimestamp(item)).toList();
        }
        return value;
      }

      // Export graduation targets
      final targetsSnapshot = await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .get();
      exportData['graduation_targets'] = targetsSnapshot.docs
          .map((doc) => convertTimestamp({'id': doc.id, ...doc.data()}))
          .toList();

      // Export transactions
      final transactionsSnapshot = await _firestore
          .collection(FirestoreCollections.transactions)
          .get();
      exportData['transactions'] = transactionsSnapshot.docs
          .map((doc) => convertTimestamp({'id': doc.id, ...doc.data()}))
          .toList();

      // Export general fund
      final fundSnapshot = await _firestore
          .collection(FirestoreCollections.generalFund)
          .get();
      exportData['general_fund'] = fundSnapshot.docs
          .map((doc) => convertTimestamp({'id': doc.id, ...doc.data()}))
          .toList();

      // Export settings
      final settingsSnapshot = await _firestore
          .collection(FirestoreCollections.settings)
          .get();
      exportData['settings'] = settingsSnapshot.docs
          .map((doc) => convertTimestamp({'id': doc.id, ...doc.data()}))
          .toList();

      // Export pending submissions
      final submissionsSnapshot = await _firestore
          .collection(FirestoreCollections.pendingSubmissions)
          .get();
      exportData['pending_submissions'] = submissionsSnapshot.docs
          .map((doc) => convertTimestamp({'id': doc.id, ...doc.data()}))
          .toList();

      // Add metadata
      exportData['export_metadata'] = {
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0',
        'app_name': AppConstants.appName,
      };

      return exportData;
    } catch (e) {
      throw Exception('Gagal export data: $e');
    }
  }

  /// Reset all data (DELETE ALL COLLECTIONS)
  /// DANGEROUS! Requires double confirmation
  Future<void> resetAllData() async {
    try {
      final batch = _firestore.batch();

      // Delete all graduation targets
      final targetsSnapshot = await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .get();
      for (var doc in targetsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all transactions
      final transactionsSnapshot = await _firestore
          .collection(FirestoreCollections.transactions)
          .get();
      for (var doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Reset general fund to 0
      final fundSnapshot = await _firestore
          .collection(FirestoreCollections.generalFund)
          .get();
      for (var doc in fundSnapshot.docs) {
        batch.update(doc.reference, {
          'balance': 0,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // Delete all pending submissions
      final submissionsSnapshot = await _firestore
          .collection(FirestoreCollections.pendingSubmissions)
          .get();
      for (var doc in submissionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all target analytics (Cloud Functions generated data)
      final analyticsSnapshot = await _firestore
          .collection('target_analytics')
          .get();
      for (var doc in analyticsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all analytics collection (another Cloud Functions data)
      final analytics2Snapshot = await _firestore
          .collection('analytics')
          .get();
      for (var doc in analytics2Snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Keep settings (don't delete)
      // Keep admin users (don't delete)

      await batch.commit();

      // DELETE ALL FIREBASE STORAGE FILES
      try {
        // Delete all proof images
        await _storageService.deleteAllProofImages();

        // Delete all QR codes
        await _storageService.deleteAllQRCodes();
      } catch (storageError) {
        // Continue even if storage deletion fails
      }
    } catch (e) {
      throw Exception('Gagal reset data: $e');
    }
  }

  /// Initialize default settings if not exists
  Future<void> initializeDefaultSettings() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.settings)
          .doc('app_config')
          .get();

      if (!doc.exists) {
        final defaultSettings = AppSettings.defaults();
        await _firestore
            .collection(FirestoreCollections.settings)
            .doc('app_config')
            .set(defaultSettings.toFirestore());
      }
    } catch (e) {
      throw Exception('Gagal initialize settings: $e');
    }
  }
}
