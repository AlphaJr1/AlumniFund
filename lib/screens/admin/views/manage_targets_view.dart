import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../providers/graduation_target_provider.dart';
import '../../../providers/admin/admin_actions_provider.dart';
import '../../../services/target_service.dart';
import '../../../models/graduate_model.dart';
import '../../../models/graduation_target_model.dart';
import '../../../widgets/admin/graduate_list_builder.dart';
import '../../../widgets/admin/edit_target_modal.dart';
import '../../../widgets/admin/target_detail_modal.dart';
import '../../../utils/currency_formatter.dart';

class ManageTargetsView extends ConsumerStatefulWidget {
  const ManageTargetsView({super.key});

  @override
  ConsumerState<ManageTargetsView> createState() => _ManageTargetsViewState();
}

class _ManageTargetsViewState extends ConsumerState<ManageTargetsView> {
  final _targetService = TargetService();
  final _formKey = GlobalKey<FormState>();
  
  List<Graduate> _graduates = [];
  String? _validationError;
  bool _isSubmitting = false;
  bool _showArchivedTargets = false;

  @override
  void initState() {
    super.initState();
    // Cleanup corrupt targets first
    _targetService.deleteCorruptTargets();
    // Check and activate targets on load
    _targetService.checkAndActivateTargets();
  }

  void _resetForm() {
    setState(() {
      _graduates = [];
      _validationError = null;
      _isSubmitting = false;
    });
    _formKey.currentState?.reset();
  }

  void _editTarget(GraduationTarget target) {
    showDialog(
      context: context,
      builder: (context) => EditTargetModal(
        target: target,
        onSuccess: () {
          // Refresh data
          ref.invalidate(graduationTargetsProvider);
        },
      ),
    );
  }

  void _showTargetDetail(GraduationTarget target) {
    showDialog(
      context: context,
      builder: (context) => TargetDetailModal(
        target: target,
        onUpdate: () {
          ref.invalidate(graduationTargetsProvider);
        },
        onDelete: target.status == 'upcoming'
            ? () => _deleteTarget(
                  target.id,
                  target.monthYearDisplay,
                )
            : null,
      ),
    );
  }

  Future<void> _createTarget() async {
    if (_graduates.isEmpty) {
      setState(() {
        _validationError = 'Add at least 1 recipient';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationError = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Use auto-split method (append to existing targets)
      final result = await _targetService.createTargetsFromGraduates(
        graduates: _graduates,
        createdBy: currentUser.email!,
      );

      // Check and auto-switch active target if needed
      await _targetService.checkAndActivateTargets();

      if (mounted) {
        // final totalTargets = result['totalTargets'] as int;
        final targetNames = (result['targetNames'] as List<String>).join(', ');
        final createdCount = (result['created'] as List).length;
        final updatedCount = (result['updated'] as List).length;
        
        String message = '✅ ';
        if (createdCount > 0 && updatedCount > 0) {
          message += '$createdCount new targets created, $updatedCount targets updated (recipients added)';
        } else if (createdCount > 0) {
          message += '$createdCount targets created successfully';
        } else {
          message += '$updatedCount targets updated successfully (recipients added)';
        }
        message += '\n$targetNames';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
        _resetForm();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _validationError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _deleteTarget(String targetId, String targetName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target'),
        content: Text('Are you sure you want to delete target $targetName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _targetService.deleteTarget(targetId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('✅ Target deleted successfully'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Future<void> _closeTarget(String targetId, String targetName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Target'),
        content: Text(
          'Are you sure you want to close "$targetName"?\n\n'
          'This will:\n'
          '• Finalize the target amount\n'
          '• Deduct allocated funds from General Fund\n'
          '• Mark target as closed\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Close Target'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Use AdminActionsService to properly handle fund deduction
      await ref.read(adminActionsProvider).closeTarget(targetId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Target closed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGraduateDetailsModal(activeTarget) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF3B82F6), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                           'Recipients List',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          activeTarget.monthYearDisplay,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Graduate list
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: activeTarget.graduates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final graduate = activeTarget.graduates[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        graduate.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      subtitle: Text(
                        '${DateFormat('dd MMMM yyyy', 'en_US').format(graduate.date)} • ${graduate.location}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTarget = ref.watch(activeTargetProvider);
    final upcomingTargets = ref.watch(upcomingTargetsProvider);
    final archivedTargets = ref.watch(archivedTargetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Manage Graduation Targets',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage graduation fundraising targets',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Active Target Card
            _buildActiveTargetCard(activeTarget),
            const SizedBox(height: 24),

            // Section 2: Upcoming Targets List
            _buildUpcomingTargetsList(upcomingTargets),
            const SizedBox(height: 24),

            // Section 3: Create New Target Form
            _buildCreateTargetForm(),
            const SizedBox(height: 24),

            // Section 4: Archived Targets
            _buildArchivedTargets(archivedTargets),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTargetCard(activeTarget) {
    if (activeTarget == null) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(height: 16),
              Text(
                 'No Active Target',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 8),
              Text(
                 'Create new target below',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use displayAmount (currentAmount + allocated_from_fund) for accurate progress
    final progress = activeTarget.displayAmount / activeTarget.targetAmount;
    final daysRemaining = activeTarget.deadline.difference(DateTime.now()).inDays;
    
    Color deadlineColor;
    if (daysRemaining > 7) {
      deadlineColor = const Color(0xFF10B981);
    } else if (daysRemaining >= 3) {
      deadlineColor = const Color(0xFFF59E0B);
    } else {
      deadlineColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                       'Active Target',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      activeTarget.monthYearDisplay,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rp ${CurrencyFormatter.formatNumber(activeTarget.displayAmount)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Rp ${CurrencyFormatter.formatNumber(activeTarget.targetAmount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                 '${(progress * 100).toStringAsFixed(1)}% reached',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people,
                  label: 'Recipients',
                  value: '${activeTarget.graduates.length}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today,
                  label: 'Deadline',
                  value: DateFormat('dd MMM yyyy', 'en_US').format(activeTarget.deadline),
                  valueColor: deadlineColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Graduate names
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                       'Recipients',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activeTarget.graduates.map((g) => g.name).join(', '),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: deadlineColor, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: deadlineColor, size: 20),
                const SizedBox(width: 8),
                Text(
                   '$daysRemaining days left',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: deadlineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Details'),
                  onPressed: () => _showTargetDetail(activeTarget),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Close Manually'),
                  onPressed: () => _closeTarget(
                    activeTarget.id,
                    activeTarget.monthYearDisplay,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: valueColor != null ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: valueColor != null ? const Color(0xFF6B7280) : Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: valueColor != null ? const Color(0xFF6B7280) : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTargetsList(List upcomingTargets) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
             'Upcoming Targets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          
          if (upcomingTargets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                   'No upcoming targets yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingTargets.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final target = upcomingTargets[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  title: Text(
                    target.monthYearDisplay,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  subtitle: Text(
                     '${target.graduates.length} recipients • Rp ${CurrencyFormatter.formatNumber(target.targetAmount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    color: const Color(0xFF3B82F6),
                    onPressed: () => _showTargetDetail(target),
                    tooltip: 'View Details',
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCreateTargetForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Target',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 24),

            // Graduate List Builder
            GraduateListBuilder(
              onChanged: (graduates) {
                setState(() {
                  _graduates = graduates;
                });
              },
              onValidationError: (error) {
                setState(() {
                  _validationError = error;
                });
              },
            ),
            const SizedBox(height: 24),


            // Error message
            if (_validationError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ),
            if (_validationError != null) const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _resetForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _createTarget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Target',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedTargets(List archivedTargets) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showArchivedTargets = !_showArchivedTargets;
              });
            },
            child: Row(
              children: [
                Icon(
                  _showArchivedTargets ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Text(
                  'Archived Targets (${archivedTargets.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          
          if (_showArchivedTargets) ...[
            const SizedBox(height: 16),
            if (archivedTargets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No archived targets yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: archivedTargets.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final target = archivedTargets[index];
                  final isComplete = target.currentAmount >= target.targetAmount;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isComplete
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFF6B7280).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isComplete ? Icons.check_circle : Icons.archive,
                        color: isComplete ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                      ),
                    ),
                    title: Text(
                      target.monthYearDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    subtitle: Text(
                      'Rp ${CurrencyFormatter.formatNumber(target.currentAmount)} / Rp ${CurrencyFormatter.formatNumber(target.targetAmount)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isComplete
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFF6B7280).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isComplete ? 'Tercapai' : 'Ditutup',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isComplete ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

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
}
