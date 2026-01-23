import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/onboarding_feedback_model.dart';
import 'user_identifier_service.dart';

/// Service untuk handle onboarding feedback operations
class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserIdentifierService _userIdentifier = UserIdentifierService();
  
  static const String _collectionName = 'onboarding_feedbacks';

  /// Submit feedback ke Firestore
  /// Returns document ID jika berhasil
  Future<String> submitFeedback(String feedbackText) async {
    // Validate: feedback tidak boleh kosong
    if (feedbackText.trim().isEmpty) {
      throw Exception('Feedback cannot be empty');
    }

    // Get user identifiers
    final anonymousUserId = _userIdentifier.getAnonymousUserId();
    final browserFingerprint = _userIdentifier.getBrowserFingerprint();
    final userAgent = _userIdentifier.getUserAgent();
    final screenResolution = _userIdentifier.getScreenResolution();
    final timezone = _userIdentifier.getTimezone();

    // Create feedback document
    final feedback = OnboardingFeedback(
      id: '', // Will be set by Firestore
      feedback: feedbackText.trim(),
      submittedAt: DateTime.now(),
      isRead: false,
      anonymousUserId: anonymousUserId,
      browserFingerprint: browserFingerprint,
      userAgent: userAgent,
      screenResolution: screenResolution,
      timezone: timezone,
    );

    // Save to Firestore
    final docRef = await _firestore
        .collection(_collectionName)
        .add(feedback.toJson());

    return docRef.id;
  }

  /// Get all feedbacks (for admin)
  Stream<List<OnboardingFeedback>> getFeedbacks() {
    return _firestore
        .collection(_collectionName)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OnboardingFeedback.fromJson(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }

  /// Get unread feedbacks count (for admin dashboard)
  Stream<int> getUnreadCount() {
    return _firestore
        .collection(_collectionName)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Mark feedback as read
  Future<void> markAsRead(String feedbackId) async {
    await _firestore
        .collection(_collectionName)
        .doc(feedbackId)
        .update({'isRead': true});
  }

  /// Mark feedback as unread
  Future<void> markAsUnread(String feedbackId) async {
    await _firestore
        .collection(_collectionName)
        .doc(feedbackId)
        .update({'isRead': false});
  }

  /// Delete feedback
  Future<void> deleteFeedback(String feedbackId) async {
    await _firestore
        .collection(_collectionName)
        .doc(feedbackId)
        .delete();
  }

  /// Get feedback by ID
  Future<OnboardingFeedback?> getFeedbackById(String id) async {
    final doc = await _firestore
        .collection(_collectionName)
        .doc(id)
        .get();

    if (!doc.exists) return null;

    return OnboardingFeedback.fromJson(
      doc.data()!,
      doc.id,
    );
  }
}
