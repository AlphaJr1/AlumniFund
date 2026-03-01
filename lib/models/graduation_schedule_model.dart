import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk data jadwal wisuda alumni
class GraduationSchedule {
  final String id;
  final String userId;
  final String name;
  final String major;
  final String campus;
  final DateTime graduationDate;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GraduationSchedule({
    required this.id,
    required this.userId,
    required this.name,
    required this.major,
    required this.campus,
    required this.graduationDate,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GraduationSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GraduationSchedule(
      id: doc.id,
      userId: data['user_id'] as String,
      name: data['name'] as String,
      major: data['major'] as String,
      campus: data['campus'] as String,
      graduationDate: (data['graduation_date'] as Timestamp).toDate(),
      location: data['location'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'major': major,
      'campus': campus,
      'graduation_date': Timestamp.fromDate(graduationDate),
      'location': location,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  GraduationSchedule copyWith({
    String? name,
    String? major,
    String? campus,
    DateTime? graduationDate,
    String? location,
    DateTime? updatedAt,
  }) {
    return GraduationSchedule(
      id: id,
      userId: userId,
      name: name ?? this.name,
      major: major ?? this.major,
      campus: campus ?? this.campus,
      graduationDate: graduationDate ?? this.graduationDate,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
