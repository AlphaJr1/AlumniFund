/**
 * Firebase Cloud Functions for Dompet Alumni
 * 
 * This is the main entry point for all cloud functions.
 * Functions are organized into:
 * - scheduled/: Time-triggered functions (cron jobs)
 * - triggers/: Event-triggered functions (Firestore changes)
 * - helpers/: Shared utility functions
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK (only once)
admin.initializeApp();

// Export all scheduled functions
const { checkDeadlines } = require('./scheduled/checkDeadlines');
const { updateClosingSoonStatus } = require('./scheduled/updateClosingSoonStatus');
const { cleanupOldSubmissions } = require('./scheduled/cleanupOldSubmissions');

exports.checkDeadlines = checkDeadlines;
exports.updateClosingSoonStatus = updateClosingSoonStatus;
exports.cleanupOldSubmissions = cleanupOldSubmissions;

// Export all triggered functions
const { onTargetClosed } = require('./triggers/onTargetClosed');
const { routeIncome } = require('./triggers/routeIncome');
const { onTargetCreated } = require('./triggers/onTargetCreated');

exports.onTargetClosed = onTargetClosed;
exports.routeIncome = routeIncome;
exports.onTargetCreated = onTargetCreated;

// Log initialization
console.log('Firebase Cloud Functions initialized');

