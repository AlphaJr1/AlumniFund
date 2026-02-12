import 'package:cloud_firestore/cloud_firestore.dart';
import 'graduate_model.dart';
import 'distribution_model.dart';

/// Model for graduation target
/// Represents a monthly fundraising target for graduates
class GraduationTarget {
  final String id;
  final String month; // Lowercase: "januari", "februari", "mei", etc.
  final int year;
  final List<Graduate> graduates;
  final double targetAmount;
  final double currentAmount;
  final double
      allocatedFromFund; // Virtual allocation from general fund (not yet deducted)
  final DateTime deadline;
  final String
      status; // "upcoming" | "active" | "closing_soon" | "closed" | "archived"
  final DateTime? openDate;
  final DateTime? closedDate;
  final Distribution distribution;
  final String? distributionProofUrl; // URL bukti distribusi (PDF/image)
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;

  const GraduationTarget({
    required this.id,
    required this.month,
    required this.year,
    required this.graduates,
    required this.targetAmount,
    required this.currentAmount,
    this.allocatedFromFund = 0.0,
    required this.deadline,
    required this.status,
    this.openDate,
    this.closedDate,
    required this.distribution,
    this.distributionProofUrl,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
  });

  /// Create GraduationTarget from Firestore document
  factory GraduationTarget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GraduationTarget(
      id: doc.id,
      month: data['month'] as String,
      year: data['year'] as int,
      graduates: (data['graduates'] as List<dynamic>)
          .map((g) => Graduate.fromMap(g as Map<String, dynamic>))
          .toList(),
      targetAmount: (data['target_amount'] as num).toDouble(),
      currentAmount: (data['current_amount'] as num).toDouble(),
      allocatedFromFund:
          (data['allocated_from_fund'] as num?)?.toDouble() ?? 0.0,
      deadline: data['deadline'] != null
          ? (data['deadline'] as Timestamp).toDate()
          : DateTime(
              data['year'] as int, _getMonthNumber(data['month'] as String), 1),
      status: data['status'] as String,
      openDate: data['open_date'] != null
          ? (data['open_date'] as Timestamp).toDate()
          : null,
      closedDate: data['closed_date'] != null
          ? (data['closed_date'] as Timestamp).toDate()
          : null,
      distribution:
          Distribution.fromMap(data['distribution'] as Map<String, dynamic>),
      distributionProofUrl: data['distribution_proof_url'] as String?,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      createdBy: data['created_by'] as String,
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Convert GraduationTarget to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'month': month,
      'year': year,
      'graduates': graduates.map((g) => g.toMap()).toList(),
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'allocated_from_fund': allocatedFromFund,
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'open_date': openDate != null ? Timestamp.fromDate(openDate!) : null,
      'closed_date':
          closedDate != null ? Timestamp.fromDate(closedDate!) : null,
      'distribution': distribution.toMap(),
      'distribution_proof_url': distributionProofUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'created_by': createdBy,
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get total display amount (actual + allocated)
  double get displayAmount => currentAmount + allocatedFromFund;

  /// Alias for targetAmount (for consistency with old code)
  double get requiredBudget => targetAmount;

  /// Calculate progress percentage based on display amount (0-100+)
  double get percentage {
    if (targetAmount == 0) return 0;
    return ((displayAmount / targetAmount) * 100).clamp(0, 999);
  }

  /// Get days until deadline
  int get daysUntilDeadline {
    return deadline.difference(DateTime.now()).inDays;
  }

  /// Check if target is in closing soon state (H-7 to H-3)
  bool get isClosingSoon {
    return daysUntilDeadline <= 7 &&
        daysUntilDeadline >= 0 &&
        status == 'active';
  }

  /// Check if target is active
  bool get isActive => status == 'active' || status == 'closing_soon';

  /// Check if target is fully funded (based on display amount)
  bool get isFullyFunded => displayAmount >= targetAmount;

  /// Get shortfall amount based on display amount (if not fully funded)
  double get shortfall {
    final diff = targetAmount - displayAmount;
    return diff > 0 ? diff : 0;
  }

  /// Get excess amount based on display amount (if over-funded)
  double get excess {
    final diff = displayAmount - targetAmount;
    return diff > 0 ? diff : 0;
  }

  /// Get formatted month-year string (e.g., "Mei 2026")
  String get monthYearDisplay {
    final monthCapitalized = month[0].toUpperCase() + month.substring(1);
    return '$monthCapitalized $year';
  }

  /// Get formatted deadline with month-year (e.g., "8 February 2026")
  String get monthYearWithDeadlineDisplay {
    final monthCapitalized = month[0].toUpperCase() + month.substring(1);
    return '${deadline.day} $monthCapitalized $year';
  }

  /// Get earliest graduation date
  DateTime? get earliestGraduationDate {
    if (graduates.isEmpty) return null;
    return graduates.map((g) => g.date).reduce(
          (a, b) => a.isBefore(b) ? a : b,
        );
  }

  /// Create copy with modified fields
  GraduationTarget copyWith({
    String? id,
    String? month,
    int? year,
    List<Graduate>? graduates,
    double? targetAmount,
    double? currentAmount,
    double? allocatedFromFund,
    DateTime? deadline,
    String? status,
    DateTime? openDate,
    DateTime? closedDate,
    Distribution? distribution,
    String? distributionProofUrl,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
  }) {
    return GraduationTarget(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      graduates: graduates ?? this.graduates,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      allocatedFromFund: allocatedFromFund ?? this.allocatedFromFund,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      openDate: openDate ?? this.openDate,
      closedDate: closedDate ?? this.closedDate,
      distribution: distribution ?? this.distribution,
      distributionProofUrl: distributionProofUrl ?? this.distributionProofUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'GraduationTarget(id: $id, month: $month, year: $year, status: $status)';

  /// Helper method to convert month name to number
  static int _getMonthNumber(String monthName) {
    const monthMap = {
      'Januari': 1,
      'Februari': 2,
      'Maret': 3,
      'April': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
    };
    return monthMap[monthName] ?? 1;
  }
}
