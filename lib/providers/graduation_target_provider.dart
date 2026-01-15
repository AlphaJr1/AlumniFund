import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/graduation_target_model.dart';
import '../utils/constants.dart';

/// Provider untuk graduation targets stream (realtime)
/// Note: Removed orderBy to avoid composite index requirement
final graduationTargetsProvider = StreamProvider<List<GraduationTarget>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.graduationTargets)
      .snapshots()
      .map((snapshot) {
        final targets = <GraduationTarget>[];
        for (var doc in snapshot.docs) {
          try {
            targets.add(GraduationTarget.fromFirestore(doc));
          } catch (e) {
            // Skip corrupt targets (e.g., null timestamps)
            print('Skipping corrupt target ${doc.id}: $e');
          }
        }
        return targets;
      });
});

/// Provider untuk active graduation target
final activeTargetProvider = Provider<GraduationTarget?>((ref) {
  final targetsAsync = ref.watch(graduationTargetsProvider);
  
  return targetsAsync.when(
    data: (targets) {
      try {
        return targets.firstWhere((t) => t.isActive);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider untuk target by ID
final targetByIdProvider = Provider.family<GraduationTarget?, String>((ref, id) {
  final targetsAsync = ref.watch(graduationTargetsProvider);
  
  return targetsAsync.when(
    data: (targets) {
      try {
        return targets.firstWhere((t) => t.id == id);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider untuk upcoming targets (status = upcoming, sorted)
final upcomingTargetsProvider = Provider<List<GraduationTarget>>((ref) {
  final targetsAsync = ref.watch(graduationTargetsProvider);
  
  return targetsAsync.when(
    data: (targets) {
      final upcoming = targets.where((t) => t.status == 'upcoming').toList();
      
      // Sort by year, then month
      upcoming.sort((a, b) {
        if (a.year != b.year) return a.year.compareTo(b.year);
        return _getMonthNumber(a.month).compareTo(_getMonthNumber(b.month));
      });
      
      return upcoming;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider untuk archived targets (status = closed or archived)
final archivedTargetsProvider = Provider<List<GraduationTarget>>((ref) {
  final targetsAsync = ref.watch(graduationTargetsProvider);
  
  return targetsAsync.when(
    data: (targets) {
      final archived = targets
          .where((t) => t.status == 'closed' || t.status == 'archived')
          .toList();
      
      // Sort by closed date descending (newest first)
      archived.sort((a, b) {
        if (a.closedDate == null && b.closedDate == null) return 0;
        if (a.closedDate == null) return 1;
        if (b.closedDate == null) return -1;
        return b.closedDate!.compareTo(a.closedDate!);
      });
      
      return archived;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Helper to get month number from Indonesian month name
int _getMonthNumber(String month) {
  const months = {
    'januari': 1,
    'februari': 2,
    'maret': 3,
    'april': 4,
    'mei': 5,
    'juni': 6,
    'juli': 7,
    'agustus': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'desember': 12,
  };
  return months[month.toLowerCase()] ?? 1;
}
