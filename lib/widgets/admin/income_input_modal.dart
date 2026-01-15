import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/storage_service.dart';
import '../../providers/graduation_target_provider.dart';
import '../../providers/admin/admin_actions_provider.dart';
import '../../providers/general_fund_provider.dart';
import '../../utils/constants.dart';

/// Quick income input modal untuk admin
/// Input pemasukan langsung tanpa melalui pending submissions
class IncomeInputModal extends ConsumerStatefulWidget {
  final String? preSelectedTargetId;

  const IncomeInputModal({
    super.key,
    this.preSelectedTargetId,
  });

  @override
  ConsumerState<IncomeInputModal> createState() => _IncomeInputModalState();
}

class _IncomeInputModalState extends ConsumerState<IncomeInputModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _donorNameController = TextEditingController();
  final _storageService = StorageService();
  final _firestore = FirebaseFirestore.instance;

  // Removed: _selectedTargetId - all income now goes to general_fund only
  Uint8List? _proofImageBytes;
  String? _proofImageName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Removed: _selectedTargetId initialization
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _donorNameController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _proofImageBytes = file.bytes;
          _proofImageName = file.name;
        });
      }
    } catch (e) {
      _showError('Failed to select image: $e');
    }
  }

  Future<void> _submitIncome() async {
    if (!_formKey.currentState!.validate()) return;
    // Removed: target selection validation - all income goes to general_fund

    setState(() => _isLoading = true);

    try {
      // Upload proof if exists
      String? proofUrl;
      if (_proofImageBytes != null) {
        proofUrl = await _storageService.uploadTransactionProof(
          imageBytes: _proofImageBytes!,
          fileName: _proofImageName ??
              'proof_${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }

      // Parse amount
      final amount = double.parse(
        _amountController.text.replaceAll('.', '').replaceAll(',', ''),
      );

      final now = Timestamp.now();
      final user = FirebaseAuth.instance.currentUser;

      // Create transaction document
      final transactionRef = _firestore.collection('transactions').doc();
      await transactionRef.set({
        'id': transactionRef.id,
        'type': 'income',
        'amount': amount,
        'target_id': 'general_fund', // Always route to general fund
        'target_month': null,
        'description': _descriptionController.text.isEmpty
            ? 'Manual income'
            : _descriptionController.text,
        'proof_url': proofUrl,
        'validated': true,
        'validation_status': 'approved',
        'created_at': now,
        'input_at': now,
        'created_by': user?.email ?? 'admin',
        'metadata': {
          'submission_method': 'manual_input',
          'input_from': 'dashboard',
          'donor_name': _donorNameController.text.isEmpty
              ? null
              : _donorNameController.text,
        },
      });

      // Always update general fund (simplified routing)
      await _firestore.collection('general_fund').doc('current').update({
        'balance': FieldValue.increment(amount),
        'total_income': FieldValue.increment(amount),
        'last_updated': now,
      });

      // Auto-allocate to active target
      try {
        final adminActions = ref.read(adminActionsProvider);
        await adminActions.autoAllocateToTarget();
        
        // Invalidate providers to refresh UI
        ref.invalidate(activeTargetProvider);
        ref.invalidate(upcomingTargetsProvider);
        ref.invalidate(generalFundProvider);
      } catch (e) {
        print('Auto-allocation error: $e');
      }

      if (mounted) {
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income added successfully'),
            backgroundColor: AppConstants.successGreen,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to add income: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed: targetOptions - no longer needed since dropdown is removed

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manual Income Input',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount Input
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    prefixText: 'Rp ',
                    hintText: '0',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount cannot be empty';
                    }
                    final amount = double.tryParse(
                      value.replaceAll('.', '').replaceAll(',', ''),
                    );
                    if (amount == null || amount <= 0) {
                      return 'Enter valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Removed: Target Destination Dropdown
                // All income now automatically goes to General Fund

                // Donor Name
                TextFormField(
                  controller: _donorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Donor Name (optional)',
                    hintText: 'Example: John Doe',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Example: Donation from event X',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Proof Upload
                const Text(
                  'Transfer Proof (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (_proofImageBytes != null)
                  Container(
                    width: 150,
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppConstants.gray300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _proofImageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _pickProofImage,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _proofImageBytes != null ? 'Change Image' : 'Choose Image',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.gray100,
                    foregroundColor: AppConstants.gray700,
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitIncome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryTeal,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
