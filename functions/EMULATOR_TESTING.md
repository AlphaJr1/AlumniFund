# Emulator Testing Guide

## Setup Firebase Emulator

### Prerequisites
- Firebase CLI installed (v15+)
- Node.js 18+
- Functions dependencies installed

### Start Emulators
```bash
# Start functions and firestore emulators
cd functions
npm run serve

# Or from project root
firebase emulators:start --only functions,firestore
```

Emulator UI akan tersedia di: http://localhost:4000

## Manual Testing Scenarios

### 1. Test checkDeadlines Function

**Setup Data**:
```javascript
// Di Firestore Emulator UI atau via script
// Create expired target
{
  "graduation_targets/test-target-1": {
    "status": "active",
    "month": "Januari",
    "year": 2026,
    "deadline": Timestamp (1 day ago),
    "current_amount": 1500000,
    "target_amount": 1000000,
    "graduates": [
      { "name": "John", "date": Timestamp, "location": "Jakarta" }
    ],
    "open_date": Timestamp,
    "created_at": Timestamp,
    "updated_at": Timestamp,
    "distribution": {
      "per_person": 0,
      "total_distributed": 0,
      "status": "pending"
    }
  }
}

// Create upcoming target
{
  "graduation_targets/test-target-2": {
    "status": "upcoming",
    "deadline": Timestamp (30 days from now),
    "current_amount": 0,
    // ... other fields
  }
}

// Create general fund
{
  "general_fund/current": {
    "balance": 0,
    "total_income": 0,
    "total_expense": 0,
    "last_updated": Timestamp
  }
}
```

**Trigger Function**:
```bash
# Via Firebase Functions Shell
firebase functions:shell
> checkDeadlines()
```

**Expected Results**:
- ✅ test-target-1 status changed to "closed"
- ✅ Distribution calculated (per_person: 250000, total: 1000000)
- ✅ Excess (500000) transferred to general_fund
- ✅ Transaction created for excess transfer
- ✅ test-target-2 status changed to "active"
- ✅ General fund balance transferred to test-target-2

**Verify**:
```javascript
// Check target
db.collection('graduation_targets').doc('test-target-1').get()
// Should have: status = 'closed', distribution filled

// Check general fund
db.collection('general_fund').doc('current').get()
// Should have: balance = 0 (transferred to new target)

// Check new target
db.collection('graduation_targets').doc('test-target-2').get()
// Should have: status = 'active', current_amount = 500000

// Check transactions
db.collection('transactions').where('created_by', '==', 'system').get()
// Should have 2 transactions: excess transfer + general fund transfer
```

---

### 2. Test updateClosingSoonStatus Function

**Setup Data**:
```javascript
// Create target with deadline in 5 days
{
  "graduation_targets/closing-soon-target": {
    "status": "active",
    "deadline": Timestamp (5 days from now),
    // ... other fields
  }
}
```

**Trigger Function**:
```bash
firebase functions:shell
> updateClosingSoonStatus()
```

**Expected Results**:
- ✅ Target status changed to "closing_soon"

---

### 3. Test cleanupOldSubmissions Function

**Setup Data**:
```javascript
// Create old rejected submission
{
  "pending_submissions/old-submission": {
    "status": "rejected",
    "reviewed_at": Timestamp (35 days ago),
    "proof_url": "https://firebasestorage.googleapis.com/...",
    // ... other fields
  }
}

// Upload proof image to Storage (manually or via script)
```

**Trigger Function**:
```bash
firebase functions:shell
> cleanupOldSubmissions()
```

**Expected Results**:
- ✅ Submission document deleted from Firestore
- ✅ Proof image deleted from Storage

---

### 4. Test onTargetClosed Trigger

**Setup Data**:
```javascript
// Create target
{
  "graduation_targets/trigger-test": {
    "status": "active",
    "month": "Februari",
    "year": 2026,
    "target_amount": 1000000,
    "current_amount": 1200000,
    "graduates": [
      { "name": "A", "date": Timestamp (past), "location": "Jakarta" }
    ],
    "open_date": Timestamp (14 days ago),
    "deadline": Timestamp,
    "created_at": Timestamp,
    "updated_at": Timestamp
  }
}
```

**Trigger Function** (via document update):
```javascript
// Update status to trigger function
db.collection('graduation_targets').doc('trigger-test').update({
  status: 'closed',
  closed_date: admin.firestore.Timestamp.now()
})
```

**Expected Results**:
- ✅ Analytics document created in `analytics/trigger-test`
- ✅ Analytics contains: percentage, duration_days, funding_status
- ✅ Target status changed to "archived" (since graduate date passed)

**Verify**:
```javascript
// Check analytics
db.collection('analytics').doc('trigger-test').get()
// Should have: percentage = 120, funding_status = 'fully_funded', duration_days = 14

// Check target
db.collection('graduation_targets').doc('trigger-test').get()
// Should have: status = 'archived'
```

---

### 5. Test routeIncome Trigger

**Scenario A: Route to Active Target**

**Setup Data**:
```javascript
// Create active target
{
  "graduation_targets/active-target": {
    "status": "active",
    "month": "Maret",
    "year": 2026,
    "current_amount": 500000,
    // ... other fields
  }
}
```

**Trigger Function** (via document create):
```javascript
// Create income transaction
db.collection('transactions').add({
  type: 'income',
  amount: 100000,
  // target_id NOT set - will be auto-routed
  description: 'Test donation',
  validated: true,
  created_at: admin.firestore.Timestamp.now()
})
```

**Expected Results**:
- ✅ Transaction target_id set to "active-target"
- ✅ Transaction target_month set to "Maret 2026"
- ✅ Target current_amount increased to 600000

**Scenario B: Route to General Fund**

**Setup**: No active targets

**Trigger Function**:
```javascript
// Create income transaction
db.collection('transactions').add({
  type: 'income',
  amount: 100000,
  description: 'Test donation',
  validated: true,
  created_at: admin.firestore.Timestamp.now()
})
```

**Expected Results**:
- ✅ Transaction target_id set to "general_fund"
- ✅ General fund balance increased by 100000
- ✅ General fund total_income increased by 100000

---

## Automated Testing

### Run Unit Tests
```bash
cd functions
npm test
```

### Run Tests in Watch Mode
```bash
npm run test:watch
```

### Test Output
```
Scheduled Functions - Unit Tests
  checkDeadlines Logic
    ✓ should identify expired targets
    ✓ should calculate distribution for fully funded target
    ✓ should calculate distribution for partially funded target
  updateClosingSoonStatus Logic
    ✓ should identify targets approaching deadline
    ✓ should not mark targets with deadline > 7 days
  cleanupOldSubmissions Logic
    ✓ should identify old rejected submissions
    ✓ should parse storage URL correctly

Triggered Functions - Unit Tests
  onTargetClosed Logic
    ✓ should detect status change to closed
    ✓ should calculate analytics metrics
    ✓ should determine if target should be archived
  routeIncome Logic
    ✓ should skip non-income transactions
    ✓ should skip if target_id already set
    ✓ should route to active target when available
    ✓ should route to general fund when no active target

Integration Tests
  Complete Flow: Deadline → Close → Open Next
    ✓ should close expired target and open next target
  Excess Transfer Flow
    ✓ should transfer excess funds to general fund
  Income Routing Scenarios
    ✓ should route to active target when available
    ✓ should route to general fund when no active target

18 passing (250ms)
```

---

## Tips

1. **Reset Emulator Data**: Stop emulator dan hapus data directory untuk fresh start
2. **View Logs**: Check emulator UI → Functions tab untuk function logs
3. **Debug**: Tambahkan `console.log()` di functions untuk debugging
4. **Timestamps**: Gunakan `admin.firestore.Timestamp.fromDate()` untuk create timestamps
5. **Batch Operations**: Test dengan multiple documents untuk verify batch logic

---

## Common Issues

### Issue: Function not triggered
**Solution**: Check function logs di emulator UI, verify trigger conditions

### Issue: Permission denied
**Solution**: Emulator tidak enforce security rules by default, check firestore.rules

### Issue: Timestamp errors
**Solution**: Pastikan menggunakan `admin.firestore.Timestamp`, bukan `Date`

### Issue: Storage errors
**Solution**: Storage emulator mungkin perlu di-start separately: `firebase emulators:start --only storage`
