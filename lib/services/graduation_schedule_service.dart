import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/graduation_schedule_model.dart';

class GraduationScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'graduation_schedules';

  /// Watch schedule by userId (realtime)
  Stream<GraduationSchedule?> watchUserSchedule(String userId) {
    return _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return GraduationSchedule.fromFirestore(snap.docs.first);
    });
  }

  /// Submit / update schedule (upsert by userId)
  Future<void> saveSchedule(GraduationSchedule schedule) async {
    final existing = await _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: schedule.userId)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      // Create
      await _firestore
          .collection(_collection)
          .doc(schedule.id)
          .set(schedule.toFirestore());
    } else {
      // Update
      await _firestore
          .collection(_collection)
          .doc(existing.docs.first.id)
          .update({
        'name': schedule.name,
        'major': schedule.major,
        'campus': schedule.campus,
        'graduation_date': Timestamp.fromDate(schedule.graduationDate),
        'location': schedule.location,
        'updated_at': Timestamp.fromDate(schedule.updatedAt),
      });
    }
  }

  /// Delete schedule by userId
  Future<void> deleteSchedule(String userId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  /// Get all schedules (for admin)
  Stream<List<GraduationSchedule>> watchAllSchedules() {
    return _firestore
        .collection(_collection)
        .orderBy('graduation_date')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GraduationSchedule.fromFirestore(d)).toList());
  }
}
