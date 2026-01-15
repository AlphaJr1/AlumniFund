import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';
import 'proof_image_modal.dart';

/// Reusable transaction table widget untuk admin dashboard
class TransactionTable extends StatelessWidget {
  final List<TransactionModel> transactions;
  final void Function(TransactionModel)? onEdit;
  final void Function(TransactionModel)? onDelete;

  const TransactionTable({
    super.key,
    required this.transactions,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return _buildMobileList(context);
    } else {
      return _buildDesktopTable(context);
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Transaksi akan muncul di sini setelah Anda menambahkannya',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
          columns: const [
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Target/Category', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: transactions.map((transaction) {
            final isIncome = transaction.isIncome; // Use getter from model (fixes enum vs string bug)
            final canEdit = _canEdit(transaction);

            return DataRow(
              cells: [
                // Type
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isIncome ? 'Income' : 'Expense',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),

                // Amount
                DataCell(
                  Text(
                    CurrencyFormatter.formatCurrency(transaction.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),

                // Target/Category
                DataCell(
                  Text(
                    transaction.targetMonth ?? transaction.category ?? '-',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                // Description
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      transaction.description ?? '-',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Timestamp
                DataCell(
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(transaction.createdAt),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ),

                // Actions
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View Proof
                      if (transaction.proofUrl != null)
                        IconButton(
                          icon: const Icon(Icons.image_outlined, size: 18),
                          onPressed: () => ProofImageModal.show(
                            context,
                            imageUrl: transaction.proofUrl!,
                            title: 'Proof ${isIncome ? "Income" : "Expense"}',
                          ),
                          tooltip: 'View Proof',
                          color: const Color(0xFF3B82F6),
                        ),

                      // Edit (only within 24h)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: canEdit ? () => onEdit?.call(transaction) : null,
                        tooltip: canEdit ? 'Edit' : 'Tidak bisa edit (>24 jam)',
                        color: canEdit ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                      ),

                      // Delete (only within 24h)
                      IconButton(
                        icon: const Icon(Icons.delete_outlined, size: 18),
                        onPressed: canEdit ? () => onDelete?.call(transaction) : null,
                        tooltip: canEdit ? 'Delete' : 'Cannot delete (>24h)',
                        color: canEdit ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context) {
    return Column(
      children: transactions.map((transaction) {
        final isIncome = transaction.isIncome; // Use getter from model (fixes enum vs string bug)
        final canEdit = _canEdit(transaction);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type + Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isIncome ? 'Income' : 'Expense',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCurrency(transaction.amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Target/Category
              if (transaction.targetMonth != null || transaction.category != null)
                Text(
                  transaction.targetMonth ?? transaction.category ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),

              // Description
              if (transaction.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  transaction.description!,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 8),

              // Timestamp
              Text(
                DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(transaction.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  // View Proof
                  if (transaction.proofUrl != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ProofImageModal.show(
                          context,
                          imageUrl: transaction.proofUrl!,
                          title: 'Proof ${isIncome ? "Income" : "Expense"}',
                        ),
                        icon: const Icon(Icons.image_outlined, size: 16),
                        label: const Text('View Proof'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                        ),
                      ),
                    ),

                  if (transaction.proofUrl != null) const SizedBox(width: 8),

                  // Edit
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canEdit ? () => onEdit?.call(transaction) : null,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: canEdit ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                        side: BorderSide(
                          color: canEdit ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Delete
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canEdit ? () => onDelete?.call(transaction) : null,
                      icon: const Icon(Icons.delete_outlined, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: canEdit ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                        side: BorderSide(
                          color: canEdit ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Check if transaction can be edited (within 24h)
  bool _canEdit(TransactionModel transaction) {
    final now = DateTime.now();
    final diff = now.difference(transaction.createdAt);
    return diff.inHours < 24;
  }
}
