import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/onboarding_feedback_model.dart';
import '../../../providers/feedback_provider.dart';
import '../../../services/feedback_service.dart';
import '../../../widgets/admin/feedback_card.dart';
import '../../../widgets/admin/feedback_detail_modal.dart';

/// Screen untuk list semua onboarding feedbacks (Admin only)
class FeedbackListScreen extends ConsumerStatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  ConsumerState<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends ConsumerState<FeedbackListScreen> {
  final FeedbackService _feedbackService = FeedbackService();

  void _showFeedbackDetail(OnboardingFeedback feedback) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDetailModal(
        feedback: feedback,
        onMarkAsRead: () async {
          if (!feedback.isRead) {
            await _feedbackService.markAsRead(feedback.id);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbacks = ref.watch(filteredFeedbacksProvider);
    final filter = ref.watch(feedbackFilterProvider);
    final unreadCount = ref.watch(unreadFeedbackCountProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Onboarding Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip(
                  'Semua',
                  feedbacks.length,
                  filter == FeedbackFilter.all,
                  () => ref.read(feedbackFilterProvider.notifier).setFilter(
                      FeedbackFilter.all),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Belum Dibaca',
                  unreadCount.value ?? 0,
                  filter == FeedbackFilter.unread,
                  () => ref.read(feedbackFilterProvider.notifier).setFilter(
                      FeedbackFilter.unread),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Sudah Dibaca',
                  feedbacks.where((f) => f.isRead).length,
                  filter == FeedbackFilter.read,
                  () => ref.read(feedbackFilterProvider.notifier).setFilter(
                      FeedbackFilter.read),
                ),
              ],
            ),
          ),

          // Feedback list
          Expanded(
            child: feedbacks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    itemCount: feedbacks.length,
                    itemBuilder: (context, index) {
                      final feedback = feedbacks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FeedbackCard(
                          feedback: feedback,
                          onTap: () => _showFeedbackDetail(feedback),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    int count,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.feedback_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada feedback',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feedback dari user akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
