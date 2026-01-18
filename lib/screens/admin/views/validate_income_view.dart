import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html show window;
import '../../../models/pending_submission_model.dart';
import '../../../providers/admin/pending_submissions_provider.dart';
import '../../../providers/admin/admin_actions_provider.dart';
import '../../../providers/graduation_target_provider.dart';
import '../../../widgets/admin/proof_image_modal.dart';
import '../../../widgets/admin/delete_confirmation_dialog.dart';

class ValidateIncomeView extends ConsumerWidget {
  const ValidateIncomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(pendingSubmissionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Validate Income',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          submissionsAsync.when(
            data: (submissions) => Text(
              '${submissions.length} submissions pending validation',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            loading: () => const Text(
               'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            error: (_, __) => const Text(
               'Error loading data',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submissions List
          submissionsAsync.when(
            data: (submissions) {
              if (submissions.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: submissions.map((submission) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _SubmissionCard(submission: submission),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          children: [
            Text(
              '🎉',
              style: TextStyle(fontSize: 64),
            ),
            SizedBox(height: 16),
            Text(
               'All Validated!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 8),
            Text(
               'No submissions pending validation',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            const Text(
               'Failed to Load Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual submission card dengan form
class _SubmissionCard extends ConsumerStatefulWidget {
  final PendingSubmission submission;

  const _SubmissionCard({required this.submission});

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  
  DateTime? _selectedDate;
  // Removed: _selectedTargetId and _selectedTargetDisplay (no longer used)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill amount if available
    if (widget.submission.submittedAmount != null) {
      _amountController.text = widget.submission.submittedAmount!.toStringAsFixed(0);
    }
    // Default date to submission date
    _selectedDate = widget.submission.submittedAt;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final activeTarget = ref.watch(activeTargetProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: isMobile
              ? _buildMobileLayout(activeTarget)
              : _buildDesktopLayout(activeTarget),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(dynamic activeTarget) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Proof Image Preview
        _buildProofPreview(),
        const SizedBox(width: 24),

        // Form Fields
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormFields(activeTarget),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(dynamic activeTarget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProofPreview(),
        const SizedBox(height: 16),
        _buildFormFields(activeTarget),
        const SizedBox(height: 16),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildProofPreview() {
    return GestureDetector(
      onTap: () {
        if (widget.submission.proofUrl != null) {
          ProofImageModal.show(
            context,
            imageUrl: widget.submission.proofUrl!,
                   title: 'Transfer Proof',
          );
        }
      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: widget.submission.proofUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.submission.proofUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Show URL as fallback - user can open in new tab
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image,
                            size: 32,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              // Open in new tab
                              html.window.open(widget.submission.proofUrl!, '_blank');
                            },
                            child: const Text(
                              'Open',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF3B82F6),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              )
            : const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Color(0xFF9CA3AF),
                ),
              ),
      ),
    );
  }

  Widget _buildFormFields(dynamic activeTarget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Submitted info
        Text(
           'Submitted: ${DateFormat('dd MMM yyyy, HH:mm', 'en_US').format(widget.submission.submittedAt)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Submitted by: ${widget.submission.submitterName?.isNotEmpty == true ? widget.submission.submitterName : "(empty)"}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // Amount Input
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
             labelText: 'Amount *',
            hintText: 'Enter amount',
            prefixText: 'Rp ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
               return 'Amount is required';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
               return 'Amount must be greater than 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Transfer Date Picker
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
               labelText: 'Transfer Date *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              _selectedDate != null
                  ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                   : 'Select date',
              style: TextStyle(
                color: _selectedDate != null
                    ? const Color(0xFF111827)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Removed: Assign To Dropdown
        // All validated income now automatically goes to General Fund
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3B82F6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Income will be added to General Fund',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Description Textarea
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
             labelText: 'Notes (optional)',
            hintText: 'Add notes...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Approve Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleApprove,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle),
             label: Text(_isLoading ? 'Processing...' : 'Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Reject Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleReject,
            icon: const Icon(Icons.cancel),
             label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleApprove() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
           content: Text('Select transfer date'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final adminActions = ref.read(adminActionsProvider);

      await adminActions.approveIncome(
        submissionId: widget.submission.id,
        amount: amount,
        transferDate: _selectedDate!,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
             content: Text('✅ Submission approved successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleReject() async {
    final reason = await DeleteConfirmationDialog.show(
      context,
       title: 'Reject Submission?',
      message: 'This submission will be rejected and cannot be processed again.',
      confirmText: 'Yes, Reject',
      cancelText: 'Cancel',
      showReasonInput: true,
       reasonLabel: 'Rejection reason (optional)',
    );

    if (reason == null) return; // User cancelled

    setState(() {
      _isLoading = true;
    });

    try {
      final adminActions = ref.read(adminActionsProvider);

      await adminActions.rejectIncome(
        submissionId: widget.submission.id,
        rejectionReason: reason.isNotEmpty ? reason : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
             content: Text('Submission rejected'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
