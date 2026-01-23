import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

/// Provider untuk recent income transactions (limit 10)
final recentIncomeProvider = StreamProvider<List<TransactionModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.transactions)
      .where('type', isEqualTo: 'income')
      .orderBy('created_at', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList());
});

/// Provider untuk recent expense transactions (limit 10)
/// Note: Removed orderBy to avoid composite index requirement
final recentExpenseProvider = StreamProvider<List<TransactionModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.transactions)
      .where('type', isEqualTo: 'expense')
      .limit(20) // Get more, then sort in memory
      .snapshots()
      .map((snapshot) {
    final expenses = snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();

    // Sort by created_at in memory
    expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Return top 10
    return expenses.take(10).toList();
  });
});

/// Provider untuk recent mixed transactions (income + expense, limit 20)
final recentMixedTransactionsProvider =
    StreamProvider<List<TransactionModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.transactions)
      .orderBy('created_at', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList());
});

/// Provider untuk transactions by target ID
final transactionsByTargetProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, targetId) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.transactions)
      .where('target_id', isEqualTo: targetId)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList());
});

/// Provider untuk income by target ID
final incomeByTargetProvider =
    Provider.family<List<TransactionModel>, String>((ref, targetId) {
  final transactionsAsync = ref.watch(transactionsByTargetProvider(targetId));

  return transactionsAsync.when(
    data: (transactions) => transactions.where((t) => t.isIncome).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider untuk total income by target ID
final totalIncomeByTargetProvider =
    Provider.family<double, String>((ref, targetId) {
  final income = ref.watch(incomeByTargetProvider(targetId));
  return income.fold(0.0, (sum, t) => sum + t.amount);
});
