import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pending_submission_model.dart';

// Stream pending submissions
final pendingSubmissionsProvider =
    StreamProvider<List<PendingSubmission>>((ref) {
  return FirebaseFirestore.instance
      .collection('pending_submissions')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
    final submissions = snapshot.docs
        .map((doc) => PendingSubmission.fromFirestore(doc))
        .toList();
    // Sort by submitted_at descending (newest first) on client-side
    submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return submissions;
  });
});

// Count provider for badge
final pendingSubmissionsCountProvider = Provider<int>((ref) {
  final submissionsAsync = ref.watch(pendingSubmissionsProvider);
  return submissionsAsync.when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
