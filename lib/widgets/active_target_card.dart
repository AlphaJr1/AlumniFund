import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/graduation_target_model.dart';
import '../providers/graduation_target_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';
import 'achievement_badge.dart';
import 'donation_modal.dart';
import 'distribution_detail_modal.dart';

/// Card widget untuk active graduation target (PRIMARY FOCUS)
class ActiveTargetCard extends ConsumerStatefulWidget {
  const ActiveTargetCard({super.key});

  @override
  ConsumerState<ActiveTargetCard> createState() => _ActiveTargetCardState();
}

class _ActiveTargetCardState extends ConsumerState<ActiveTargetCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final activeTarget = ref.watch(activeTargetProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AppConstants.getCardPadding(screenWidth);

    if (activeTarget == null) {
      return _buildNoActiveTarget(screenWidth);
    }
    return _buildActiveTarget(activeTarget, screenWidth, padding);
  }

  Widget _buildActiveTarget(GraduationTarget target, double screenWidth, double padding) {
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;
    
    return Center(
      child: InkWell(
        onTap: () {
          // Show distribution detail modal
          DistributionDetailModal.show(context, target);
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Container(
          width: screenWidth * 0.9,
          constraints: const BoxConstraints(
            maxWidth: AppConstants.cardMaxWidthLarge,
          ),
          margin: const EdgeInsets.only(top: 24, bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: AppConstants.primaryTeal,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan status badge
              _buildHeader(target),
              const SizedBox(height: 16),
              
              // Target info
              _buildTargetInfo(target),
              const SizedBox(height: 12),
              
              // Deadline info
              _buildDeadlineInfo(target),
              const SizedBox(height: 20),
              
              // Progress section
              _buildProgressSection(target),
              const SizedBox(height: 16),
              
              // Contributor stats
              _buildContributorStats(),
              const SizedBox(height: 20),
              
              // Graduate details (expandable)
              _buildGraduateDetails(target),
              const SizedBox(height: 24),
              
              // Action buttons
              _buildActionButtons(isMobile, target),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GraduationTarget target) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            '🎯 TARGET SOKONGAN DANA WISUDA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.gray900,
            ),
          ),
        ),
        _buildStatusBadge(target),
      ],
    );
  }

  Widget _buildStatusBadge(GraduationTarget target) {
    final isClosingSoon = target.isClosingSoon;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isClosingSoon ? AppConstants.warningBg : AppConstants.successBg,
        border: Border.all(
          color: isClosingSoon ? AppConstants.warningBorder : AppConstants.successBorder,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isClosingSoon 
            ? '⚠️ Deadline ${target.daysUntilDeadline} hari lagi'
            : '🟢 Aktif',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isClosingSoon ? FontWeight.w600 : FontWeight.w500,
          color: isClosingSoon ? const Color(0xFF92400E) : const Color(0xFF065F46),
        ),
      ),
    );
  }

  Widget _buildTargetInfo(GraduationTarget target) {
    return Row(
      children: [
        Text(
          '📅 ${target.monthYearDisplay.toUpperCase()}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.gray900,
          ),
        ),
        const Text(
          ' • ',
          style: TextStyle(
            fontSize: 16,
            color: AppConstants.gray500,
          ),
        ),
        Text(
          '${target.graduates.length} Wisudawan',
          style: const TextStyle(
            fontSize: 16,
            color: AppConstants.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineInfo(GraduationTarget target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⏰ Deadline: ${DateFormatter.formatDate(target.deadline)} (H-3 dari wisuda pertama)',
          style: const TextStyle(
            fontSize: 14,
            color: AppConstants.gray500,
          ),
        ),
        if (target.isClosingSoon) ...[
          const SizedBox(height: 4),
          Text(
            '⚠️ ${target.daysUntilDeadline} hari lagi!',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppConstants.errorRed,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection(GraduationTarget target) {
    final percentage = target.percentage;
    final gradient = AppConstants.getProgressGradient(percentage);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          'Dana Terkumpul',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.gray500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Amount display - Use displayAmount (actual + allocated)
        Text(
          '${CurrencyFormatter.formatCurrency(target.displayAmount)} / ${CurrencyFormatter.formatCurrency(target.targetAmount)} (${percentage.toStringAsFixed(0)}%)',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryTeal,
          ),
        ),
        const SizedBox(height: 12),
        
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 24,
            color: AppConstants.gray100,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: AppConstants.progressAnimationDuration,
                  width: MediaQuery.of(context).size.width * 0.9 * (percentage / 100).clamp(0, 1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Achievement badge
        AchievementBadge(percentage: percentage),
      ],
    );
  }

  Widget _buildContributorStats() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '❤️ 0 kontribusi tercatat',
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.gray500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '(Dana dari 0 transaksi)',
          style: TextStyle(
            fontSize: 12,
            color: AppConstants.gray400,
          ),
        ),
      ],
    );
  }

  Widget _buildGraduateDetails(GraduationTarget target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              const Text(
                '📋 Detail Wisudawan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.primaryTeal,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppConstants.primaryTeal,
                size: 20,
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.gray50,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: target.graduates.map((graduate) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• ${graduate.name} - ${DateFormatter.formatDate(graduate.date)} - ${graduate.location}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.gray700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile, GraduationTarget target) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Primary button: DONASI
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => DonationModal(target: target),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusRounded),
            ),
            elevation: 2,
          ),
          child: const Text(
            '💸 DONASI SEKARANG',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Secondary button: DETAIL
        OutlinedButton(
          onPressed: () {
            setState(() {
              _isExpanded = true;
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.gray500,
            side: const BorderSide(color: AppConstants.gray300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusRounded),
            ),
          ),
          child: const Text(
            'ℹ️ Detail Target',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveTarget(double screenWidth) {
    return Center(
      child: Container(
        width: screenWidth * 0.9,
        constraints: const BoxConstraints(
          maxWidth: AppConstants.cardMaxWidthLarge,
        ),
        margin: const EdgeInsets.only(top: 24, bottom: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppConstants.infoBg,
          border: Border.all(color: AppConstants.infoBorder),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: const Column(
          children: [
            Text('💡', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'Tidak ada target wisuda yang aktif saat ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Target wisuda berikutnya akan dibuka setelah deadline target sebelumnya atau dibuat oleh admin',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(double screenWidth) {
    return Center(
      child: Container(
        width: screenWidth * 0.9,
        constraints: const BoxConstraints(
          maxWidth: AppConstants.cardMaxWidthLarge,
        ),
        margin: const EdgeInsets.only(top: 24, bottom: 24),
        padding: const EdgeInsets.all(48),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryTeal),
          ),
        ),
      ),
    );
  }

  Widget _buildError(double screenWidth) {
    return Center(
      child: Container(
        width: screenWidth * 0.9,
        constraints: const BoxConstraints(
          maxWidth: AppConstants.cardMaxWidthLarge,
        ),
        margin: const EdgeInsets.only(top: 24, bottom: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppConstants.errorBg,
          border: Border.all(color: AppConstants.errorBorder),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: const Column(
          children: [
            Icon(Icons.error_outline, color: AppConstants.errorRed, size: 48),
            SizedBox(height: 16),
            Text(
              'Gagal memuat target wisuda',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
