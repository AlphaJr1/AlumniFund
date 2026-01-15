# Backup & Recovery Guide - Dompet Alumni

## 🔄 Automated Backups

### Firestore Backups

**Weekly Automated Export**:
```bash
# Setup via gcloud CLI
gcloud firestore export gs://dompetalumni-backups/firestore \
  --project=dompetalumni \
  --async

# Schedule weekly (Sunday 3 AM)
gcloud scheduler jobs create app-engine weekly-firestore-backup \
  --schedule="0 3 * * 0" \
  --time-zone="Asia/Jakarta" \
  --http-method=POST \
  --uri="https://firestore.googleapis.com/v1/projects/dompetalumni/databases/(default):exportDocuments" \
  --message-body='{"outputUriPrefix":"gs://dompetalumni-backups/firestore"}' \
  --oauth-service-account-email=firebase-adminsdk@dompetalumni.iam.gserviceaccount.com
```

**Manual Backup**:
```bash
# Export all collections
gcloud firestore export gs://dompetalumni-backups/manual/$(date +%Y%m%d) \
  --project=dompetalumni

# Export specific collections
gcloud firestore export gs://dompetalumni-backups/manual/$(date +%Y%m%d) \
  --collection-ids=graduation_targets,transactions,general_fund \
  --project=dompetalumni
```

---

### Storage Backups

**Monthly Backup** (via Cloud Storage Transfer):
1. Buka: https://console.cloud.google.com/transfer/cloud
2. Create transfer job:
   - Source: `dompetalumni.appspot.com`
   - Destination: `dompetalumni-backups/storage`
   - Schedule: Monthly (1st day, 3 AM)

**Manual Backup**:
```bash
# Copy all storage files
gsutil -m cp -r gs://dompetalumni.appspot.com/* gs://dompetalumni-backups/storage/$(date +%Y%m%d)/
```

---

### Function Code Versioning

**Git Repository**:
```bash
# Ensure functions code is committed
cd functions
git add .
git commit -m "Phase 3: Cloud Functions deployment"
git push origin main

# Tag release
git tag -a v3.0.0 -m "Phase 3 Complete - Cloud Functions"
git push origin v3.0.0
```

**Firebase Function Versions**:
- Otomatis tersimpan di Firebase Console
- View: Functions → Select function → Version history
- Rollback: Functions → Version history → Rollback

---

## 🔧 Recovery Procedures

### Restore Firestore from Backup

**1. List Available Backups**:
```bash
gsutil ls gs://dompetalumni-backups/firestore/
```

**2. Restore**:
```bash
# Restore from specific backup
gcloud firestore import gs://dompetalumni-backups/firestore/2026-01-07 \
  --project=dompetalumni

# Restore specific collections only
gcloud firestore import gs://dompetalumni-backups/firestore/2026-01-07 \
  --collection-ids=graduation_targets,transactions \
  --project=dompetalumni
```

**3. Verify Data**:
```bash
# Check document counts
firebase firestore:get graduation_targets --limit 1
firebase firestore:get transactions --limit 1
```

---

### Restore Storage Files

**1. List Backups**:
```bash
gsutil ls gs://dompetalumni-backups/storage/
```

**2. Restore**:
```bash
# Restore all files
gsutil -m cp -r gs://dompetalumni-backups/storage/20260107/* gs://dompetalumni.appspot.com/

# Restore specific folder
gsutil -m cp -r gs://dompetalumni-backups/storage/20260107/proofs/* gs://dompetalumni.appspot.com/proofs/
```

---

### Redeploy Cloud Functions

**1. From Git**:
```bash
# Checkout specific version
git checkout v3.0.0

# Deploy
cd functions
npm install
firebase deploy --only functions
```

**2. Rollback via Console**:
1. Firebase Console → Functions
2. Select function
3. Version history tab
4. Click "Rollback" on previous version

**3. Verify Deployment**:
```bash
# Check function status
firebase functions:list

# Check logs
firebase functions:log --limit 20
```

---

## ✅ Data Consistency Verification

### Post-Recovery Checklist

**1. Firestore Data**:
```bash
# Check collections exist
- [ ] graduation_targets
- [ ] transactions
- [ ] general_fund
- [ ] settings
- [ ] pending_submissions
- [ ] analytics

# Verify document counts match backup
# Verify latest documents exist
```

**2. Storage Files**:
```bash
# Check folders exist
- [ ] proofs/
- [ ] qr_codes/
- [ ] expenses/

# Verify file counts
gsutil ls -r gs://dompetalumni.appspot.com/ | wc -l
```

**3. Cloud Functions**:
```bash
# All 5 functions deployed
- [ ] checkDeadlines
- [ ] updateClosingSoonStatus
- [ ] cleanupOldSubmissions
- [ ] onTargetClosed
- [ ] routeIncome

# Scheduler jobs created
- [ ] 3 cron jobs active
```

**4. Test Critical Flows**:
```bash
# Test income routing
- [ ] Create test transaction → Verify auto-routing

# Test target closure
- [ ] Close test target → Verify analytics logged

# Check admin dashboard
- [ ] System health widget shows green
- [ ] Analytics viewer displays data
```

---

## 📋 Backup Schedule

| Type | Frequency | Time | Retention |
|------|-----------|------|-----------|
| Firestore | Weekly | Sunday 3 AM | 4 weeks |
| Storage | Monthly | 1st day 3 AM | 3 months |
| Git | On deploy | - | Forever |
| Function versions | Auto | - | Last 10 |

---

## 🚨 Disaster Recovery Plan

### Scenario 1: Firestore Data Loss

**Steps**:
1. Identify last good backup
2. Restore from backup (see above)
3. Verify data consistency
4. Test critical functions
5. Monitor for 24h

**Recovery Time**: ~30 minutes

---

### Scenario 2: Storage Files Deleted

**Steps**:
1. Identify affected files
2. Restore from monthly backup
3. Verify file accessibility
4. Update Firestore URLs if needed

**Recovery Time**: ~1 hour

---

### Scenario 3: Functions Not Working

**Steps**:
1. Check function logs for errors
2. Rollback to previous version (Console)
3. Or redeploy from Git tag
4. Verify scheduler jobs
5. Test manually

**Recovery Time**: ~15 minutes

---

### Scenario 4: Complete Project Loss

**Steps**:
1. Create new Firebase project
2. Restore Firestore from backup
3. Restore Storage from backup
4. Deploy functions from Git
5. Update firebase config
6. Redeploy web app
7. Update DNS if needed

**Recovery Time**: ~4 hours

---

## 🔐 Backup Security

**Access Control**:
- Backup bucket: Private
- Service account: firebase-adminsdk only
- Encryption: Google-managed keys

**Verification**:
```bash
# Check backup bucket permissions
gsutil iam get gs://dompetalumni-backups

# Verify encryption
gsutil ls -L gs://dompetalumni-backups/
```

---

## 📊 Monitoring Backups

### Check Backup Status

**Firestore**:
```bash
# List recent backups
gsutil ls -l gs://dompetalumni-backups/firestore/ | tail -5

# Check backup size
gsutil du -sh gs://dompetalumni-backups/firestore/
```

**Storage**:
```bash
# List monthly backups
gsutil ls gs://dompetalumni-backups/storage/

# Check size
gsutil du -sh gs://dompetalumni-backups/storage/
```

### Alerts

Setup alerts untuk:
- Backup job failures
- Backup size anomalies
- Missing scheduled backups

---

## 🧪 Test Recovery (Quarterly)

**Checklist**:
```bash
# Q1: Test Firestore restore
- [ ] Restore to test project
- [ ] Verify data integrity
- [ ] Document issues

# Q2: Test Storage restore
- [ ] Restore sample files
- [ ] Verify accessibility
- [ ] Document issues

# Q3: Test function redeploy
- [ ] Deploy from Git tag
- [ ] Verify all functions work
- [ ] Document issues

# Q4: Full disaster recovery drill
- [ ] Simulate complete loss
- [ ] Follow recovery plan
- [ ] Measure recovery time
- [ ] Update procedures
```

---

## 📞 Emergency Contacts

**Firebase Support**: https://firebase.google.com/support  
**Admin**: adrianalfajri@gmail.com  
**Project ID**: dompetalumni

---

**Last Updated**: 2026-01-08  
**Next Review**: 2026-04-08
