import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/graduation_target_model.dart';
import '../models/pending_submission_model.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/url_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal popup untuk donasi dengan multi-payment support
class DonationModal extends ConsumerStatefulWidget {
  final GraduationTarget target;

  const DonationModal({
    super.key,
    required this.target,
  });

  @override
  ConsumerState<DonationModal> createState() => _DonationModalState();
}

class _DonationModalState extends ConsumerState<DonationModal> {
  int _selectedTabIndex = 0;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final paymentMethods = ref.watch(paymentMethodsProvider);
    final adminConfig = ref.watch(adminConfigProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target info summary
                    _buildTargetSummary(),
                    const SizedBox(height: 24),

                    // Payment method tabs
                    _buildPaymentTabs(paymentMethods),
                    const SizedBox(height: 16),

                    // Payment method content
                    if (paymentMethods.isNotEmpty)
                      _buildPaymentMethodCard(
                          paymentMethods[_selectedTabIndex]),
                    const SizedBox(height: 24),

                    // Proof upload section
                    _buildProofUploadSection(),
                    const SizedBox(height: 24),

                    // WhatsApp alternative
                    _buildWhatsAppButton(adminConfig),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryTeal, AppConstants.darkTeal],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConstants.borderRadiusLarge),
          topRight: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '💸 DONASI SEKARANG',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.lightTeal,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎓 ${widget.target.monthYearDisplay.toUpperCase()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.target.graduates.length} Wisudawan • Target: ${CurrencyFormatter.formatCurrency(widget.target.targetAmount)}',
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Terkumpul: ${CurrencyFormatter.formatCurrency(widget.target.currentAmount)} (${widget.target.percentage.toStringAsFixed(0)}%)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTabs(List<PaymentMethod> methods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Metode Pembayaran:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.gray700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: methods.asMap().entries.map((entry) {
            final index = entry.key;
            final method = entry.value;
            final isSelected = _selectedTabIndex == index;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.primaryTeal : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.primaryTeal
                        : AppConstants.gray300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  method.provider,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppConstants.gray700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.gray50,
        border: Border.all(color: AppConstants.gray200),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider name
          Text(
            method.isBank ? '🏦 ${method.provider}' : '💳 ${method.provider}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.gray900,
            ),
          ),
          const SizedBox(height: 12),

          // Account number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nomor Rekening:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.gray600,
                ),
              ),
              Text(
                method.accountNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Account name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Atas Nama:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.gray600,
                ),
              ),
              Text(
                method.accountName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.gray900,
                ),
              ),
            ],
          ),

          // QR Code (if available)
          if (method.qrCodeUrl != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  method.qrCodeUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('QR Code tidak tersedia'),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProofUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📸 Upload Bukti Transfer:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.gray700,
          ),
        ),
        const SizedBox(height: 12),

        // File picker button
        InkWell(
          onTap: _isUploading ? null : _pickFile,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _selectedFileBytes != null
                  ? AppConstants.successBg
                  : AppConstants.gray50,
              border: Border.all(
                color: _selectedFileBytes != null
                    ? AppConstants.successBorder
                    : AppConstants.gray300,
                style: BorderStyle.solid,
              ),
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFileBytes != null
                      ? Icons.check_circle
                      : Icons.upload_file,
                  size: 48,
                  color: _selectedFileBytes != null
                      ? AppConstants.successGreen
                      : AppConstants.gray400,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedFileBytes != null
                      ? '✓ File terpilih: $_selectedFileName'
                      : 'Klik untuk pilih file (JPG/PNG, max 5MB)',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedFileBytes != null
                        ? AppConstants.successGreen
                        : AppConstants.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Upload button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedFileBytes != null && !_isUploading
                ? _uploadProof
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusSmall),
              ),
            ),
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '✓ KIRIM BUKTI TRANSFER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppButton(AdminConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Atau konfirmasi via WhatsApp:',
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.gray600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openWhatsApp(config),
            icon: const Text('📱', style: TextStyle(fontSize: 20)),
            label: const Text(
              'Konfirmasi via WhatsApp',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.whatsappGreen,
              side:
                  const BorderSide(color: AppConstants.whatsappGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size
        if (file.size > AppConstants.maxFileSize) {
          _showError('Ukuran file terlalu besar (Max: 5MB)');
          return;
        }

        // Validate file type
        if (file.extension != null &&
            !AppConstants.allowedImageExtensions
                .contains(file.extension!.toLowerCase())) {
          _showError('Format file tidak didukung. Gunakan JPG atau PNG');
          return;
        }

        setState(() {
          _selectedFileBytes = file.bytes;
          _selectedFileName = file.name;
        });
      }
    } catch (e) {
      _showError('Gagal memilih file: $e');
    }
  }

  Future<void> _uploadProof() async {
    if (_selectedFileBytes == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final storageService = StorageService();
      final firestoreService = FirestoreService();

      // Upload to Firebase Storage
      final downloadUrl = await storageService.uploadTransactionProof(
        imageBytes: _selectedFileBytes!,
        fileName: _selectedFileName ??
            'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Create pending submission in Firestore
      final submission = PendingSubmission(
        id: '', // Will be auto-generated
        proofUrl: downloadUrl,
        submittedAmount: 0, // User doesn't input amount, admin will verify
        targetId: widget.target.id,
        targetMonth: widget.target.monthYearDisplay,
        submittedAt: DateTime.now(),
        status: 'pending',
      );

      await firestoreService.createPendingSubmission(submission);

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccess(
            'Bukti transfer berhasil dikirim! Admin akan memvalidasi segera.');
      }
    } catch (e) {
      _showError('Gagal upload bukti: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _openWhatsApp(AdminConfig config) async {
    final url = UrlService.generateWhatsAppUrl(
      phoneNumber: config.whatsappNumber,
      targetMonth: widget.target.monthYearDisplay,
    );

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, webOnlyWindowName: '_blank');
      } else {
        _showError('Tidak dapat membuka WhatsApp');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorRed,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successGreen,
      ),
    );
  }
}
