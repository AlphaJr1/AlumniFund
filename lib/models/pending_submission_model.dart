import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for pending proof submission
/// Tracks user-uploaded proof images awaiting admin validation
class PendingSubmission {
  final String id;
  final String proofUrl;
  final double? submittedAmount;
  final String? targetId;
  final String? targetMonth;
  final DateTime submittedAt;
  final String status; // "pending" | "approved" | "rejected"
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? notes;
  final String? submitterName;

  const PendingSubmission({
    required this.id,
    required this.proofUrl,
    this.submittedAmount,
    this.targetId,
    this.targetMonth,
    required this.submittedAt,
    required this.status,
    this.reviewedAt,
    this.reviewedBy,
    this.notes,
    this.submitterName,
  });

  /// Create PendingSubmission from Firestore document
  factory PendingSubmission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PendingSubmission(
      id: doc.id,
      proofUrl: data['proof_url'] as String,
      submittedAmount: (data['submitted_amount'] as num?)?.toDouble(),
      targetId: data['target_id'] as String?,
      targetMonth: data['target_month'] as String?,
      submittedAt: (data['submitted_at'] as Timestamp).toDate(),
      status: data['status'] as String,
      reviewedAt: data['reviewed_at'] != null
          ? (data['reviewed_at'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewed_by'] as String?,
      notes: data['notes'] as String?,
      submitterName: data['submitter_name'] as String?,
    );
  }

  /// Convert PendingSubmission to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'proof_url': proofUrl,
      'submitted_amount': submittedAmount,
      'target_id': targetId,
      'target_month': targetMonth,
      'submitted_at': Timestamp.fromDate(submittedAt),
      'status': status,
      'reviewed_at':
          reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewed_by': reviewedBy,
      'notes': notes,
      'submitter_name': submitterName,
    };
  }

  /// Check if submission is pending
  bool get isPending => status == 'pending';

  /// Check if submission is approved
  bool get isApproved => status == 'approved';

  /// Check if submission is rejected
  bool get isRejected => status == 'rejected';

  /// Create copy with modified fields
  PendingSubmission copyWith({
    String? id,
    String? proofUrl,
    double? submittedAmount,
    DateTime? submittedAt,
    String? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? notes,
    String? submitterName,
  }) {
    return PendingSubmission(
      id: id ?? this.id,
      proofUrl: proofUrl ?? this.proofUrl,
      submittedAmount: submittedAmount ?? this.submittedAmount,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      notes: notes ?? this.notes,
      submitterName: submitterName ?? this.submitterName,
    );
  }

  @override
  String toString() => 'PendingSubmission(id: $id, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingSubmission &&
        other.id == id &&
        other.proofUrl == proofUrl &&
        other.submittedAmount == submittedAmount &&
        other.submittedAt == submittedAt &&
        other.status == status &&
        other.reviewedAt == reviewedAt &&
        other.reviewedBy == reviewedBy &&
        other.notes == notes &&
        other.submitterName == submitterName;
  }

  @override
  int get hashCode => Object.hash(
        id,
        proofUrl,
        submittedAmount,
        submittedAt,
        status,
        reviewedAt,
        reviewedBy,
        notes,
        submitterName,
      );
}
