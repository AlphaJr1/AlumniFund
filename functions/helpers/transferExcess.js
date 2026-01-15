/**
 * Helper: Transfer excess funds to general fund
 * Called when a target is closed and has excess funds
 */

const admin = require('firebase-admin');
const { COLLECTIONS, GENERAL_FUND_DOC_ID, SYSTEM_USER } = require('./constants');

/**
 * Transfer excess funds from closed target to general fund
 * @param {string} targetId - ID of the closed target
 * @param {number} amount - Excess amount to transfer
 * @param {Object} targetData - Target data for reference
 * @returns {Promise<void>}
 */
async function transferExcessToGeneralFund(targetId, amount, targetData) {
    const db = admin.firestore();
    const batch = db.batch();

    console.log(`Transferring Rp ${amount.toLocaleString('id-ID')} excess to general fund`);

    // Update general fund
    const gfRef = db.collection(COLLECTIONS.GENERAL_FUND).doc(GENERAL_FUND_DOC_ID);
    batch.update(gfRef, {
        balance: admin.firestore.FieldValue.increment(amount),
        total_income: admin.firestore.FieldValue.increment(amount),
        last_updated: admin.firestore.Timestamp.now(),
    });

    // Create transaction record
    const txRef = db.collection(COLLECTIONS.TRANSACTIONS).doc();
    batch.set(txRef, {
        id: txRef.id,
        type: 'income',
        amount: amount,
        target_id: 'general_fund',
        target_month: null,
        description: `Transfer kelebihan dari target ${targetData.month} ${targetData.year}`,
        proof_url: null,
        validated: true,
        validation_status: 'approved',
        created_at: admin.firestore.Timestamp.now(),
        input_at: admin.firestore.Timestamp.now(),
        created_by: SYSTEM_USER,
        metadata: {
            source_target_id: targetId,
            source_target_month: `${targetData.month} ${targetData.year}`,
            submission_method: 'auto',
            transfer_type: 'excess_funds',
        }
    });

    await batch.commit();
    console.log(`✓ Transferred Rp ${amount.toLocaleString('id-ID')} to general fund`);
}

module.exports = {
    transferExcessToGeneralFund,
};
