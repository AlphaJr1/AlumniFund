const admin = require('firebase-admin');

// Initialize without service account for emulator or use default credentials
admin.initializeApp({
    projectId: 'dompetalumni'
});

const db = admin.firestore();

async function updateSeasonActive() {
    try {
        // Get all brand_seasons documents
        const seasonsSnapshot = await db.collection('brand_seasons').get();

        console.log(`Found ${seasonsSnapshot.size} season(s)`);

        if (seasonsSnapshot.empty) {
            console.log('❌ No seasons found!');
            process.exit(1);
        }

        // Update each document to add isActive: true
        for (const doc of seasonsSnapshot.docs) {
            console.log(`Updating document: ${doc.id}`);
            console.log('Current data:', doc.data());

            await doc.ref.update({
                isActive: true
            });

            console.log(`✅ Updated ${doc.id} with isActive: true`);
        }

        console.log('\n✅ All seasons updated successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

updateSeasonActive();
