import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/graduation_target_model.dart';
import '../../models/graduate_model.dart';
import '../../services/target_service.dart';
import '../../utils/currency_formatter.dart';
import 'edit_target_modal.dart';

/// Modal untuk view detail target + CRUD actions
class TargetDetailModal extends StatelessWidget {
  final GraduationTarget target;
  final VoidCallback onUpdate;
  final VoidCallback? onDelete;

  const TargetDetailModal({
    super.key,
    required this.target,
    required this.onUpdate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = target.status == 'upcoming';
    final isActive = target.status == 'active' || target.status == 'closing_soon';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school,
                    color: _getStatusColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${TargetService.getMonthName(_getMonthNumber(target.month))} ${target.year}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // Target Info
            _buildInfoRow('Target Amount',
                'Rp ${CurrencyFormatter.formatNumber(target.targetAmount)}'),
            _buildInfoRow('Current Amount',
                'Rp ${CurrencyFormatter.formatNumber(target.currentAmount)}'),
            _buildInfoRow('Progress',
                '${((target.currentAmount / target.targetAmount) * 100).toStringAsFixed(1)}%'),
            _buildInfoRow(
                'Deadline', DateFormat('dd MMM yyyy').format(target.deadline)),
            _buildInfoRow(
                'Total Wisudawan', '${target.graduates.length} orang'),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Graduate List
            const Text(
              'Recipients List',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: target.graduates.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final grad = target.graduates[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFF3B82F6).withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        grad.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${DateFormat('dd MMM yyyy').format(grad.date)} • ${grad.location}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Close button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),

                const SizedBox(width: 12),

                // Edit button (for upcoming and active targets)
                if (isUpcoming || isActive) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) => EditTargetModal(
                            target: target,
                            onSuccess: onUpdate,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Delete button (only for upcoming)
                if (isUpcoming && onDelete != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDelete!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (target.status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'upcoming':
        return const Color(0xFF3B82F6);
      case 'closed':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusLabel() {
    switch (target.status) {
      case 'active':
        return 'AKTIF';
      case 'upcoming':
        return 'MENDATANG';
      case 'closed':
        return 'DITUTUP';
      default:
        return target.status.toUpperCase();
    }
  }

  int _getMonthNumber(String month) {
    // Capitalize first letter to handle lowercase month names from Firestore
    final capitalizedMonth =
        month[0].toUpperCase() + month.substring(1).toLowerCase();
    const monthMap = {
      'Januari': 1,
      'Februari': 2,
      'Maret': 3,
      'April': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
    };
    return monthMap[capitalizedMonth] ?? 1;
  }
}
