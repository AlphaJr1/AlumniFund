# Cloud Functions Monitoring & Logging Guide

## Overview
Monitoring dan logging untuk memastikan Cloud Functions berjalan dengan baik dan mendeteksi issues secara proaktif.

---

## 1. Structured Logging

### Logging Best Practices
Semua functions sudah menggunakan structured logging dengan format:

```javascript
// Success logs
console.log('✓ Operation successful:', { details });

// Info logs
console.log('Processing target:', targetId);

// Warning logs
console.warn('⚠ Warning:', { issue, context });

// Error logs
console.error('ERROR in functionName:', error);
```

### Log Levels
- **INFO**: Normal operations, progress updates
- **WARN**: Non-critical issues, degraded performance
- **ERROR**: Failures, exceptions, critical issues

---

## 2. Viewing Logs

### Via Firebase Console
1. Buka: https://console.firebase.google.com/project/dompetalumni/functions
2. Klik function name (e.g., `checkDeadlines`)
3. Tab **Logs** → Lihat real-time logs

### Via Firebase CLI
```bash
# View all function logs
firebase functions:log

# View specific function
firebase functions:log --only checkDeadlines

# View last 50 entries
firebase functions:log --limit 50

# Real-time streaming
firebase functions:log --follow
```

### Via Google Cloud Console
1. Buka: https://console.cloud.google.com/logs/query?project=dompetalumni
2. Query builder:
```
resource.type="cloud_function"
resource.labels.function_name="checkDeadlines"
severity>=WARNING
```

---

## 3. Key Metrics to Monitor

### Function Execution Metrics

**checkDeadlines**:
- Execution count (should be ~24/day)
- Targets closed per execution
- Excess transfers performed
- Next target activations
- Average execution time

**updateClosingSoonStatus**:
- Execution count (should be ~1/day)
- Targets marked as closing_soon
- Days until deadline for each

**cleanupOldSubmissions**:
- Execution count (should be ~1/week)
- Submissions deleted
- Storage freed (MB)
- Deletion errors

**onTargetClosed**:
- Execution count (variable)
- Analytics records created
- Archive operations performed

**routeIncome**:
- Execution count (variable)
- Routing to active target vs general fund
- Amount routed

### Performance Metrics
- **Execution time**: Should be <10s for scheduled, <5s for triggered
- **Memory usage**: Should be <256MB
- **Error rate**: Should be <1%
- **Cold start time**: First execution after idle

---

## 4. Cloud Monitoring Dashboard

### Create Custom Dashboard

**Via Google Cloud Console**:
1. Buka: https://console.cloud.google.com/monitoring/dashboards?project=dompetalumni
2. Klik **Create Dashboard**
3. Nama: "Dompet Alumni - Cloud Functions"

**Add Charts**:

#### Chart 1: Function Invocations (24h)
```
Resource type: Cloud Function
Metric: Executions
Aggregation: Sum
Group by: function_name
Time range: Last 24 hours
```

#### Chart 2: Error Rate
```
Resource type: Cloud Function
Metric: Execution count
Filter: status != "ok"
Aggregation: Rate
Group by: function_name
```

#### Chart 3: Execution Time
```
Resource type: Cloud Function
Metric: Execution times
Aggregation: 95th percentile
Group by: function_name
```

#### Chart 4: Memory Usage
```
Resource type: Cloud Function
Metric: User memory usage
Aggregation: Max
Group by: function_name
```

---

## 5. Alert Policies

### Setup Alerts via Cloud Console

**Alert 1: Function Execution Errors**
```
Condition:
  Resource: Cloud Function
  Metric: Execution count
  Filter: status != "ok"
  Threshold: > 3 errors in 1 hour
  
Notification:
  Email: adrianalfajri@gmail.com
  
Documentation:
  "Cloud Function execution failed. Check logs immediately."
```

**Alert 2: Function Timeout**
```
Condition:
  Resource: Cloud Function
  Metric: Execution times
  Threshold: > 50 seconds
  Duration: 5 minutes
  
Notification:
  Email: adrianalfajri@gmail.com
```

**Alert 3: Invocation Count Anomaly**
```
Condition:
  Resource: Cloud Function (checkDeadlines)
  Metric: Execution count
  Threshold: < 20 in 24 hours OR > 30 in 24 hours
  
Notification:
  Email: adrianalfajri@gmail.com
  
Documentation:
  "checkDeadlines should run ~24 times per day. Investigate scheduler."
```

**Alert 4: High Error Rate**
```
Condition:
  Resource: Cloud Function
  Metric: Error rate
  Threshold: > 5% over 1 hour
  
Notification:
  Email: adrianalfajri@gmail.com
```

### Create Alerts via gcloud CLI
```bash
# Function execution errors
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Cloud Functions - Execution Errors" \
  --condition-display-name="Error count > 3" \
  --condition-threshold-value=3 \
  --condition-threshold-duration=3600s

# Replace CHANNEL_ID with your notification channel
# Get channel ID: gcloud alpha monitoring channels list
```

---

## 6. Monitoring Queries

### Useful Log Queries

**All errors in last 24h**:
```
resource.type="cloud_function"
severity=ERROR
timestamp>="2026-01-07T00:00:00Z"
```

**checkDeadlines executions**:
```
resource.type="cloud_function"
resource.labels.function_name="checkDeadlines"
textPayload=~"=== Target closed"
```

**Targets auto-closed**:
```
resource.type="cloud_function"
resource.labels.function_name="checkDeadlines"
textPayload=~"✓.*closed successfully"
```

**Income routing**:
```
resource.type="cloud_function"
resource.labels.function_name="routeIncome"
textPayload=~"Routing to"
```

**Analytics logged**:
```
resource.type="cloud_function"
resource.labels.function_name="onTargetClosed"
textPayload=~"Analytics logged"
```

---

## 7. Health Check Checklist

### Daily Checks
- [ ] Check error count (should be 0)
- [ ] Verify scheduled functions executed
- [ ] Review execution times (no timeouts)

### Weekly Checks
- [ ] Review invocation counts vs expected
- [ ] Check memory usage trends
- [ ] Verify cleanup function ran
- [ ] Review cost vs budget

### Monthly Checks
- [ ] Analyze performance trends
- [ ] Review and update alert thresholds
- [ ] Check for deprecated APIs
- [ ] Update dependencies if needed

---

## 8. Troubleshooting

### Issue: Function not executing
**Check**:
1. Cloud Scheduler jobs enabled?
2. Function deployed successfully?
3. Billing account active?

**Fix**:
```bash
# Check scheduler jobs
gcloud scheduler jobs list --project=dompetalumni

# Manually trigger
gcloud scheduler jobs run JOB_NAME
```

### Issue: High error rate
**Check**:
1. Recent code changes?
2. Firestore index issues?
3. Permission errors?

**Fix**:
```bash
# View detailed errors
firebase functions:log --only FUNCTION_NAME | grep ERROR

# Rollback if needed (via Console)
```

### Issue: Slow execution
**Check**:
1. Large batch operations?
2. Network latency?
3. Cold starts?

**Fix**:
- Optimize batch size
- Add retry logic
- Consider min instances (costs $)

---

## 9. Cost Monitoring

### View Costs
1. Buka: https://console.cloud.google.com/billing?project=dompetalumni
2. **Reports** → Filter by "Cloud Functions"

### Expected Monthly Costs
- **Invocations**: ~1,000/month → FREE (within 2M limit)
- **Compute time**: ~100 GB-seconds → FREE (within 400K limit)
- **Networking**: <1GB → FREE (within 5GB limit)

**Total**: $0/month (well within free tier)

### Set Budget Alert
1. Cloud Console → Billing → Budgets & alerts
2. Create budget: $5/month
3. Alert at: 50%, 90%, 100%
4. Email: adrianalfajri@gmail.com

---

## 10. Performance Optimization

### Current Performance
- checkDeadlines: ~3-5s
- updateClosingSoonStatus: ~2-3s
- cleanupOldSubmissions: ~5-10s
- onTargetClosed: ~1-2s
- routeIncome: ~1-2s

### Optimization Tips
1. **Batch operations**: Already implemented ✅
2. **Retry logic**: Already implemented ✅
3. **Structured logging**: Already implemented ✅
4. **Error handling**: Already implemented ✅

### Future Optimizations
- Add caching for frequently accessed data
- Implement min instances for critical functions (if needed)
- Use Firestore bundles for large reads

---

## 11. Security Monitoring

### Monitor for:
- Unauthorized function invocations
- Unusual execution patterns
- Permission errors
- API quota exceeded

### Security Logs Query
```
resource.type="cloud_function"
protoPayload.status.code!=0
protoPayload.status.message=~"permission"
```

---

## Quick Reference

### Important URLs
- **Functions Dashboard**: https://console.firebase.google.com/project/dompetalumni/functions
- **Logs Explorer**: https://console.cloud.google.com/logs/query?project=dompetalumni
- **Monitoring**: https://console.cloud.google.com/monitoring?project=dompetalumni
- **Billing**: https://console.cloud.google.com/billing?project=dompetalumni

### Quick Commands
```bash
# View logs
firebase functions:log

# List functions
firebase functions:list

# Check scheduler
gcloud scheduler jobs list --project=dompetalumni

# View errors only
firebase functions:log | grep ERROR
```
