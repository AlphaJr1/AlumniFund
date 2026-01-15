import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../providers/general_fund_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/admin/admin_actions_provider.dart';
import '../../../providers/graduation_target_provider.dart';
import '../../../services/expense_service.dart';
import '../../../services/submission_service.dart';
import '../../../utils/currency_formatter.dart';

class InputExpenseView extends ConsumerStatefulWidget {
  const InputExpenseView({super.key});

  @override
  ConsumerState<InputExpenseView> createState() => _InputExpenseViewState();
}

class _InputExpenseViewState extends ConsumerState<InputExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _submissionService = SubmissionService();
  final _expenseService = ExpenseService();

  String? _selectedCategory;
  DateTime? _selectedDate;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size
        if (!_submissionService.validateFileSize(file.size)) {
          setState(() {
            _errorMessage = 'File terlalu besar. Maksimal 5MB';
          });
          return;
        }

        // Validate extension
        if (!_submissionService.validateFileExtension(file.name)) {
          setState(() {
            _errorMessage = 'Unsupported format. Use JPG, PNG, or PDF';
          });
          return;
        }

        setState(() {
          _selectedFileBytes = file.bytes;
          _selectedFileName = file.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select file: ${e.toString()}';
      });
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Pilih tanggal transaksi';
      });
      return;
    }
    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Pilih kategori';
      });
      return;
    }
    if (_selectedFileBytes == null) {
      setState(() {
        _errorMessage = 'Upload bukti pengeluaran';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Parse amount
      final amount = double.parse(_amountController.text.replaceAll(',', ''));

      // Upload proof
      final proofUrl = await _submissionService.uploadProofImage(_selectedFileBytes!);

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create expense
      await _expenseService.createExpense(
        amount: amount,
        category: _selectedCategory!,
        description: _descriptionController.text,
        transactionDate: _selectedDate!,
        proofUrl: proofUrl,
        createdBy: currentUser.email!,
      );

      // Recalculate auto-allocation after fund balance changed
      try {
        final adminActions = ref.read(adminActionsProvider);
        await adminActions.autoAllocateToTarget();
        
        // Invalidate target providers to fetch fresh allocation data from Firestore
        ref.invalidate(activeTargetProvider);
        ref.invalidate(upcomingTargetsProvider);
      } catch (e) {
        // Silent fail - allocation is not critical
        print('Failed to recalculate allocation: $e');
      }

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Expense recorded successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Reset form
        _formKey.currentState!.reset();
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedDate = DateTime.now();
          _selectedFileBytes = null;
          _selectedFileName = null;
          _isSubmitting = false;
        });

        // Refresh data
        ref.invalidate(generalFundProvider);
        ref.invalidate(recentMixedTransactionsProvider);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fundAsync = ref.watch(generalFundProvider);
    final mixedTransactionsAsync = ref.watch(recentMixedTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Input Expense',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Record alumni fund expenses',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Balance Display
            fundAsync.when(
              data: (fund) => _buildBalanceCard(fund.balance),
              loading: () => _buildBalanceCard(0),
              error: (_, __) => _buildBalanceCard(0),
            ),
            const SizedBox(height: 24),

            // Expense Form
            Container(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Expense Form',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount Input
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount *',
                        hintText: 'Enter expense amount',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Amount is required';
                        }
                        final amount = double.tryParse(value.replaceAll(',', ''));
                        if (amount == null || amount <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        // Check balance
                        final fundAsync = ref.read(generalFundProvider);
                        if (fundAsync.hasValue) {
                          final balance = fundAsync.value!.balance;
                          if (amount > balance) {
                            return 'Insufficient balance (available: Rp ${CurrencyFormatter.formatCurrency(balance)})';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'wisuda',
                          child: Text('🎓 Wisuda'),
                        ),
                        DropdownMenuItem(
                          value: 'community',
                          child: Text('👥 Kegiatan Komunitas'),
                        ),
                        DropdownMenuItem(
                          value: 'operational',
                          child: Text('⚙️ Operasional'),
                        ),
                        DropdownMenuItem(
                          value: 'others',
                          child: Text('📦 Lainnya'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih kategori';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Textarea
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe this expense',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        helperText: 'Minimum 10 characters',
                      ),
                      maxLines: 4,
                      maxLength: 200,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description is required';
                        }
                        if (value.length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Transaction Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : 'Pilih tanggal',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? const Color(0xFF111827)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Proof Upload
                    _buildProofUpload(),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage != null)
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
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    _formKey.currentState!.reset();
                                    _amountController.clear();
                                    _descriptionController.clear();
                                    setState(() {
                                      _selectedCategory = null;
                                      _selectedDate = DateTime.now();
                                      _selectedFileBytes = null;
                                      _selectedFileName = null;
                                      _errorMessage = null;
                                    });
                                  },
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
                            onPressed: _isSubmitting ? null : _submitExpense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
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
                                    'Submit Expense',
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
            ),
            const SizedBox(height: 32),

            // Recent Expenses
            const Text(
              'Recent Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            mixedTransactionsAsync.when(
              data: (transactions) {
                final expenses = transactions
                    .where((t) => t.isExpense)
                    .take(10)
                    .toList();
                return _buildRecentExpenses(expenses);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF3B82F6),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${CurrencyFormatter.formatCurrency(balance)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofUpload() {
    if (_selectedFileBytes != null && _selectedFileName != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: Column(
          children: [
            if (_selectedFileName!.toLowerCase().endsWith('.jpg') ||
                _selectedFileName!.toLowerCase().endsWith('.jpeg') ||
                _selectedFileName!.toLowerCase().endsWith('.png'))
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _selectedFileBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFileName!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedFileBytes = null;
                      _selectedFileName = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFD1D5DB),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: Color(0xFF6B7280),
            ),
            SizedBox(height: 16),
            Text(
              'Upload Expense Proof *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Receipt/Proof (JPG, PNG, PDF - Max 5MB)',
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

  Widget _buildRecentExpenses(List expenses) {
    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(height: 16),
              Text(
                'No expenses yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length > 10 ? 10 : expenses.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ListTile(
            leading: Text(
              ExpenseService.getCategoryIcon(expense.category ?? 'others'),
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              ExpenseService.getCategoryName(expense.category ?? 'others'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              expense.description ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- Rp ${CurrencyFormatter.formatCurrency(expense.amount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444),
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(expense.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
