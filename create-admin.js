const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./dompetalumni-firebase-adminsdk-fbsvc-6c106a51bf.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://dompetalumni.firebaseio.com'
});

// Admin credentials
const ADMIN_EMAIL = 'adrianalfajri@gmail.com';
const ADMIN_PASSWORD = 'adri210404';

async function createAdminUser() {
    try {
        console.log('🔧 Creating admin user...');

        // Check if user already exists
        try {
            const existingUser = await admin.auth().getUserByEmail(ADMIN_EMAIL);
            console.log('⚠️  User already exists!');
            console.log('   Email:', existingUser.email);
            console.log('   UID:', existingUser.uid);
            console.log('   Created:', existingUser.metadata.creationTime);
            console.log('\n✅ Admin account is ready to use!');
            process.exit(0);
        } catch (error) {
            if (error.code !== 'auth/user-not-found') {
                throw error;
            }
            // User doesn't exist, continue to create
        }

        // Create new user
        const userRecord = await admin.auth().createUser({
            email: ADMIN_EMAIL,
            password: ADMIN_PASSWORD,
            emailVerified: true, // Auto-verify email
            disabled: false
        });

        console.log('✅ Admin user created successfully!');
        console.log('   Email:', userRecord.email);
        console.log('   UID:', userRecord.uid);
        console.log('   Created:', userRecord.metadata.creationTime);
        console.log('\n🎉 You can now login at: http://localhost:8000/admin/login');
        console.log('   Email:', ADMIN_EMAIL);
        console.log('   Password:', ADMIN_PASSWORD);

    } catch (error) {
        console.error('❌ Error creating admin user:', error.message);
        process.exit(1);
    }
}

// Run the script
createAdminUser();
