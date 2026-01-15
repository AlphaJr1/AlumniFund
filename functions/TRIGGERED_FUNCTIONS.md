# Triggered Functions Documentation

## Overview
Triggered functions berjalan otomatis sebagai response terhadap events di Firestore. Functions ini execute secara real-time saat data berubah.

## Functions

### 1. onTargetClosed
**Trigger**: Firestore document update  
**Path**: `graduation_targets/{targetId}`  
**Condition**: Status changes to "closed"  
**File**: `triggers/onTargetClosed.js`

**Purpose**: Handle post-closure actions ketika target ditutup (manual atau otomatis)

**Process Flow**:
1. Detect status change dari any status → `closed`
2. Log analytics ke collection `analytics`
3. Check apakah semua graduates sudah lulus
4. Jika semua sudah lulus: auto-archive target

**Analytics Data Logged**:
```javascript
{
  target_id: string,
  month: string,
  year: number,
  target_amount: number,
  collected_amount: number,
  percentage: number,              // % funded
  graduates_count: number,
  distribution: object,
  opened_at: Timestamp,
  closed_at: Timestamp,
  deadline: Timestamp,
  duration_days: number,           // Days from open to close
  funding_status: string,          // 'fully_funded' | 'partially_funded'
  metadata: {
    auto_closed: boolean,
    excess_amount: number
  }
}
```

**Auto-Archive Logic**:
```javascript
// Find latest graduation date
const lastGraduateDate = max(graduates.map(g => g.date))

// If all graduations have passed
if (now > lastGraduateDate) {
  status = 'archived'
}
```

**Error Handling**: 
- Tidak throw error (avoid infinite retries)
- Analytics failure tidak block closure process
- Log errors untuk debugging

---

### 2. routeIncome
**Trigger**: Firestore document create  
**Path**: `transactions/{transactionId}`  
**Condition**: Type is "income"  
**File**: `triggers/routeIncome.js`

**Purpose**: Auto-route income baru ke destination yang tepat (active target atau general fund)

**Process Flow**:
1. Check transaction type = 'income'
2. Check jika target_id sudah di-set (skip jika sudah)
3. Query active/closing_soon target
4. Jika ada active target:
   - Route ke target tersebut
   - Update target current_amount
   - Set transaction target_id & target_month
5. Jika tidak ada active target:
   - Route ke general fund
   - Update general fund balance
   - Set transaction target_id = 'general_fund'

**Routing Logic**:
```javascript
// Priority 1: Active or closing_soon target
const activeTarget = query('status IN [active, closing_soon]').limit(1)

if (activeTarget exists) {
  target_id = activeTarget.id
  target.current_amount += amount
} else {
  // Priority 2: General fund
  target_id = 'general_fund'
  generalFund.balance += amount
  generalFund.total_income += amount
}

// Update transaction
transaction.target_id = target_id
transaction.target_month = targetMonth
```

**Use Cases**:
- Public donations via submit proof form
- Manual income input tanpa target specified
- Automated transfers dari system

**Error Handling**:
- Tidak throw error (transaction sudah created)
- Admin bisa manual fix routing jika error
- Log errors untuk monitoring

---

## Helper Functions

### logTargetAnalytics()
**File**: `helpers/analytics.js`

**Purpose**: Create analytics record untuk target yang closed

**Calculations**:
- **Percentage**: `(collected / target) * 100`
- **Duration**: Days between open_date and closed_date
- **Funding Status**: 
  - `fully_funded` jika collected >= target
  - `partially_funded` jika collected < target

**Metadata Tracked**:
- Auto-closed vs manual close
- Excess amount (jika over-funded)

---

## Testing

### Local Testing (Emulator)

**onTargetClosed**:
```javascript
// 1. Create target
const targetRef = db.collection('graduation_targets').doc('test-target')
await targetRef.set({
  status: 'active',
  month: 'Januari',
  year: 2026,
  // ... other fields
})

// 2. Trigger function by updating status
await targetRef.update({ status: 'closed' })

// 3. Check analytics collection
const analytics = await db.collection('analytics').doc('test-target').get()
console.log(analytics.data())
```

**routeIncome**:
```javascript
// 1. Create active target
await db.collection('graduation_targets').doc('target1').set({
  status: 'active',
  current_amount: 0,
  // ... other fields
})

// 2. Create income transaction (trigger function)
await db.collection('transactions').add({
  type: 'income',
  amount: 100000,
  // target_id NOT set - will be auto-routed
})

// 3. Check transaction updated
const tx = await db.collection('transactions').doc(txId).get()
console.log(tx.data().target_id) // Should be 'target1'

// 4. Check target updated
const target = await db.collection('graduation_targets').doc('target1').get()
console.log(target.data().current_amount) // Should be 100000
```

### Test Scenarios

**onTargetClosed**:
1. ✅ Analytics logged correctly
2. ✅ Auto-archive when all graduates passed
3. ✅ Stay closed when graduations upcoming
4. ✅ Handle missing fields gracefully

**routeIncome**:
1. ✅ Route to active target
2. ✅ Route to closing_soon target
3. ✅ Route to general fund when no active target
4. ✅ Skip if target_id already set
5. ✅ Skip if transaction type is expense

---

## Monitoring

### Logs
```bash
# View trigger logs
firebase functions:log --only onTargetClosed
firebase functions:log --only routeIncome
```

### Key Metrics
- **onTargetClosed**:
  - Execution count per closure
  - Analytics creation success rate
  - Archive rate
  
- **routeIncome**:
  - Execution count per income
  - Route to target vs general fund ratio
  - Routing errors

### Alerts
Setup alerts untuk:
- Function execution errors
- Missing analytics records
- Routing failures

---

## Integration with Scheduled Functions

**Complete Flow**:
1. User donates → Transaction created
2. **routeIncome** → Auto-route to active target
3. Target reaches deadline
4. **checkDeadlines** → Close target
5. **onTargetClosed** → Log analytics, archive
6. **checkDeadlines** → Open next target
7. **routeIncome** → Route new donations to new target

---

## Notes

- Triggered functions run with admin privileges
- No retry on errors (by design)
- Idempotent operations preferred
- Comprehensive logging untuk debugging
- Future: Add notification triggers
