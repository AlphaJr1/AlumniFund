import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/constants.dart';

/// Service untuk handle Firebase Storage operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload transaction proof image
  /// Returns download URL dari uploaded image
  Future<String> uploadTransactionProof({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Generate unique filename dengan timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      // Reference ke storage path
      final ref =
          _storage.ref().child(StoragePaths.proofImages).child(uniqueFileName);

      // Upload file
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal upload gambar: $e');
    }
  }

  /// Upload QR code image
  /// Returns download URL dari uploaded QR code
  Future<String> uploadQRCode({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      final ref =
          _storage.ref().child(StoragePaths.qrCodes).child(uniqueFileName);

      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal upload QR code: $e');
    }
  }

  /// Delete file dari storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Get reference dari URL
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Gagal hapus file: $e');
    }
  }

  /// Delete all proof images from storage
  Future<void> deleteAllProofImages() async {
    try {
      final proofRef = _storage.ref().child(StoragePaths.proofImages);
      final proofList = await proofRef.listAll();
      for (var item in proofList.items) {
        await item.delete();
      }
    } catch (e) {
      throw Exception('Gagal hapus semua proof images: $e');
    }
  }

  /// Delete all QR codes from storage
  Future<void> deleteAllQRCodes() async {
    try {
      final qrRef = _storage.ref().child(StoragePaths.qrCodes);
      final qrList = await qrRef.listAll();
      for (var item in qrList.items) {
        await item.delete();
      }
    } catch (e) {
      throw Exception('Gagal hapus semua QR codes: $e');
    }
  }
}
