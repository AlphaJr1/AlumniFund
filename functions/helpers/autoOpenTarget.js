/**
 * Helper: Auto-open next upcoming target
 * Called when a target is closed to activate the next one
 */

const admin = require('firebase-admin');
const { COLLECTIONS, GENERAL_FUND_DOC_ID, TARGET_STATUS, SYSTEM_USER } = require('./constants');

/**
 * Auto-open the next upcoming target and transfer general fund balance
 * @returns {Promise<void>}
 */
async function autoOpenNextTarget() {
    const db = admin.firestore();

    console.log('Checking for next upcoming target to open...');

    // Get next upcoming target (ordered by deadline)
    const nextTargetSnapshot = await db.collection(COLLECTIONS.GRADUATION_TARGETS)
        .where('status', '==', TARGET_STATUS.UPCOMING)
        .orderBy('deadline', 'asc')
        .limit(1)
        .get();

    if (nextTargetSnapshot.empty) {
        console.log('No upcoming targets to open');
        return;
    }

    const nextTargetDoc = nextTargetSnapshot.docs[0];
    const nextTarget = nextTargetDoc.data();

    console.log(`Auto-opening target: ${nextTarget.month} ${nextTarget.year}`);

    const batch = db.batch();
    const now = admin.firestore.Timestamp.now();

    // Update target status to active
    batch.update(nextTargetDoc.ref, {
        status: TARGET_STATUS.ACTIVE,
        open_date: now,
        updated_at: now,
    });

    // Get general fund balance
    const gfDoc = await db.collection(COLLECTIONS.GENERAL_FUND).doc(GENERAL_FUND_DOC_ID).get();
    const gfBalance = gfDoc.data()?.balance || 0;

    if (gfBalance > 0) {
        console.log(`Transferring Rp ${gfBalance.toLocaleString('id-ID')} from general fund to new target`);

        // Update target current_amount
        batch.update(nextTargetDoc.ref, {
            current_amount: admin.firestore.FieldValue.increment(gfBalance),
        });

        // Clear general fund balance
        batch.update(db.collection(COLLECTIONS.GENERAL_FUND).doc(GENERAL_FUND_DOC_ID), {
            balance: 0,
            last_updated: now,
        });

        // Create transaction record
        const txRef = db.collection(COLLECTIONS.TRANSACTIONS).doc();
        batch.set(txRef, {
            id: txRef.id,
            type: 'income',
            amount: gfBalance,
            target_id: nextTargetDoc.id,
            target_month: `${nextTarget.month} ${nextTarget.year}`,
            description: 'Transfer dari Dompet Bersama',
            proof_url: null,
            validated: true,
            validation_status: 'approved',
            created_at: now,
            input_at: now,
            created_by: SYSTEM_USER,
            metadata: {
                submission_method: 'auto',
                transfer_type: 'general_fund_to_target',
            }
        });
    }

    await batch.commit();
    console.log(`✓ Target ${nextTarget.month} ${nextTarget.year} opened successfully`);
}

module.exports = {
    autoOpenNextTarget,
};
