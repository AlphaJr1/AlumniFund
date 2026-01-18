import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feedback_provider.dart';

/// Dashboard stat card untuk onboarding feedback
class FeedbackStatCard extends ConsumerWidget {
  final VoidCallback onTap;

  const FeedbackStatCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCount = ref.watch(totalFeedbackCountProvider);
    final unreadCount = ref.watch(unreadFeedbackCountProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14 : 18), // Reduced from 16/20
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10), // Reduced from 12
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                                .withLightness(0.3)
                                .toColor(),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10), // Reduced from 12
                      ),
                      child: const Icon(
                        Icons.feedback,
                        color: Colors.white,
                        size: 20, // Reduced from 24
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14, // Reduced from 16
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                
                SizedBox(height: isMobile ? 12 : 14), // Reduced spacing
                
                // Title
                Text(
                  'Onboarding Feedback',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15, // Reduced from 15/16
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: isMobile ? 10 : 12), // Reduced spacing
                
                // Stats
                unreadCount.when(
                  data: (unread) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Total count
                      Row(
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13, // Reduced
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 6), // Reduced from 8
                          Flexible(
                            child: Text(
                              '$totalCount feedback',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13, // Reduced
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4), // Reduced from 6
                      
                      // Unread count
                      Row(
                        children: [
                          Text(
                            'Belum dibaca:',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13, // Reduced
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 6), // Reduced from 8
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6, // Reduced from 8
                                vertical: 2, // Reduced from 3
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8), // Reduced from 10
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  fontSize: 11, // Reduced from 12
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            Text(
                              '0',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13, // Reduced
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: SizedBox(
                      width: 16, // Reduced from 20
                      height: 16, // Reduced from 20
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => Text(
                    'Error loading stats',
                    style: TextStyle(
                      fontSize: 11, // Reduced from 12
                      color: Colors.red[600],
                    ),
                  ),
                ),
                
                SizedBox(height: isMobile ? 10 : 12), // Reduced spacing
                
                // View all button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, // Reduced from 12
                    vertical: 6, // Reduced from 8
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6), // Reduced from 8
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 12, // Reduced from 14
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4), // Reduced from 6
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 11, // Reduced from 12
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
