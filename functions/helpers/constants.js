/**
 * Constants and configuration for Cloud Functions
 */

module.exports = {
    // Timezone configuration
    TIMEZONE: 'Asia/Jakarta',

    // Schedule configurations (cron format)
    SCHEDULES: {
        CHECK_DEADLINES: '0 1 * * *',        // Daily at 1 AM (optimized from every hour)
        UPDATE_CLOSING_SOON: '0 0 * * *',    // Daily at midnight
        CLEANUP_SUBMISSIONS: '0 2 * * 0',     // Weekly Sunday at 2 AM
    },

    // Retention periods (days)
    RETENTION: {
        REJECTED_SUBMISSIONS: 30,  // Delete rejected submissions after 30 days
    },

    // Target status definitions
    TARGET_STATUS: {
        UPCOMING: 'upcoming',
        ACTIVE: 'active',
        CLOSING_SOON: 'closing_soon',
        CLOSED: 'closed',
        ARCHIVED: 'archived',
    },

    // Transaction types
    TRANSACTION_TYPE: {
        INCOME: 'income',
        EXPENSE: 'expense',
    },

    // System defaults
    DEFAULTS: {
        PER_PERSON_ALLOCATION: 250000,  // Rp 250.000
        CLOSING_SOON_DAYS: 7,           // Mark as closing_soon 7 days before deadline
    },

    // Collection names
    COLLECTIONS: {
        GRADUATION_TARGETS: 'graduation_targets',
        TRANSACTIONS: 'transactions',
        GENERAL_FUND: 'general_fund',
        PENDING_SUBMISSIONS: 'pending_submissions',
        ANALYTICS: 'analytics',
    },

    // General fund document ID
    GENERAL_FUND_DOC_ID: 'current',

    // System user for automated transactions
    SYSTEM_USER: 'system',
};
