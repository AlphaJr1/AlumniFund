import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../utils/firestore_collections.dart';

/// Provider untuk admin action methods (approve/reject income, etc.)
final adminActionsProvider = Provider((ref) => AdminActionsService());

class AdminActionsService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Approve income submission - batch operation
  /// Creates transaction, updates general fund, deletes submission, and auto-allocates to active target
  Future<void> approveIncome({
    required String submissionId,
    required double amount,
    required DateTime transferDate,
    String? description,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get batch instance for atomic operation
    final batch = _firestore.batch();

    try {
      // 0. Fetch submission document to get proof_url and submitter_name
      final submissionDoc = await _firestore
          .collection(FirestoreCollections.pendingSubmissions)
          .doc(submissionId)
          .get();

      final submissionData = submissionDoc.data();
      final proofUrl = submissionData?['proof_url'] as String?;
      final submitterName = submissionData?['submitter_name'] as String?;

      // 1. Create transaction document (always goes to general fund)
      final transactionRef =
          _firestore.collection(FirestoreCollections.transactions).doc();

      batch.set(transactionRef, {
        'type': 'income',
        'amount': amount,
        'target_id': 'general_fund', // Always general fund
        'target_month': null,
        'description': description ?? 'Income from validated submission',
        'proof_url': proofUrl, // Copy proof_url from submission document
        'validated': true,
        'validation_status': 'approved',
        'created_at': Timestamp.fromDate(transferDate),
        'input_at': FieldValue.serverTimestamp(),
        'created_by': currentUser.email,
        'metadata': {
          'submitted_by': null,
          'submission_method': 'web',
          'ip_address': null,
          'submitter_name': submitterName,
        },
      });

      // 2. Update general fund
      final fundRef = _firestore
          .collection(FirestoreCollections.generalFund)
          .doc('current');

      batch.update(fundRef, {
        'balance': FieldValue.increment(amount),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 3. Delete submission document
      final submissionRef = _firestore
          .collection(FirestoreCollections.pendingSubmissions)
          .doc(submissionId);

      batch.delete(submissionRef);

      // 4. Commit batch (atomic operation)
      await batch.commit();

      // 5. Trigger auto-allocation to active target
      await autoAllocateToTarget();
    } catch (e) {
      // Rollback happens automatically if batch.commit() fails
      rethrow;
    }
  }

  /// Reject income submission
  /// Updates submission status to "rejected"
  Future<void> rejectIncome({
    required String submissionId,
    String? rejectionReason,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection(FirestoreCollections.pendingSubmissions)
          .doc(submissionId)
          .update({
        'status': 'rejected',
        'rejection_reason': rejectionReason,
        'rejected_at': FieldValue.serverTimestamp(),
        'rejected_by': currentUser.email,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Edit transaction (within 24h only)
  /// Updates transaction and reconciles balance if amount changed
  Future<void> editTransaction({
    required TransactionModel original,
    required TransactionModel updated,
  }) async {
    final batch = _firestore.batch();

    try {
      final amountChanged = original.amount != updated.amount;
      final targetId = original.targetId;
      final isIncome = original.isIncome;

      // 1. If amount changed, revert old amount and apply new amount
      if (amountChanged) {
        if (isIncome) {
          // Income: affect target or general fund
          if (targetId == 'general_fund' || targetId == null) {
            final fundRef = _firestore
                .collection(FirestoreCollections.generalFund)
                .doc('current');

            // Revert old amount, add new amount
            final netChange = updated.amount - original.amount;
            batch.update(fundRef, {
              'balance': FieldValue.increment(netChange),
              'updated_at': FieldValue.serverTimestamp(),
            });
          } else {
            // Update graduation target
            final targetRef = _firestore
                .collection(FirestoreCollections.graduationTargets)
                .doc(targetId);

            // Revert old amount, add new amount
            final netChange = updated.amount - original.amount;
            batch.update(targetRef, {
              'current_amount': FieldValue.increment(netChange),
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // Expense: revert old deduction, apply new deduction from general fund
          final fundRef = _firestore
              .collection(FirestoreCollections.generalFund)
              .doc('current');

          // Revert old: add back old amount
          // Apply new: subtract new amount
          // Net: add old, subtract new = old - new
          final netChange = original.amount - updated.amount;
          batch.update(fundRef, {
            'balance': FieldValue.increment(netChange),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }

      // 2. Update transaction document
      final transactionRef = _firestore
          .collection(FirestoreCollections.transactions)
          .doc(original.id);

      batch.update(transactionRef, updated.toFirestore());

      // 3. Commit batch
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete transaction (within 24h only)
  /// Reverts fund/target amount and deletes transaction
  Future<void> deleteTransaction({
    required String transactionId,
    required String type, // "income" or "expense"
    required double amount,
    required String? targetId,
  }) async {
    final batch = _firestore.batch();

    try {
      // 1. Revert fund/target amount
      if (type == 'income') {
        if (targetId == 'general_fund' || targetId == null) {
          final fundRef = _firestore
              .collection(FirestoreCollections.generalFund)
              .doc('current');

          batch.update(fundRef, {
            'balance': FieldValue.increment(-amount),
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          final targetRef = _firestore
              .collection(FirestoreCollections.graduationTargets)
              .doc(targetId);

          batch.update(targetRef, {
            'current_amount': FieldValue.increment(-amount),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Expense: add back to general fund
        final fundRef = _firestore
            .collection(FirestoreCollections.generalFund)
            .doc('current');

        batch.update(fundRef, {
          'balance': FieldValue.increment(amount),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // 2. Delete transaction
      final transactionRef = _firestore
          .collection(FirestoreCollections.transactions)
          .doc(transactionId);

      batch.delete(transactionRef);

      // 3. Commit batch
      await batch.commit();

      // 4. Recalculate allocation (if income was deleted, allocation should decrease)
      await autoAllocateToTarget();
    } catch (e) {
      rethrow;
    }
  }

  /// Auto-allocate from general fund to active target (virtual allocation)
  /// This does NOT deduct from general fund, only updates allocated_from_fund
  /// Recalculates allocation from scratch based on current balances
  Future<void> autoAllocateToTarget() async {
    try {
      // 1. Get active target
      final activeTargetSnapshot = await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .where('status', whereIn: ['active', 'closing_soon'])
          .limit(1)
          .get();

      if (activeTargetSnapshot.docs.isEmpty) {
        return; // No active target, keep in general fund
      }

      final activeTargetDoc = activeTargetSnapshot.docs.first;
      final targetData = activeTargetDoc.data();
      final currentAmount =
          (targetData['current_amount'] as num?)?.toDouble() ?? 0.0;
      final requiredBudget =
          (targetData['target_amount'] as num?)?.toDouble() ?? 0.0;

      // 2. Get general fund
      final fundDoc = await _firestore
          .collection(FirestoreCollections.generalFund)
          .doc('current')
          .get();

      final fundBalance =
          (fundDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      // 3. Calculate NEW allocation (recalculate from scratch)
      // stillNeeded = target - current (IGNORE old allocated_from_fund)
      final stillNeeded = requiredBudget - currentAmount;
      
      // Allocate min(fundBalance, stillNeeded)
      final newAllocation =
          fundBalance < stillNeeded ? fundBalance : stillNeeded;
      final clampedAllocation = newAllocation > 0 ? newAllocation : 0.0;

      print('🔄 Auto-allocation:');
      print('   Target: $requiredBudget, Current: $currentAmount');
      print('   Still needed: $stillNeeded');
      print('   Fund balance: $fundBalance');
      print('   New allocation: $clampedAllocation');

      // 4. Update allocated_from_fund with NEW value (not increment!)
      await activeTargetDoc.reference.update({
        'allocated_from_fund': clampedAllocation, // Set to new value
        'updated_at': FieldValue.serverTimestamp(),
      });

      // NOTE: General fund balance is NOT changed here!
      // It's only a virtual allocation/reservation
    } catch (e) {
      // Log error but don't throw - allocation is not critical
      print('Auto-allocation error: $e');
    }
  }

  /// Force recalculate allocation for active target
  /// Public method that can be called from UI
  Future<Map<String, dynamic>> forceRecalculateAllocation() async {
    try {
      await autoAllocateToTarget();
      
      // Get updated target info
      final activeTargetSnapshot = await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .where('status', whereIn: ['active', 'closing_soon'])
          .limit(1)
          .get();

      if (activeTargetSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No active target found',
        };
      }

      final targetData = activeTargetSnapshot.docs.first.data();
      final allocated = (targetData['allocated_from_fund'] as num?)?.toDouble() ?? 0.0;
      final current = (targetData['current_amount'] as num?)?.toDouble() ?? 0.0;
      
      return {
        'success': true,
        'message': 'Allocation recalculated successfully',
        'allocated': allocated,
        'current': current,
        'total': allocated + current,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Close graduation target and finalize allocation
  /// This ACTUALLY deducts allocated_from_fund from general fund
  Future<void> closeTarget(String targetId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final batch = _firestore.batch();

    try {
      // 1. Get target
      final targetDoc = await _firestore
          .collection(FirestoreCollections.graduationTargets)
          .doc(targetId)
          .get();

      if (!targetDoc.exists) {
        throw Exception('Target not found');
      }

      final targetData = targetDoc.data()!;
      final allocatedFromFund =
          (targetData['allocated_from_fund'] as num?)?.toDouble() ?? 0.0;
      final currentAmount =
          (targetData['current_amount'] as num?)?.toDouble() ?? 0.0;
      final month = targetData['month'] as String? ?? 'Unknown';
      final year = (targetData['year'] as num?)?.toInt() ?? 0;

      // Get graduate names
      final graduates = (targetData['graduates'] as List<dynamic>?)
              ?.map((g) => (g as Map<String, dynamic>)['name'] as String?)
              .where((name) => name != null)
              .cast<String>()
              .toList() ??
          [];

      // Capitalize first letter of month
      final monthCapitalized = month.isNotEmpty
          ? month[0].toUpperCase() + month.substring(1)
          : month;

      // Create description with recipient names
      String description =
          'Allocation to graduation target: $monthCapitalized $year';
      if (graduates.isNotEmpty) {
        final recipientNames = graduates.join(', ');
        description += ' - Recipients: $recipientNames';
      }

      // 2. Create EXPENSE transaction for the allocation (CRITICAL FIX!)
      if (allocatedFromFund > 0) {
        final expenseRef =
            _firestore.collection(FirestoreCollections.transactions).doc();

        batch.set(expenseRef, {
          'type': 'expense',
          'amount': allocatedFromFund,
          'target_id': targetId,
          'target_month': month,
          'description': description,
          'proof_url': null,
          'validated': true,
          'validation_status': 'approved',
          'created_at': FieldValue.serverTimestamp(),
          'input_at': FieldValue.serverTimestamp(),
          'created_by': currentUser.email,
        });
      }

      // 3. Deduct allocated amount from general fund (NOW - actual deduction)
      if (allocatedFromFund > 0) {
        final fundRef = _firestore
            .collection(FirestoreCollections.generalFund)
            .doc('current');

        batch.update(fundRef, {
          'balance': FieldValue.increment(-allocatedFromFund),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // 4. Finalize target amount and close
      batch.update(targetDoc.reference, {
        'current_amount': currentAmount + allocatedFromFund, // Finalize total
        'allocated_from_fund': 0, // Reset to 0
        'status': 'closed',
        'closed_date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 5. Commit batch
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
