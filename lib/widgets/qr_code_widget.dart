import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/settings_model.dart';
import '../theme/app_theme.dart';

/// QR Code widget dengan payment information
class QRCodeWidget extends StatelessWidget {
  final PaymentMethod paymentInfo;
  
  const QRCodeWidget({
    super.key,
    required this.paymentInfo,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Informasi Transfer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Payment info
            _buildInfoRow(
              context,
              icon: Icons.account_balance,
              label: paymentInfo.isBank ? 'Bank' : 'E-Wallet',
              value: paymentInfo.provider,
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            _buildInfoRow(
              context,
              icon: Icons.credit_card,
              label: 'No. Rekening',
              value: paymentInfo.accountNumber,
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            _buildInfoRow(
              context,
              icon: Icons.person,
              label: 'Atas Nama',
              value: paymentInfo.accountName,
            ),
            
            // QR Code (jika ada)
            if (paymentInfo.qrCodeUrl != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              const Divider(),
              const SizedBox(height: AppTheme.spacingM),
              
              Center(
                child: Column(
                  children: [
                    Text(
                      'Scan QR Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // QR Code image dari URL
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Image.network(
                        paymentInfo.qrCodeUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback: generate QR code dari account number
                          return QrImageView(
                            data: paymentInfo.accountNumber,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Generate QR code dari account number jika tidak ada URL
              const SizedBox(height: AppTheme.spacingL),
              const Divider(),
              const SizedBox(height: AppTheme.spacingM),
              
              Center(
                child: Column(
                  children: [
                    Text(
                      'Scan QR Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: QrImageView(
                        data: paymentInfo.accountNumber,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build info row
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
