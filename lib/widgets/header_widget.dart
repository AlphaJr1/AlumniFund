import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';

/// Fixed header widget untuk dashboard
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;
    final headerHeight = AppConstants.getHeaderHeight(screenWidth);

    // Get dynamic theme colors from built-in Theme
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    // Create darker shade for gradient
    final darkColor = HSLColor.fromColor(primaryColor)
        .withLightness(
            (HSLColor.fromColor(primaryColor).lightness - 0.1).clamp(0.0, 1.0))
        .toColor();

    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, darkColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Logo + Title
            Row(
              children: [
                const Text(
                  '🎓',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  isMobile ? 'DOMPET ALUMNI' : 'DOMPET ALUMNI COMM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Right side: Admin button
            IconButton(
              icon: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Admin Login',
              onPressed: () {
                // Navigate to admin login
                context.go('/admin/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
