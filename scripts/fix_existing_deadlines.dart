import 'package:cloud_firestore/cloud_firestore.dart';

/// Script untuk update deadline target yang sudah ada
/// Mengubah deadline dari 00:00:00 menjadi 23:59:59
void main() async {
  final firestore = FirebaseFirestore.instance;

  print('🔍 Mencari semua target...');

  // Get all targets
  final snapshot = await firestore.collection('graduation_targets').get();

  print('📊 Ditemukan ${snapshot.docs.length} target');

  int updatedCount = 0;

  for (var doc in snapshot.docs) {
    try {
      final data = doc.data();
      final deadlineTimestamp = data['deadline'] as Timestamp?;

      if (deadlineTimestamp == null) {
        print('⚠️  Target ${doc.id}: Tidak ada deadline, skip');
        continue;
      }

      final oldDeadline = deadlineTimestamp.toDate();

      // Check if deadline is at 00:00:00 (needs update)
      if (oldDeadline.hour == 0 &&
          oldDeadline.minute == 0 &&
          oldDeadline.second == 0) {
        // Update to 23:59:59
        final newDeadline = DateTime(
          oldDeadline.year,
          oldDeadline.month,
          oldDeadline.day,
          23,
          59,
          59,
        );

        await doc.reference.update({
          'deadline': Timestamp.fromDate(newDeadline),
          'updated_at': FieldValue.serverTimestamp(),
        });

        print(
            '✅ Target ${doc.id} (${data['month']} ${data['year']}): $oldDeadline → $newDeadline');
        updatedCount++;
      } else {
        print(
            '⏭️  Target ${doc.id} (${data['month']} ${data['year']}): Sudah benar ($oldDeadline)');
      }
    } catch (e) {
      print('❌ Error pada target ${doc.id}: $e');
    }
  }

  print('\n🎉 Selesai! $updatedCount target diupdate');
}
