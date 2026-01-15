import 'package:cloud_firestore/cloud_firestore.dart';

/// One-time migration script to update Indonesian month names to English
/// Run this from Flutter DevTools console or create a temporary button in admin panel
class MonthNameMigration {
  final _firestore = FirebaseFirestore.instance;

  /// Month name mapping: Indonesian → English
  final Map<String, String> monthMapping = {
    'januari': 'january',
    'februari': 'february',
    'maret': 'march',
    'april': 'april', 
    'mei': 'may',
    'juni': 'june',
    'juli': 'july',
    'agustus': 'august',
    'september': 'september',
    'oktober': 'october',
    'november': 'november',
    'desember': 'december',
  };

  /// Migrate graduation targets month names
  Future<void> migrateGraduationTargets() async {
    print('🔄 Starting graduation targets migration...');
    
    try {
      // Get all graduation targets
      final snapshot = await _firestore
          .collection('graduation_targets')
          .get();

      int updated = 0;
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final currentMonth = (data['month'] as String?)?.toLowerCase();

        if (currentMonth != null && monthMapping.containsKey(currentMonth)) {
          final englishMonth = monthMapping[currentMonth]!;
          
          print('  Updating ${doc.id}: $currentMonth → $englishMonth');
          
          batch.update(doc.reference, {
            'month': englishMonth,
          });
          
          updated++;
        }
      }

      if (updated > 0) {
        await batch.commit();
        print('✅ Successfully updated $updated graduation targets!');
      } else {
        print('ℹ️  No targets need updating.');
      }
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Migrate transaction descriptions (if needed)
  Future<void> migrateTransactionDescriptions() async {
    print('🔄 Starting transaction descriptions migration...');
    
    try {
      // Get transactions with Indonesian descriptions
      final snapshot = await _firestore
          .collection('transactions')
          .where('description', isEqualTo: 'Pemasukkan dari validasi submission')
          .get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️  No transactions need updating.');
        return;
      }

      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        print('  Updating transaction ${doc.id}');
        
        batch.update(doc.reference, {
          'description': 'Income from validated submission',
        });
      }

      await batch.commit();
      print('✅ Successfully updated ${snapshot.docs.length} transactions!');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Run all migrations
  Future<void> runAll() async {
    print('🚀 Starting full migration...\n');
    
    await migrateGraduationTargets();
    print('');
    await migrateTransactionDescriptions();
    
    print('\n✅ All migrations completed!');
  }
}

// Usage in Flutter DevTools console or temporary admin button:
// final migration = MonthNameMigration();
// await migration.runAll();
