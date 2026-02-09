const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createBrandSeason() {
    try {
        const deadline = new Date();
        deadline.setDate(deadline.getDate() + 30);

        await db.collection('brand_seasons').add({
            phase: 'input',
            isActive: true,
            inputDeadline: admin.firestore.Timestamp.fromDate(deadline),
            votingDeadline: null,
            winnerId: null
        });

        console.log('✅ Brand season created successfully!');
        console.log('📅 Deadline:', deadline.toISOString());
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

createBrandSeason();
