import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Footer widget untuk dashboard
class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;

    return Container(
      width: double.infinity,
      color: AppConstants.gray800,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 32 : 40,
        horizontal: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Made with love
          const Text(
            'Made with ❤️ for Alumni Community',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Copyright
          const Text(
            '© 2026 Dompet Alumni Comm',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Contact info
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              InkWell(
                onTap: () {
                  // TODO: Open email
                },
                child: const Text(
                  '📧 adrianalfajri@gmail.com',
                  style: TextStyle(
                    color: AppConstants.gray300,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(
                '|',
                style: TextStyle(
                  color: AppConstants.gray300,
                  fontSize: 12,
                ),
              ),
              InkWell(
                onTap: () {
                  // TODO: Open WhatsApp
                },
                child: const Text(
                  '📱 +6281377707700',
                  style: TextStyle(
                    color: AppConstants.gray300,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
