import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_feedback_model.dart';
import '../services/feedback_service.dart';

/// Provider untuk feedback service
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

/// Stream provider untuk all feedbacks (sorted by date, descending)
final feedbacksStreamProvider = StreamProvider<List<OnboardingFeedback>>((ref) {
  final service = ref.watch(feedbackServiceProvider);
  return service.getFeedbacks();
});

/// Stream provider untuk unread feedback count
final unreadFeedbackCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(feedbackServiceProvider);
  return service.getUnreadCount();
});

/// Provider untuk get total feedback count
final totalFeedbackCountProvider = Provider<int>((ref) {
  final feedbacks = ref.watch(feedbacksStreamProvider);
  return feedbacks.when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider untuk filter feedbacks by read status
enum FeedbackFilter { all, unread, read }

/// Notifier for feedback filter state
class FeedbackFilterNotifier extends Notifier<FeedbackFilter> {
  @override
  FeedbackFilter build() => FeedbackFilter.all;

  void setFilter(FeedbackFilter filter) {
    state = filter;
  }
}

final feedbackFilterProvider =
    NotifierProvider<FeedbackFilterNotifier, FeedbackFilter>(
  FeedbackFilterNotifier.new,
);

final filteredFeedbacksProvider = Provider<List<OnboardingFeedback>>((ref) {
  final feedbacks = ref.watch(feedbacksStreamProvider);
  final filter = ref.watch(feedbackFilterProvider);

  return feedbacks.when(
    data: (list) {
      switch (filter) {
        case FeedbackFilter.unread:
          return list.where((f) => !f.isRead).toList();
        case FeedbackFilter.read:
          return list.where((f) => f.isRead).toList();
        case FeedbackFilter.all:
          return list;
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
