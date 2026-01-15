/**
 * Helper: Auto-allocate general fund to target
 * Supports virtual allocation pattern
 */

const admin = require('firebase-admin');
const { COLLECTIONS, GENERAL_FUND_DOC_ID } = require('./constants');

/**
 * Auto-allocate general fund balance to target (virtual allocation)
 * Does NOT deduct from fund, only sets allocated_from_fund
 * @param {string} targetId - Target document ID
 */
async function autoAllocateToTarget(targetId) {
    const db = admin.firestore();
    
    try {
        console.log(`Auto-allocating funds to target ${targetId}...`);
        
        // 1. Get general fund balance
        const fundDoc = await db.collection(COLLECTIONS.GENERAL_FUND)
            .doc(GENERAL_FUND_DOC_ID)
            .get();
        
        const fundBalance = fundDoc.data()?.balance || 0;
        
        if (fundBalance <= 0) {
            console.log('No funds available to allocate');
            return;
        }
        
        // 2. Get target
        const targetDoc = await db.collection(COLLECTIONS.GRADUATION_TARGETS)
            .doc(targetId)
            .get();
        
        if (!targetDoc.exists) {
            console.log(`Target ${targetId} not found`);
            return;
        }
        
        const targetData = targetDoc.data();
        const requiredBudget = targetData.target_amount || 0;
        const currentAmount = targetData.current_amount || 0;
        const stillNeeded = requiredBudget - currentAmount;
        
        // 3. Calculate allocation amount
        const newAllocation = Math.min(fundBalance, stillNeeded);
        const clampedAllocation = newAllocation > 0 ? newAllocation : 0;
        
        if (clampedAllocation <= 0) {
            console.log('Target already funded or no allocation needed');
            return;
        }
        
        // 4. Update allocated_from_fund (virtual allocation - fund balance NOT changed)
        await targetDoc.ref.update({
            allocated_from_fund: clampedAllocation, // Set to new value
            updated_at: admin.firestore.Timestamp.now(),
        });
        
        console.log(`✓ Allocated Rp ${clampedAllocation.toLocaleString('id-ID')} to target (virtual)`);
        console.log(`  Fund balance remains: Rp ${fundBalance.toLocaleString('id-ID')}`);
    } catch (error) {
        console.error('ERROR in autoAllocateToTarget:', error);
        // Don't throw - allocation is not critical
    }
}

module.exports = { autoAllocateToTarget };
