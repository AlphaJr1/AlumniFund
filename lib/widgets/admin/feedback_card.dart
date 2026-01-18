import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/onboarding_feedback_model.dart';

/// Card widget untuk display feedback preview di list
class FeedbackCard extends StatelessWidget {
  final OnboardingFeedback feedback;
  final VoidCallback onTap;

  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final preview = feedback.feedback.length > 100
        ? '${feedback.feedback.substring(0, 100)}...'
        : feedback.feedback;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: feedback.isRead ? 0 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14 : 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: feedback.isRead 
                  ? Colors.grey[200]! 
                  : Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: feedback.isRead ? 1 : 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Badge + timestamp
              Row(
                children: [
                  // New/Read badge
                  if (!feedback.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'BARU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (!feedback.isRead) const SizedBox(width: 8),
                  
                  // Timestamp
                  Expanded(
                    child: Text(
                      _formatTimestamp(feedback.submittedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: feedback.isRead 
                            ? FontWeight.normal 
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Feedback preview
              Text(
                preview,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: const Color(0xFF111827),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Footer: User info
              Row(
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'User: ${_formatUserId(feedback.anonymousUserId)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Fingerprint match indicator
                  if (feedback.browserFingerprint != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 10,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'ID',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  String _formatUserId(String userId) {
    // Show shortened version
    if (userId.length > 20) {
      return '${userId.substring(0, 8)}...${userId.substring(userId.length - 6)}';
    }
    return userId;
  }
}
