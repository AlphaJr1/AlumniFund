import 'package:cloud_firestore/cloud_firestore.dart';

class BrandIdea {
  final String userId;
  final String title;
  final String philosophy;
  final String submittedByName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BrandIdea({
    required this.userId,
    required this.title,
    required this.philosophy,
    required this.submittedByName,
    required this.createdAt,
    this.updatedAt,
  });

  factory BrandIdea.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BrandIdea(
      userId: doc.id,
      title: data['title'] ?? '',
      philosophy: data['philosophy'] ?? '',
      submittedByName: data['submittedByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'philosophy': philosophy,
      'submittedByName': submittedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  BrandIdea copyWith({
    String? userId,
    String? title,
    String? philosophy,
    String? submittedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandIdea(
      userId: userId ?? this.userId,
      title: title ?? this.title,
      philosophy: philosophy ?? this.philosophy,
      submittedByName: submittedByName ?? this.submittedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
