import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brand_idea_model.dart';
import '../models/brand_season_model.dart';

class BrandIdentityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _ideasCollection =>
      _firestore.collection('brand_ideas');
  DocumentReference get _seasonDoc =>
      _firestore.collection('brand_seasons').doc('current');

  // ==================== BRAND IDEAS ====================

  /// Get user's idea (if exists)
  Future<BrandIdea?> getUserIdea(String userId) async {
    try {
      final doc = await _ideasCollection.doc(userId).get();
      if (!doc.exists) return null;
      return BrandIdea.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user idea: $e');
    }
  }

  /// Watch user's idea (real-time stream)
  Stream<BrandIdea?> watchUserIdea(String userId) {
    return _ideasCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BrandIdea.fromFirestore(doc);
    });
  }

  /// Submit new idea
  Future<void> submitIdea({
    required String userId,
    required String title,
    required String philosophy,
    required String submittedByName,
  }) async {
    try {
      // Check if title already exists (by other users)
      final existingTitles = await _ideasCollection
          .where('title', isEqualTo: title)
          .get();

      if (existingTitles.docs.isNotEmpty &&
          existingTitles.docs.first.id != userId) {
        throw Exception('This brand name is already taken by another user');
      }

      final idea = BrandIdea(
        userId: userId,
        title: title,
        philosophy: philosophy,
        submittedByName: submittedByName,
        createdAt: DateTime.now(),
      );

      await _ideasCollection.doc(userId).set(idea.toFirestore());
    } catch (e) {
      throw Exception('Failed to submit idea: $e');
    }
  }

  /// Update existing idea
  Future<void> updateIdea({
    required String userId,
    required String title,
    required String philosophy,
    required String submittedByName,
  }) async {
    try {
      // Check if new title already exists (by other users)
      final existingTitles = await _ideasCollection
          .where('title', isEqualTo: title)
          .get();

      if (existingTitles.docs.isNotEmpty &&
          existingTitles.docs.first.id != userId) {
        throw Exception('This brand name is already taken by another user');
      }

      final updates = {
        'title': title,
        'philosophy': philosophy,
        'submittedByName': submittedByName,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _ideasCollection.doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update idea: $e');
    }
  }

  /// Get all ideas (for admin)
  Stream<List<BrandIdea>> getAllIdeasStream() {
    return _ideasCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BrandIdea.fromFirestore(doc)).toList());
  }

  /// Delete idea (admin only)
  Future<void> deleteIdea(String userId) async {
    try {
      await _ideasCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete idea: $e');
    }
  }

  // ==================== BRAND SEASON ====================

  /// Get current season
  Future<BrandSeason> getCurrentSeason() async {
    try {
      final doc = await _seasonDoc.get();
      if (!doc.exists) {
        // Return default closed season
        return BrandSeason(phase: BrandSeasonPhase.closed);
      }
      return BrandSeason.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get current season: $e');
    }
  }

  /// Get current season stream
  Stream<BrandSeason> getCurrentSeasonStream() {
    return _seasonDoc.snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists) {
        // Auto-create default season if not exists
        final defaultSeason = BrandSeason(
          phase: BrandSeasonPhase.input,
          inputDeadline: DateTime.now().add(const Duration(days: 30)),
        );
        await _seasonDoc.set(defaultSeason.toFirestore());
        return defaultSeason;
      }
      return BrandSeason.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  /// Update season (admin only)
  Future<void> updateSeason(BrandSeason season) async {
    try {
      await _seasonDoc.set(season.toFirestore());
    } catch (e) {
      throw Exception('Failed to update season: $e');
    }
  }

  /// Set input deadline (admin only)
  Future<void> setInputDeadline(DateTime deadline) async {
    try {
      // Get all brand_seasons documents
      final seasonsSnapshot = await _firestore
          .collection('brand_seasons')
          .get();
      
      if (seasonsSnapshot.docs.isEmpty) {
        // No seasons exist, create one
        await _firestore.collection('brand_seasons').add({
          'phase': BrandSeasonPhase.input.toFirestore(),
          'inputDeadline': Timestamp.fromDate(deadline),
          'isActive': true,
        });
      } else {
        // Update all existing seasons
        for (var doc in seasonsSnapshot.docs) {
          await doc.reference.update({
            'phase': BrandSeasonPhase.input.toFirestore(),
            'inputDeadline': Timestamp.fromDate(deadline),
            'isActive': true,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to set input deadline: $e');
    }
  }

  /// Create new brand season (admin only)
  Future<void> createNewSeason(DateTime inputDeadline) async {
    try {
      // First, close any existing active seasons
      final existingSeasons = await _firestore
          .collection('brand_seasons')
          .where('isActive', isEqualTo: true)
          .get();
      
      for (var doc in existingSeasons.docs) {
        await doc.reference.update({'isActive': false});
      }

      // Create new season
      final newSeason = BrandSeason(
        phase: BrandSeasonPhase.input,
        inputDeadline: inputDeadline,
      );

      await _firestore.collection('brand_seasons').add({
        ...newSeason.toFirestore(),
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Failed to create new season: $e');
    }
  }

  /// Close input phase (admin only)
  Future<void> closeInputPhase() async {
    try {
      await _seasonDoc.update({
        'phase': BrandSeasonPhase.closed.toFirestore(),
      });
    } catch (e) {
      throw Exception('Failed to close input phase: $e');
    }
  }

  /// Get total ideas count
  Future<int> getIdeasCount() async {
    try {
      final snapshot = await _ideasCollection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
