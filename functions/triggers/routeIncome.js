/**
 * Triggered Function: Route Income
 * Auto-route new income transactions to active target or general fund
 * Executes when new transaction is created
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { COLLECTIONS, TARGET_STATUS, TRANSACTION_TYPE, GENERAL_FUND_DOC_ID } = require('../helpers/constants');

const db = admin.firestore();

/**
 * Triggered function: Auto-route income to correct destination
 * Executes when new income transaction is created
 */
exports.routeIncome = functions.firestore
    .document('transactions/{transactionId}')
    .onCreate(async (snapshot, context) => {
        const transaction = snapshot.data();
        const transactionId = context.params.transactionId;

        // Only process income transactions
        if (transaction.type !== TRANSACTION_TYPE.INCOME) {
            console.log(`Transaction ${transactionId} is not income, skipping`);
            return null;
        }

        // Check if target_id is already set (manual admin input)
        if (transaction.target_id) {
            console.log(`Transaction ${transactionId} already has target_id: ${transaction.target_id}, skipping auto-route`);
            return null;
        }

        console.log(`=== Auto-routing income transaction ${transactionId} (Rp ${transaction.amount?.toLocaleString('id-ID')}) ===`);

        try {
            // Find active target
            const activeTargetSnapshot = await db.collection(COLLECTIONS.GRADUATION_TARGETS)
                .where('status', 'in', [TARGET_STATUS.ACTIVE, TARGET_STATUS.CLOSING_SOON])
                .limit(1)
                .get();

            let targetId;
            let targetMonth;

            if (!activeTargetSnapshot.empty) {
                // Route to active target
                const activeTargetDoc = activeTargetSnapshot.docs[0];
                const targetData = activeTargetDoc.data();

                targetId = activeTargetDoc.id;
                targetMonth = `${targetData.month} ${targetData.year}`;

                console.log(`Routing to active target: ${targetMonth}`);

                // Update target current_amount
                await activeTargetDoc.ref.update({
                    current_amount: admin.firestore.FieldValue.increment(transaction.amount),
                    updated_at: admin.firestore.Timestamp.now(),
                });

                console.log(`✓ Updated target ${targetMonth} current_amount`);

            } else {
                // No active target - route to general fund
                targetId = GENERAL_FUND_DOC_ID;
                targetMonth = null;

                console.log('No active target - routing to general fund');

                // Update general fund
                await db.collection(COLLECTIONS.GENERAL_FUND).doc(GENERAL_FUND_DOC_ID).update({
                    balance: admin.firestore.FieldValue.increment(transaction.amount),
                    total_income: admin.firestore.FieldValue.increment(transaction.amount),
                    last_updated: admin.firestore.Timestamp.now(),
                });

                console.log('✓ Updated general fund balance');
            }

            // Update transaction document with routing info
            await snapshot.ref.update({
                target_id: targetId,
                target_month: targetMonth,
            });

            console.log(`✓ Transaction ${transactionId} routed to: ${targetId}`);
            console.log('=== routeIncome completed successfully ===');

            return null;

        } catch (error) {
            console.error('ERROR in routeIncome:', error);
            // Don't throw - transaction already created, we don't want infinite retries
            // Admin can manually fix routing if needed
            return null;
        }
    });
