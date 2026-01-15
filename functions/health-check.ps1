# Health Check Script for Cloud Functions (PowerShell)

Write-Host "=== Cloud Functions Health Check ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project: dompetalumni"
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# Check function list
Write-Host "1. Checking deployed functions..." -ForegroundColor Yellow
firebase functions:list --project dompetalumni
Write-Host ""

# Check recent logs
Write-Host "2. Checking recent function logs..." -ForegroundColor Yellow
firebase functions:log --limit 20
Write-Host ""

# Check for errors
Write-Host "3. Checking for errors..." -ForegroundColor Yellow
$errors = firebase functions:log --limit 100 | Select-String -Pattern "ERROR" -CaseSensitive
if ($errors) {
    Write-Host "   Found $($errors.Count) errors" -ForegroundColor Red
    $errors | Select-Object -First 5
} else {
    Write-Host "   ✓ No errors found" -ForegroundColor Green
}
Write-Host ""

# Check scheduler jobs
Write-Host "4. Checking Cloud Scheduler jobs..." -ForegroundColor Yellow
try {
    gcloud scheduler jobs list --project=dompetalumni
    Write-Host "   ✓ Scheduler jobs listed" -ForegroundColor Green
} catch {
    Write-Host "   ⚠ Could not list scheduler jobs" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=== Health Check Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "  - Review logs in Firebase Console"
Write-Host "  - Check monitoring dashboard"
Write-Host "  - Verify scheduled functions running"
Write-Host ""
