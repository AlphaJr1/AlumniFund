import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/graduation_target_model.dart';
import '../models/general_fund_model.dart';
import '../models/pending_submission_model.dart';
import '../models/transaction_model.dart';
import '../models/settings_model.dart';
import '../utils/constants.dart';

/// Service untuk handle semua Firestore operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== GRADUATION TARGETS ====================

  /// Get graduation target by ID
  Future<GraduationTarget?> getGraduationTarget(String targetId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .doc(targetId)
          .get();

      if (!doc.exists) return null;
      return GraduationTarget.fromFirestore(doc);
    } catch (e) {
      throw Exception('Gagal get target: $e');
    }
  }

  /// Create graduation target baru
  Future<void> createGraduationTarget(GraduationTarget target) async {
    try {
      await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .doc(target.id)
          .set(target.toFirestore());
    } catch (e) {
      throw Exception('Gagal create target: $e');
    }
  }

  /// Update graduation target
  Future<void> updateGraduationTarget(GraduationTarget target) async {
    try {
      await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .doc(target.id)
          .update(target.toFirestore());
    } catch (e) {
      throw Exception('Gagal update target: $e');
    }
  }

  /// Delete graduation target
  Future<void> deleteGraduationTarget(String targetId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .doc(targetId)
          .delete();
    } catch (e) {
      throw Exception('Gagal delete target: $e');
    }
  }

  // ==================== TRANSACTIONS ====================

  /// Add transaction baru
  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final docRef = await _firestore
          .collection(FirestoreCollections.transactions)
          .add(transaction.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah transaksi: $e');
    }
  }

  /// Update transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection(FirestoreCollections.transactions)
          .doc(transaction.id)
          .update(transaction.toFirestore());
    } catch (e) {
      throw Exception('Gagal update transaksi: $e');
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.transactions)
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception('Gagal menghapus transaksi: $e');
    }
  }

  // ==================== GENERAL FUND ====================

  /// Get general fund
  Future<GeneralFund> getGeneralFund() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.generalFund)
          .doc('current')
          .get();

      return GeneralFund.fromFirestore(doc);
    } catch (e) {
      throw Exception('Gagal get general fund: $e');
    }
  }

  /// Update general fund
  Future<void> updateGeneralFund(GeneralFund fund) async {
    try {
      await _firestore
          .collection(FirestoreCollections.generalFund)
          .doc('current')
          .set(fund.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Gagal update general fund: $e');
    }
  }

  /// Initialize general fund jika belum ada
  Future<void> initializeGeneralFund() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.generalFund)
          .doc('current')
          .get();

      if (!doc.exists) {
        final emptyFund = GeneralFund.empty();
        await _firestore
            .collection(FirestoreCollections.generalFund)
            .doc('current')
            .set(emptyFund.toFirestore());
      }
    } catch (e) {
      throw Exception('Gagal initialize general fund: $e');
    }
  }

  // ==================== PENDING SUBMISSIONS ====================

  /// Create pending submission
  Future<String> createPendingSubmission(PendingSubmission submission) async {
    try {
      final docRef = await _firestore
          .collection(FirestoreCollections.pendingSubmissions)
          .add(submission.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal create submission: $e');
    }
  }

  /// Update pending submission (untuk admin approval)
  Future<void> updatePendingSubmission(PendingSubmission submission) async {
    try {
      await _firestore
          .collection(FirestoreCollections.pendingSubmissions)
          .doc(submission.id)
          .update(submission.toFirestore());
    } catch (e) {
      throw Exception('Gagal update submission: $e');
    }
  }

  /// Delete pending submission
  Future<void> deletePendingSubmission(String submissionId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.pendingSubmissions)
          .doc(submissionId)
          .delete();
    } catch (e) {
      throw Exception('Gagal delete submission: $e');
    }
  }

  // ==================== SETTINGS ====================

  /// Get app settings
  Future<AppSettings> getAppSettings() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.settings)
          .doc('app_config')
          .get();

      return AppSettings.fromFirestore(doc);
    } catch (e) {
      throw Exception('Gagal get settings: $e');
    }
  }

  /// Update app settings
  Future<void> updateAppSettings(AppSettings settings) async {
    try {
      await _firestore
          .collection(FirestoreCollections.settings)
          .doc('app_config')
          .set(settings.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Gagal update settings: $e');
    }
  }

  /// Initialize default settings jika belum ada
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

      // Also initialize general fund
      await initializeGeneralFund();
    } catch (e) {
      throw Exception('Gagal initialize settings: $e');
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Approve pending submission dan create transaction
  Future<void> approvePendingSubmission({
    required String submissionId,
    required String targetId,
    required String targetMonth,
    required double amount,
    required String proofUrl,
    required String adminEmail,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Update submission status
      final submissionRef = _firestore
          .collection(FirestoreCollections.pendingSubmissions)
          .doc(submissionId);

      batch.update(submissionRef, {
        'status': 'approved',
        'reviewed_at': FieldValue.serverTimestamp(),
      });

      // 2. Create transaction
      final transactionRef =
          _firestore.collection(FirestoreCollections.transactions).doc();

      final transaction = TransactionModel(
        id: transactionRef.id,
        type: TransactionType.income,
        amount: amount,
        targetId: targetId,
        targetMonth: targetMonth,
        description: 'Donasi untuk $targetMonth',
        proofUrl: proofUrl,
        validated: true,
        validationStatus: 'approved',
        createdAt: DateTime.now(),
        inputAt: DateTime.now(),
        createdBy: adminEmail,
      );

      batch.set(transactionRef, transaction.toFirestore());

      // 3. Update target current amount
      final targetRef = _firestore
          .collection(FirestoreCollections.graduationTargets)
          .doc(targetId);

      batch.update(targetRef, {
        'current_amount': FieldValue.increment(amount),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal approve submission: $e');
    }
  }
}
