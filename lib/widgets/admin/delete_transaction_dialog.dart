import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/constants.dart';

/// Delete Transaction Confirmation Dialog
class DeleteTransactionDialog extends StatelessWidget {
  final TransactionModel transaction;

  const DeleteTransactionDialog({
    super.key,
    required this.transaction,
  });

  static Future<bool?> show(
    BuildContext context,
    TransactionModel transaction,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteTransactionDialog(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final typeLabel = isIncome ? 'Income' : 'Expense';
    final typeColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppConstants.errorRed),
          SizedBox(width: 12),
          Text('Delete Transaction'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to delete this transaction?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          // Transaction details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', typeLabel, typeColor),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Amount',
                  CurrencyFormatter.formatCurrency(transaction.amount),
                  typeColor,
                ),
                if (transaction.targetMonth != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Target',
                    transaction.targetMonth!,
                    const Color(0xFF6B7280),
                  ),
                ],
                if (transaction.category != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Category',
                    transaction.category!,
                    const Color(0xFF6B7280),
                  ),
                ],
                if (transaction.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Description',
                    transaction.description,
                    const Color(0xFF6B7280),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action will:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.errorRed,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Remove transaction record',
                  style: TextStyle(fontSize: 14, color: AppConstants.errorRed),
                ),
                Text(
                  '• Revert balance changes',
                  style: TextStyle(fontSize: 14, color: AppConstants.errorRed),
                ),
                SizedBox(height: 8),
                Text(
                  '⚠️ This action CANNOT be undone!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.errorRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Yes, Delete'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
