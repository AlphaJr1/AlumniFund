import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/onboarding_feedback_model.dart';

/// Detail modal untuk view full feedback content
class FeedbackDetailModal extends StatelessWidget {
  final OnboardingFeedback feedback;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onMarkAsUnread;
  final VoidCallback? onDelete;

  const FeedbackDetailModal({
    super.key,
    required this.feedback,
    this.onMarkAsRead,
    this.onMarkAsUnread,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxWidth: isMobile ? 500 : 700,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, isMobile),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feedback content
                    _buildSection(
                      'Feedback',
                      feedback.feedback,
                      Icons.chat_bubble_outline,
                      isMobile,
                    ),

                    const SizedBox(height: 24),

                    // User info
                    _buildUserInfo(isMobile),

                    const SizedBox(height: 24),

                    // Device info
                    _buildDeviceInfo(isMobile),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActions(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                .withLightness(0.3)
                .toColor(),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: feedback.isRead
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  feedback.isRead ? Icons.check_circle : Icons.fiber_new,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  feedback.isRead ? 'Sudah Dibaca' : 'Baru',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Timestamp
          Text(
            DateFormat('dd MMM yyyy, HH:mm').format(feedback.submittedAt),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 12),

          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: const Color(0xFF111827),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline,
                size: 18, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              'User Information',
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Anonymous ID', feedback.anonymousUserId, isMobile),
        if (feedback.browserFingerprint != null)
          _buildInfoRow(
            'Browser Fingerprint',
            feedback.browserFingerprint!.substring(0, 16) + '...',
            isMobile,
          ),
      ],
    );
  }

  Widget _buildDeviceInfo(bool isMobile) {
    if (feedback.userAgent == null &&
        feedback.screenResolution == null &&
        feedback.timezone == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.devices, size: 18, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              'Device Information',
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (feedback.userAgent != null)
          _buildInfoRow(
              'Browser', _parseUserAgent(feedback.userAgent!), isMobile),
        if (feedback.screenResolution != null)
          _buildInfoRow('Screen', feedback.screenResolution!, isMobile),
        if (feedback.timezone != null)
          _buildInfoRow('Timezone', feedback.timezone!, isMobile),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 100 : 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
              },
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Delete button (left side)
          if (onDelete != null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onDelete!();
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Hapus'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 12 : 14,
                ),
              ),
            ),

          const Spacer(),

          // Toggle read/unread button
          if (!feedback.isRead && onMarkAsRead != null)
            ElevatedButton.icon(
              onPressed: () {
                onMarkAsRead!();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Tandai Sudah Dibaca'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 12 : 14,
                ),
              ),
            )
          else if (feedback.isRead && onMarkAsUnread != null)
            OutlinedButton.icon(
              onPressed: () {
                onMarkAsUnread!();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.mark_email_unread_outlined, size: 18),
              label: const Text('Tandai Belum Dibaca'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 12 : 14,
                ),
              ),
            ),

          const SizedBox(width: 12),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _parseUserAgent(String userAgent) {
    // Simple parsing - detect browser
    if (userAgent.contains('Chrome')) return 'Chrome';
    if (userAgent.contains('Firefox')) return 'Firefox';
    if (userAgent.contains('Safari')) return 'Safari';
    if (userAgent.contains('Edge')) return 'Edge';
    return 'Unknown';
  }
}
