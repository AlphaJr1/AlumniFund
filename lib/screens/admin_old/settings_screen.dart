import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/settings_model.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Settings screen untuk admin
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _communityNameController = TextEditingController();
  
  Uint8List? _qrImageBytes;
  String? _qrImageName;
  String? _currentQrUrl;
  bool _isLoading = false;
  bool _isInitialized = false;
  
  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _targetAmountController.dispose();
    _communityNameController.dispose();
    super.dispose();
  }
  
  void _initializeFields(SettingsModel? settings) {
    if (_isInitialized || settings == null) return;
    
    _bankNameController.text = settings.paymentInfo.bankName;
    _accountNumberController.text = settings.paymentInfo.accountNumber;
    _accountNameController.text = settings.paymentInfo.accountName;
    _targetAmountController.text = settings.targetAmount.toString();
    _communityNameController.text = settings.communityName;
    _currentQrUrl = settings.paymentInfo.qrCodeUrl;
    _isInitialized = true;
  }
  
  Future<void> _pickQRImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _qrImageBytes = bytes;
          _qrImageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }
  
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      String? qrCodeUrl = _currentQrUrl;
      
      // Upload QR code jika ada gambar baru
      if (_qrImageBytes != null) {
        final storageService = StorageService();
        qrCodeUrl = await storageService.uploadQRCode(
          imageBytes: _qrImageBytes!,
          fileName: _qrImageName ?? 'qr_code.png',
        );
      }
      
      // Create settings model
      final settings = SettingsModel(
        id: 'default',
        paymentInfo: PaymentInfo(
          bankName: _bankNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          accountName: _accountNameController.text.trim(),
          qrCodeUrl: qrCodeUrl,
        ),
        targetAmount: double.parse(_targetAmountController.text),
        communityName: _communityNameController.text.trim(),
      );
      
      // Save to Firestore
      final firestoreService = FirestoreService();
      await firestoreService.updateSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan berhasil disimpan')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pengaturan: $e')),
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
  
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      
      body: settingsAsync.when(
        data: (settings) {
          _initializeFields(settings);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Community name
                  Text(
                    'Informasi Komunitas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  
                  const SizedBox(height: AppTheme.spacingM),
                  
                  TextFormField(
                    controller: _communityNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Komunitas',
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama komunitas tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingM),
                  
                  TextFormField(
                    controller: _targetAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Dana',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Target dana tidak boleh kosong';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Target dana harus lebih dari 0';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Payment info
                  Text(
                    'Informasi Rekening',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  
                  const SizedBox(height: AppTheme.spacingM),
                  
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Bank',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama bank tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingM),
                  
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Rekening',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nomor rekening tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingM),
                  
                  TextFormField(
                    controller: _accountNameController,
                    decoration: const InputDecoration(
                      labelText: 'Atas Nama',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama pemilik rekening tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // QR Code
                  Text(
                    'QR Code Pembayaran',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  
                  const SizedBox(height: AppTheme.spacingM),
                  
                  if (_qrImageBytes != null) ...[
                    // New QR preview
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.primaryColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        child: Image.memory(
                          _qrImageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    OutlinedButton.icon(
                      onPressed: _pickQRImage,
                      icon: const Icon(Icons.edit),
                      label: const Text('Ganti QR Code'),
                    ),
                  ] else if (_currentQrUrl != null) ...[
                    // Current QR preview
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.primaryColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        child: Image.network(
                          _currentQrUrl!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    OutlinedButton.icon(
                      onPressed: _pickQRImage,
                      icon: const Icon(Icons.edit),
                      label: const Text('Ganti QR Code'),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _pickQRImage,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Upload QR Code'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Save button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan Pengaturan'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
