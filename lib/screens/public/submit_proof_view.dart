import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:confetti/confetti.dart';
import '../../services/submission_service.dart';

class SubmitProofView extends StatefulWidget {
  const SubmitProofView({super.key});

  @override
  State<SubmitProofView> createState() => _SubmitProofViewState();
}

class _SubmitProofViewState extends State<SubmitProofView> {
  final _submissionService = SubmissionService();
  final _amountController = TextEditingController();
  final _usernameController = TextEditingController();
  
  // Confetti controllers for side shooting
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;
  
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize confetti controllers
    _confettiControllerLeft = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiControllerRight = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    _amountController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true, // Get bytes for web
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
            _errorMessage = 'Format tidak didukung. Gunakan JPG, PNG, atau PDF';
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
        _errorMessage = 'Gagal memilih file: ${e.toString()}';
      });
    }
  }

  Future<void> _submitProof() async {
    if (_selectedFileBytes == null) {
      setState(() {
        _errorMessage = 'Pilih file terlebih dahulu';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Upload image
      final proofUrl = await _submissionService.uploadProofImage(_selectedFileBytes!);

      // Parse amount
      double? amount;
      if (_amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text.replaceAll(',', ''));
      }

      // Create submission
      await _submissionService.createSubmission(
        proofUrl: proofUrl,
        amount: amount,
        username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
      );

      setState(() {
        _isUploading = false;
        _isSuccess = true;
      });

      // 🎉 TRIGGER CONFETTI!
      _confettiControllerLeft.play();
      _confettiControllerRight.play();

      // Reset form after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isSuccess = false;
            _selectedFileBytes = null;
            _selectedFileName = null;
            _amountController.clear();
            _usernameController.clear();
          });
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Submit Bukti Transfer'),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(24),
              child: _isSuccess ? _buildSuccessState() : _buildForm(),
            ),
          ),
          // Confetti from LEFT side
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.3,
            child: ConfettiWidget(
              confettiController: _confettiControllerLeft,
              blastDirection: 0, // Shoot to the right (0 radians)
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 50,
              minBlastForce: 20,
              gravity: 0.2,
              canvas: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              colors: const [
                Color(0xFF14B8A6), // Teal
                Color(0xFFEC4899), // Pink
                Color(0xFF8B5CF6), // Purple
                Color(0xFFF97316), // Orange
                Color(0xFFFBBF24), // Yellow
              ],
            ),
          ),
          // Confetti from RIGHT side
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.3,
            child: ConfettiWidget(
              confettiController: _confettiControllerRight,
              blastDirection: pi, // Shoot to the left (180 degrees)
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 50,
              minBlastForce: 20,
              gravity: 0.2,
              canvas: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              colors: const [
                Color(0xFF14B8A6), // Teal
                Color(0xFFEC4899), // Pink
                Color(0xFF8B5CF6), // Purple
                Color(0xFFF97316), // Orange
                Color(0xFFFBBF24), // Yellow
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.all(48),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 48,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Terima Kasih!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bukti Anda sedang diproses',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Admin akan memvalidasi dalam 1-2 hari kerja',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Upload Bukti Transfer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload bukti transfer pemasukkan Anda',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Upload Area
            _buildUploadArea(),
            const SizedBox(height: 24),

            // Username Input (Optional)
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username (Optional)',
                hintText: 'Your name or any name you want',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Leave empty to remain unnamed',
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 12),

            // Amount Input (Optional)
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Jumlah (Opsional)',
                hintText: 'Masukkan jumlah transfer',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Opsional - admin dapat mengisi nanti',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
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

            // Submit Button
            ElevatedButton(
              onPressed: _isUploading || _selectedFileBytes == null ? null : _submitProof,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
                      'Submit Bukti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    if (_selectedFileBytes != null && _selectedFileName != null) {
      // Show preview
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview image (if JPG/PNG)
            if (_selectedFileName!.toLowerCase().endsWith('.jpg') ||
                _selectedFileName!.toLowerCase().endsWith('.jpeg') ||
                _selectedFileName!.toLowerCase().endsWith('.png'))
              Container(
                height: 120, // Reduced from 200 to prevent overflow
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

    // Show upload button
    return InkWell(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(48),
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
              'Click to upload image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Max 5MB (JPG, PNG, PDF)',
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
}
