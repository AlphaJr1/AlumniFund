import 'package:flutter/material.dart';
import '../../models/graduation_target_model.dart';
import '../../models/graduate_model.dart';
import '../../services/target_service.dart';
import 'graduate_list_builder.dart';

/// Modal untuk edit target (upcoming only)
class EditTargetModal extends StatefulWidget {
  final GraduationTarget target;
  final VoidCallback onSuccess;

  const EditTargetModal({
    super.key,
    required this.target,
    required this.onSuccess,
  });

  @override
  State<EditTargetModal> createState() => _EditTargetModalState();
}

class _EditTargetModalState extends State<EditTargetModal> {
  final _targetService = TargetService();
  final _formKey = GlobalKey<FormState>();
  
  List<Graduate> _graduates = [];
  String? _validationError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing graduates
    _graduates = List.from(widget.target.graduates);
  }

  Future<void> _saveChanges() async {
    if (_graduates.isEmpty) {
      setState(() {
        _validationError = 'Minimal harus ada 1 wisudawan';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationError = null;
    });

    try {
      await _targetService.replaceGraduates(
        targetId: widget.target.id,
        graduates: _graduates,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Target berhasil diupdate'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _validationError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Target',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${TargetService.getMonthName(_getMonthNumber(widget.target.month))} ${widget.target.year}',
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
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // Graduate List Builder
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: GraduateListBuilder(
                    initialGraduates: _graduates,
                    onChanged: (graduates) {
                      setState(() {
                        _graduates = graduates;
                        _validationError = null;
                      });
                    },
                    onValidationError: (error) {
                      setState(() {
                        _validationError = error;
                      });
                    },
                  ),
                ),
              ),
            ),

            // Validation Error
            if (_validationError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
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
            ],

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _saveChanges,
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
                            'Save Changes',
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

  int _getMonthNumber(String month) {
    const monthMap = {
      'Januari': 1, 'Februari': 2, 'Maret': 3, 'April': 4,
      'Mei': 5, 'Juni': 6, 'Juli': 7, 'Agustus': 8,
      'September': 9, 'Oktober': 10, 'November': 11, 'Desember': 12,
    };
    return monthMap[month] ?? 1;
  }
}
