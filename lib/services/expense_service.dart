import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service untuk handle expense operations
class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Create expense transaction with batch write
  Future<void> createExpense({
    required double amount,
    required String category,
    required String description,
    required DateTime transactionDate,
    required String proofUrl,
    required String createdBy,
  }) async {
    try {
      // 1. Get current balance
      final fundDoc =
          await _firestore.collection('general_fund').doc('current').get();

      final currentBalance = (fundDoc.data()?['balance'] ?? 0.0).toDouble();

      // 2. Validate balance
      if (amount > currentBalance) {
        throw Exception(
            'Saldo tidak cukup (tersedia: Rp ${currentBalance.toStringAsFixed(0)})');
      }

      // 3. Use batch write for atomic operation
      final batch = _firestore.batch();

      // 4. Create transaction document
      final transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'type': 'expense',
        'amount': amount,
        'category': category,
        'description': description,
        'proof_url': proofUrl,
        'validated': true,
        'created_at': Timestamp.fromDate(transactionDate),
        'input_at': FieldValue.serverTimestamp(),
        'created_by': createdBy,
      });

      // 5. Update general fund (decrement balance)
      final fundRef = _firestore.collection('general_fund').doc('current');
      batch.update(fundRef, {
        'balance': FieldValue.increment(-amount),
      });

      // 6. Commit batch
      await batch.commit();
    } catch (e) {
      throw Exception('Gagal membuat pengeluaran: ${e.toString()}');
    }
  }

  /// Get category display name
  static String getCategoryName(String category) {
    switch (category) {
      case 'wisuda':
        return 'Wisuda';
      case 'community':
        return 'Kegiatan Komunitas';
      case 'operational':
        return 'Operasional';
      case 'others':
        return 'Lainnya';
      default:
        return category;
    }
  }

  /// Get category icon
  static String getCategoryIcon(String category) {
    switch (category) {
      case 'wisuda':
        return '🎓';
      case 'community':
        return '👥';
      case 'operational':
        return '⚙️';
      case 'others':
        return '📦';
      default:
        return '💰';
    }
  }
}
