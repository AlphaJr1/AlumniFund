import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../models/transaction_model.dart';
import '../../providers/admin/admin_actions_provider.dart';
import '../../providers/general_fund_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';

/// Edit Transaction Modal
class EditTransactionModal extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const EditTransactionModal({
    super.key,
    required this.transaction,
  });

  static Future<bool?> show(
    BuildContext context,
    TransactionModel transaction,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EditTransactionModal(transaction: transaction),
    );
  }

  @override
  ConsumerState<EditTransactionModal> createState() => _EditTransactionModalState();
}

class _EditTransactionModalState extends ConsumerState<EditTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _transferDate;
  
  Uint8List? _newProofBytes;
  String? _newProofFileName;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(0),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );
    _transferDate = widget.transaction.createdAt;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'File too large. Maximum 5MB.';
          });
          return;
        }

        setState(() {
          _newProofBytes = file.bytes;
          _newProofFileName = file.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select file: $e';
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transferDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _transferDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final newAmount = double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', ''));
      final newDescription = _descriptionController.text.trim();
      
      // Upload new proof if selected
      String? newProofUrl = widget.transaction.proofUrl;
      if (_newProofBytes != null && _newProofFileName != null) {
        final storageService = StorageService();
        newProofUrl = await storageService.uploadTransactionProof(
          imageBytes: _newProofBytes!,
          fileName: _newProofFileName!,
        );
      }

      // Create updated transaction
      final updatedTransaction = widget.transaction.copyWith(
        amount: newAmount,
        description: newDescription,
        createdAt: _transferDate,
        proofUrl: newProofUrl,
      );

      // Call edit transaction with balance reconciliation
      await ref.read(adminActionsProvider).editTransaction(
        original: widget.transaction,
        updated: updatedTransaction,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.isIncome;
    final typeLabel = isIncome ? 'Income' : 'Expense';
    final typeColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    
    final fundAsync = ref.watch(generalFundProvider);
    final availableBalance = fundAsync.maybeWhen(
      data: (fund) => fund.balance,
      orElse: () => 0.0,
    );

    return AlertDialog(
      title: const Text('Edit Transaction'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type (readonly)
                Row(
                  children: [
                    const Text(
                      'Type: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (widget.transaction.targetMonth != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Target: ${widget.transaction.targetMonth}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    hintText: 'Enter amount',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      final number = int.parse(newValue.text);
                      final formatted = NumberFormat('#,###', 'id_ID').format(number);
                      return TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount cannot be empty';
                    }
                    final amount = double.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
                    if (amount == null || amount <= 0) {
                      return 'Enter valid amount';
                    }
                    
                    // For expenses, check if new amount exceeds available balance
                    if (!isIncome) {
                      final previousAmount = widget.transaction.amount;
                      final netChange = amount - previousAmount;
                      if (availableBalance + previousAmount < amount) {
                        return 'Insufficient balance (available: Rp ${CurrencyFormatter.formatCurrency(availableBalance)})';
                      }
                    }
                    
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Enter description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description cannot be empty';
                    }
                    if (value.trim().length < 10) {
                      return 'Minimum 10 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),

                // Transfer Date
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Transfer Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd MMMM yyyy', 'en_US').format(_transferDate),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),

                // Proof Image
                const Text(
                  'Proof Image (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    if (widget.transaction.proofUrl != null) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Show proof in modal
                        },
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('View Current'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: _pickProofImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_newProofFileName != null ? 'Change' : 'Upload New'),
                    ),
                  ],
                ),
                
                if (_newProofFileName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Selected: $_newProofFileName',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppConstants.errorRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppConstants.errorRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryTeal,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
