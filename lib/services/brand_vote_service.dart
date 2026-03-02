import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brand_vote_model.dart';

class BrandVoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _votesCollection =>
      _firestore.collection('brand_votes');

  /// Cek apakah user sudah vote
  Future<BrandVote?> getUserVote(String userId) async {
    final doc = await _votesCollection.doc(userId).get();
    if (!doc.exists) return null;
    return BrandVote.fromFirestore(doc);
  }

  /// Stream user vote (realtime)
  Stream<BrandVote?> watchUserVote(String userId) {
    return _votesCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BrandVote.fromFirestore(doc);
    });
  }

  /// Stream semua votes (realtime) - untuk hasil persentase
  Stream<List<BrandVote>> watchAllVotes() {
    return _votesCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => BrandVote.fromFirestore(doc))
              .toList(),
        );
  }

  /// Submit vote (sekali saja, doc id = userId)
  Future<void> submitVote({
    required String userId,
    required String votedForIdeaId,
    required String votedForTitle,
    required String voterName,
  }) async {
    final existing = await getUserVote(userId);
    if (existing != null) {
      throw Exception('You have already voted. Each user can only vote once.');
    }

    final vote = BrandVote(
      userId: userId,
      votedForIdeaId: votedForIdeaId,
      votedForTitle: votedForTitle,
      voterName: voterName,
      votedAt: DateTime.now(),
    );

    await _votesCollection.doc(userId).set(vote.toFirestore());
  }

  /// Hapus vote user (admin only — user bisa vote ulang setelah ini)
  Future<void> deleteVote(String userId) async {
    await _votesCollection.doc(userId).delete();
  }

  /// Hitung persentase per kandidat dari list votes
  Map<String, _VoteCount> calculateResults(List<BrandVote> votes) {
    final Map<String, _VoteCount> result = {};
    for (final vote in votes) {
      if (result.containsKey(vote.votedForIdeaId)) {
        result[vote.votedForIdeaId]!.count++;
        result[vote.votedForIdeaId]!.voters.add(vote.voterName);
      } else {
        result[vote.votedForIdeaId] = _VoteCount(
          ideaId: vote.votedForIdeaId,
          title: vote.votedForTitle,
          count: 1,
          voters: [vote.voterName],
        );
      }
    }
    return result;
  }
}

class _VoteCount {
  final String ideaId;
  final String title;
  int count;
  List<String> voters;

  _VoteCount({
    required this.ideaId,
    required this.title,
    required this.count,
    required this.voters,
  });
}

class VoteResult {
  final String ideaId;
  final String title;
  final int count;
  final double percentage;
  final List<String> voters;

  VoteResult({
    required this.ideaId,
    required this.title,
    required this.count,
    required this.percentage,
    required this.voters,
  });
}

/// Helper: hitung VoteResult dari list BrandVote
List<VoteResult> computeVoteResults(List<BrandVote> votes) {
  final Map<String, VoteResult> map = {};
  final total = votes.length;

  for (final vote in votes) {
    if (map.containsKey(vote.votedForIdeaId)) {
      final old = map[vote.votedForIdeaId]!;
      map[vote.votedForIdeaId] = VoteResult(
        ideaId: old.ideaId,
        title: old.title,
        count: old.count + 1,
        percentage: 0, // dihitung ulang di bawah
        voters: [...old.voters, vote.voterName],
      );
    } else {
      map[vote.votedForIdeaId] = VoteResult(
        ideaId: vote.votedForIdeaId,
        title: vote.votedForTitle,
        count: 1,
        percentage: 0,
        voters: [vote.voterName],
      );
    }
  }

  if (total == 0) return [];

  return map.values.map((r) {
    return VoteResult(
      ideaId: r.ideaId,
      title: r.title,
      count: r.count,
      percentage: r.count / total * 100,
      voters: r.voters,
    );
  }).toList()
    ..sort((a, b) => b.count.compareTo(a.count));
}
