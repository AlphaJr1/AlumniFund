import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for fund distribution
/// Tracks how funds are distributed to graduates when target closes
class Distribution {
  final double perPerson;
  final double totalDistributed;
  final String status; // "pending" | "distributed"
  final DateTime? distributedAt;

  const Distribution({
    required this.perPerson,
    required this.totalDistributed,
    required this.status,
    this.distributedAt,
  });

  /// Create empty/pending distribution
  factory Distribution.pending() {
    return const Distribution(
      perPerson: 0,
      totalDistributed: 0,
      status: 'pending',
      distributedAt: null,
    );
  }

  /// Create Distribution from Firestore map
  factory Distribution.fromMap(Map<String, dynamic> map) {
    return Distribution(
      perPerson: (map['per_person'] as num?)?.toDouble() ?? 0.0,
      totalDistributed: (map['total_distributed'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      distributedAt: map['distributed_at'] != null
          ? (map['distributed_at'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert Distribution to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'per_person': perPerson,
      'total_distributed': totalDistributed,
      'status': status,
      'distributed_at':
          distributedAt != null ? Timestamp.fromDate(distributedAt!) : null,
    };
  }

  /// Check if distribution is complete
  bool get isDistributed => status == 'distributed';

  /// Create copy with modified fields
  Distribution copyWith({
    double? perPerson,
    double? totalDistributed,
    String? status,
    DateTime? distributedAt,
  }) {
    return Distribution(
      perPerson: perPerson ?? this.perPerson,
      totalDistributed: totalDistributed ?? this.totalDistributed,
      status: status ?? this.status,
      distributedAt: distributedAt ?? this.distributedAt,
    );
  }

  @override
  String toString() =>
      'Distribution(perPerson: $perPerson, totalDistributed: $totalDistributed, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Distribution &&
        other.perPerson == perPerson &&
        other.totalDistributed == totalDistributed &&
        other.status == status &&
        other.distributedAt == distributedAt;
  }

  @override
  int get hashCode =>
      Object.hash(perPerson, totalDistributed, status, distributedAt);
}
