/**
 * Scheduled Function: Update Closing Soon Status
 * Mark targets as "closing_soon" when deadline is within 7 days
 * Runs daily at midnight
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { SCHEDULES, TIMEZONE, COLLECTIONS, TARGET_STATUS } = require('../helpers/constants');
const { getSystemSettings } = require('../helpers/settingsHelper');

const db = admin.firestore();

/**
 * Scheduled function: Update targets to "closing_soon" status
 * Runs daily at midnight Jakarta time
 */
exports.updateClosingSoonStatus = functions.pubsub
    .schedule(SCHEDULES.UPDATE_CLOSING_SOON)
    .timeZone(TIMEZONE)
    .onRun(async (context) => {
        console.log('=== Running updateClosingSoonStatus function ===');

        const now = admin.firestore.Timestamp.now();

        // Fetch system settings from Firestore
        const settings = await getSystemSettings();
        const closingSoonDays = settings.deadlineOffsetDays;
        console.log(`Using deadline offset: ${closingSoonDays} days`);

        const closingSoonThreshold = new Date(
            now.toDate().getTime() + closingSoonDays * 24 * 60 * 60 * 1000
        );

        console.log(`Checking for targets with deadline <= ${closingSoonDays} days from now`);

        try {
            // Query active targets with deadline <= 7 days from now
            const targetsSnapshot = await db.collection(COLLECTIONS.GRADUATION_TARGETS)
                .where('status', '==', TARGET_STATUS.ACTIVE)
                .where('deadline', '<=', admin.firestore.Timestamp.fromDate(closingSoonThreshold))
                .get();

            if (targetsSnapshot.empty) {
                console.log('No targets approaching deadline');
                return null;
            }

            console.log(`Found ${targetsSnapshot.size} target(s) approaching deadline`);

            // Update status to closing_soon
            const batch = db.batch();

            targetsSnapshot.forEach(doc => {
                const target = doc.data();
                const daysRemaining = Math.ceil(
                    (target.deadline.toDate() - now.toDate()) / (1000 * 60 * 60 * 24)
                );

                console.log(`Marking as closing_soon: ${target.month} ${target.year} (${daysRemaining} days remaining)`);

                batch.update(doc.ref, {
                    status: TARGET_STATUS.CLOSING_SOON,
                    updated_at: now,
                });
            });

            await batch.commit();
            console.log(`✓ Updated ${targetsSnapshot.size} target(s) to closing_soon`);

            console.log('=== updateClosingSoonStatus completed successfully ===');
            return null;

        } catch (error) {
            console.error('ERROR in updateClosingSoonStatus:', error);
            throw error; // Re-throw to trigger Cloud Functions retry
        }
    });
