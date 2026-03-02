import 'package:cloud_firestore/cloud_firestore.dart';

class BrandVote {
  final String userId;
  final String votedForIdeaId; // userId dari idea yang dipilih (doc id di brand_ideas)
  final String votedForTitle;  // judul idea yang dipilih
  final String voterName;
  final DateTime votedAt;

  BrandVote({
    required this.userId,
    required this.votedForIdeaId,
    required this.votedForTitle,
    required this.voterName,
    required this.votedAt,
  });

  factory BrandVote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BrandVote(
      userId: doc.id,
      votedForIdeaId: data['votedForIdeaId'] ?? '',
      votedForTitle: data['votedForTitle'] ?? '',
      voterName: data['voterName'] ?? '',
      votedAt: (data['votedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'votedForIdeaId': votedForIdeaId,
      'votedForTitle': votedForTitle,
      'voterName': voterName,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }
}
