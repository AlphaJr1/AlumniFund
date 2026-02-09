import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand_idea_model.dart';
import '../models/brand_season_model.dart';
import '../services/brand_identity_service.dart';

// Service provider
final brandIdentityServiceProvider = Provider<BrandIdentityService>((ref) {
  return BrandIdentityService();
});

// Current season stream
final currentSeasonProvider = StreamProvider<BrandSeason>((ref) {
  final service = ref.watch(brandIdentityServiceProvider);
  return service.getCurrentSeasonStream();
});

// User's idea provider - cached per userId
final brandIdentityProvider =
    FutureProvider.family<BrandIdea?, String>((ref, userId) async {
  final service = ref.watch(brandIdentityServiceProvider);
  return await service.getUserIdea(userId);
});

// All ideas stream (for admin)
final allIdeasProvider = StreamProvider<List<BrandIdea>>((ref) {
  final service = ref.watch(brandIdentityServiceProvider);
  return service.getAllIdeasStream();
});

// Ideas count provider
final ideasCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(brandIdentityServiceProvider);
  return await service.getIdeasCount();
});
