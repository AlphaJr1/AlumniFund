import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/constants.dart';

/// Reusable proof upload widget
class ProofUploadWidget extends StatefulWidget {
  final Function(Uint8List bytes, String fileName) onFileSelected;
  final bool isUploading;

  const ProofUploadWidget({
    super.key,
    required this.onFileSelected,
    this.isUploading = false,
  });

  @override
  State<ProofUploadWidget> createState() => _ProofUploadWidgetState();
}

class _ProofUploadWidgetState extends State<ProofUploadWidget> {
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  Widget build(BuildContext context) {
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
          onTap: widget.isUploading ? null : _pickFile,
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
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFileBytes != null ? Icons.check_circle : Icons.upload_file,
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
            !AppConstants.allowedImageExtensions.contains(file.extension!.toLowerCase())) {
          _showError('Format file tidak didukung. Gunakan JPG atau PNG');
          return;
        }

        setState(() {
          _selectedFileBytes = file.bytes;
          _selectedFileName = file.name;
        });

        // Callback to parent
        if (_selectedFileBytes != null && _selectedFileName != null) {
          widget.onFileSelected(_selectedFileBytes!, _selectedFileName!);
        }
      }
    } catch (e) {
      _showError('Gagal memilih file: $e');
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
}
