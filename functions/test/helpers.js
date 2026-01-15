/**
 * Test Helper: Mock data generators
 */

const admin = require('firebase-admin');

/**
 * Generate mock target data
 */
function mockTarget(overrides = {}) {
    const now = admin.firestore.Timestamp.now();

    return {
        id: 'test-target-1',
        month: 'Januari',
        year: 2026,
        status: 'active',
        target_amount: 1000000,
        current_amount: 500000,
        graduates: [
            {
                name: 'John Doe',
                date: admin.firestore.Timestamp.fromDate(new Date('2026-01-15')),
                location: 'Jakarta'
            },
            {
                name: 'Jane Smith',
                date: admin.firestore.Timestamp.fromDate(new Date('2026-01-20')),
                location: 'Bandung'
            }
        ],
        deadline: admin.firestore.Timestamp.fromDate(new Date('2026-01-12')),
        open_date: now,
        created_at: now,
        updated_at: now,
        distribution: {
            per_person: 0,
            total_distributed: 0,
            status: 'pending',
            distributed_at: null
        },
        ...overrides
    };
}

/**
 * Generate mock transaction data
 */
function mockTransaction(overrides = {}) {
    const now = admin.firestore.Timestamp.now();

    return {
        id: 'test-tx-1',
        type: 'income',
        amount: 100000,
        target_id: null,
        target_month: null,
        description: 'Test donation',
        proof_url: 'https://example.com/proof.jpg',
        validated: true,
        validation_status: 'approved',
        created_at: now,
        input_at: now,
        created_by: 'test-user',
        metadata: {
            submission_method: 'manual'
        },
        ...overrides
    };
}

/**
 * Generate mock submission data
 */
function mockSubmission(overrides = {}) {
    const now = admin.firestore.Timestamp.now();

    return {
        id: 'test-submission-1',
        donor_name: 'Test Donor',
        amount: 50000,
        transfer_date: now,
        proof_url: 'https://firebasestorage.googleapis.com/v0/b/test/o/proofs%2Ftest.jpg?token=test',
        status: 'rejected',
        reviewed_at: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - 35 * 24 * 60 * 60 * 1000) // 35 days ago
        ),
        reviewed_by: 'admin@test.com',
        rejection_reason: 'Invalid proof',
        created_at: now,
        ...overrides
    };
}

/**
 * Generate mock general fund data
 */
function mockGeneralFund(overrides = {}) {
    const now = admin.firestore.Timestamp.now();

    return {
        balance: 0,
        total_income: 0,
        total_expense: 0,
        last_updated: now,
        ...overrides
    };
}

/**
 * Create past date (days ago)
 */
function daysAgo(days) {
    return admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - days * 24 * 60 * 60 * 1000)
    );
}

/**
 * Create future date (days from now)
 */
function daysFromNow(days) {
    return admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + days * 24 * 60 * 60 * 1000)
    );
}

module.exports = {
    mockTarget,
    mockTransaction,
    mockSubmission,
    mockGeneralFund,
    daysAgo,
    daysFromNow,
};
