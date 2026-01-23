import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk onboarding feedback dari users
class OnboardingFeedback {
  final String id;
  final String feedback;
  final DateTime submittedAt;
  final bool isRead;

  // Hybrid anonymous user tracking
  final String anonymousUserId; // UUID from localStorage
  final String? browserFingerprint; // Browser fingerprint hash

  // Device info for admin insight
  final String? userAgent; // Browser/OS info
  final String? screenResolution; // Screen dimensions
  final String? timezone; // User timezone

  const OnboardingFeedback({
    required this.id,
    required this.feedback,
    required this.submittedAt,
    required this.isRead,
    required this.anonymousUserId,
    this.browserFingerprint,
    this.userAgent,
    this.screenResolution,
    this.timezone,
  });

  /// Create from Firestore document
  factory OnboardingFeedback.fromJson(Map<String, dynamic> json, String id) {
    return OnboardingFeedback(
      id: id,
      feedback: json['feedback'] as String,
      submittedAt: (json['submittedAt'] as Timestamp).toDate(),
      isRead: json['isRead'] as bool? ?? false,
      anonymousUserId: json['anonymousUserId'] as String,
      browserFingerprint: json['browserFingerprint'] as String?,
      userAgent: json['userAgent'] as String?,
      screenResolution: json['screenResolution'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'feedback': feedback,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'isRead': isRead,
      'anonymousUserId': anonymousUserId,
      'browserFingerprint': browserFingerprint,
      'userAgent': userAgent,
      'screenResolution': screenResolution,
      'timezone': timezone,
    };
  }

  /// Copy with method for updating fields
  OnboardingFeedback copyWith({
    String? id,
    String? feedback,
    DateTime? submittedAt,
    bool? isRead,
    String? anonymousUserId,
    String? browserFingerprint,
    String? userAgent,
    String? screenResolution,
    String? timezone,
  }) {
    return OnboardingFeedback(
      id: id ?? this.id,
      feedback: feedback ?? this.feedback,
      submittedAt: submittedAt ?? this.submittedAt,
      isRead: isRead ?? this.isRead,
      anonymousUserId: anonymousUserId ?? this.anonymousUserId,
      browserFingerprint: browserFingerprint ?? this.browserFingerprint,
      userAgent: userAgent ?? this.userAgent,
      screenResolution: screenResolution ?? this.screenResolution,
      timezone: timezone ?? this.timezone,
    );
  }
}
