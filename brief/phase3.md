# **PROMPT 3: CLOUD FUNCTIONS & AUTOMATION**


# DOMPET ALUMNI - PHASE 3: CLOUD FUNCTIONS & AUTOMATION

## CONTEXT FROM PREVIOUS PHASES

**Phase 1**: Public dashboard with real-time data
**Phase 2**: Admin panel for manual management

**Phase 3 adds**: Automated processes via Cloud Functions for deadline management, status updates, and system intelligence.

---

## CLOUD FUNCTIONS OVERVIEW

### Required Functions

1. **checkDeadlines** (Scheduled): Auto-close targets past deadline
2. **updateClosingSoonStatus** (Scheduled): Update status to closing_soon at H-7
3. **onTargetClosed** (Triggered): Handle post-closure actions
4. **cleanupOldSubmissions** (Scheduled): Remove old rejected submissions

---

## FUNCTION 1: CHECK DEADLINES (Auto-Close Targets)

**Purpose**: Automatically close active targets when deadline is reached

**Trigger**: Scheduled (Cloud Scheduler)
**Schedule**: Every hour (`0 * * * *`)
**Runtime**: Node.js 18

**Implementation**:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin (only once in index.js)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Scheduled function: Check for targets past deadline and auto-close them
 * Runs every hour
 */
exports.checkDeadlines = functions.pubsub
  .schedule('0 * * * *')
  .timeZone('Asia/Jakarta')  // Set to Jakarta timezone
  .onRun(async (context) => {
    console.log('Running checkDeadlines function');
    
    const now = admin.firestore.Timestamp.now();
    
    // Query active/closing_soon targets past deadline
    const targetsSnapshot = await db.collection('graduation_targets')
      .where('status', 'in', ['active', 'closing_soon'])
      .where('deadline', '<', now)
      .get();
    
    if (targetsSnapshot.empty) {
      console.log('No targets past deadline');
      return null;
    }
    
    console.log(`Found ${targetsSnapshot.size} targets past deadline`);
    
    // Process each target
    const batch = db.batch();
    const closedTargets = [];
    
    for (const doc of targetsSnapshot.docs) {
      const target = doc.data();
      console.log(`Closing target: ${target.month} ${target.year}`);
      
      // Calculate distribution
      const isFullyFunded = target.current_amount >= target.target_amount;
      const perPerson = isFullyFunded 
        ? 250000 
        : target.current_amount / target.graduates.length;
      
      const totalDistributed = isFullyFunded
        ? target.target_amount
        : target.current_amount;
      
      const excess = isFullyFunded
        ? target.current_amount - target.target_amount
        : 0;
      
      // Update target status
      batch.update(doc.ref, {
        status: 'closed',
        closed_date: now,
        'distribution.per_person': perPerson,
        'distribution.total_distributed': totalDistributed,
        'distribution.status': 'distributed',
        'distribution.distributed_at': now,
        updated_at: now,
      });
      
      // Store closed target info for next steps
      closedTargets.push({
        id: doc.id,
        month: target.month,
        year: target.year,
        excess: excess,
      });
    }
    
    // Commit batch
    await batch.commit();
    console.log(`Closed ${closedTargets.length} targets`);
    
    // Handle post-closure actions for each target
    for (const target of closedTargets) {
      // Transfer excess to general fund
      if (target.excess > 0) {
        await transferExcessToGeneralFund(target.id, target.excess);
      }
      
      // Auto-open next target
      await autoOpenNextTarget();
    }
    
    return null;
  });

/**
 * Helper: Transfer excess funds to general fund
 */
async function transferExcessToGeneralFund(targetId, amount) {
  const batch = db.batch();
  
  // Update general fund
  const gfRef = db.collection('general_fund').doc('current');
  batch.update(gfRef, {
    balance: admin.firestore.FieldValue.increment(amount),
    total_income: admin.firestore.FieldValue.increment(amount),
    last_updated: admin.firestore.Timestamp.now(),
  });
  
  // Create transaction record
  const txRef = db.collection('transactions').doc();
  batch.set(txRef, {
    id: txRef.id,
    type: 'income',
    amount: amount,
    target_id: 'general_fund',
    target_month: null,
    description: `Transfer kelebihan dari target yang telah ditutup`,
    proof_url: null,
    validated: true,
    validation_status: 'approved',
    created_at: admin.firestore.Timestamp.now(),
    input_at: admin.firestore.Timestamp.now(),
    created_by: 'system',
    metadata: {
      source_target_id: targetId,
      submission_method: 'auto',
    }
  });
  
  await batch.commit();
  console.log(`Transferred Rp ${amount} excess to general fund`);
}

/**
 * Helper: Auto-open next upcoming target
 */
async function autoOpenNextTarget() {
  // Get next upcoming target (ordered by deadline)
  const nextTargetSnapshot = await db.collection('graduation_targets')
    .where('status', '==', 'upcoming')
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
  
  // Update target status to active
  batch.update(nextTargetDoc.ref, {
    status: 'active',
    open_date: admin.firestore.Timestamp.now(),
    updated_at: admin.firestore.Timestamp.now(),
  });
  
  // Transfer general fund balance to new target
  const gfDoc = await db.collection('general_fund').doc('current').get();
  const gfBalance = gfDoc.data()?.balance || 0;
  
  if (gfBalance > 0) {
    console.log(`Transferring Rp ${gfBalance} from general fund to new target`);
    
    // Update target amount
    batch.update(nextTargetDoc.ref, {
      current_amount: admin.firestore.FieldValue.increment(gfBalance),
    });
    
    // Clear general fund balance
    batch.update(db.collection('general_fund').doc('current'), {
      balance: 0,
      last_updated: admin.firestore.Timestamp.now(),
    });
    
    // Create transaction record
    const txRef = db.collection('transactions').doc();
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
      created_at: admin.firestore.Timestamp.now(),
      input_at: admin.firestore.Timestamp.now(),
      created_by: 'system',
      metadata: {
        submission_method: 'auto',
      }
    });
  }
  
  await batch.commit();
  console.log('Next target opened successfully');
}
```

---

## FUNCTION 2: UPDATE CLOSING SOON STATUS

**Purpose**: Mark targets as "closing_soon" when deadline is within 7 days

**Trigger**: Scheduled (Cloud Scheduler)
**Schedule**: Daily at midnight (`0 0 * * *`)
**Runtime**: Node.js 18

**Implementation**:

```javascript
/**
 * Scheduled function: Update targets to "closing_soon" status
 * Runs daily at midnight Jakarta time
 */
exports.updateClosingSoonStatus = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Asia/Jakarta')
  .onRun(async (context) => {
    console.log('Running updateClosingSoonStatus function');
    
    const now = admin.firestore.Timestamp.now();
    const sevenDaysFromNow = new Date(now.toDate().getTime() + 7 * 24 * 60 * 60 * 1000);
    
    // Query active targets with deadline <= 7 days from now
    const targetsSnapshot = await db.collection('graduation_targets')
      .where('status', '==', 'active')
      .where('deadline', '<=', admin.firestore.Timestamp.fromDate(sevenDaysFromNow))
      .get();
    
    if (targetsSnapshot.empty) {
      console.log('No targets approaching deadline');
      return null;
    }
    
    console.log(`Found ${targetsSnapshot.size} targets approaching deadline`);
    
    // Update status to closing_soon
    const batch = db.batch();
    
    targetsSnapshot.forEach(doc => {
      const target = doc.data();
      console.log(`Marking as closing soon: ${target.month} ${target.year}`);
      
      batch.update(doc.ref, {
        status: 'closing_soon',
        updated_at: now,
      });
    });
    
    await batch.commit();
    console.log(`Updated ${targetsSnapshot.size} targets to closing_soon`);
    
    return null;
  });
```

---

## FUNCTION 3: ON TARGET CLOSED (Triggered)

**Purpose**: Handle additional actions when a target is closed (manual or auto)

**Trigger**: Firestore document update
**Path**: `graduation_targets/{targetId}`
**Condition**: Status changes to "closed"

**Implementation**:

```javascript
/**
 * Triggered function: Execute actions when target status changes to "closed"
 * Handles archival, notifications (future), analytics
 */
exports.onTargetClosed = functions.firestore
  .document('graduation_targets/{targetId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only execute if status just changed to "closed"
    if (before.status !== 'closed' && after.status === 'closed') {
      console.log(`Target closed: ${after.month} ${after.year}`);
      
      const targetId = context.params.targetId;
      
      // Optional: Send notifications (future feature)
      // await sendClosureNotifications(targetId, after);
      
      // Optional: Log analytics
      await logTargetAnalytics(targetId, after);
      
      // Check if all graduates in this month have graduated (for archival)
      const now = new Date();
      const lastGraduateDate = new Date(
        Math.max(...after.graduates.map(g => g.date.toDate()))
      );
      
      if (now > lastGraduateDate) {
        console.log('All graduates completed - archiving target');
        await change.after.ref.update({
          status: 'archived',
          updated_at: admin.firestore.Timestamp.now(),
        });
      }
    }
    
    return null;
  });

/**
 * Helper: Log target completion analytics
 */
async function logTargetAnalytics(targetId, target) {
  const analyticsRef = db.collection('analytics').doc(targetId);
  
  await analyticsRef.set({
    target_id: targetId,
    month: target.month,
    year: target.year,
    target_amount: target.target_amount,
    collected_amount: target.current_amount,
    percentage: (target.current_amount / target.target_amount) * 100,
    graduates_count: target.graduates.length,
    distribution: target.distribution,
    opened_at: target.open_date,
    closed_at: target.closed_date,
    duration_days: Math.ceil(
      (target.closed_date.toDate() - target.open_date.toDate()) / (1000 * 60 * 60 * 24)
    ),
    status: target.current_amount >= target.target_amount ? 'fully_funded' : 'partially_funded',
    created_at: admin.firestore.Timestamp.now(),
  });
  
  console.log('Analytics logged');
}
```

---

## FUNCTION 4: CLEANUP OLD SUBMISSIONS

**Purpose**: Delete old rejected proof submissions (older than 30 days)

**Trigger**: Scheduled (Cloud Scheduler)
**Schedule**: Weekly, Sunday at 2 AM (`0 2 * * 0`)
**Runtime**: Node.js 18

**Implementation**:

```javascript
/**
 * Scheduled function: Cleanup old rejected/pending submissions
 * Runs weekly to free up storage
 */
exports.cleanupOldSubmissions = functions.pubsub
  .schedule('0 2 * * 0')  // Sunday 2 AM
  .timeZone('Asia/Jakarta')
  .onRun(async (context) => {
    console.log('Running cleanupOldSubmissions function');
    
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    // Query old rejected submissions
    const submissionsSnapshot = await db.collection('pending_submissions')
      .where('status', '==', 'rejected')
      .where('reviewed_at', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .get();
    
    if (submissionsSnapshot.empty) {
      console.log('No old submissions to clean up');
      return null;
    }
    
    console.log(`Found ${submissionsSnapshot.size} old submissions to delete`);
    
    const batch = db.batch();
    const storageDeletePromises = [];
    
    for (const doc of submissionsSnapshot.docs) {
      const submission = doc.data();
      
      // Delete proof image from Storage
      if (submission.proof_url) {
        try {
          const storageRef = admin.storage().refFromURL(submission.proof_url);
          storageDeletePromises.push(storageRef.delete());
        } catch (error) {
          console.error(`Error deleting image: ${error.message}`);
        }
      }
      
      // Delete Firestore document
      batch.delete(doc.ref);
    }
    
    // Execute deletions
    await Promise.all([
      batch.commit(),
      ...storageDeletePromises
    ]);
    
    console.log(`Cleaned up ${submissionsSnapshot.size} old submissions`);
    
    return null;
  });
```

---

## ADDITIONAL HELPER FUNCTIONS

### Income Routing Logic (Firestore Trigger)

**Purpose**: Auto-route new income to active target or general fund

**Trigger**: Firestore document create
**Path**: `transactions/{transactionId}`
**Condition**: Type is "income"

**Implementation**:

```javascript
/**
 * Triggered function: Auto-route income to correct destination
 * Executes when new income transaction is created
 */
exports.routeIncome = functions.firestore
  .document('transactions/{transactionId}')
  .onCreate(async (snapshot, context) => {
    const transaction = snapshot.data();
    
    // Only process income transactions
    if (transaction.type !== 'income') {
      return null;
    }
    
    // Check if target_id is already set (manual admin input)
    if (transaction.target_id) {
      console.log('Target already assigned, skipping auto-route');
      return null;
    }
    
    console.log('Auto-routing income transaction');
    
    // Find active target
    const activeTargetSnapshot = await db.collection('graduation_targets')
      .where('status', 'in', ['active', 'closing_soon'])
      .limit(1)
      .get();
    
    let targetId;
    let targetMonth;
    
    if (!activeTargetSnapshot.empty) {
      // Route to active target
      const activeTarget = activeTargetSnapshot.docs[0];
      targetId = activeTarget.id;
      const targetData = activeTarget.data();
      targetMonth = `${targetData.month} ${targetData.year}`;
      
      // Update target current_amount
      await activeTarget.ref.update({
        current_amount: admin.firestore.FieldValue.increment(transaction.amount),
        updated_at: admin.firestore.Timestamp.now(),
      });
      
      console.log(`Routed to active target: ${targetMonth}`);
    } else {
      // No active target - route to general fund
      targetId = 'general_fund';
      targetMonth = null;
      
      // Update general fund
      await db.collection('general_fund').doc('current').update({
        balance: admin.firestore.FieldValue.increment(transaction.amount),
        total_income: admin.firestore.FieldValue.increment(transaction.amount),
        last_updated: admin.firestore.Timestamp.now(),
      });
      
      console.log('Routed to general fund');
    }
    
    // Update transaction document
    await snapshot.ref.update({
      target_id: targetId,
      target_month: targetMonth,
    });
    
    return null;
  });
```

---

## DEPLOYMENT SETUP

### Firebase Functions Configuration

**File**: `functions/package.json`

```json
{
  "name": "dompet-alumni-functions",
  "version": "1.0.0",
  "description": "Cloud Functions for Dompet Alumni",
  "scripts": {
    "serve": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  },
  "devDependencies": {
    "firebase-functions-test": "^3.1.0"
  }
}
```

**File**: `functions/index.js` (Main entry point)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export all functions
exports.checkDeadlines = require('./scheduled/checkDeadlines');
exports.updateClosingSoonStatus = require('./scheduled/updateClosingSoonStatus');
exports.cleanupOldSubmissions = require('./scheduled/cleanupOldSubmissions');

exports.onTargetClosed = require('./triggers/onTargetClosed');
exports.routeIncome = require('./triggers/routeIncome');
```

**Project Structure**:
```
functions/
├── index.js
├── package.json
├── scheduled/
│   ├── checkDeadlines.js
│   ├── updateClosingSoonStatus.js
│   └── cleanupOldSubmissions.js
├── triggers/
│   ├── onTargetClosed.js
│   └── routeIncome.js
└── helpers/
    ├── transferExcess.js
    ├── autoOpenTarget.js
    └── analytics.js
```

---

## TESTING CLOUD FUNCTIONS

### Local Emulator Testing

**Setup**:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Functions
firebase init functions

# Start emulators
firebase emulators:start
```

**Test Scenarios**:

1. **Test checkDeadlines**:
   - Create target with deadline in past
   - Manually trigger function
   - Verify target status changes to "closed"
   - Check excess transferred to general fund
   - Verify next target opened (if exists)

2. **Test updateClosingSoonStatus**:
   - Create target with deadline 5 days from now
   - Manually trigger function
   - Verify status changes to "closing_soon"

3. **Test onTargetClosed**:
   - Manually update target status to "closed"
   - Verify analytics logged
   - Check archival logic (if all graduations passed)

4. **Test routeIncome**:
   - Create income transaction without target_id
   - Verify auto-routing to active target
   - Test with no active target (should route to general fund)

---

## MONITORING & LOGGING

### Cloud Function Logs

**View logs**:
```bash
firebase functions:log --only checkDeadlines
firebase functions:log --only updateClosingSoonStatus
```

**Log Alerts** (Firebase Console):
- Set up alerts for function errors
- Monitor execution time (timeout warnings)
- Track invocation count

### Error Handling

**Retry Logic**:
```javascript
// Add retry logic for critical operations
async function executeWithRetry(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      console.error(`Attempt ${i + 1} failed:`, error);
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}
```

**Error Notifications** (Future enhancement):
- Send email to admin on critical errors
- Log to separate error collection for review
- Integrate with monitoring tools (e.g., Sentry)

---

## PERFORMANCE OPTIMIZATIONS

### Batch Operations

Always use batches for multiple writes:
```javascript
const batch = db.batch();
// ... add operations
await batch.commit();
```

### Minimize Read Operations

Cache frequently accessed data:
```javascript
// Cache general fund ref
const gfRef = db.collection('general_fund').doc('current');
const gfData = (await gfRef.get()).data();
```

### Index Optimization

Required Firestore indexes (create via console or firebase.json):
```json
{
  "firestore": {
    "indexes": [
      {
        "collectionGroup": "graduation_targets",
        "queryScope": "COLLECTION",
        "fields": [
          { "fieldPath": "status", "order": "ASCENDING" },
          { "fieldPath": "deadline", "order": "ASCENDING" }
        ]
      },
      {
        "collectionGroup": "pending_submissions",
        "queryScope": "COLLECTION",
        "fields": [
          { "fieldPath": "status", "order": "ASCENDING" },
          { "fieldPath": "reviewed_at", "order": "ASCENDING" }
        ]
      }
    ]
  }
}
```

---

## SECURITY CONSIDERATIONS

### Function Access Control

- Functions run with admin privileges (bypass Firestore rules)
- Validate all input data before processing
- Use transactions for critical multi-step operations
- Implement rate limiting for triggered functions (if needed)

### Secrets Management

**Environment variables** (for sensitive data):
```bash
firebase functions:config:set admin.email="admin@example.com"
firebase functions:config:set whatsapp.number="+628123456789"
```

**Access in code**:
```javascript
const adminEmail = functions.config().admin.email;
```

---

## DELIVERABLES FOR PHASE 3

**Please generate:**

1. **Complete Cloud Functions project** (`/functions`)
   - All scheduled functions
   - All triggered functions
   - Helper utilities
   - Error handling
   - Logging

2. **Deployment configuration** (`firebase.json`, `firestore.indexes.json`)

3. **Testing suite** (`/functions/test`)
   - Unit tests for each function
   - Integration tests
   - Mock data generators

4. **Monitoring setup**
   - Error alerting configuration
   - Performance monitoring
   - Log analysis queries

5. **Documentation**
   - Function deployment guide
   - Testing instructions
   - Troubleshooting guide
   - Maintenance procedures

---

## FINAL INTEGRATION NOTES

### Complete System Flow

1. **User donates** → Web form or WhatsApp
2. **Proof uploaded** → Pending submissions collection
3. **Admin validates** → Creates income transaction
4. **routeIncome trigger** → Auto-assigns to active target/general fund
5. **Daily check** → updateClosingSoonStatus marks closing targets
6. **Hourly check** → checkDeadlines closes past-deadline targets
7. **onTargetClosed** → Handles excess transfer, opens next target
8. **Weekly cleanup** → Removes old rejected submissions

### System Health Checks

**Create admin dashboard widget** showing:
- Last function execution times
- Function error count (24h)
- Pending items count
- System status (all green/yellow/red)

### Backup & Recovery

**Automated backups**:
- Firestore export (weekly)
- Storage backup (monthly)
- Function code versioning (Git)

**Recovery procedure**:
1. Restore Firestore from backup
2. Redeploy functions
3. Verify all scheduled functions running
4. Check data consistency

---

**END OF PROMPT 3**

This completes all three phases of the Dompet Alumni project.

**COMPLETE SYSTEM SUMMARY:**

✅ **Phase 1**: Public dashboard with real-time transparency
✅ **Phase 2**: Admin panel for full fund management
✅ **Phase 3**: Automated deadline handling and system intelligence

The system is now production-ready with:
- Full transparency for members
- Powerful admin controls
- Automated lifecycle management
- Error handling & monitoring
- Scalability & security

Ready to deploy to Firebase and serve your alumni community! 🎓🚀
```
