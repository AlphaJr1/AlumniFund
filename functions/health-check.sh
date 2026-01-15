#!/bin/bash
# Health Check Script for Cloud Functions

echo "=== Cloud Functions Health Check ==="
echo ""
echo "Project: dompetalumni"
echo "Date: $(date)"
echo ""

# Check function list
echo "1. Checking deployed functions..."
firebase functions:list --project dompetalumni
echo ""

# Check recent errors
echo "2. Checking for errors in last 24h..."
firebase functions:log --limit 100 | grep -i error | wc -l
echo ""

# Check scheduler jobs
echo "3. Checking Cloud Scheduler jobs..."
gcloud scheduler jobs list --project=dompetalumni
echo ""

# Check last execution times
echo "4. Recent function executions..."
firebase functions:log --limit 10
echo ""

echo "=== Health Check Complete ==="
