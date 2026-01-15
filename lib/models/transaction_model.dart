import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum untuk tipe transaksi
enum TransactionType {
  income,  // Pemasukan
  expense, // Pengeluaran
}

/// Metadata untuk transaksi
class TransactionMetadata {
  final String? submittedBy;
  final String? submissionMethod; // "web" | "whatsapp" | "admin_direct"
  final String? ipAddress;
  final String? submitterName;

  const TransactionMetadata({
    this.submittedBy,
    this.submissionMethod,
    this.ipAddress,
    this.submitterName,
  });

  factory TransactionMetadata.fromMap(Map<String, dynamic> map) {
    return TransactionMetadata(
      submittedBy: map['submitted_by'] as String?,
      submissionMethod: map['submission_method'] as String?,
      ipAddress: map['ip_address'] as String?,
      submitterName: map['submitter_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'submitted_by': submittedBy,
      'submission_method': submissionMethod,
      'ip_address': ipAddress,
      'submitter_name': submitterName,
    };
  }
}

/// Model untuk transaksi (income & expense)
class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String? targetId; // "mei_2026" | "general_fund" | null
  final String? targetMonth; // "mei 2026" (for display)
  final String? category; // Hanya untuk expense: "wisuda" | "community" | "operational" | "others"
  final String description;
  final String? proofUrl; // URL bukti transaksi dari Firebase Storage
  final bool validated; // true for approved income, always true for expense
  final String? validationStatus; // "pending" | "approved" | "rejected" (income only)
  final DateTime createdAt; // Actual transaction time
  final DateTime inputAt; // When admin input to system
  final String createdBy; // Email admin yang input
  final TransactionMetadata? metadata;
  
  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.targetId,
    this.targetMonth,
    this.category,
    required this.description,
    this.proofUrl,
    this.validated = true,
    this.validationStatus,
    required this.createdAt,
    required this.inputAt,
    required this.createdBy,
    this.metadata,
  });
  
  /// Convert dari Firestore DocumentSnapshot ke TransactionModel
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TransactionModel(
      id: doc.id,
      type: data['type'] == 'income' 
          ? TransactionType.income 
          : TransactionType.expense,
      amount: (data['amount'] as num).toDouble(),
      targetId: data['target_id'] as String?,
      targetMonth: data['target_month'] as String?,
      category: data['category'] as String?,
      description: data['description'] as String? ?? '',
      proofUrl: data['proof_url'] as String?,
      validated: data['validated'] as bool? ?? true,
      validationStatus: data['validation_status'] as String?,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      inputAt: data['input_at'] != null
          ? (data['input_at'] as Timestamp).toDate()
          : (data['created_at'] as Timestamp).toDate(),
      createdBy: data['created_by'] as String? ?? '',
      metadata: data['metadata'] != null
          ? TransactionMetadata.fromMap(data['metadata'] as Map<String, dynamic>)
          : null,
    );
  }
  
  /// Convert TransactionModel ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'type': type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'target_id': targetId,
      'target_month': targetMonth,
      'category': category,
      'description': description,
      'proof_url': proofUrl,
      'validated': validated,
      'validation_status': validationStatus,
      'created_at': Timestamp.fromDate(createdAt),
      'input_at': Timestamp.fromDate(inputAt),
      'created_by': createdBy,
      'metadata': metadata?.toMap(),
    };
  }

  /// Get relative time in Indonesian
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months bulan lalu';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years tahun lalu';
    }
  }

  /// Get category icon for expense
  String get categoryIcon {
    if (type == TransactionType.income) return '💰';
    
    switch (category) {
      case 'wisuda':
        return '🎓';
      case 'community':
        return '🍕';
      case 'operational':
        return '⚙️';
      default:
        return '📦';
    }
  }

  /// Check if transaction is income
  bool get isIncome => type == TransactionType.income;

  /// Check if transaction is expense
  bool get isExpense => type == TransactionType.expense;
  
  /// Copy with method untuk immutable updates
  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? targetId,
    String? targetMonth,
    String? category,
    String? description,
    String? proofUrl,
    bool? validated,
    String? validationStatus,
    DateTime? createdAt,
    DateTime? inputAt,
    String? createdBy,
    TransactionMetadata? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      targetId: targetId ?? this.targetId,
      targetMonth: targetMonth ?? this.targetMonth,
      category: category ?? this.category,
      description: description ?? this.description,
      proofUrl: proofUrl ?? this.proofUrl,
      validated: validated ?? this.validated,
      validationStatus: validationStatus ?? this.validationStatus,
      createdAt: createdAt ?? this.createdAt,
      inputAt: inputAt ?? this.inputAt,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'TransactionModel(id: $id, type: $type, amount: $amount)';
}
