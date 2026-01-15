/**
 * Triggered Function: On Target Closed
 * Executes when a target status changes to "closed"
 * Handles analytics logging and auto-archival
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { TARGET_STATUS } = require('../helpers/constants');
const { logTargetAnalytics } = require('../helpers/analytics');
const { executeWithRetry } = require('../helpers/retryUtils');

/**
 * Triggered function: Execute actions when target status changes to "closed"
 * Handles archival, notifications (future), analytics
 */
exports.onTargetClosed = functions.firestore
    .document('graduation_targets/{targetId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        const targetId = context.params.targetId;

        // Only execute if status just changed to "closed"
        if (before.status !== TARGET_STATUS.CLOSED && after.status === TARGET_STATUS.CLOSED) {
            console.log(`=== Target closed: ${after.month} ${after.year} (ID: ${targetId}) ===`);

            try {
                // Log analytics with retry
                await executeWithRetry(
                    () => logTargetAnalytics(targetId, after),
                    3
                );

                // Check if all graduates have graduated (for archival)
                const now = new Date();

                if (after.graduates && after.graduates.length > 0) {
                    // Find the latest graduation date
                    const graduateDates = after.graduates
                        .map(g => g.date?.toDate())
                        .filter(date => date != null);

                    if (graduateDates.length > 0) {
                        const lastGraduateDate = new Date(Math.max(...graduateDates));

                        console.log(`Last graduate date: ${lastGraduateDate.toISOString()}`);
                        console.log(`Current date: ${now.toISOString()}`);

                        // If all graduations have passed, archive the target
                        if (now > lastGraduateDate) {
                            console.log('All graduates completed - archiving target');

                            await change.after.ref.update({
                                status: TARGET_STATUS.ARCHIVED,
                                updated_at: admin.firestore.Timestamp.now(),
                            });

                            console.log('✓ Target archived successfully');
                        } else {
                            console.log('Some graduations still upcoming - keeping as closed');
                        }
                    }
                }

                // Future: Send notifications
                // await sendClosureNotifications(targetId, after);

                console.log('=== onTargetClosed completed successfully ===');
                return null;

            } catch (error) {
                console.error('ERROR in onTargetClosed:', error);
                // Don't throw - we don't want to retry this trigger
                // Analytics failure shouldn't block the closure
                return null;
            }
        }

        // Status didn't change to closed, ignore
        return null;
    });
