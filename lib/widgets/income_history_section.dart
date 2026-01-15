import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';

/// Section untuk menampilkan riwayat pemasukkan
class IncomeHistorySection extends ConsumerWidget {
  const IncomeHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(recentIncomeProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.9,
      constraints: const BoxConstraints(
        maxWidth: AppConstants.cardMaxWidthLarge,
      ),
      margin: const EdgeInsets.only(top: 32, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '💚 RIWAYAT PEMASUKKAN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.gray900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Menampilkan 10 transaksi terbaru',
            style: TextStyle(
              fontSize: 13,
              color: AppConstants.gray400,
            ),
          ),
          const SizedBox(height: 16),
          
          // Transaction list
          incomeAsync.when(
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
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '↓ ${CurrencyFormatter.formatCurrency(transaction.amount)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.successGreen,
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
                                transaction.targetMonth != null 
                                    ? 'Target: ${transaction.targetMonth}'
                                    : 'Dompet Bersama',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Right section
                        Expanded(
                          flex: 3,
                          child: Text(
                            DateFormatter.formatDateTime(transaction.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.gray400,
                            ),
                            textAlign: TextAlign.right,
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
                // TODO: Navigate to all transactions page
              },
              child: const Text(
                'Lihat Semua',
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
          Text('📭', style: TextStyle(fontSize: 48)),
          SizedBox(height: 8),
          Text(
            'Belum ada pemasukkan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.gray700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Mulai donasi sekarang untuk mendukung teman wisuda!',
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
        'Gagal memuat riwayat pemasukkan',
        style: TextStyle(color: AppConstants.errorRed),
        textAlign: TextAlign.center,
      ),
    );
  }
}
