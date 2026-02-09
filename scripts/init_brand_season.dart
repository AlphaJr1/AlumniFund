import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  // Buat brand season aktif
  await firestore.collection('brand_seasons').add({
    'phase': 'input',
    'isActive': true,
    'inputDeadline': Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 30)),
    ),
    'votingDeadline': null,
    'winnerId': null,
  });

  print('✅ Brand season berhasil dibuat!');
  print('📅 Deadline: 30 hari dari sekarang');
}
