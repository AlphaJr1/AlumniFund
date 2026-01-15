# Scheduled Functions Documentation

## Overview
Scheduled functions berjalan otomatis berdasarkan cron schedule untuk mengelola lifecycle targets dan maintenance sistem.

## Functions

### 1. checkDeadlines
**Schedule**: Setiap jam (`0 * * * *`)  
**Timezone**: Asia/Jakarta  
**File**: `scheduled/checkDeadlines.js`

**Purpose**: Auto-close targets yang sudah melewati deadline

**Process Flow**:
1. Query targets dengan status `active` atau `closing_soon` yang deadline < now
2. Untuk setiap target:
   - Hitung distribusi per person
   - Hitung total distributed
   - Hitung excess (jika fully funded)
   - Update status ke `closed`
3. Transfer excess ke general fund (jika ada)
4. Auto-open target berikutnya

**Distribution Logic**:
```javascript
if (fully_funded) {
  per_person = Rp 250.000
  total_distributed = target_amount
  excess = current_amount - target_amount
} else {
  per_person = current_amount / jumlah_graduates
  total_distributed = current_amount
  excess = 0
}
```

**Error Handling**: Retry logic dengan exponential backoff (max 3 attempts)

---

### 2. updateClosingSoonStatus
**Schedule**: Setiap hari tengah malam (`0 0 * * *`)  
**Timezone**: Asia/Jakarta  
**File**: `scheduled/updateClosingSoonStatus.js`

**Purpose**: Mark targets sebagai `closing_soon` saat deadline <= 7 hari

**Process Flow**:
1. Calculate threshold: now + 7 days
2. Query targets dengan status `active` dan deadline <= threshold
3. Batch update status ke `closing_soon`
4. Log jumlah hari tersisa untuk setiap target

**Use Case**: Memberikan warning visual di public dashboard bahwa target akan segera ditutup

---

### 3. cleanupOldSubmissions
**Schedule**: Setiap Minggu jam 2 pagi (`0 2 * * 0`)  
**Timezone**: Asia/Jakarta  
**File**: `scheduled/cleanupOldSubmissions.js`

**Purpose**: Hapus rejected submissions yang sudah >30 hari untuk menghemat storage

**Process Flow**:
1. Calculate cutoff date: now - 30 days
2. Query submissions dengan status `rejected` dan reviewed_at < cutoff
3. Untuk setiap submission:
   - Parse proof_url untuk extract file path
   - Delete file dari Firebase Storage
   - Delete document dari Firestore
4. Log hasil (success count, error count)

**Storage URL Parsing**:
```javascript
// URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?token={token}
const url = new URL(proof_url);
const pathMatch = url.pathname.match(/\/o\/(.+)/);
const filePath = decodeURIComponent(pathMatch[1]);
```

**Error Handling**: Continue on storage errors, log warnings

---

## Helper Functions

### transferExcessToGeneralFund()
**File**: `helpers/transferExcess.js`

**Purpose**: Transfer kelebihan dana dari target yang closed ke general fund

**Operations**:
1. Update general_fund balance (+amount)
2. Update general_fund total_income (+amount)
3. Create transaction record dengan type `income`

**Transaction Metadata**:
- `source_target_id`: ID target yang ditutup
- `source_target_month`: Bulan target
- `transfer_type`: 'excess_funds'
- `created_by`: 'system'

---

### autoOpenNextTarget()
**File**: `helpers/autoOpenTarget.js`

**Purpose**: Buka target upcoming berikutnya dan transfer general fund balance

**Process Flow**:
1. Query target dengan status `upcoming`, order by deadline ASC, limit 1
2. Update status ke `active`
3. Get general fund balance
4. Jika balance > 0:
   - Transfer balance ke target current_amount
   - Clear general fund balance
   - Create transaction record

**Transaction Metadata**:
- `transfer_type`: 'general_fund_to_target'
- `created_by`: 'system'

---

## Testing

### Local Testing (Emulator)
```bash
# Start emulators
firebase emulators:start

# Trigger function manually
firebase functions:shell
> checkDeadlines()
```

### Manual Trigger (Production)
```bash
# Trigger via gcloud CLI
gcloud functions call checkDeadlines --project dompetalumni
```

### Test Scenarios

**checkDeadlines**:
1. Create target dengan deadline di masa lalu
2. Set current_amount > target_amount (test excess transfer)
3. Create upcoming target (test auto-open)
4. Trigger function
5. Verify: target closed, excess transferred, next target opened

**updateClosingSoonStatus**:
1. Create target dengan deadline 5 hari dari sekarang
2. Trigger function
3. Verify: status changed to closing_soon

**cleanupOldSubmissions**:
1. Create rejected submission dengan reviewed_at 35 hari lalu
2. Upload proof image
3. Trigger function
4. Verify: document deleted, image deleted from storage

---

## Monitoring

### Logs
```bash
# View function logs
firebase functions:log --only checkDeadlines
firebase functions:log --only updateClosingSoonStatus
firebase functions:log --only cleanupOldSubmissions
```

### Key Metrics
- Execution count per day
- Average execution time
- Error rate
- Targets closed per execution
- Storage freed per cleanup

### Alerts
Setup alerts di Firebase Console untuk:
- Function execution errors
- Timeout (>60s)
- Abnormal invocation count

---

## Deployment

```bash
# Deploy semua functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:checkDeadlines
```

## Notes

- Semua functions menggunakan batch operations untuk efficiency
- Retry logic implemented untuk critical operations
- Comprehensive logging untuk debugging
- Error handling yang proper (throw untuk trigger retry)
