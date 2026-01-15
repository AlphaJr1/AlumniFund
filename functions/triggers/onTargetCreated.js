/**
 * Triggered Function: On Target Created
 * Auto-activates newly created target if no active target exists
 * Auto-allocates general fund balance to new active target
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { COLLECTIONS, TARGET_STATUS } = require('../helpers/constants');
const { autoAllocateToTarget } = require('../helpers/autoAllocate');

const db = admin.firestore();

/**
 * Triggered function: Auto-activate and allocate when new target is created
 * Executes when new graduation target document is created
 */
exports.onTargetCreated = functions.firestore
    .document('graduation_targets/{targetId}')
    .onCreate(async (snapshot, context) => {
        const targetId = context.params.targetId;
        const targetData = snapshot.data();

        console.log(`=== New target created: ${targetData.month} ${targetData.year} (ID: ${targetId}) ===`);

        try {
            // 1. Check if there's currently an active target
            const activeSnapshot = await db.collection(COLLECTIONS.GRADUATION_TARGETS)
                .where('status', '==', TARGET_STATUS.ACTIVE)
                .limit(1)
                .get();

            // 2. If no active target and this target is 'upcoming', activate it
            if (activeSnapshot.empty && targetData.status === TARGET_STATUS.UPCOMING) {
                console.log('No active target found - activating new target');

                await snapshot.ref.update({
                    status: TARGET_STATUS.ACTIVE,
                    open_date: admin.firestore.Timestamp.now(),
                    updated_at: admin.firestore.Timestamp.now(),
                });

                console.log('✓ Target activated');

                // Auto-allocate general fund to new active target
                await autoAllocateToTarget(targetId);
            }
            // 3. If target was created as 'active' (client-side logic), just allocate
            else if (targetData.status === TARGET_STATUS.ACTIVE) {
                console.log('Target created as active - allocating funds');
                await autoAllocateToTarget(targetId);
            }
            else {
                console.log('Active target exists - new target remains upcoming');
            }

            console.log('=== onTargetCreated completed successfully ===');
            return null;

        } catch (error) {
            console.error('ERROR in onTargetCreated:', error);
            // Don't throw - this is non-critical automation
            return null;
        }
    });
