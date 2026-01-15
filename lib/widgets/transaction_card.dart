import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';
import 'image_viewer.dart';

/// Card widget untuk menampilkan transaksi (updated design)
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool showProofButton;
  
  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.showProofButton = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppConstants.gray200),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left section
            Expanded(
              flex: isIncome ? 7 : 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  Text(
                    '${isIncome ? "↓" : "↑"} ${CurrencyFormatter.formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isIncome 
                          ? AppConstants.successGreen 
                          : AppConstants.errorRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Relative time
                  Text(
                    transaction.relativeTime,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.gray500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Target month or category
                  if (isIncome)
                    Text(
                      transaction.targetMonth != null 
                          ? 'Target: ${transaction.targetMonth}'
                          : 'Dompet Bersama',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.primaryTeal,
                      ),
                    )
                  else
                    Text(
                      '${transaction.categoryIcon} ${transaction.description}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.gray700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            // Right section
            Expanded(
              flex: isIncome ? 3 : 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Timestamp
                  Text(
                    DateFormatter.formatDateTime(transaction.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.gray400,
                    ),
                  ),
                  
                  // Proof button for expense
                  if (!isIncome && showProofButton && transaction.proofUrl != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ImageViewer(
                              imageUrl: transaction.proofUrl!,
                              title: 'Bukti Pengeluaran',
                            ),
                          ),
                        );
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
                  
                  // Proof thumbnail for income
                  if (isIncome && transaction.proofUrl != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ImageViewer(
                              imageUrl: transaction.proofUrl!,
                              title: 'Bukti Transfer',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppConstants.primaryTeal.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: CachedNetworkImage(
                            imageUrl: transaction.proofUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppConstants.gray100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppConstants.primaryTeal,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppConstants.gray100,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 20,
                                color: AppConstants.gray400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
