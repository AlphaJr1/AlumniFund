import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/graduation_target_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';

/// Card widget untuk upcoming target
class UpcomingTargetCard extends ConsumerWidget {
  const UpcomingTargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingTargets = ref.watch(upcomingTargetsProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    // Get first upcoming target
    if (upcomingTargets.isEmpty) return const SizedBox.shrink();
    final target = upcomingTargets.first;

    return Center(
      child: Container(
        width: screenWidth * 0.9,
        constraints: const BoxConstraints(
          maxWidth: AppConstants.cardMaxWidthLarge,
        ),
        margin: const EdgeInsets.only(top: 16, bottom: 16),
        decoration: BoxDecoration(
          color: AppConstants.gray50,
          border: Border.all(
            color: AppConstants.gray300,
            style: BorderStyle.solid,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            const Text(
              '🔒 TARGET MENDATANG',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.gray500,
              ),
            ),
            const SizedBox(height: 8),

            // Month info
            Text(
              '📅 ${target.monthYearDisplay.toUpperCase()} • ${target.graduates.length} Wisudawan',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.gray700,
              ),
            ),
            const SizedBox(height: 8),

            // Open timing info
            const Text(
              '🔓 Akan dibuka: Setelah deadline target aktif ditutup',
              style: TextStyle(
                fontSize: 13,
                color: AppConstants.gray500,
              ),
            ),
            const SizedBox(height: 8),

            // Target amount
            Text(
              'Target: ${CurrencyFormatter.formatCurrency(target.targetAmount)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppConstants.primaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
