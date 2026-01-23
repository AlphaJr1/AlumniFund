import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Achievement badge widget untuk milestone progress
class AchievementBadge extends StatelessWidget {
  final double percentage;

  const AchievementBadge({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _getBadgeInfo();

    if (badge == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badge.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badge.color, width: 1),
      ),
      child: Text(
        badge.text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: badge.color,
        ),
      ),
    );
  }

  _BadgeInfo? _getBadgeInfo() {
    if (percentage >= 100) {
      return const _BadgeInfo(
        text: '🎊 TARGET TERCAPAI!',
        color: AppConstants.primaryTeal,
      );
    } else if (percentage >= 75) {
      return const _BadgeInfo(
        text: '🥇 Almost there!',
        color: AppConstants.successGreen,
      );
    } else if (percentage >= 50) {
      return const _BadgeInfo(
        text: '🥈 Setengah perjalanan!',
        color: Color(0xFFEA580C),
      );
    } else if (percentage >= 25) {
      return const _BadgeInfo(
        text: '🥉 Seperempat jalan!',
        color: Color(0xFFF59E0B),
      );
    }
    return null;
  }
}

class _BadgeInfo {
  final String text;
  final Color color;

  const _BadgeInfo({
    required this.text,
    required this.color,
  });
}
