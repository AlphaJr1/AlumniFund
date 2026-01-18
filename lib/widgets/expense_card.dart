import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';
import 'hint_provider.dart';

/// Expense summary card dengan tap untuk detail modal
class ExpenseCard extends ConsumerStatefulWidget {
  final VoidCallback? onModalOpen; // Callback saat modal open
  final VoidCallback? onModalClose; // Callback saat modal close
  
  const ExpenseCard({
    super.key,
    this.onModalOpen,
    this.onModalClose,
  });

  @override
  ConsumerState<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends ConsumerState<ExpenseCard> {

  @override
  Widget build(BuildContext context) {
    final expenseAsync = ref.watch(recentExpenseProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 1024;

    return Center(
      child: GestureDetector(
        onTap: () {
          // Notify onboarding
          widget.onModalOpen?.call();
          // debugPrint('[ExpenseCard] Card tapped - opening modal');
          
          // Open detail modal
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => _ExpenseDetailModal(),
          ).then((_) {
            // Modal closed
            widget.onModalClose?.call();
            // debugPrint('[ExpenseCard] Modal closed');
          });
        },
        onDoubleTap: () {
          // Consume double-tap to prevent theme change
        },
        child: Container(
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
          child: expenseAsync.when(
            data: (transactions) => _buildContent(transactions),
            loading: () => _buildLoading(),
            error: (error, stack) => _buildError(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<TransactionModel> transactions) {
    final totalExpense = transactions.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
    final count = transactions.length;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          
          const Text(
            '💸',
            style: TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 8),
          Text(
            'EXPENSES',
            style: TextStyle(
              fontSize: isMobile ? 17 : 19,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          
          // Total Expense
          Text(
            'Total Spent:',
            style: TextStyle(
              fontSize: isMobile ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCurrency(totalExpense),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEF4444),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Transaction Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Text(
              'Total: $count transactions',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
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
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
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
            'Gagal memuat data pengeluaran',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail modal untuk menampilkan semua expense transactions
class _ExpenseDetailModal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(recentExpenseProvider);

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
                  color: Color(0xFFEF4444),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '💸',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Expense Details',
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
                child: expenseAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Text(
                          'No expenses yet',
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
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
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  CurrencyFormatter.formatCurrency(transaction.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444),
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
          if (transaction.category != null && transaction.category!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Kategori: ${transaction.category}',
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
