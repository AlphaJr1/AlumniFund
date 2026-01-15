import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/settings_model.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/graduation_target_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/general_fund_provider.dart';
import '../../../providers/admin/pending_submissions_provider.dart';
import '../../../services/settings_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/admin/change_password_modal.dart';
import '../../../utils/migrations/month_name_migration.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _settingsService = SettingsService();
  final _formKey = GlobalKey<FormState>();

  // System Config Controllers
  late TextEditingController _perPersonController;
  late TextEditingController _deadlineOffsetController;
  late TextEditingController _minContributionController;
  bool _autoOpenNextTarget = true;

  // QR Code
  Uint8List? _qrImageBytes;
  String? _qrImageName;
  String? _currentQrUrl;

  bool _isLoadingSystemConfig = false;
  bool _isLoadingExport = false;
  bool _isLoadingReset = false;

  @override
  void initState() {
    super.initState();
    _perPersonController = TextEditingController();
    _deadlineOffsetController = TextEditingController();
    _minContributionController = TextEditingController();
  }

  @override
  void dispose() {
    _perPersonController.dispose();
    _deadlineOffsetController.dispose();
    _minContributionController.dispose();
    super.dispose();
  }

  Future<void> _pickQRImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _qrImageBytes = file.bytes;
          _qrImageName = file.name;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to select image: $e');
    }
  }

  Future<void> _saveQRCode() async {
    if (_qrImageBytes == null) {
      _showErrorSnackbar('Silakan pilih gambar QR code terlebih dahulu');
      return;
    }

    try {
      setState(() => _isLoadingSystemConfig = true);

      // Upload QR code
      final qrUrl = await _settingsService.uploadQRCode(
        imageBytes: _qrImageBytes!,
        fileName: _qrImageName ?? 'qr_code.png',
      );

      // Get current settings
      final settings = await _settingsService.getSettings();

      // Update payment methods dengan QR URL baru
      // Set QR URL ke payment method pertama (bisa bank atau e-wallet)
      final updatedMethods = settings.paymentMethods.map((method) {
        // Update hanya payment method pertama dengan QR code
        if (settings.paymentMethods.indexOf(method) == 0) {
          return PaymentMethod(
            type: method.type,
            provider: method.provider,
            accountNumber: method.accountNumber,
            accountName: method.accountName,
            qrCodeUrl: qrUrl,
          );
        }
        return method;
      }).toList();

      await _settingsService.updatePaymentMethods(
        paymentMethods: updatedMethods,
        updatedBy: FirebaseAuth.instance.currentUser?.email ?? 'admin',
      );

      setState(() {
        _currentQrUrl = qrUrl;
        _qrImageBytes = null;
        _qrImageName = null;
      });

      _showSuccessSnackbar('QR code uploaded successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to upload QR code: $e');
    } finally {
      setState(() => _isLoadingSystemConfig = false);
    }
  }

  Future<void> _saveSystemConfig() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoadingSystemConfig = true);

      // Get current settings to check what changed
      final currentSettings = await _settingsService.getSettings();
      final offsetChanged = currentSettings.systemConfig.deadlineOffsetDays !=
          int.parse(_deadlineOffsetController.text);
      final allocationChanged =
          currentSettings.systemConfig.perPersonAllocation !=
              double.parse(_perPersonController.text.replaceAll('.', ''));

      final systemConfig = SystemConfig(
        perPersonAllocation: double.parse(
          _perPersonController.text.replaceAll('.', ''),
        ),
        deadlineOffsetDays: int.parse(_deadlineOffsetController.text),
        minimumContribution: double.parse(
          _minContributionController.text.replaceAll('.', ''),
        ),
        autoOpenNextTarget: _autoOpenNextTarget,
      );

      await _settingsService.updateSystemConfig(
        systemConfig: systemConfig,
        updatedBy: FirebaseAuth.instance.currentUser?.email ?? 'admin',
      );

      // Show appropriate success message
      if (offsetChanged && allocationChanged) {
        _showSuccessSnackbar(
          'System configuration saved successfully. Deadline and target amount for all targets have been updated.',
        );
      } else if (offsetChanged) {
        _showSuccessSnackbar(
          'System configuration saved successfully. Deadline for all targets have been updated.',
        );
      } else if (allocationChanged) {
        _showSuccessSnackbar(
          'System configuration saved successfully. Target amount for all targets have been updated.',
        );
      } else {
        _showSuccessSnackbar('System configuration saved successfully');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to save configuration: $e');
    } finally {
      setState(() => _isLoadingSystemConfig = false);
    }
  }

  Future<void> _exportData() async {
    try {
      setState(() => _isLoadingExport = true);

      final data = await _settingsService.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Download file
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'dompet_alumni_export_${DateTime.now().millisecondsSinceEpoch}.json',
        )
        ..click();
      html.Url.revokeObjectUrl(url);

      _showSuccessSnackbar('Data exported successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to export data: $e');
    } finally {
      setState(() => _isLoadingExport = false);
    }
  }

  Future<void> _resetAllData() async {
    // First confirmation
    final confirmed1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppConstants.errorRed),
            SizedBox(width: 12),
            Text('Confirm Data Reset'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete ALL data?\n\n'
          'Data to be deleted:\n'
          '• All graduation targets\n'
          '• All transactions\n'
          '• All pending submissions\n'
          '• General fund will be reset to 0\n\n'
          'Settings and admin account will NOT be deleted.\n\n'
          'This action CANNOT be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Reset All Data'),
          ),
        ],
      ),
    );

    if (confirmed1 != true) return;

    // Second confirmation (type RESET)
    final textController = TextEditingController();
    final confirmed2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type "RESET" to confirm data deletion:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'RESET',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text == 'RESET') {
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop(false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, I\'m Sure'),
          ),
        ],
      ),
    );

    if (confirmed2 != true) return;

    // Execute reset
    try {
      setState(() => _isLoadingReset = true);

      await _settingsService.resetAllData();

      // FORCE REFRESH ALL DATA - Invalidate all providers
      ref.invalidate(graduationTargetsProvider);
      ref.invalidate(recentMixedTransactionsProvider);
      ref.invalidate(recentIncomeProvider);
      ref.invalidate(recentExpenseProvider);
      ref.invalidate(generalFundProvider);
      ref.invalidate(pendingSubmissionsProvider);
      ref.invalidate(activeTargetProvider);

      _showSuccessSnackbar('All data deleted successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to reset data: $e');
    } finally {
      setState(() => _isLoadingReset = false);
    }
  }

  void _showChangePasswordModal() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordModal(),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successGreen,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // Initialize controllers dengan current values
        if (_perPersonController.text.isEmpty) {
          _perPersonController.text = Formatters.formatCurrency(
            settings.systemConfig.perPersonAllocation,
          ).replaceAll('Rp ', '');
          _deadlineOffsetController.text =
              settings.systemConfig.deadlineOffsetDays.toString();
          _minContributionController.text = Formatters.formatCurrency(
            settings.systemConfig.minimumContribution,
          ).replaceAll('Rp ', '');
          _autoOpenNextTarget = settings.systemConfig.autoOpenNextTarget;
          _currentQrUrl = settings.paymentMethods.isNotEmpty
              ? settings.paymentMethods.first.qrCodeUrl
              : null;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage system configuration and payment information',
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.gray600,
                ),
              ),
              const SizedBox(height: 32),

              // Section 1: Payment Info
              _buildPaymentInfoSection(settings),
              const SizedBox(height: 32),

              // Section 2: System Configuration
              _buildSystemConfigSection(settings),
              const SizedBox(height: 32),

              // Section 3: Admin Account
              _buildAdminAccountSection(),
              const SizedBox(height: 32),

              // Section 4: Danger Zone
              _buildDangerZoneSection(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildPaymentInfoSection(AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: AppConstants.primaryTeal),
                SizedBox(width: 12),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Available payment methods for donations',
              style: TextStyle(color: AppConstants.gray600),
            ),
            const SizedBox(height: 24),

            // Payment Methods List
            ...settings.paymentMethods.map((method) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppConstants.gray300),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusSmall,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      method.isBank
                          ? Icons.account_balance
                          : Icons.account_balance_wallet,
                      color: AppConstants.primaryTeal,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.provider,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method.accountNumber,
                            style: const TextStyle(
                              color: AppConstants.gray600,
                            ),
                          ),
                          Text(
                            method.accountName,
                            style: const TextStyle(
                              color: AppConstants.gray600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 32),

            // QR Code Upload
            const Text(
              'Payment QR Code',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload 1 QR code for all payment methods',
              style: TextStyle(
                color: AppConstants.gray600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // QR Preview
            if (_currentQrUrl != null || _qrImageBytes != null)
              Container(
                width: 200,
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppConstants.gray300),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusSmall,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusSmall,
                  ),
                  child: _qrImageBytes != null
                      ? Image.memory(_qrImageBytes!, fit: BoxFit.cover)
                      : Image.network(_currentQrUrl!, fit: BoxFit.cover),
                ),
              ),

            // Upload Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickQRImage,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_qrImageBytes != null
                      ? 'Change QR Code'
                      : 'Choose QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.gray100,
                    foregroundColor: AppConstants.gray700,
                  ),
                ),
                if (_qrImageBytes != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoadingSystemConfig ? null : _saveQRCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryTeal,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoadingSystemConfig
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
                        : const Text('Save QR Code'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemConfigSection(AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.settings, color: AppConstants.primaryTeal),
                  SizedBox(width: 12),
                  Text(
                    'System Configuration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Default settings for target calculation and deadline',
                style: TextStyle(color: AppConstants.gray600),
              ),
              const SizedBox(height: 24),

              // Per Person Allocation
              TextFormField(
                controller: _perPersonController,
                decoration: const InputDecoration(
                  labelText: 'Allocation Per Person',
                  hintText: 'Example: 250.000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                  helperText: 'Amount allocated per recipient',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Allocation per person cannot be empty';
                  }
                  final number = double.tryParse(value.replaceAll('.', ''));
                  if (number == null || number <= 0) {
                    return 'Enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Deadline Offset
              TextFormField(
                controller: _deadlineOffsetController,
                decoration: const InputDecoration(
                  labelText: 'Deadline Offset (Days)',
                  hintText: 'Example: 3',
                  suffixText: 'days',
                  border: OutlineInputBorder(),
                  helperText: 'Deadline = D-X from nearest graduation date',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deadline offset cannot be empty';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Minimum Contribution
              TextFormField(
                controller: _minContributionController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Donation',
                  hintText: 'Example: 10.000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                  helperText: 'Minimum donation amount accepted',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Minimum donation cannot be empty';
                  }
                  final number = double.tryParse(value.replaceAll('.', ''));
                  if (number == null || number <= 0) {
                    return 'Enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Auto Open Next Target
              SwitchListTile(
                title: const Text('Auto-activate Next Target'),
                subtitle: const Text(
                  'Automatically activate next target when active target is closed',
                ),
                value: _autoOpenNextTarget,
                onChanged: (value) {
                  setState(() => _autoOpenNextTarget = value);
                },
                activeColor: AppConstants.primaryTeal,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoadingSystemConfig ? null : _saveSystemConfig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: _isLoadingSystemConfig
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
                    : const Text('Save Configuration'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminAccountSection() {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: AppConstants.primaryTeal),
                SizedBox(width: 12),
                Text(
                  'Admin Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Email
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(user?.email ?? 'N/A'),
              contentPadding: EdgeInsets.zero,
            ),

            // Last Login
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Last Login'),
              subtitle: Text(
                user?.metadata.lastSignInTime != null
                    ? _formatDateTime(user!.metadata.lastSignInTime!)
                    : 'N/A',
              ),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 16),

            // Change Password Button
            ElevatedButton.icon(
              onPressed: _showChangePasswordModal,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Change Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.gray100,
                foregroundColor: AppConstants.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection() {
    return Card(
      color: AppConstants.errorBg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: AppConstants.errorRed),
                SizedBox(width: 12),
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.errorRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Dangerous operations that can affect the entire system',
              style: TextStyle(color: AppConstants.gray700),
            ),
            const SizedBox(height: 24),

            // Export Data
            ListTile(
              leading: const Icon(Icons.download, color: AppConstants.gray700),
              title: const Text('Export Data'),
              subtitle: const Text(
                'Download all data in JSON format',
              ),
              trailing: ElevatedButton(
                onPressed: _isLoadingExport ? null : _exportData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.gray700,
                  foregroundColor: Colors.white,
                ),
                child: _isLoadingExport
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
                    : const Text('Export'),
              ),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 32),

            // Migrate Month Names
            ListTile(
              leading: const Icon(Icons.translate, color: Colors.orange),
              title: const Text(
                'Migrate to English Month Names',
                style: TextStyle(color: Colors.orange),
              ),
              subtitle: const Text(
                'Convert all existing targets from Indonesian to English month names',
              ),
              trailing: ElevatedButton(
                onPressed: _isLoadingReset
                    ? null
                    : () async {
                        final migration = MonthNameMigration();
                        try {
                          setState(() => _isLoadingReset = true);
                          await migration.runAll();
                          _showSuccessSnackbar(
                            'Migration completed! All targets updated to English.',
                          );
                        } catch (e) {
                          _showErrorSnackbar('Migration failed: $e');
                        } finally {
                          setState(() => _isLoadingReset = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Migrate'),
              ),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 32),

            // Reset All Data
            ListTile(
              leading: const Icon(Icons.delete_forever,
                  color: AppConstants.errorRed),
              title: const Text(
                'Reset All Data',
                style: TextStyle(color: AppConstants.errorRed),
              ),
              subtitle: const Text(
                'Delete all targets, transactions, and submissions. CANNOT BE UNDONE!',
              ),
              trailing: ElevatedButton(
                onPressed: _isLoadingReset ? null : _resetAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.errorRed,
                  foregroundColor: Colors.white,
                ),
                child: _isLoadingReset
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
                    : const Text('Reset All Data'),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }
}
