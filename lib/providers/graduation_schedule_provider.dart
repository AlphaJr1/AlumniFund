import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/graduation_schedule_service.dart';
import '../models/graduation_schedule_model.dart';

final graduationScheduleServiceProvider = Provider((_) => GraduationScheduleService());

/// Watch schedule untuk user tertentu
final userGraduationScheduleProvider =
    StreamProvider.family<GraduationSchedule?, String>((ref, userId) {
  return ref.watch(graduationScheduleServiceProvider).watchUserSchedule(userId);
});

/// Watch all schedules untuk admin panel
final allGraduationSchedulesProvider =
    StreamProvider<List<GraduationSchedule>>((ref) {
  return ref.watch(graduationScheduleServiceProvider).watchAllSchedules();
});
