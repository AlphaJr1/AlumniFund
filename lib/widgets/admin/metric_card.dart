import 'package:flutter/material.dart';

/// Reusable metric card widget for admin dashboard
class MetricCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color valueColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final card = Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20), // Reduced padding for mobile
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Text(
            icon,
            style: TextStyle(fontSize: isMobile ? 28 : 32),
          ),
          SizedBox(height: isMobile ? 8 : 12), // Reduced spacing for mobile

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 6 : 8), // Reduced spacing for mobile

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Subtitle (optional)
          if (subtitle != null) ...[
            SizedBox(height: isMobile ? 2 : 4), // Reduced spacing for mobile
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: const Color(0xFF9CA3AF),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    // Wrap with InkWell if clickable
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.grey.withOpacity(0.05),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: card,
          ),
        ),
      );
    }

    return card;
  }
}
