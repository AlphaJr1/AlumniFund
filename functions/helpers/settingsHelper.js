const admin = require('firebase-admin');

/**
 * Fetch system settings from Firestore
 * Reads from settings/app_config document
 * 
 * @returns {Promise<Object>} System configuration object
 */
async function getSystemSettings() {
    try {
        const settingsDoc = await admin
            .firestore()
            .collection('settings')
            .doc('app_config')
            .get();

        if (!settingsDoc.exists) {
            console.warn('⚠ Settings document not found, using defaults');
            return getDefaultSettings();
        }

        const data = settingsDoc.data();
        const systemConfig = data.system_config || {};

        return {
            perPersonAllocation: systemConfig.per_person_allocation || 250000,
            deadlineOffsetDays: systemConfig.deadline_offset_days || 3,
            minimumContribution: systemConfig.minimum_contribution || 10000,
            autoOpenNextTarget: systemConfig.auto_open_next_target !== false, // Default true
        };
    } catch (error) {
        console.error('ERROR fetching settings:', error);
        return getDefaultSettings();
    }
}

/**
 * Get default settings (fallback)
 */
function getDefaultSettings() {
    return {
        perPersonAllocation: 250000,
        deadlineOffsetDays: 3,
        minimumContribution: 10000,
        autoOpenNextTarget: true,
    };
}

module.exports = {
    getSystemSettings,
    getDefaultSettings,
};
