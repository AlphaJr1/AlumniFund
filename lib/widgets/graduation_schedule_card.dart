import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/graduation_schedule_provider.dart';
import '../providers/user_identification_provider.dart';
import '../models/graduation_schedule_model.dart';
import '../services/graduation_schedule_service.dart';

/// Card untuk mendaftarkan jadwal wisuda alumni
class GraduationScheduleCard extends ConsumerWidget {
  const GraduationScheduleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userIdentificationProvider);
    final userId = userState.userData?.userId;
    final userName = userState.userData?.displayName ?? '';

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 1024;

    return Center(
      child: GestureDetector(
        onTap: () {
          _openForm(context, ref, userId, userName);
        },
        onDoubleTap: () {}, // prevent theme change
        child: Container(
          width: screenWidth * 0.9,
          height: isMobile ? screenHeight * 0.65 : screenHeight * 0.75,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          margin: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: userId == null
              ? _buildEmptyState(isMobile)
              : _buildWithData(context, ref, userId, userName, isMobile),
        ),
      ),
    );
  }

  Widget _buildWithData(BuildContext context, WidgetRef ref, String userId,
      String userName, bool isMobile) {
    final scheduleAsync = ref.watch(userGraduationScheduleProvider(userId));

    return scheduleAsync.when(
      data: (schedule) => schedule == null
          ? _buildEmptyState(isMobile)
          : _buildFilledState(schedule, isMobile),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyState(isMobile),
    );
  }

  /// State saat belum submit — card invitation
  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 28.0 : 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mortar board icon with glow
            _GlowingIcon(isMobile: isMobile),
            SizedBox(height: isMobile ? 20 : 24),

            Text(
              'Register Your Graduation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 22 : 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              "Let the community know when and\nwhere you'll be graduating!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
            SizedBox(height: isMobile ? 28 : 36),

            // Decorative dashes / timeline visual
            _TimelineDots(),

            SizedBox(height: isMobile ? 28 : 36),

            // Pulsing CTA chip
            _PulsingChip(isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  /// State setelah submit — tampilkan data wisuda
  Widget _buildFilledState(GraduationSchedule schedule, bool isMobile) {
    final dateStr = DateFormat('d MMMM yyyy', 'en_US').format(schedule.graduationDate);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Graduation',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      schedule.name,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Registered badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✓ Registered',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isMobile ? 20 : 24),

          // Date highlight card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GRADUATION DATE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isMobile ? 16 : 20),

          // Info grid
          _InfoRow(
            icon: Icons.menu_book_rounded,
            label: 'Major',
            value: schedule.major,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.account_balance_rounded,
            label: 'University',
            value: schedule.campus,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.location_on_rounded,
            label: 'Venue',
            value: schedule.location,
          ),

          const Spacer(),

          // Tap hint
          Center(
            child: Text(
              'Tap to edit your graduation info',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, String? userId, String userName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _GraduationFormModal(
        userId: userId,
        userName: userName,
      ),
    );
  }
}

// ========================== FORM MODAL ==========================

class _GraduationFormModal extends ConsumerStatefulWidget {
  final String? userId;
  final String userName;

  const _GraduationFormModal({required this.userId, required this.userName});

  @override
  ConsumerState<_GraduationFormModal> createState() =>
      _GraduationFormModalState();
}

class _GraduationFormModalState extends ConsumerState<_GraduationFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _majorCtrl;
  late TextEditingController _campusCtrl;
  late TextEditingController _locationCtrl;

  DateTime? _selectedDate;
  bool _isSubmitting = false;
  bool _isDirty = false;
  GraduationSchedule? _existing;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill Full Name langsung dari username — bisa diedit user
    _nameCtrl = TextEditingController(text: widget.userName);
    _majorCtrl = TextEditingController();
    _campusCtrl = TextEditingController();
    _locationCtrl = TextEditingController();

    _nameCtrl.addListener(_markDirty);
    _majorCtrl.addListener(_markDirty);
    _campusCtrl.addListener(_markDirty);
    _locationCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  /// Prefill seluruh form dari data existing (edit mode)
  void _prefillIfExisting(GraduationSchedule existing) {
    if (_loaded) return;
    _loaded = true;
    _existing = existing;
    // Nama dari existing schedule (yang mungkin sudah diedit user sebelumnya)
    _nameCtrl.text = existing.name;
    _majorCtrl.text = existing.major;
    _campusCtrl.text = existing.campus;
    _locationCtrl.text = existing.location;
    _selectedDate = existing.graduationDate;
  }

  void _markLoadedNoData() {
    if (_loaded) return;
    _loaded = true;
    // Name sudah di-set di initState dari userName
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _majorCtrl.dispose();
    _campusCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final allFilled = _nameCtrl.text.trim().isNotEmpty &&
        _majorCtrl.text.trim().isNotEmpty &&
        _campusCtrl.text.trim().isNotEmpty &&
        _locationCtrl.text.trim().isNotEmpty &&
        _selectedDate != null;

    if (!allFilled || _isSubmitting) return false;
    // New registration: cukup semua field terisi
    // Edit mode: harus ada perubahan
    return _existing == null ? true : _isDirty;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(graduationScheduleServiceProvider);
      final now = DateTime.now();
      final schedule = GraduationSchedule(
        id: _existing?.id ?? const Uuid().v4(),
        userId: widget.userId ?? '',
        name: _nameCtrl.text.trim(),
        major: _majorCtrl.text.trim(),
        campus: _campusCtrl.text.trim(),
        graduationDate: _selectedDate!,
        location: _locationCtrl.text.trim(),
        createdAt: _existing?.createdAt ?? now,
        updatedAt: now,
      );
      await service.saveSchedule(schedule);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    if (widget.userId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Registration'),
        content: const Text(
            'Are you sure you want to remove your graduation registration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final service = ref.read(graduationScheduleServiceProvider);
    await service.deleteSchedule(widget.userId!);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF6366F1),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isDirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Load existing data dari Firestore
    if (widget.userId != null) {
      final scheduleAsync =
          ref.watch(userGraduationScheduleProvider(widget.userId!));
      scheduleAsync.whenData((s) {
        if (s != null) {
          _prefillIfExisting(s);
        } else {
          _markLoadedNoData();
        }
      });
    } else {
      _markLoadedNoData();
    }

    final hasExisting = _existing != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: keyboardHeight > 0 ? keyboardHeight + 8 : 20,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? 420 : 520,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(hasExisting),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          label: 'Full Name',
                          hint: 'Your name as it will appear on the list',
                          controller: _nameCtrl,
                          icon: Icons.person_rounded,
                          helperText: 'Confirm or edit your name',
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Major / Study Program',
                          hint: 'e.g. Computer Science',
                          controller: _majorCtrl,
                          icon: Icons.menu_book_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'University',
                          hint: 'e.g. Universitas Indonesia',
                          controller: _campusCtrl,
                          icon: Icons.account_balance_rounded,
                        ),
                        const SizedBox(height: 16),

                        // Date picker
                        _buildLabel('Graduation Date'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedDate != null
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFFE5E7EB),
                                width: _selectedDate != null ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: _selectedDate != null
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedDate != null
                                      ? DateFormat('d MMMM yyyy', 'en_US')
                                          .format(_selectedDate!)
                                      : 'Select graduation date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedDate != null
                                        ? const Color(0xFF1F2937)
                                        : const Color(0xFF9CA3AF),
                                    fontWeight: _selectedDate != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Venue / Location',
                          hint: 'e.g. Balairung UI, Depok',
                          controller: _locationCtrl,
                          icon: Icons.location_on_rounded,
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            child: ElevatedButton(
                              onPressed: _canSubmit ? _submit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _canSubmit
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFFE5E7EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      hasExisting
                                          ? 'Update Registration'
                                          : 'Register Graduation',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _canSubmit
                                            ? Colors.white
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // Delete button (only if existing)
                        if (hasExisting) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _delete,
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Color(0xFFEF4444)),
                              label: const Text(
                                'Remove Registration',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasExisting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const Text('🎓', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasExisting ? 'Edit Graduation Info' : 'Graduation Registration',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Tell us when you graduate!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (v) =>
              v == null || v.trim().isEmpty ? '$label is required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            helperText: helperText,
            helperStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
        ),
      ],
    );
  }
}

// ========================== HELPER WIDGETS ==========================

class _GlowingIcon extends StatefulWidget {
  final bool isMobile;
  const _GlowingIcon({required this.isMobile});

  @override
  State<_GlowingIcon> createState() => _GlowingIconState();
}

class _GlowingIconState extends State<_GlowingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this)
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isMobile ? 80.0 : 96.0;
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(_glow.value),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          Icons.school_rounded,
          size: size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TimelineDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final isCenter = i == 2;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            width: isCenter ? 40 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: isCenter
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    )
                  : null,
              color: isCenter ? null : const Color(0xFFE5E7EB),
            ),
          ),
        );
      }),
    );
  }
}

class _PulsingChip extends StatefulWidget {
  final bool isMobile;
  const _PulsingChip({required this.isMobile});

  @override
  State<_PulsingChip> createState() => _PulsingChipState();
}

class _PulsingChipState extends State<_PulsingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1800), vsync: this)
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Tap to Register',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.isMobile ? 13 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 200,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
