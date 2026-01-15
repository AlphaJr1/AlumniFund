/**
 * Helper: Log target analytics
 * Called when a target is closed to record completion metrics
 */

const admin = require('firebase-admin');
const { COLLECTIONS } = require('./constants');

/**
 * Log target completion analytics to analytics collection
 * @param {string} targetId - ID of the closed target
 * @param {Object} targetData - Target data
 * @returns {Promise<void>}
 */
async function logTargetAnalytics(targetId, targetData) {
    const db = admin.firestore();

    console.log(`Logging analytics for target: ${targetData.month} ${targetData.year}`);

    // Calculate metrics
    const percentage = targetData.target_amount > 0
        ? Math.round((targetData.current_amount / targetData.target_amount) * 100)
        : 0;

    const durationDays = targetData.open_date && targetData.closed_date
        ? Math.ceil(
            (targetData.closed_date.toDate() - targetData.open_date.toDate()) / (1000 * 60 * 60 * 24)
        )
        : null;

    const fundingStatus = targetData.current_amount >= targetData.target_amount
        ? 'fully_funded'
        : 'partially_funded';

    // Create analytics document
    const analyticsRef = db.collection(COLLECTIONS.ANALYTICS).doc(targetId);

    await analyticsRef.set({
        target_id: targetId,
        month: targetData.month,
        year: targetData.year,
        target_amount: targetData.target_amount,
        collected_amount: targetData.current_amount,
        percentage: percentage,
        graduates_count: targetData.graduates?.length || 0,
        distribution: targetData.distribution || null,
        opened_at: targetData.open_date || null,
        closed_at: targetData.closed_date || null,
        deadline: targetData.deadline || null,
        duration_days: durationDays,
        funding_status: fundingStatus,
        created_at: admin.firestore.Timestamp.now(),
        metadata: {
            auto_closed: targetData.closed_by === 'system',
            excess_amount: targetData.current_amount > targetData.target_amount
                ? targetData.current_amount - targetData.target_amount
                : 0,
        }
    });

    console.log(`✓ Analytics logged: ${percentage}% funded, ${durationDays} days duration`);
}

module.exports = {
    logTargetAnalytics,
};
