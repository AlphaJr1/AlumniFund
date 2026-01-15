import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script untuk seed initial data ke Firestore
/// 
/// Usage:
///   dart run scripts/seed_data.dart
/// 
/// Pastikan Firebase emulator sudah running atau sudah login ke production
Future<void> main() async {
  print('🌱 Starting data seeding...\n');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Connect to emulator jika running di localhost
    // Comment jika mau seed ke production
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    print('✅ Connected to Firestore Emulator (localhost:8080)\n');
    
    final firestore = FirebaseFirestore.instance;
    
    // 1. Seed Settings
    print('📝 Seeding settings...');
    await firestore.collection('settings').doc('app_config').set({
      'payment_methods': [
        {
          'type': 'bank',
          'provider': 'BNI',
          'account_number': '1428471525',
          'account_name': 'Adrian Alfajri',
          'qr_code_url': null,
        },
        {
          'type': 'bank',
          'provider': 'BCA',
          'account_number': '3000968357',
          'account_name': 'Adrian Alfajri',
          'qr_code_url': null,
        },
        {
          'type': 'ewallet',
          'provider': 'OVO',
          'account_number': '081377707700',
          'account_name': 'Adrian Alfajri',
          'qr_code_url': null,
        },
        {
          'type': 'ewallet',
          'provider': 'Gopay',
          'account_number': '081377707700',
          'account_name': 'Adrian Alfajri',
          'qr_code_url': null,
        },
      ],
      'system_config': {
        'per_person_allocation': 250000,
        'deadline_offset_days': 3,
        'minimum_contribution': 10000,
        'auto_open_next_target': true,
      },
      'admin_config': {
        'whatsapp_number': '+6281377707700',
        'admin_email': 'adrianalfajri@gmail.com',
      },
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': 'seed_script',
    });
    print('   ✅ Settings created\n');
    
    // 2. Seed General Fund
    print('💰 Seeding general fund...');
    await firestore.collection('general_fund').doc('current').set({
      'balance': 0,
      'last_updated': FieldValue.serverTimestamp(),
      'total_income': 0,
      'total_expense': 0,
      'transaction_count': 0,
    });
    print('   ✅ General fund created\n');
    
    // 3. Seed Sample Graduation Target
    print('🎓 Seeding sample graduation target...');
    await firestore.collection('graduation_targets').doc('mei_2026').set({
      'month': 5,
      'year': 2026,
      'graduates': [
        {
          'name': 'Budi Santoso',
          'date': Timestamp.fromDate(DateTime(2026, 5, 15)),
          'location': 'Universitas Indonesia',
        },
        {
          'name': 'Siti Rahmawati',
          'date': Timestamp.fromDate(DateTime(2026, 5, 20)),
          'location': 'ITB',
        },
      ],
      'target_amount': 500000,
      'current_amount': 0,
      'deadline': Timestamp.fromDate(DateTime(2026, 5, 12)),
      'status': 'active',
      'distribution': {
        'per_person': 0,
        'total_distributed': 0,
        'status': 'pending',
        'distributed_at': null,
      },
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    print('   ✅ Graduation target created (Mei 2026)\n');
    
    // 4. (Optional) Seed Sample Transaction
    print('💸 Seeding sample transaction...');
    await firestore.collection('transactions').add({
      'type': 'income',
      'amount': 100000,
      'target_id': 'mei_2026',
      'target_month': 'Mei 2026',
      'description': 'Donasi awal untuk testing',
      'proof_url': null,
      'validated': true,
      'validation_status': 'approved',
      'created_at': FieldValue.serverTimestamp(),
      'input_at': FieldValue.serverTimestamp(),
      'created_by': 'seed_script',
    });
    print('   ✅ Sample transaction created\n');
    
    // Update target current amount
    await firestore.collection('graduation_targets').doc('mei_2026').update({
      'current_amount': 100000,
    });
    print('   ✅ Target amount updated\n');
    
    print('🎉 Data seeding completed successfully!\n');
    print('📊 Summary:');
    print('   - Settings: 1 document');
    print('   - General Fund: 1 document');
    print('   - Graduation Targets: 1 document');
    print('   - Transactions: 1 document');
    print('\n✅ Ready to test!');
    
  } catch (e) {
    print('❌ Error seeding data: $e');
    print('\nMake sure:');
    print('1. Firebase emulator is running (firebase emulators:start)');
    print('2. Or you are logged in to Firebase (firebase login)');
  }
}
