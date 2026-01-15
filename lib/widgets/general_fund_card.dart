import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/general_fund_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';

/// Card widget untuk menampilkan saldo Dompet Bersama
class GeneralFundCard extends ConsumerWidget {
  const GeneralFundCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generalFundAsync = ref.watch(generalFundProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AppConstants.getCardPadding(screenWidth);

    return Center(
      child: Container(
        width: screenWidth * 0.9,
        constraints: const BoxConstraints(
          maxWidth: AppConstants.cardMaxWidthSmall,
        ),
        margin: const EdgeInsets.only(top: 20, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(padding),
        child: generalFundAsync.when(
          data: (fund) => _buildContent(fund.balance),
          loading: () => _buildLoading(),
          error: (error, stack) => _buildError(),
        ),
      ),
    );
  }

  Widget _buildContent(double balance) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        const Text(
          '💰 Saldo Dompet Bersama',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.gray500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Amount
        Text(
          CurrencyFormatter.formatCurrency(balance),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppConstants.primaryTeal,
          ),
        ),
        const SizedBox(height: 8),
        
        // Description
        const Text(
          'Dana tidak teralokasi • Tersedia untuk kebutuhan komunitas',
          style: TextStyle(
            fontSize: 13,
            color: AppConstants.gray400,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Info box (conditional)
        if (balance > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.infoBg,
              border: Border.all(color: AppConstants.infoBorder),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Row(
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dana ini akan otomatis masuk ke target wisuda berikutnya yang aktif',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoading() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '💰 Saldo Dompet Bersama',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.gray500,
          ),
        ),
        SizedBox(height: 16),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryTeal),
        ),
      ],
    );
  }

  Widget _buildError() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: AppConstants.errorRed, size: 48),
        SizedBox(height: 8),
        Text(
          'Gagal memuat data dompet bersama',
          style: TextStyle(color: AppConstants.errorRed),
        ),
      ],
    );
  }
}
