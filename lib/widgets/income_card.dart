import 'dart:ui';
import 'package:flutter/material.dart';
import'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/admin/pending_submissions_provider.dart';
import '../models/pending_submission_model.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';
import 'hint_provider.dart';

/// Income summary card dengan tap untuk detail modal
class IncomeCard extends ConsumerStatefulWidget {
  const IncomeCard({super.key});

  @override
  ConsumerState<IncomeCard> createState() => _IncomeCardState();
}

class _IncomeCardState extends ConsumerState<IncomeCard> {

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(recentIncomeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 1024;

    return Center(
      child: GestureDetector(
        onTap: () {
          // Open detail modal
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => _IncomeDetailModal(),
          );
        },
        onDoubleTap: () {
          // Consume double-tap to prevent theme change
        },
        child: Stack(
          children: [
            Container(
              width: screenWidth * 0.9,
              height: isMobile ? screenHeight * 0.65 : screenHeight * 0.75,
              constraints: const BoxConstraints(
                maxWidth: 600,
                maxHeight: 700,
              ),
              margin: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                // boxShadow removed for testing
              ),
              child: incomeAsync.when(
                data: (transactions) => _buildContent(transactions),
                loading: () => _buildLoading(),
                error: (error, stack) => _buildError(),
              ),
            ),
            // Pending badge removed - duplicate of badge inside card
            // _buildPendingBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<TransactionModel> transactions) {
    final totalIncome = transactions.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
    final count = transactions.length;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '💚',
              style: TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 20),
            Text(
              'RECENT PROPS',
              style: TextStyle(
                fontSize: isMobile ? 17 : 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            
            // Total Income
            Text(
              'Total Props:',
              style: TextStyle(
                fontSize: isMobile ? 15 : 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.formatCurrency(totalIncome),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10B981),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Pending badge (if any)
            _buildPendingBadge(),
            if (ref.watch(pendingSubmissionsCountProvider) > 0)
              const SizedBox(height: 12),
            
            // Transaction Count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Text(
                'Total: $count transactions',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
          SizedBox(height: 16),
          Text(
            'Failed to load income data',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // Pending badge indicator - positioned above transaction count
  Widget _buildPendingBadge() {
    final pendingCount = ref.watch(pendingSubmissionsCountProvider);
    
    if (pendingCount == 0) return const SizedBox.shrink();
    
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () {
        // Show pending modal
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => _PendingSubmissionsModal(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty,
              color: primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '$pendingCount pending',
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail modal untuk menampilkan semua income transactions
class _IncomeDetailModal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(recentIncomeProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '💚',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Income Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Scrollable list
              Expanded(
                child: incomeAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Text(
                          'No income yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _buildTransactionItem(transaction);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                  error: (error, stack) => const Center(
                    child: Text(
                      'Gagal memuat data',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'en_US');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.arrow_downward,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  CurrencyFormatter.formatCurrency(transaction.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateFormat.format(transaction.createdAt),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          if (transaction.metadata?.submitterName != null) ...[
            const SizedBox(height: 4),
            Text(
              'By: ${transaction.metadata!.submitterName}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          if (transaction.targetId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Target: ${transaction.targetId}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          if (transaction.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              transaction.description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modal untuk menampilkan pending submissions yang belum divalidasi
class _PendingSubmissionsModal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingSubmissionsProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '⏳',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Pending Submissions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                color: primaryColor.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Waiting for admin verification (up to 24 hours)',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scrollable list
              Expanded(
                child: pendingAsync.when(
                  data: (submissions) {
                    if (submissions.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF10B981),
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No pending submissions',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: submissions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final submission = submissions[index];
                        return _buildSubmissionItem(submission);
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  error: (error, stack) => const Center(
                    child: Text(
                      'Failed to load pending submissions',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionItem(PendingSubmission submission) {
    final dateFormat = DateFormat('dd MMM, h:mm a', 'en_US');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Hourglass icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.hourglass_empty,
              color: Color(0xFF6B7280),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Date and Username/ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Date (with username if available)
                Text(
                  submission.submitterName?.isNotEmpty == true
                      ? '${dateFormat.format(submission.submittedAt)} by ${submission.submitterName}'
                      : dateFormat.format(submission.submittedAt),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                // Line 2: ID (always shown)
                Text(
                  'ID: ${submission.id.substring(0, 12)}...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
