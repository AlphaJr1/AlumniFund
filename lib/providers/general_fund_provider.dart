import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/general_fund_model.dart';
import '../utils/constants.dart';

/// Provider untuk general fund (Dompet Bersama)
/// 
/// Returns real-time data dari general_fund/current document
final generalFundProvider = StreamProvider<GeneralFund>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.generalFund)
      .doc('current')
      .snapshots()
      .map((doc) => GeneralFund.fromFirestore(doc));
});
