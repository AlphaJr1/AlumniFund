import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../transaction_provider.dart';
import '../graduation_target_provider.dart';

/// Provider untuk monthly change in general fund
final monthlyFundChangeProvider = Provider<double>((ref) {
  final transactions = ref.watch(recentMixedTransactionsProvider);
  
  return transactions.when(
    data: (list) {
      final now = DateTime.now();
      final thisMonth = list.where((t) => 
        t.createdAt.month == now.month &&
        t.createdAt.year == now.year
      );
      
      final income = thisMonth
          .where((t) => t.type == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final expense = thisMonth
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);
      
      return income - expense;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider untuk days until deadline (from active target)
final daysUntilDeadlineProvider = Provider<int?>((ref) {
  final target = ref.watch(activeTargetProvider);
  
  if (target == null) return null;
  
  final now = DateTime.now();
  final deadline = target.deadline;
  return deadline.difference(now).inDays;
});

/// Provider untuk deadline color based on days remaining
final deadlineColorProvider = Provider<Color>((ref) {
  final days = ref.watch(daysUntilDeadlineProvider);
  
  if (days == null) return const Color(0xFF6B7280); // Gray
  if (days < 3) return const Color(0xFFEF4444); // Red
  if (days < 7) return const Color(0xFFF59E0B); // Orange
  return const Color(0xFF10B981); // Green
});
