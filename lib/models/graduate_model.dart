import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for graduate information
/// Represents a single graduate in a graduation target
class Graduate {
  final String name;
  final DateTime date;
  final String location;

  const Graduate({
    required this.name,
    required this.date,
    required this.location,
  });

  /// Create Graduate from Firestore map
  factory Graduate.fromMap(Map<String, dynamic> map) {
    return Graduate(
      name: map['name'] as String,
      date: (map['date'] as Timestamp).toDate(),
      location: map['location'] as String,
    );
  }

  /// Convert Graduate to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'location': location,
    };
  }

  /// Create copy with modified fields
  Graduate copyWith({
    String? name,
    DateTime? date,
    String? location,
  }) {
    return Graduate(
      name: name ?? this.name,
      date: date ?? this.date,
      location: location ?? this.location,
    );
  }

  @override
  String toString() => 'Graduate(name: $name, date: $date, location: $location)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Graduate &&
        other.name == name &&
        other.date == date &&
        other.location == location;
  }

  @override
  int get hashCode => Object.hash(name, date, location);
}
