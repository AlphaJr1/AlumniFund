import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/general_fund_provider.dart';
import '../providers/graduation_target_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';
import 'simple_donation_modal.dart';
import 'distribution_detail_modal.dart';

/// Combined card untuk General Fund Balance + Active Target
class BalanceTargetCard extends ConsumerWidget {
  final bool showHint; // Unused but needed for compatibility
  final VoidCallback? onProofSubmitted; // Callback when proof submitted
  final VoidCallback? onModalOpen; // NEW: Callback when modal opens
  final VoidCallback? onModalClose; // NEW: Callback when modal closes

  const BalanceTargetCard({
    super.key,
    this.showHint = false,
    this.onProofSubmitted,
    this.onModalOpen,
    this.onModalClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generalFundAsync = ref.watch(generalFundProvider);
    final activeTarget = ref.watch(activeTargetProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 1024;

    return Center(
      child: GestureDetector(
        // Consume double-tap on entire card to prevent theme change
        onDoubleTap: () {
          // Do nothing - block double-tap from reaching background
        },
        child: Container(
          width: screenWidth * 0.9,
          height: isMobile ? screenHeight * 0.65 : screenHeight * 0.75,
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          margin: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            // boxShadow removed for testing
          ),
          child: generalFundAsync.when(
            data: (fund) => _buildContent(
              context,
              ref,
              fund?.balance ?? 0,
              activeTarget,
              onProofSubmitted,
            ),
            loading: () => _buildLoading(),
            error: (error, stack) => _buildError(),
          ),
        ),
      ),
    );
  }

  // Get color based on progress (3 phases)
  Color _getProgressColor(double percentage) {
    if (percentage < 34) {
      return const Color(0xFFEF4444); // Red (0-33%)
    } else if (percentage < 67) {
      return const Color(0xFFF59E0B); // Yellow/Orange (34-66%)
    } else {
      return const Color(0xFF10B981); // Green (67-100%)
    }
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    double balance,
    dynamic activeTarget,
    VoidCallback? onProofSubmitted,
  ) {
    final hasActiveTarget = activeTarget != null;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top spacer - responsive
            SizedBox(height: isMobile ? 16 : 24),

            // General Fund Balance Section
            const Text(
              '💰',
              style: TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 20),
            Text(
              'Shared Pool',
              style: TextStyle(
                fontSize: isMobile ? 17 : 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              CurrencyFormatter.formatCurrency(balance),
              style: TextStyle(
                fontSize: isMobile ? 38 : 46,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            // Show reserved amount if active target exists
            if (activeTarget != null && activeTarget.allocatedFromFund > 0) ...[
              const SizedBox(height: 8),
              Text(
                '(${CurrencyFormatter.formatCurrency(activeTarget.allocatedFromFund)} reserved)',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],

            // Middle spacer - responsive
            SizedBox(height: isMobile ? 24 : 32),

            // Active Target Section (if exists)
            if (hasActiveTarget) ...[
              InkWell(
                onTap: () {
                  // Show distribution detail modal
                  showDialog(
                    context: context,
                    builder: (context) =>
                        DistributionDetailModal(target: activeTarget),
                  );
                },
                onDoubleTap: () {
                  // Consume double-tap to prevent theme change
                  // Do nothing - only single tap should show modal
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🎯',
                        style: TextStyle(fontSize: isMobile ? 28 : 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Active Goal',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${activeTarget.month.toUpperCase()} ${activeTarget.year}',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Animated Progress bar
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        tween: Tween<double>(
                          begin: 0.0,
                          end: activeTarget.targetAmount > 0
                              ? (activeTarget.displayAmount /
                                      activeTarget.targetAmount)
                                  .clamp(0.0, 1.0)
                              : 0.0,
                        ),
                        builder: (context, value, child) {
                          final percentage = (value * 100);
                          final progressColor = _getProgressColor(percentage);

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                LinearProgressIndicator(
                                  value: value,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      progressColor),
                                ),
                                // Pulse glow effect overlay
                                if (value > 0 && value < 1.0)
                                  Positioned.fill(
                                    child: _PulseGlow(color: progressColor),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Animated percentage and shortfall
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        tween: Tween<double>(
                          begin: 0.0,
                          end: activeTarget.targetAmount > 0
                              ? (activeTarget.displayAmount /
                                          activeTarget.targetAmount)
                                      .clamp(0.0, 1.0) *
                                  100
                              : 0.0,
                        ),
                        builder: (context, animatedPercentage, child) {
                          final progressColor =
                              _getProgressColor(animatedPercentage);
                          final animatedShortfall = activeTarget.targetAmount -
                              (activeTarget.targetAmount *
                                  (animatedPercentage / 100));

                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${animatedPercentage.toStringAsFixed(0)}% reached',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: progressColor,
                                  ),
                                ),
                                if (animatedPercentage < 100) ...[
                                  TextSpan(
                                    text: ' | ',
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${CurrencyFormatter.formatCurrency(animatedShortfall)} more needed',
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: progressColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${activeTarget.graduates.length} Recipients',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 24),
            ] else ...[
              SizedBox(height: isMobile ? 32 : 40),
            ],

            // Donation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Notify onboarding that modal is opening
                  onModalOpen?.call();
                  // debugPrint('[BalanceCard] Drop Your Prop button tapped - modal opening');

                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => SimpleDonationModal(
                      onProofSubmitted: onProofSubmitted,
                    ),
                  ).then((_) {
                    // Modal closed
                    onModalClose?.call();
                    // debugPrint('[BalanceCard] SimpleDonationModal closed');
                  });
                },
                icon: Icon(Icons.volunteer_activism, size: isMobile ? 20 : 24),
                label: Text(
                  'Drop Your Prop',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Bottom spacer
            SizedBox(height: isMobile ? 16 : 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Builder(
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
          SizedBox(height: 16),
          Text(
            'Gagal memuat data',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// Pulse glow animation widget for progress bar
class _PulseGlow extends StatefulWidget {
  final Color color;

  const _PulseGlow({required this.color});

  @override
  State<_PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<_PulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withOpacity(_animation.value * 0.3),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
