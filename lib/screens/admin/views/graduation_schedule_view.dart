import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/graduation_schedule_provider.dart';
import '../../../models/graduation_schedule_model.dart';

class GraduationScheduleView extends ConsumerWidget {
  const GraduationScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(allGraduationSchedulesProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Graduation Schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    'Alumni graduation registrations',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          schedulesAsync.when(
            data: (schedules) => _buildContent(schedules, isMobile),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: Color(0xFFEF4444))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<GraduationSchedule> schedules, bool isMobile) {
    if (schedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_outlined,
                    size: 48, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(height: 16),
              const Text(
                'No graduation registrations yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Alumni will appear here once they register',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      );
    }

    // Summary stats
    final now = DateTime.now();
    final upcoming = schedules.where((s) => s.graduationDate.isAfter(now)).length;
    final past = schedules.length - upcoming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        if (!isMobile)
          Row(
            children: [
              _StatCard(
                label: 'Total Registered',
                value: schedules.length.toString(),
                color: const Color(0xFF6366F1),
                icon: Icons.people_rounded,
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: 'Upcoming',
                value: upcoming.toString(),
                color: const Color(0xFF10B981),
                icon: Icons.event_rounded,
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: 'Past',
                value: past.toString(),
                color: const Color(0xFF9CA3AF),
                icon: Icons.history_rounded,
              ),
            ],
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                label: 'Total',
                value: schedules.length.toString(),
                color: const Color(0xFF6366F1),
                icon: Icons.people_rounded,
              ),
              _StatCard(
                label: 'Upcoming',
                value: upcoming.toString(),
                color: const Color(0xFF10B981),
                icon: Icons.event_rounded,
              ),
              _StatCard(
                label: 'Past',
                value: past.toString(),
                color: const Color(0xFF9CA3AF),
                icon: Icons.history_rounded,
              ),
            ],
          ),

        const SizedBox(height: 28),

        // Table header (desktop)
        if (!isMobile) _buildTableHeader(),
        if (!isMobile) const SizedBox(height: 8),

        // List
        ...schedules.map((s) => isMobile
            ? _buildMobileCard(s)
            : _buildTableRow(s, schedules.indexOf(s).isEven)),
      ],
    );
  }

  Widget _buildTableHeader() {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF6B7280),
      letterSpacing: 0.8,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('NAME', style: style)),
          Expanded(flex: 3, child: Text('MAJOR', style: style)),
          Expanded(flex: 3, child: Text('UNIVERSITY', style: style)),
          Expanded(flex: 2, child: Text('DATE', style: style)),
          Expanded(flex: 3, child: Text('VENUE', style: style)),
        ],
      ),
    );
  }

  Widget _buildTableRow(GraduationSchedule s, bool isEven) {
    final now = DateTime.now();
    final isUpcoming = s.graduationDate.isAfter(now);
    final dateStr = DateFormat('d MMM yyyy', 'en_US').format(s.graduationDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              s.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s.major,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s.campus,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isUpcoming
                      ? const Color(0xFF065F46)
                      : const Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s.location,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(GraduationSchedule s) {
    final now = DateTime.now();
    final isUpcoming = s.graduationDate.isAfter(now);
    final dateStr =
        DateFormat('d MMMM yyyy', 'en_US').format(s.graduationDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isUpcoming ? 'Upcoming' : 'Past',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUpcoming
                        ? const Color(0xFF065F46)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.major,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(s.campus,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 5),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(s.location,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF374151)),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
