import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for general fund (Dompet Bersama)
/// Tracks the community's shared fund balance and statistics
class GeneralFund {
  final double balance;
  final DateTime lastUpdated;
  final String? lastTransactionId;
  final double totalIncome;
  final double totalExpense;
  final int transactionCount;

  const GeneralFund({
    required this.balance,
    required this.lastUpdated,
    this.lastTransactionId,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactionCount,
  });

  /// Create empty GeneralFund
  factory GeneralFund.empty() {
    return GeneralFund(
      balance: 0,
      lastUpdated: DateTime.now(),
      lastTransactionId: null,
      totalIncome: 0,
      totalExpense: 0,
      transactionCount: 0,
    );
  }

  /// Create GeneralFund from Firestore document
  factory GeneralFund.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return GeneralFund.empty();
    }

    final data = doc.data() as Map<String, dynamic>;
    
    return GeneralFund(
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      lastUpdated: data['last_updated'] != null
          ? (data['last_updated'] as Timestamp).toDate()
          : DateTime.now(),
      lastTransactionId: data['last_transaction_id'] as String?,
      totalIncome: (data['total_income'] as num?)?.toDouble() ?? 0,
      totalExpense: (data['total_expense'] as num?)?.toDouble() ?? 0,
      transactionCount: (data['transaction_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert GeneralFund to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'balance': balance,
      'last_updated': Timestamp.fromDate(lastUpdated),
      'last_transaction_id': lastTransactionId,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'transaction_count': transactionCount,
    };
  }

  /// Check if fund has balance
  bool get hasBalance => balance > 0;

  /// Get net amount (total income - total expense)
  double get netAmount => totalIncome - totalExpense;

  /// Create copy with modified fields
  GeneralFund copyWith({
    double? balance,
    DateTime? lastUpdated,
    String? lastTransactionId,
    double? totalIncome,
    double? totalExpense,
    int? transactionCount,
  }) {
    return GeneralFund(
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }

  @override
  String toString() => 'GeneralFund(balance: $balance, transactionCount: $transactionCount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneralFund &&
        other.balance == balance &&
        other.lastUpdated == lastUpdated &&
        other.lastTransactionId == lastTransactionId &&
        other.totalIncome == totalIncome &&
        other.totalExpense == totalExpense &&
        other.transactionCount == transactionCount;
  }

  @override
  int get hashCode => Object.hash(
        balance,
        lastUpdated,
        lastTransactionId,
        totalIncome,
        totalExpense,
        transactionCount,
      );
}
