# Deployment Configuration Guide

## Firebase Functions Configuration

### Region Setup
Functions deployed ke **asia-southeast1** (Singapore) untuk latency optimal ke Indonesia.

**Configured in**: `firebase.json`
```json
{
  "functions": [{
    "region": "asia-southeast1",
    "runtime": "nodejs18"
  }]
}
```

---

## Environment Variables

### Setup via Firebase CLI

**Set environment variables**:
```bash
# Admin email
firebase functions:config:set admin.email="adrianalfajri@gmail.com"

# Future: WhatsApp credentials
firebase functions:config:set whatsapp.api_key="your_key"
firebase functions:config:set whatsapp.phone="your_phone"
```

**View current config**:
```bash
firebase functions:config:get
```

**Access in code**:
```javascript
const functions = require('firebase-functions');
const adminEmail = functions.config().admin.email;
```

### Local Development

**Download config for emulator**:
```bash
firebase functions:config:get > functions/.runtimeconfig.json
```

**Add to .gitignore**:
```
.runtimeconfig.json
.env
```

---

## Cloud Scheduler Setup

Cloud Scheduler akan otomatis dibuat saat deploy functions dengan schedule.

### Scheduled Functions

**1. checkDeadlines**
- **Schedule**: `0 * * * *` (Every hour)
- **Timezone**: Asia/Jakarta
- **Purpose**: Auto-close expired targets

**2. updateClosingSoonStatus**
- **Schedule**: `0 0 * * *` (Daily at midnight)
- **Timezone**: Asia/Jakarta
- **Purpose**: Mark targets approaching deadline

**3. cleanupOldSubmissions**
- **Schedule**: `0 2 * * 0` (Weekly Sunday 2 AM)
- **Timezone**: Asia/Jakarta
- **Purpose**: Delete old rejected submissions

### Verify Scheduler Jobs

**Via Firebase Console**:
1. Go to Cloud Functions → Dashboard
2. Click on scheduled function
3. View "Cloud Scheduler" tab
4. Verify schedule and timezone

**Via gcloud CLI**:
```bash
gcloud scheduler jobs list --project=dompetalumni
```

### Manual Trigger (Testing)

```bash
# Trigger via gcloud
gcloud scheduler jobs run firebase-schedule-checkDeadlines-asia-southeast1 --project=dompetalumni

# Or via Firebase Console
# Functions → Select function → Testing tab → Run function
```

---

## Deployment Commands

### Initial Deployment

```bash
# Deploy all (hosting, functions, firestore, storage)
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:checkDeadlines
```

### Update Deployment

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy only scheduled functions
firebase deploy --only functions:checkDeadlines,functions:updateClosingSoonStatus,functions:cleanupOldSubmissions

# Deploy only triggered functions
firebase deploy --only functions:onTargetClosed,functions:routeIncome
```

### Rollback

```bash
# List previous deployments
firebase functions:log

# Rollback to previous version (via Firebase Console)
# Functions → Select function → Version history → Rollback
```

---

## Pre-Deployment Checklist

### 1. Code Quality
- [ ] All tests passing (`npm test`)
- [ ] No console errors in emulator
- [ ] Functions tested manually via emulator

### 2. Configuration
- [ ] firebase.json configured correctly
- [ ] Region set to asia-southeast1
- [ ] Runtime set to nodejs18
- [ ] Environment variables set

### 3. Indexes
- [ ] Firestore indexes created
- [ ] Composite indexes for queries verified

### 4. Security
- [ ] Firestore rules updated
- [ ] Storage rules updated
- [ ] Admin-only access enforced

### 5. Dependencies
- [ ] package.json dependencies up to date
- [ ] No vulnerabilities (`npm audit`)
- [ ] node_modules installed

---

## Post-Deployment Verification

### 1. Check Function Status
```bash
# List all functions
firebase functions:list

# Check function logs
firebase functions:log --only checkDeadlines --limit 50
```

### 2. Verify Scheduler Jobs
- Go to Cloud Console → Cloud Scheduler
- Verify all 3 jobs created
- Check next run time
- Verify timezone (Asia/Jakarta)

### 3. Test Triggered Functions
- Create test transaction (trigger routeIncome)
- Update target status (trigger onTargetClosed)
- Verify logs in Firebase Console

### 4. Monitor First 24 Hours
- Check function execution count
- Monitor error rate
- Verify scheduled functions running
- Check Firestore updates

---

## Cost Optimization

### Free Tier Limits
- **Invocations**: 2M/month
- **Compute time**: 400,000 GB-seconds/month
- **Outbound networking**: 5GB/month

### Estimated Usage
- **checkDeadlines**: 720 invocations/month (hourly)
- **updateClosingSoonStatus**: 30 invocations/month (daily)
- **cleanupOldSubmissions**: 4 invocations/month (weekly)
- **Triggered functions**: Variable (depends on activity)

**Total estimated**: ~1,000 invocations/month (well within free tier)

### Monitoring Costs
```bash
# View billing
firebase projects:list
gcloud billing accounts list
```

---

## Troubleshooting

### Issue: Function deployment fails
**Solution**: 
- Check Node.js version (should be 18)
- Verify package.json syntax
- Check function exports in index.js

### Issue: Scheduler jobs not created
**Solution**:
- Enable Cloud Scheduler API
- Verify billing account linked
- Check function region matches scheduler region

### Issue: Environment variables not working
**Solution**:
- Verify config set: `firebase functions:config:get`
- Redeploy functions after config change
- Check .runtimeconfig.json for local testing

### Issue: Function timeout
**Solution**:
- Increase timeout in function config (max 540s)
- Optimize batch operations
- Add retry logic for long operations

---

## Security Best Practices

1. **Never commit secrets**: Use .env and .gitignore
2. **Use environment variables**: For API keys and credentials
3. **Validate inputs**: Even in admin functions
4. **Log sensitive operations**: For audit trail
5. **Monitor function errors**: Set up alerts

---

## Maintenance

### Regular Tasks
- **Weekly**: Check function logs for errors
- **Monthly**: Review function performance metrics
- **Quarterly**: Update dependencies (`npm update`)
- **Yearly**: Review and optimize costs

### Updates
```bash
# Update Firebase tools
npm install -g firebase-tools

# Update function dependencies
cd functions
npm update
npm audit fix
```
