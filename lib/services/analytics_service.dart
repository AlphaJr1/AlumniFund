import 'package:cloud_firestore/cloud_firestore.dart';

/// Service untuk mengakses analytics collection dari Cloud Functions
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all target analytics
  Stream<List<TargetAnalytics>> getTargetAnalytics() {
    return _firestore
        .collection('analytics')
        .orderBy('closed_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TargetAnalytics.fromFirestore(doc))
          .toList();
    });
  }

  /// Get analytics for specific target
  Future<TargetAnalytics?> getTargetAnalyticsById(String targetId) async {
    final doc = await _firestore.collection('analytics').doc(targetId).get();
    if (!doc.exists) return null;
    return TargetAnalytics.fromFirestore(doc);
  }

  /// Get analytics summary (last 6 months)
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

    final snapshot = await _firestore
        .collection('analytics')
        .where('closed_at', isGreaterThan: Timestamp.fromDate(sixMonthsAgo))
        .get();

    final analytics =
        snapshot.docs.map((doc) => TargetAnalytics.fromFirestore(doc)).toList();

    return AnalyticsSummary.fromAnalytics(analytics);
  }

  /// Get system health status
  Future<SystemHealth> getSystemHealth() async {
    try {
      // Check last 24h analytics
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));

      final recentAnalytics = await _firestore
          .collection('analytics')
          .where('created_at', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();

      // Note: Function execution logs tidak bisa diakses langsung dari Firestore
      // Ini hanya simulasi. Real implementation perlu Cloud Functions API atau logging service
      return SystemHealth(
        status: SystemStatus.healthy,
        lastAnalyticsUpdate: recentAnalytics.docs.isNotEmpty
            ? (recentAnalytics.docs.first.data()['created_at'] as Timestamp)
                .toDate()
            : null,
        analyticsCount24h: recentAnalytics.docs.length,
        message: 'System operating normally',
      );
    } catch (e) {
      return SystemHealth(
        status: SystemStatus.error,
        lastAnalyticsUpdate: null,
        analyticsCount24h: 0,
        message: 'Error checking system health: $e',
      );
    }
  }
}

/// Model untuk target analytics
class TargetAnalytics {
  final String targetId;
  final String month;
  final int year;
  final int targetAmount;
  final int collectedAmount;
  final int percentage;
  final int graduatesCount;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final DateTime? deadline;
  final int? durationDays;
  final String fundingStatus;
  final Map<String, dynamic>? metadata;

  TargetAnalytics({
    required this.targetId,
    required this.month,
    required this.year,
    required this.targetAmount,
    required this.collectedAmount,
    required this.percentage,
    required this.graduatesCount,
    this.openedAt,
    this.closedAt,
    this.deadline,
    this.durationDays,
    required this.fundingStatus,
    this.metadata,
  });

  factory TargetAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TargetAnalytics(
      targetId: doc.id,
      month: data['month'] ?? '',
      year: data['year'] ?? 0,
      targetAmount: data['target_amount'] ?? 0,
      collectedAmount: data['collected_amount'] ?? 0,
      percentage: data['percentage'] ?? 0,
      graduatesCount: data['graduates_count'] ?? 0,
      openedAt: (data['opened_at'] as Timestamp?)?.toDate(),
      closedAt: (data['closed_at'] as Timestamp?)?.toDate(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      durationDays: data['duration_days'],
      fundingStatus: data['funding_status'] ?? 'unknown',
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Model untuk analytics summary
class AnalyticsSummary {
  final int totalTargets;
  final int fullyFundedCount;
  final int partiallyFundedCount;
  final double averagePercentage;
  final double averageDuration;
  final int totalGraduates;
  final int totalCollected;

  AnalyticsSummary({
    required this.totalTargets,
    required this.fullyFundedCount,
    required this.partiallyFundedCount,
    required this.averagePercentage,
    required this.averageDuration,
    required this.totalGraduates,
    required this.totalCollected,
  });

  factory AnalyticsSummary.fromAnalytics(List<TargetAnalytics> analytics) {
    if (analytics.isEmpty) {
      return AnalyticsSummary(
        totalTargets: 0,
        fullyFundedCount: 0,
        partiallyFundedCount: 0,
        averagePercentage: 0,
        averageDuration: 0,
        totalGraduates: 0,
        totalCollected: 0,
      );
    }

    final fullyFunded =
        analytics.where((a) => a.fundingStatus == 'fully_funded').length;
    final partiallyFunded =
        analytics.where((a) => a.fundingStatus == 'partially_funded').length;

    final avgPercentage =
        analytics.map((a) => a.percentage).reduce((a, b) => a + b) /
            analytics.length;

    final durations = analytics
        .where((a) => a.durationDays != null)
        .map((a) => a.durationDays!)
        .toList();
    final avgDuration = durations.isNotEmpty
        ? durations.reduce((a, b) => a + b) / durations.length
        : 0;

    final totalGrads =
        analytics.map((a) => a.graduatesCount).reduce((a, b) => a + b);
    final totalCollect =
        analytics.map((a) => a.collectedAmount).reduce((a, b) => a + b);

    return AnalyticsSummary(
      totalTargets: analytics.length,
      fullyFundedCount: fullyFunded,
      partiallyFundedCount: partiallyFunded,
      averagePercentage: avgPercentage,
      averageDuration: avgDuration.toDouble(),
      totalGraduates: totalGrads,
      totalCollected: totalCollect,
    );
  }
}

/// Model untuk system health
class SystemHealth {
  final SystemStatus status;
  final DateTime? lastAnalyticsUpdate;
  final int analyticsCount24h;
  final String message;

  SystemHealth({
    required this.status,
    this.lastAnalyticsUpdate,
    required this.analyticsCount24h,
    required this.message,
  });
}

enum SystemStatus {
  healthy,
  warning,
  error,
}
