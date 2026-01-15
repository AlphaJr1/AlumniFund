const admin = require('firebase-admin');
const serviceAccount = require('./dompetalumni-firebase-adminsdk-fbsvc-6c106a51bf.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function seedData() {
  console.log('🌱 Seeding Firestore data...\n');

  try {
    // 1. Settings
    console.log('📝 Creating settings...');
    await db.collection('settings').doc('app_config').set({
      payment_methods: [
        {
          type: 'bank',
          provider: 'BNI',
          account_number: '1428471525',
          account_name: 'Adrian Alfajri',
          qr_code_url: null
        },
        {
          type: 'bank',
          provider: 'BCA',
          account_number: '3000968357',
          account_name: 'Adrian Alfajri',
          qr_code_url: null
        },
        {
          type: 'ewallet',
          provider: 'OVO',
          account_number: '081377707700',
          account_name: 'Adrian Alfajri',
          qr_code_url: null
        },
        {
          type: 'ewallet',
          provider: 'Gopay',
          account_number: '081377707700',
          account_name: 'Adrian Alfajri',
          qr_code_url: null
        }
      ],
      system_config: {
        per_person_allocation: 250000,
        deadline_offset_days: 3,
        minimum_contribution: 10000,
        auto_open_next_target: true
      },
      admin_config: {
        whatsapp_number: '+6281377707700',
        admin_email: 'adrianalfajri@gmail.com'
      },
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: 'seed_script'
    });
    console.log('   ✅ Settings created\n');

    // 2. General Fund
    console.log('💰 Creating general fund...');
    await db.collection('general_fund').doc('current').set({
      balance: 0,
      last_updated: admin.firestore.FieldValue.serverTimestamp(),
      total_income: 0,
      total_expense: 0,
      transaction_count: 0
    });
    console.log('   ✅ General fund created\n');

    console.log('🎉 Seed complete!\n');
    console.log('✅ Refresh your app - errors should be gone!');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding data:', error);
    process.exit(1);
  }
}

seedData();
