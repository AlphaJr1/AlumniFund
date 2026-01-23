import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service untuk handle proof submission
class SubmissionService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload proof image to Firebase Storage
  /// Returns download URL
  Future<String> uploadProofImage(dynamic file) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecondsSinceEpoch % 10000;
      final filename = '${timestamp}_$random.jpg';

      // Upload to Storage
      final storageRef = _storage.ref().child('proof_images/$filename');

      UploadTask uploadTask;
      if (kIsWeb) {
        // Web: file is Uint8List
        uploadTask = storageRef.putData(
          file is Uint8List ? file : Uint8List.fromList(file as List<int>),
        );
      } else {
        // Mobile: file is File
        uploadTask = storageRef.putFile(file as File);
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal upload file: ${e.toString()}');
    }
  }

  /// Create pending submission document
  Future<void> createSubmission({
    required String proofUrl,
    double? amount,
    String? username,
  }) async {
    try {
      await _firestore.collection('pending_submissions').add({
        'proof_url': proofUrl,
        'submitted_amount': amount,
        'submitted_at': FieldValue.serverTimestamp(),
        'status': 'pending',
        'target_id': null,
        'target_month': null,
        'reviewed_at': null,
        'reviewed_by': null,
        'notes': null,
        'submitter_name': username,
      });
    } catch (e) {
      throw Exception('Gagal submit: ${e.toString()}');
    }
  }

  /// Validate file size (max 5MB)
  bool validateFileSize(int bytes) {
    const maxSize = 5 * 1024 * 1024; // 5MB
    return bytes <= maxSize;
  }

  /// Validate file extension
  bool validateFileExtension(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'pdf'].contains(ext);
  }
}
