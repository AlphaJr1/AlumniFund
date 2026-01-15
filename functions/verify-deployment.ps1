# Pre-Deployment Verification Script (PowerShell)
# Windows version of verify-deployment.sh

Write-Host "=== Pre-Deployment Verification ===" -ForegroundColor Cyan
Write-Host ""

# Check Node.js version
Write-Host "1. Checking Node.js version..." -ForegroundColor Yellow
$nodeVersion = node -v
Write-Host "   Node.js version: $nodeVersion"
if ($nodeVersion -like "v18*" -or $nodeVersion -like "v20*") {
    Write-Host "   ✓ Node.js version OK" -ForegroundColor Green
}
else {
    Write-Host "   ⚠ Warning: Node.js 18+ recommended, current: $nodeVersion" -ForegroundColor Yellow
}
Write-Host ""

# Check Firebase CLI
Write-Host "2. Checking Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "   Firebase CLI version: $firebaseVersion"
    Write-Host "   ✓ Firebase CLI installed" -ForegroundColor Green
}
catch {
    Write-Host "   ✗ Firebase CLI not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check dependencies
Write-Host "3. Checking dependencies..." -ForegroundColor Yellow
Set-Location functions
if (Test-Path "node_modules") {
    Write-Host "   ✓ node_modules exists" -ForegroundColor Green
}
else {
    Write-Host "   ✗ node_modules not found. Run: npm install" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host ""

# Run tests
Write-Host "4. Running tests..." -ForegroundColor Yellow
npm test
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ All tests passed" -ForegroundColor Green
}
else {
    Write-Host "   ✗ Tests failed. Fix errors before deploying." -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host ""

# Check for vulnerabilities
Write-Host "5. Checking for vulnerabilities..." -ForegroundColor Yellow
npm audit --audit-level=high
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ No high/critical vulnerabilities" -ForegroundColor Green
}
else {
    Write-Host "   ⚠ Vulnerabilities found. Run: npm audit fix" -ForegroundColor Yellow
}
Write-Host ""

# Check firebase.json
Write-Host "6. Checking firebase.json..." -ForegroundColor Yellow
Set-Location ..
if (Test-Path "firebase.json") {
    Write-Host "   ✓ firebase.json exists" -ForegroundColor Green
}
else {
    Write-Host "   ✗ firebase.json not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check firestore indexes
Write-Host "7. Checking Firestore indexes..." -ForegroundColor Yellow
if (Test-Path "firestore.indexes.json") {
    Write-Host "   ✓ firestore.indexes.json exists" -ForegroundColor Green
}
else {
    Write-Host "   ⚠ firestore.indexes.json not found" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ready to deploy? Run:" -ForegroundColor Green
Write-Host "  firebase deploy --only functions" -ForegroundColor White
Write-Host ""
