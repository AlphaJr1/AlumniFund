import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Custom progress bar widget untuk menampilkan dana terkumpul vs target
class ProgressBarWidget extends StatelessWidget {
  final double current;
  final double target;
  final bool showPercentage;

  const ProgressBarWidget({
    super.key,
    required this.current,
    required this.target,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage (max 100%)
    final percentage =
        target > 0 ? (current / target * 100).clamp(0, 100) : 0.0;
    final progress = percentage / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(percentage.toDouble()),
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingS),

        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Current amount
            Text(
              Formatters.formatCurrency(current),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
            ),

            // Percentage or target
            if (showPercentage)
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
              )
            else
              Text(
                'Target: ${Formatters.formatCurrency(target)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
          ],
        ),

        // Target amount (if showing percentage)
        if (showPercentage) ...[
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'Target: ${Formatters.formatCurrency(target)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ],
    );
  }

  /// Get color based on progress percentage
  Color _getProgressColor(double percentage) {
    if (percentage >= 100) {
      return AppTheme.successColor;
    } else if (percentage >= 75) {
      return AppTheme.primaryColor;
    } else if (percentage >= 50) {
      return AppTheme.secondaryColor;
    } else if (percentage >= 25) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }
}
