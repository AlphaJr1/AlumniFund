/**
 * Scheduled Function: Check Deadlines
 * Auto-close targets past deadline
 * Runs every hour
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { SCHEDULES, TIMEZONE, COLLECTIONS, TARGET_STATUS } = require('../helpers/constants');
const { transferExcessToGeneralFund } = require('../helpers/transferExcess');
const { autoOpenNextTarget } = require('../helpers/autoOpenTarget');
const { executeWithRetry } = require('../helpers/retryUtils');
const { getSystemSettings } = require('../helpers/settingsHelper');

const db = admin.firestore();

/**
 * Scheduled function: Check for targets past deadline and auto-close them
 * Runs every hour
 */
exports.checkDeadlines = functions.pubsub
    .schedule(SCHEDULES.CHECK_DEADLINES)
    .timeZone(TIMEZONE)
    .onRun(async (context) => {
        console.log('=== Running checkDeadlines function ===');

        const now = admin.firestore.Timestamp.now();

        try {
            // Fetch system settings from Firestore
            const settings = await getSystemSettings();
            console.log(`Using settings: perPersonAllocation=${settings.perPersonAllocation}, autoOpenNextTarget=${settings.autoOpenNextTarget}`);

            // Query active/closing_soon targets past deadline
            const targetsSnapshot = await db.collection(COLLECTIONS.GRADUATION_TARGETS)
                .where('status', 'in', [TARGET_STATUS.ACTIVE, TARGET_STATUS.CLOSING_SOON])
                .where('deadline', '<', now)
                .get();

            if (targetsSnapshot.empty) {
                console.log('No targets past deadline');
                return null;
            }

            console.log(`Found ${targetsSnapshot.size} target(s) past deadline`);

            // Process each target
            const batch = db.batch();
            const closedTargets = [];

            for (const doc of targetsSnapshot.docs) {
                const target = doc.data();
                console.log(`Closing target: ${target.month} ${target.year} (ID: ${doc.id})`);

                // Calculate distribution using settings
                const isFullyFunded = target.current_amount >= target.target_amount;
                const perPerson = isFullyFunded
                    ? settings.perPersonAllocation
                    : Math.floor(target.current_amount / target.graduates.length);

                const totalDistributed = isFullyFunded
                    ? target.target_amount
                    : target.current_amount;

                const excess = isFullyFunded
                    ? target.current_amount - target.target_amount
                    : 0;

                // Update target status
                batch.update(doc.ref, {
                    status: TARGET_STATUS.CLOSED,
                    closed_date: now,
                    'distribution.per_person': perPerson,
                    'distribution.total_distributed': totalDistributed,
                    'distribution.status': 'distributed',
                    'distribution.distributed_at': now,
                    updated_at: now,
                });

                // Store closed target info for next steps
                closedTargets.push({
                    id: doc.id,
                    month: target.month,
                    year: target.year,
                    excess: excess,
                    data: target,
                });
            }

            // Commit batch
            await batch.commit();
            console.log(`✓ Closed ${closedTargets.length} target(s)`);

            // Handle post-closure actions for each target
            for (const target of closedTargets) {
                // Transfer excess to general fund
                if (target.excess > 0) {
                    await executeWithRetry(
                        () => transferExcessToGeneralFund(target.id, target.excess, target.data),
                        3
                    );
                }

                // Auto-open next target (only once, if enabled in settings)
                if (settings.autoOpenNextTarget && closedTargets.indexOf(target) === closedTargets.length - 1) {
                    await executeWithRetry(
                        () => autoOpenNextTarget(),
                        3
                    );
                }
            }

            console.log('=== checkDeadlines completed successfully ===');
            return null;

        } catch (error) {
            console.error('ERROR in checkDeadlines:', error);
            throw error; // Re-throw to trigger Cloud Functions retry
        }
    });
