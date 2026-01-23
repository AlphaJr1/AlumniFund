import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../models/settings_model.dart';
import '../utils/constants.dart';

/// Card widget untuk menampilkan informasi payment methods dan button donasi
class PaymentInfoCard extends ConsumerStatefulWidget {
  const PaymentInfoCard({super.key});

  @override
  ConsumerState<PaymentInfoCard> createState() => _PaymentInfoCardState();
}

class _PaymentInfoCardState extends ConsumerState<PaymentInfoCard> {
  bool _showAllMethods = false; // State untuk show/hide payment methods

  @override
  Widget build(BuildContext context) {
    final paymentMethods = ref.watch(paymentMethodsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AppConstants.getCardPadding(screenWidth);

    return Center(
      child: Container(
        width: screenWidth * 0.9,
        constraints: const BoxConstraints(
          maxWidth: AppConstants.cardMaxWidthLarge,
        ),
        margin: const EdgeInsets.only(top: 16, bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryTeal,
              Color(0xFF00695C),
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryTeal.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(padding),
        child: paymentMethods.isEmpty
            ? _buildError()
            : _buildContent(context, paymentMethods),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<PaymentMethod> methods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Row(
          children: [
            Text(
              '💳',
              style: TextStyle(fontSize: 28),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donasi Sekarang',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Transfer ke salah satu rekening di bawah ini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Payment Methods - Show 1 random or all based on state
        ...(_showAllMethods
                ? methods
                : [methods[(methods.hashCode % methods.length).abs()]])
            .map((method) => _buildPaymentMethodRow(context, method)),

        // Show More / Show Less button
        if (methods.length > 1) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllMethods = !_showAllMethods;
                });
              },
              icon: Icon(
                _showAllMethods ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                _showAllMethods
                    ? 'Show less'
                    : 'Show ${methods.length - 1} more payment method${methods.length > 2 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Divider
        Container(
          height: 1,
          color: Colors.white24,
        ),

        const SizedBox(height: 20),

        // Upload Proof Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/submit');
            },
            icon: const Icon(Icons.upload_file, size: 20),
            label: const Text(
              'Upload Bukti Transfer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppConstants.primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusSmall),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Info text
        const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white70, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Setelah transfer, upload bukti transfer untuk verifikasi admin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodRow(BuildContext context, PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon/Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                _getPaymentLogo(method.provider),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to emoji if image fails
                  return Center(
                    child: Text(
                      _getPaymentIcon(method.provider),
                      style: const TextStyle(fontSize: 24),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.provider,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method.accountNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'a.n. ${method.accountName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Copy button
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: method.accountNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nomor ${method.provider} berhasil disalin!'),
                  backgroundColor: AppConstants.successGreen,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy, color: Colors.white),
            tooltip: 'Salin nomor rekening',
          ),
        ],
      ),
    );
  }

  String _getPaymentLogo(String provider) {
    switch (provider.toLowerCase()) {
      case 'bni':
        return 'assets/images/payment_logos/bni.png';
      case 'bca':
        return 'assets/images/payment_logos/bca.png';
      case 'ovo':
        return 'assets/images/payment_logos/ovo.png';
      case 'gopay':
        return 'assets/images/payment_logos/gopay.png';
      default:
        return 'assets/images/payment_logos/bni.png'; // Fallback
    }
  }

  String _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bni':
        return '🏦';
      case 'bca':
        return '🏦';
      case 'mandiri':
        return '🏦';
      case 'bri':
        return '🏦';
      case 'ovo':
        return '💰';
      case 'gopay':
        return '💳';
      case 'dana':
        return '💵';
      case 'shopeepay':
        return '🛒';
      default:
        return '💳';
    }
  }

  Widget _buildError() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: Colors.white, size: 48),
        SizedBox(height: 8),
        Text(
          'Gagal memuat informasi pembayaran',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
