import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand_vote_model.dart';
import '../services/brand_vote_service.dart';

final brandVoteServiceProvider = Provider<BrandVoteService>((ref) {
  return BrandVoteService();
});

/// Stream semua votes (realtime)
final allVotesProvider = StreamProvider<List<BrandVote>>((ref) {
  final service = ref.watch(brandVoteServiceProvider);
  return service.watchAllVotes();
});

/// Stream vote user tertentu (realtime)
final userVoteProvider =
    StreamProvider.family<BrandVote?, String>((ref, userId) {
  final service = ref.watch(brandVoteServiceProvider);
  return service.watchUserVote(userId);
});
