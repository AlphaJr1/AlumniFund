import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/graduation_target_model.dart';
import '../models/graduate_model.dart';
import '../models/settings_model.dart';

/// Service untuk handle graduation target operations
class TargetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get month number from Indonesian month name
  int _getMonthNumber(String month) {
    const months = {
      // English (primary)
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4, // Same spelling in both English & Indonesian
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9, // Same spelling in both English & Indonesian  
      'october': 10,
      'november': 11, // Same spelling in both English & Indonesian
      'december': 12,
      // Indonesian (backward compatibility - only different spellings)
      'januari': 1,
      'februari': 2,
      'maret': 3,
      'mei': 5,
      'juni': 6,
      'juli': 7,
      'agustus': 8,
      'oktober': 10,
      'desember': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }

  /// Get settings
  Future<SystemConfig> _getSettings() async {
    final doc = await _firestore.collection('settings').doc('app_config').get();
    if (!doc.exists) {
      // Return default system config
      return SystemConfig.defaults();
    }
    final appSettings = AppSettings.fromFirestore(doc);
    return appSettings.systemConfig;
  }

  /// Check if target exists for month/year (only upcoming or active)
  Future<GraduationTarget?> _checkExistingTarget(String month, int year) async {
    final snapshot = await _firestore
        .collection('graduation_targets')
        .where('month', isEqualTo: month.toLowerCase())
        .where('year', isEqualTo: year)
        .get();

    if (snapshot.docs.isEmpty) return null;
    
    // Filter to only upcoming or active targets (exclude closed/archived)
    final targets = snapshot.docs
        .map((doc) => GraduationTarget.fromFirestore(doc))
        .where((target) => target.status == 'upcoming' || target.status == 'active')
        .toList();
    
    if (targets.isEmpty) return null;
    return targets.first;
  }

  /// Get target by ID
  Future<GraduationTarget> _getTarget(String targetId) async {
    final doc = await _firestore.collection('graduation_targets').doc(targetId).get();
    if (!doc.exists) {
      throw Exception('Target tidak ditemukan');
    }
    return GraduationTarget.fromFirestore(doc);
  }

  /// Get active target
  Future<GraduationTarget?> _getActiveTarget() async {
    final snapshot = await _firestore
        .collection('graduation_targets')
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return GraduationTarget.fromFirestore(snapshot.docs.first);
  }

  /// Get upcoming targets sorted by year, month
  Future<List<GraduationTarget>> _getUpcomingTargets() async {
    final snapshot = await _firestore
        .collection('graduation_targets')
        .where('status', isEqualTo: 'upcoming')
        .get();

    final targets = snapshot.docs
        .map((doc) => GraduationTarget.fromFirestore(doc))
        .toList();

    // Sort by year, then month
    targets.sort((a, b) {
      if (a.year != b.year) return a.year.compareTo(b.year);
      return _getMonthNumber(a.month).compareTo(_getMonthNumber(b.month));
    });

    return targets;
  }

  /// Activate next upcoming target
  Future<void> _activateNextTarget() async {
    final upcomingTargets = await _getUpcomingTargets();
    
    if (upcomingTargets.isEmpty) return;
    
    // Activate first upcoming target
    final nextTarget = upcomingTargets.first;
    await _firestore.collection('graduation_targets').doc(nextTarget.id).update({
      'status': 'active',
      'open_date': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Create new graduation target
  Future<String> createTarget({
    required String month,
    required int year,
    required List<Graduate> graduates,
    required String createdBy,
  }) async {
    try {
      // 1. Validate no duplicate month/year
      final existing = await _checkExistingTarget(month, year);
      if (existing != null) {
        throw Exception('Target untuk $month $year sudah ada');
      }

      // 2. Get settings
      final settings = await _getSettings();
      final perPersonAllocation = settings.perPersonAllocation;
      final deadlineOffset = settings.deadlineOffsetDays;

      // 3. Calculate target amount
      final targetAmount = graduates.length * perPersonAllocation;

      // 4. Calculate deadline (H-3 from earliest graduate date)
      // Find earliest graduation date
      graduates.sort((a, b) => a.date.compareTo(b.date));
      final earliestDate = graduates.first.date;
      
      // Deadline = earliest date - offset days
      final deadline = earliestDate.subtract(Duration(days: deadlineOffset));

      // 5. Check if there's currently an active target
      // If no active target exists, make this target active immediately
      final activeTarget = await _getActiveTarget();
      final status = activeTarget == null ? 'active' : 'upcoming';
      final openDate = activeTarget == null ? FieldValue.serverTimestamp() : null;

      // 6. Create target document
      final targetRef = _firestore.collection('graduation_targets').doc();
      await targetRef.set({
        'month': month.toLowerCase(),
        'year': year,
        'graduates': graduates.map((g) => g.toMap()).toList(),
        'target_amount': targetAmount,
        'current_amount': 0.0,
        'allocated_from_fund': 0.0, // Initialize virtual allocation
        'deadline': Timestamp.fromDate(deadline),
        'status': status, // Dynamic: 'active' if no active target, else 'upcoming'
        'open_date': openDate, // Set timestamp if becoming active
        'closed_date': null,
        'distribution': {
          'status': 'pending',
          'distributed_at': null,
          'per_person': perPersonAllocation,
          'total_distributed': 0.0,
        },
        'created_at': FieldValue.serverTimestamp(),
        'created_by': createdBy,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return targetRef.id;
    } catch (e) {
      throw Exception('Gagal membuat target: ${e.toString()}');
    }
  }

  /// Create multiple targets from graduates (auto-split by month/year)
  /// This allows flexible multi-month target creation
  Future<Map<String, dynamic>> createTargetsFromGraduates({
    required List<Graduate> graduates,
    required String createdBy,
  }) async {
    try {
      if (graduates.isEmpty) {
        throw Exception('Minimal 1 wisudawan diperlukan');
      }

      // 1. Group graduates by month/year
      final Map<String, List<Graduate>> groupedByMonth = {};
      
      for (var graduate in graduates) {
        final month = getMonthName(graduate.date.month).toLowerCase();
        final year = graduate.date.year;
        final monthKey = '${month}_$year';
        
        if (!groupedByMonth.containsKey(monthKey)) {
          groupedByMonth[monthKey] = [];
        }
        groupedByMonth[monthKey]!.add(graduate);
      }

      // 2. Create/update target for each month
      final List<String> createdTargetIds = [];
      final List<String> updatedTargetIds = [];
      final List<String> targetNames = [];
      
      for (var entry in groupedByMonth.entries) {
        final parts = entry.key.split('_');
        final month = parts[0];
        final year = int.parse(parts[1]);
        final monthGraduates = entry.value;
        
        // Check if target exists
        final existing = await _checkExistingTarget(month, year);
        
        if (existing != null) {
          // Merge with existing target (manually merge then replace)
          final existingGraduates = existing.graduates;
          final allGraduates = [...existingGraduates, ...monthGraduates];
          
          // Remove duplicates by name (case-insensitive)
          final uniqueGraduates = <Graduate>[];
          final seenNames = <String>{};
          for (var grad in allGraduates) {
            final nameLower = grad.name.toLowerCase();
            if (!seenNames.contains(nameLower)) {
              seenNames.add(nameLower);
              uniqueGraduates.add(grad);
            }
          }
          
          // Use replaceGraduates to avoid double-append
          await replaceGraduates(
            targetId: existing.id,
            graduates: uniqueGraduates,
          );
          updatedTargetIds.add(existing.id);
          targetNames.add('${getMonthName(_getMonthNumber(month))} $year');
        } else {
          // Create new target
          final targetId = await createTarget(
            month: month,
            year: year,
            graduates: monthGraduates,
            createdBy: createdBy,
          );
          createdTargetIds.add(targetId);
          targetNames.add('${getMonthName(_getMonthNumber(month))} $year');
        }
      }

      return {
        'created': createdTargetIds,
        'updated': updatedTargetIds,
        'targetNames': targetNames,
        'totalTargets': createdTargetIds.length + updatedTargetIds.length,
      };
    } catch (e) {
      throw Exception('Gagal membuat target: ${e.toString()}');
    }
  }

  /// Update target (only upcoming targets)
  Future<void> updateTarget({
    required String targetId,
    required List<Graduate> graduates,
  }) async {
    try {
      // 1. Get target
      final target = await _getTarget(targetId);

      // 2. Validate can edit (upcoming or active targets only, not closed)
      if (target.status != 'upcoming' && target.status != 'active') {
        throw Exception('Hanya target upcoming atau aktif yang bisa ditambahkan wisudawan');
      }

      // 3. APPEND new graduates to existing graduates (not replace)
      final existingGraduates = target.graduates;
      final allGraduates = [...existingGraduates, ...graduates];
      
      // Remove duplicates by name (case-insensitive)
      final uniqueGraduates = <Graduate>[];
      final seenNames = <String>{};
      for (var grad in allGraduates) {
        final nameLower = grad.name.toLowerCase();
        if (!seenNames.contains(nameLower)) {
          seenNames.add(nameLower);
          uniqueGraduates.add(grad);
        }
      }

      // 4. Recalculate target amount and deadline
      final settings = await _getSettings();
      final targetAmount = uniqueGraduates.length * settings.perPersonAllocation;
      
      // Recalculate deadline (H-3 from earliest graduate)
      uniqueGraduates.sort((a, b) => a.date.compareTo(b.date));
      final earliestDate = uniqueGraduates.first.date;
      final deadline = earliestDate.subtract(Duration(days: settings.deadlineOffsetDays));

      // 5. Update target
      await _firestore.collection('graduation_targets').doc(targetId).update({
        'graduates': uniqueGraduates.map((g) => g.toMap()).toList(),
        'target_amount': targetAmount,
        'deadline': Timestamp.fromDate(deadline),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal update target: ${e.toString()}');
    }
  }

  /// Replace graduates (for edit modal - smart version with movement detection)
  Future<void> replaceGraduates({
    required String targetId,
    required List<Graduate> graduates,
  }) async {
    try {
      // 1. Get current target
      final target = await _getTarget(targetId);

      // 2. Validate can edit
      if (target.status != 'upcoming' && target.status != 'active') {
        throw Exception('Hanya target upcoming atau aktif yang bisa diedit');
      }

      // 3. Group graduates by month/year
      final groupedGrads = _groupGraduatesByMonth(graduates);

      // 4. Determine action based on groups
      if (groupedGrads.length == 1) {
        // All graduates in same month
        final entry = groupedGrads.entries.first;
        final parts = entry.key.split(' ');
        final month = parts[0]; // "maret"
        final year = int.parse(parts[1]); // 2026

        if (month == target.month.toLowerCase() && year == target.year) {
          // Scenario 1: No month change - simple update
          await _simpleUpdateGraduates(targetId, graduates);
        } else {
          // Scenario 2: All moved to new month
          // Check if destination month already has a target
          final destTarget = await _checkExistingTarget(month, year);
          
          if (destTarget != null) {
            // Merge to existing target, then delete current
            await _mergeToTargetAndDelete(targetId, destTarget.id, graduates);
          } else {
            // No existing target - just update month/year
            await _updateTargetMonth(targetId, month, year, graduates);
          }
        }
      } else {
        // Scenario 3: Split across months - complex movement
        await _splitAndMoveGraduates(targetId, target, groupedGrads);
      }
    } catch (e) {
      throw Exception('Gagal update target: ${e.toString()}');
    }
  }

  /// Group graduates by month/year
  Map<String, List<Graduate>> _groupGraduatesByMonth(List<Graduate> graduates) {
    final groups = <String, List<Graduate>>{};

    for (var grad in graduates) {
      final month = getMonthName(grad.date.month).toLowerCase();
      final year = grad.date.year;
      final key = '$month $year'; // "maret 2026"

      groups.putIfAbsent(key, () => []).add(grad);
    }

    return groups;
  }

  /// Simple update (no month change)
  Future<void> _simpleUpdateGraduates(
    String targetId,
    List<Graduate> graduates,
  ) async {
    final settings = await _getSettings();
    final targetAmount = graduates.length * settings.perPersonAllocation;

    graduates.sort((a, b) => a.date.compareTo(b.date));
    final deadline = graduates.first.date.subtract(
      Duration(days: settings.deadlineOffsetDays),
    );

    await _firestore.collection('graduation_targets').doc(targetId).update({
      'graduates': graduates.map((g) => g.toMap()).toList(),
      'target_amount': targetAmount,
      'deadline': Timestamp.fromDate(deadline),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Update target month/year (all graduates moved together)
  Future<void> _updateTargetMonth(
    String targetId,
    String newMonth,
    int newYear,
    List<Graduate> graduates,
  ) async {
    final settings = await _getSettings();
    final targetAmount = graduates.length * settings.perPersonAllocation;

    graduates.sort((a, b) => a.date.compareTo(b.date));
    final deadline = graduates.first.date.subtract(
      Duration(days: settings.deadlineOffsetDays),
    );

    await _firestore.collection('graduation_targets').doc(targetId).update({
      'month': newMonth, // ✅ UPDATE MONTH
      'year': newYear, // ✅ UPDATE YEAR
      'graduates': graduates.map((g) => g.toMap()).toList(),
      'target_amount': targetAmount,
      'deadline': Timestamp.fromDate(deadline),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Merge graduates to existing target and delete source target
  Future<void> _mergeToTargetAndDelete(
    String sourceTargetId,
    String destTargetId,
    List<Graduate> graduatesToMerge,
  ) async {
    // 1. Get destination target
    final destTarget = await _getTarget(destTargetId);
    
    // 2. Merge graduates
    final updatedGrads = [...destTarget.graduates, ...graduatesToMerge];
    updatedGrads.sort((a, b) => a.date.compareTo(b.date));
    
    // 3. Recalculate target amount and deadline
    final settings = await _getSettings();
    final targetAmount = updatedGrads.length * settings.perPersonAllocation;
    final deadline = updatedGrads.first.date.subtract(
      Duration(days: settings.deadlineOffsetDays),
    );
    
    // 4. Use batch for atomic operation
    final batch = _firestore.batch();
    
    // Update destination target with merged graduates
    batch.update(
      _firestore.collection('graduation_targets').doc(destTargetId),
      {
        'graduates': updatedGrads.map((g) => g.toMap()).toList(),
        'target_amount': targetAmount,
        'deadline': Timestamp.fromDate(deadline),
        'updated_at': FieldValue.serverTimestamp(),
      },
    );
    
    // Delete source target
    batch.delete(
      _firestore.collection('graduation_targets').doc(sourceTargetId),
    );
    
    await batch.commit();
  }

  /// Split and move graduates across targets
  Future<void> _splitAndMoveGraduates(
    String currentTargetId,
    GraduationTarget currentTarget,
    Map<String, List<Graduate>> groupedGrads,
  ) async {
    final settings = await _getSettings();

    for (var entry in groupedGrads.entries) {
      final parts = entry.key.split(' ');
      final month = parts[0];
      final year = int.parse(parts[1]);
      final grads = entry.value;

      // Check if this is same as current target month
      if (month == currentTarget.month.toLowerCase() && year == currentTarget.year) {
        // Update current target with these graduates
        await _simpleUpdateGraduates(currentTargetId, grads);
        continue;
      }

      // Find existing target for this month/year
      final destTarget = await _checkExistingTarget(month, year);

      if (destTarget != null) {
        // Merge: Add to existing target
        final updatedGrads = [...destTarget.graduates, ...grads];
        updatedGrads.sort((a, b) => a.date.compareTo(b.date));
        
        final targetAmount = updatedGrads.length * settings.perPersonAllocation;
        final deadline = updatedGrads.first.date.subtract(
          Duration(days: settings.deadlineOffsetDays),
        );

        await _firestore.collection('graduation_targets').doc(destTarget.id).update({
          'graduates': updatedGrads.map((g) => g.toMap()).toList(),
          'target_amount': targetAmount,
          'deadline': Timestamp.fromDate(deadline),
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new target for this month
        await createTarget(
          month: month,
          year: year,
          graduates: grads,
          createdBy: 'admin', // TODO: Get actual user email
        );
      }
    }

    // Delete original target if it's not in the grouped grads
    final currentKey = '${currentTarget.month.toLowerCase()} ${currentTarget.year}';
    if (!groupedGrads.containsKey(currentKey)) {
      await _firestore.collection('graduation_targets').doc(currentTargetId).delete();
    }
  }

  /// Delete target (only upcoming targets)
  Future<void> deleteTarget(String targetId) async {
    try {
      // 1. Get target
      final target = await _getTarget(targetId);

      // 2. Validate can delete (only upcoming targets)
      if (target.status != 'upcoming') {
        throw Exception('Hanya target upcoming yang bisa dihapus');
      }

      // 3. Delete target
      await _firestore.collection('graduation_targets').doc(targetId).delete();
    } catch (e) {
      throw Exception('Gagal hapus target: ${e.toString()}');
    }
  }

  /// Close active target manually
  Future<void> closeTarget(String targetId) async {
    try {
      // 1. Get target
      final target = await _getTarget(targetId);

      // 2. Validate is active
      if (target.status != 'active') {
        throw Exception('Hanya target aktif yang bisa ditutup');
      }

      // 3. Close target
      await _firestore.collection('graduation_targets').doc(targetId).update({
        'status': 'closed',
        'closed_date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 4. Activate next upcoming target (if exists)
      await _activateNextTarget();
    } catch (e) {
      throw Exception('Gagal tutup target: ${e.toString()}');
    }
  }

  /// Check and activate targets (run on app load and after target creation)
  Future<void> checkAndActivateTargets() async {
    try {
      // 1. Get all targets (skip corrupt ones)
      final snapshot = await _firestore.collection('graduation_targets').get();
      final allTargets = <GraduationTarget>[];
      
      for (var doc in snapshot.docs) {
        try {
          allTargets.add(GraduationTarget.fromFirestore(doc));
        } catch (e) {
          // Skip corrupt targets (e.g., null timestamps)
          print('Skipping corrupt target ${doc.id}: $e');
        }
      }

      // 2. Get current active target
      final currentActive = allTargets.where((t) => t.status == 'active').toList();

      // 3. Check if active target deadline passed
      if (currentActive.isNotEmpty) {
        for (var activeTarget in currentActive) {
          if (DateTime.now().isAfter(activeTarget.deadline)) {
            await _closeTarget(activeTarget.id);
          }
        }
      }

      // 4. Find target with nearest deadline (upcoming only, future deadline)
      final now = DateTime.now();
      final validTargets = allTargets
          .where((t) => t.status == 'upcoming' && t.deadline.isAfter(now))
          .toList();

      if (validTargets.isEmpty) return;

      // Sort by deadline ascending (nearest first)
      validTargets.sort((a, b) => a.deadline.compareTo(b.deadline));
      final nearestTarget = validTargets.first;

      // 5. Get current active (after potential close)
      final activeAfterClose = allTargets
          .where((t) => t.status == 'active' && !DateTime.now().isAfter(t.deadline))
          .toList();

      if (activeAfterClose.isEmpty) {
        // No active target, activate nearest
        await _activateTarget(nearestTarget.id);
      } else {
        // Check if nearest target has earlier deadline than current active
        final currentActiveTarget = activeAfterClose.first;
        if (nearestTarget.deadline.isBefore(currentActiveTarget.deadline)) {
          // Switch! Deactivate current, activate nearest
          await _deactivateTarget(currentActiveTarget.id);
          await _activateTarget(nearestTarget.id);
        }
      }
    } catch (e) {
      // Silent fail - don't block app startup
      print('Error checking targets: $e');
    }
  }

  /// Activate a target
  Future<void> _activateTarget(String targetId) async {
    await _firestore.collection('graduation_targets').doc(targetId).update({
      'status': 'active',
      'open_date': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Deactivate a target (back to upcoming)
  Future<void> _deactivateTarget(String targetId) async {
    await _firestore.collection('graduation_targets').doc(targetId).update({
      'status': 'upcoming',
      'open_date': null,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Close a target (internal method)
  Future<void> _closeTarget(String targetId) async {
    await _firestore.collection('graduation_targets').doc(targetId).update({
      'status': 'closed',
      'closed_date': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get Indonesian month name
  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Get month options for dropdown
  static List<String> getMonthOptions() {
    return [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
  }

  /// Get year options for dropdown (current year + 2 years)
  static List<int> getYearOptions() {
    final currentYear = DateTime.now().year;
    return [currentYear, currentYear + 1, currentYear + 2];
  }

  /// Delete corrupt targets (targets with null/invalid timestamps)
  /// This is a cleanup utility method
  Future<Map<String, dynamic>> deleteCorruptTargets() async {
    try {
      final snapshot = await _firestore.collection('graduation_targets').get();
      final corruptIds = <String>[];
      final validCount = 0;

      for (var doc in snapshot.docs) {
        try {
          // Try to parse the target
          GraduationTarget.fromFirestore(doc);
        } catch (e) {
          // If parsing fails, it's corrupt - delete it
          corruptIds.add(doc.id);
          await doc.reference.delete();
          print('Deleted corrupt target ${doc.id}: $e');
        }
      }

      return {
        'deleted': corruptIds.length,
        'corruptIds': corruptIds,
        'message': corruptIds.isEmpty 
            ? 'No corrupt targets found' 
            : '${corruptIds.length} corrupt targets deleted',
      };
    } catch (e) {
      throw Exception('Failed to delete corrupt targets: ${e.toString()}');
    }
  }
}
