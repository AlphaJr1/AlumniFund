/**
 * Scheduled Function: Cleanup Old Submissions
 * Delete old rejected proof submissions (older than 30 days)
 * Runs weekly, Sunday at 2 AM
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { SCHEDULES, TIMEZONE, COLLECTIONS, RETENTION } = require('../helpers/constants');

const db = admin.firestore();
const storage = admin.storage();

/**
 * Scheduled function: Cleanup old rejected/pending submissions
 * Runs weekly to free up storage
 */
exports.cleanupOldSubmissions = functions.pubsub
    .schedule(SCHEDULES.CLEANUP_SUBMISSIONS)
    .timeZone(TIMEZONE)
    .onRun(async (context) => {
        console.log('=== Running cleanupOldSubmissions function ===');

        const retentionDays = RETENTION.REJECTED_SUBMISSIONS;
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

        console.log(`Deleting rejected submissions older than ${retentionDays} days (before ${cutoffDate.toISOString()})`);

        try {
            // Query old rejected submissions
            const submissionsSnapshot = await db.collection(COLLECTIONS.PENDING_SUBMISSIONS)
                .where('status', '==', 'rejected')
                .where('reviewed_at', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
                .get();

            if (submissionsSnapshot.empty) {
                console.log('No old submissions to clean up');
                return null;
            }

            console.log(`Found ${submissionsSnapshot.size} old submission(s) to delete`);

            const batch = db.batch();
            const storageDeletePromises = [];
            let deletedCount = 0;
            let storageErrorCount = 0;

            for (const doc of submissionsSnapshot.docs) {
                const submission = doc.data();

                // Delete proof image from Storage
                if (submission.proof_url) {
                    try {
                        // Extract file path from URL
                        // URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?token={token}
                        const url = new URL(submission.proof_url);
                        const pathMatch = url.pathname.match(/\/o\/(.+)/);

                        if (pathMatch) {
                            const filePath = decodeURIComponent(pathMatch[1]);
                            console.log(`Deleting storage file: ${filePath}`);

                            const bucket = storage.bucket();
                            const file = bucket.file(filePath);

                            storageDeletePromises.push(
                                file.delete()
                                    .then(() => {
                                        console.log(`✓ Deleted: ${filePath}`);
                                    })
                                    .catch(error => {
                                        console.error(`✗ Failed to delete ${filePath}:`, error.message);
                                        storageErrorCount++;
                                    })
                            );
                        }
                    } catch (error) {
                        console.error(`Error parsing proof_url for doc ${doc.id}:`, error.message);
                        storageErrorCount++;
                    }
                }

                // Delete Firestore document
                batch.delete(doc.ref);
                deletedCount++;
            }

            // Execute deletions
            await Promise.all([
                batch.commit(),
                ...storageDeletePromises
            ]);

            console.log(`✓ Deleted ${deletedCount} Firestore document(s)`);
            console.log(`✓ Deleted ${storageDeletePromises.length - storageErrorCount} storage file(s)`);

            if (storageErrorCount > 0) {
                console.warn(`⚠ ${storageErrorCount} storage deletion(s) failed`);
            }

            console.log('=== cleanupOldSubmissions completed successfully ===');
            return null;

        } catch (error) {
            console.error('ERROR in cleanupOldSubmissions:', error);
            throw error; // Re-throw to trigger Cloud Functions retry
        }
    });
