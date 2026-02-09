import 'package:cloud_firestore/cloud_firestore.dart';

enum BrandSeasonPhase {
  input,
  voting,
  result,
  closed;

  String toFirestore() => name;

  static BrandSeasonPhase fromFirestore(String value) {
    return BrandSeasonPhase.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BrandSeasonPhase.closed,
    );
  }
}

class BrandSeason {
  final BrandSeasonPhase phase;
  final DateTime? inputDeadline;
  final DateTime? votingDeadline;
  final String? winnerId;

  BrandSeason({
    required this.phase,
    this.inputDeadline,
    this.votingDeadline,
    this.winnerId,
  });

  factory BrandSeason.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return BrandSeason(phase: BrandSeasonPhase.closed);
    }

    return BrandSeason.fromMap(data);
  }

  factory BrandSeason.fromMap(Map<String, dynamic> data) {
    return BrandSeason(
      phase: BrandSeasonPhase.fromFirestore(data['phase'] ?? 'closed'),
      inputDeadline: data['inputDeadline'] != null
          ? (data['inputDeadline'] as Timestamp).toDate()
          : null,
      votingDeadline: data['votingDeadline'] != null
          ? (data['votingDeadline'] as Timestamp).toDate()
          : null,
      winnerId: data['winnerId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phase': phase.toFirestore(),
      if (inputDeadline != null)
        'inputDeadline': Timestamp.fromDate(inputDeadline!),
      if (votingDeadline != null)
        'votingDeadline': Timestamp.fromDate(votingDeadline!),
      if (winnerId != null) 'winnerId': winnerId,
    };
  }

  bool get isInputOpen => phase == BrandSeasonPhase.input;
  bool get isVotingOpen => phase == BrandSeasonPhase.voting;
  bool get isClosed => phase == BrandSeasonPhase.closed;

  BrandSeason copyWith({
    BrandSeasonPhase? phase,
    DateTime? inputDeadline,
    DateTime? votingDeadline,
    String? winnerId,
  }) {
    return BrandSeason(
      phase: phase ?? this.phase,
      inputDeadline: inputDeadline ?? this.inputDeadline,
      votingDeadline: votingDeadline ?? this.votingDeadline,
      winnerId: winnerId ?? this.winnerId,
    );
  }
}
