# Cloud Functions - Dompet Alumni

Automated backend processes untuk mengelola lifecycle targets dan maintenance sistem.

## 🎯 Overview

5 Cloud Functions yang berjalan otomatis di Firebase:

### Scheduled Functions (Cron Jobs)
1. **checkDeadlines** - Setiap jam
   - Auto-close targets yang expired
   - Transfer excess funds ke general fund
   - Buka target berikutnya

2. **updateClosingSoonStatus** - Setiap hari tengah malam
   - Mark targets H-7 sebagai "closing_soon"

3. **cleanupOldSubmissions** - Setiap Minggu jam 2 pagi
   - Hapus rejected submissions >30 hari
   - Delete files dari Storage

### Triggered Functions (Event-based)
4. **onTargetClosed** - Saat target ditutup
   - Log analytics ke Firestore
   - Auto-archive setelah semua graduations

5. **routeIncome** - Saat ada donasi baru
   - Route ke active target atau general fund
   - Update balances otomatis

---

## 🚀 Quick Start

### Prerequisites
- Node.js 20+
- Firebase CLI
- Blaze plan (Pay-as-you-go)

### Deploy
```bash
# Install dependencies
cd functions
npm install

# Deploy to production
firebase deploy --only functions
```

---

## 📁 Structure

```
functions/
├── index.js                    # Main entry point
├── scheduled/                  # Cron jobs
│   ├── checkDeadlines.js
│   ├── updateClosingSoonStatus.js
│   └── cleanupOldSubmissions.js
├── triggers/                   # Event-based
│   ├── onTargetClosed.js
│   └── routeIncome.js
├── helpers/                    # Utilities
│   ├── transferExcess.js
│   ├── autoOpenTarget.js
│   ├── analytics.js
│   ├── constants.js
│   └── retryUtils.js
└── test/                       # Unit tests
```

---

## 🔧 Local Development

### Run Emulator
```bash
firebase emulators:start --only functions,firestore
```

### Run Tests
```bash
cd functions
npm test
```

### Manual Trigger
```bash
firebase functions:shell
> checkDeadlines()
```

---

## 📊 Monitoring

### View Logs
```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only checkDeadlines
```

### Dashboards
- **Functions**: https://console.firebase.google.com/project/dompetalumni/functions
- **Logs**: https://console.cloud.google.com/logs/query?project=dompetalumni
- **Monitoring**: https://console.cloud.google.com/monitoring?project=dompetalumni

### Health Check
```bash
# PowerShell
.\functions\health-check.ps1

# Bash
./functions/health-check.sh
```

---

## 🔍 Function Details

### checkDeadlines
**Trigger**: `0 * * * *` (Hourly)  
**Purpose**: Auto-close expired targets

**Process**:
1. Query targets dengan deadline < now
2. Calculate distribution (Rp 250K per person jika fully funded)
3. Update status → `closed`
4. Transfer excess → general fund
5. Open next upcoming target

**Example Log**:
```
=== Target closed: Januari 2026 ===
✓ Distribution: Rp 250.000 per person
✓ Excess transferred: Rp 500.000
✓ Next target opened: Februari 2026
```

---

### updateClosingSoonStatus
**Trigger**: `0 0 * * *` (Daily midnight)  
**Purpose**: Mark targets approaching deadline

**Process**:
1. Calculate threshold: now + 7 days
2. Query active targets dengan deadline <= threshold
3. Update status → `closing_soon`

---

### cleanupOldSubmissions
**Trigger**: `0 2 * * 0` (Weekly Sunday 2AM)  
**Purpose**: Delete old rejected submissions

**Process**:
1. Query rejected submissions >30 days
2. Delete from Firestore
3. Delete proof images from Storage

---

### onTargetClosed
**Trigger**: Firestore update (status → closed)  
**Purpose**: Post-closure actions

**Process**:
1. Log analytics (percentage, duration, funding status)
2. Check if all graduates passed
3. Auto-archive if yes

**Analytics Data**:
- Percentage funded
- Duration (days)
- Graduates count
- Funding status (fully/partially)

---

### routeIncome
**Trigger**: Firestore create (new transaction)  
**Purpose**: Auto-route income

**Process**:
1. Check if transaction type = income
2. Find active/closing_soon target
3. Route to target OR general fund
4. Update balances

**Routing Logic**:
```
IF active target exists:
  → Route to target
ELSE:
  → Route to general fund
```

---

## ⚙️ Configuration

### Dynamic Settings (Auto-Sync with Admin Panel)

Cloud Functions automatically read settings from Firestore (`settings/app_config`):

**Settings that Auto-Sync**:
- **per_person_allocation** (default: Rp 250.000)
  - Used by: `checkDeadlines`
  - Admin can change via Settings → System Configuration
  
- **deadline_offset_days** (default: 3 days)
  - Used by: `updateClosingSoonStatus`
  - Admin can change via Settings → System Configuration
  
- **auto_open_next_target** (default: true)
  - Used by: `checkDeadlines`
  - Admin can toggle via Settings → System Configuration

**How It Works**:
```javascript
// Functions fetch settings on each execution
const settings = await getSystemSettings();
const perPerson = settings.perPersonAllocation; // From Firestore!
```

**No Redeployment Needed!**  
Admin changes settings → Functions automatically use new values on next execution.

### Environment Variables
```bash
# Set via Firebase CLI
firebase functions:config:set admin.email="your@email.com"

# View current config
firebase functions:config:get
```

### Constants
Edit `functions/helpers/constants.js`:
- Schedules (cron expressions)
- Retention periods
- Collection names
- System defaults

---

## 🐛 Troubleshooting

### Function not executing
**Check**:
- Cloud Scheduler enabled?
- Billing account active?
- Function deployed?

**Fix**:
```bash
gcloud scheduler jobs list --project=dompetalumni
```

### High error rate
**Check logs**:
```bash
firebase functions:log | grep ERROR
```

**Common issues**:
- Firestore index missing
- Permission errors
- Timeout (>60s)

### Deployment fails
**Check**:
- Node.js version (should be 20)
- API enabled (Cloud Functions, Artifact Registry)
- Billing account linked

---

## 💰 Cost

**Expected**: $0/month (within free tier)

**Free Tier Limits**:
- 2M invocations/month
- 400K GB-seconds compute
- 5GB networking

**Actual Usage** (~1,000 invocations/month):
- checkDeadlines: 720/month
- updateClosingSoonStatus: 30/month
- cleanupOldSubmissions: 4/month
- Triggered: Variable

---

## 📚 Additional Docs

- **Scheduled Functions**: `functions/SCHEDULED_FUNCTIONS.md`
- **Triggered Functions**: `functions/TRIGGERED_FUNCTIONS.md`
- **Deployment Guide**: `functions/DEPLOYMENT.md`
- **Monitoring Guide**: `functions/MONITORING.md`
- **Emulator Testing**: `functions/EMULATOR_TESTING.md`

---

## 🔐 Security

- Functions run with admin privileges
- Bypass Firestore rules
- Validate inputs in function code
- Monitor for unauthorized access

---

## 📝 Maintenance

### Weekly
- Check error logs
- Verify scheduled executions

### Monthly
- Review performance metrics
- Update dependencies if needed

### Updates
```bash
# Update Firebase tools
npm install -g firebase-tools

# Update dependencies
cd functions
npm update
```

---

**Questions?** Check detailed docs in `functions/` directory or Firebase Console.
