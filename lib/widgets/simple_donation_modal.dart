import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../services/submission_service.dart';
import '../utils/toast_utils.dart';

/// Simplified all-in-one donation modal
/// Contains: Payment info + Upload + Submit
class SimpleDonationModal extends ConsumerStatefulWidget {
  final VoidCallback? onProofSubmitted;

  const SimpleDonationModal({super.key, this.onProofSubmitted});

  static Future<void> show(BuildContext context,
      {VoidCallback? onProofSubmitted}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          SimpleDonationModal(onProofSubmitted: onProofSubmitted),
    );
  }

  @override
  ConsumerState<SimpleDonationModal> createState() =>
      _SimpleDonationModalState();
}

class _SimpleDonationModalState extends ConsumerState<SimpleDonationModal> {
  final _submissionService = SubmissionService();
  final _usernameController = TextEditingController();

  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  late BuildContext _rootContext;
  bool _showAllMethods = false; // State untuk show/hide payment methods

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = file.bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(
          _rootContext,
          'Error memilih file: $e',
        );
      }
    }
  }

  void _showFullImagePreview() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Full image preview with zoom
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _selectedFileBytes!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedFileBytes == null) {
      ToastUtils.showError(
        _rootContext,
        'Please select transfer proof first',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      // 1. Upload image to Firebase Storage with progress tracking
      setState(() => _uploadProgress = 0.3); // Start upload
      final proofUrl =
          await _submissionService.uploadProofImage(_selectedFileBytes!);
      setState(() => _uploadProgress = 0.7); // Upload complete

      // 2. Create pending submission in Firestore
      await _submissionService.createSubmission(
        proofUrl: proofUrl,
        amount: null, // User will input amount in admin validation
        username: _usernameController.text.isNotEmpty
            ? _usernameController.text
            : null,
      );
      setState(() => _uploadProgress = 1.0); // Complete

      if (!mounted) return;

      // Close modal IMMEDIATELY
      Navigator.pop(context);

      // Trigger confetti from parent (dashboard)
      widget.onProofSubmitted?.call();

      // Show success toast message (above confetti)
      ToastUtils.showSuccess(
        _rootContext,
        '✅ Proof submitted successfully! Admin will verify within 24 hours.',
      );
    } catch (e) {
      if (!mounted) return;

      ToastUtils.showError(
        _rootContext,
        'Gagal mengirim: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Save root context for showing toasts above modal
    _rootContext = context;

    final paymentMethods = ref.watch(paymentMethodsProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: screenWidth * 0.9,
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 700,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                          .withLightness(0.3)
                          .toColor(),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '💳',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Drop Your Prop',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Payment Methods
                      const Text(
                        '📋 Transfer to one of the accounts:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Show 1 random method or all methods based on state
                      // Safety check: only show if paymentMethods is not empty
                      if (paymentMethods.isNotEmpty)
                        ...(_showAllMethods
                                ? paymentMethods
                                : [
                                    paymentMethods[(paymentMethods.hashCode %
                                            paymentMethods.length)
                                        .abs()]
                                  ])
                            .map((method) => _buildPaymentMethod(method))
                      else
                        // Show message when no payment methods available
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No payment methods configured yet. Please contact admin.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Show More / Show Less button
                      if (paymentMethods.length > 1) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAllMethods = !_showAllMethods;
                              });
                            },
                            icon: Icon(
                              _showAllMethods
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                            ),
                            label: Text(
                              _showAllMethods
                                  ? 'Show less'
                                  : 'Show ${paymentMethods.length - 1} more payment method${paymentMethods.length > 2 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Section 2: Upload Proof
                      const Text(
                        '📸 Upload Transfer Proof',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image Preview or File Picker
                      if (_selectedFileBytes != null) ...[
                        // Preview with delete button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Image preview (clickable)
                              InkWell(
                                onTap: _showFullImagePreview,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  child: Stack(
                                    children: [
                                      Image.memory(
                                        _selectedFileBytes!,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                      // Hover hint overlay
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.zoom_in,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Click to view',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // File info and delete button
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedFileName ?? 'Image selected',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF111827),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Delete button
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedFileBytes = null;
                                          _selectedFileName = null;
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      color: const Color(0xFFEF4444),
                                      tooltip: 'Remove image',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // File picker button
                        InkWell(
                          onTap: _pickFile,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Choose file',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Section 2.5: Username Input (Optional)
                      TextField(
                        controller: _usernameController,
                        enabled: !_isSubmitting,
                        decoration: InputDecoration(
                          labelText: 'Username (Optional)',
                          hintText: 'Your name or any name you want',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Leave empty to remain unnamed',
                          helperStyle: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        maxLength: 50,
                        style: const TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 16),

                      // Progress indicator (shown when submitting)
                      if (_isSubmitting) ...[
                        Column(
                          children: [
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Uploading... ${(_uploadProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],

                      // Section 3: Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle, size: 20),
                          label: Text(
                            _isSubmitting ? 'Submitting...' : 'Submit Proof',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF0284C7),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'After upload, admin will verify within 24 hours',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                _getPaymentLogo(method.provider),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to emoji if image fails
                  return Center(
                    child: Text(
                      _getPaymentIcon(method.provider),
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.provider,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  method.accountNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'a.n. ${method.accountName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Copy button
          IconButton(
            onPressed: () {
              // Copy to clipboard
              Clipboard.setData(ClipboardData(text: method.accountNumber));

              // Show toast above modal using Overlay
              ToastUtils.showSuccess(
                _rootContext,
                '${method.provider} number copied!',
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy number',
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  String _getPaymentLogo(String provider) {
    switch (provider.toLowerCase()) {
      case 'bni':
        return 'assets/images/payment_logos/bni.png';
      case 'bca':
        return 'assets/images/payment_logos/bca.png';
      case 'ovo':
        return 'assets/images/payment_logos/ovo.png';
      case 'gopay':
        return 'assets/images/payment_logos/gopay.png';
      default:
        return 'assets/images/payment_logos/bni.png'; // Fallback
    }
  }

  String _getPaymentIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'bni':
      case 'bca':
      case 'mandiri':
      case 'bri':
        return '🏦';
      case 'ovo':
        return '💰';
      case 'gopay':
        return '💳';
      case 'dana':
        return '💵';
      case 'shopeepay':
        return '🛒';
      default:
        return '💳';
    }
  }
}
