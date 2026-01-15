import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';

/// Section untuk menampilkan pengeluaran dompet
class ExpenseHistorySection extends ConsumerWidget {
  const ExpenseHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(recentExpenseProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.9,
      constraints: const BoxConstraints(
        maxWidth: AppConstants.cardMaxWidthLarge,
      ),
      margin: const EdgeInsets.only(top: 40, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '📤 PENGELUARAN DOMPET',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.gray900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Transparansi penggunaan dana',
            style: TextStyle(
              fontSize: 13,
              color: AppConstants.gray400,
            ),
          ),
          const SizedBox(height: 16),
          
          // Transaction list
          expenseAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return _buildEmptyState();
              }
              return Column(
                children: transactions.map((transaction) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppConstants.gray200),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left section
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '↑ ${CurrencyFormatter.formatCurrency(transaction.amount)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.errorRed,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transaction.relativeTime,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppConstants.gray500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${transaction.categoryIcon} ${transaction.description}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppConstants.gray700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Right section
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormatter.formatDateTime(transaction.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.gray400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () {
                                  // TODO: Show proof image modal
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  side: const BorderSide(color: AppConstants.gray300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  minimumSize: const Size(0, 28),
                                ),
                                child: const Text(
                                  '📷 Lihat Bukti',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppConstants.gray600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryTeal),
              ),
            ),
            error: (error, stack) => _buildError(),
          ),
          
          // Footer button
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Navigate to all expenses page
              },
              child: const Text(
                'Lihat Semua Pengeluaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.primaryTeal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppConstants.gray50,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: const Column(
        children: [
          Text('💰', style: TextStyle(fontSize: 48)),
          SizedBox(height: 8),
          Text(
            'Belum ada pengeluaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.gray700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Dana tersimpan aman di dompet bersama',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.errorBg,
        border: Border.all(color: AppConstants.errorBorder),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: const Text(
        'Gagal memuat riwayat pengeluaran',
        style: TextStyle(color: AppConstants.errorRed),
        textAlign: TextAlign.center,
      ),
    );
  }
}
