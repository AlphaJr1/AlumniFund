#!/bin/bash
# Pre-deployment verification script

echo "=== Pre-Deployment Verification ==="
echo ""

# Check Node.js version
echo "1. Checking Node.js version..."
node_version=$(node -v)
echo "   Node.js version: $node_version"
if [[ $node_version == v18* ]]; then
  echo "   ✓ Node.js 18 detected"
else
  echo "   ⚠ Warning: Node.js 18 recommended, current: $node_version"
fi
echo ""

# Check Firebase CLI
echo "2. Checking Firebase CLI..."
firebase_version=$(firebase --version)
echo "   Firebase CLI version: $firebase_version"
echo "   ✓ Firebase CLI installed"
echo ""

# Check dependencies
echo "3. Checking dependencies..."
cd functions
if [ -d "node_modules" ]; then
  echo "   ✓ node_modules exists"
else
  echo "   ✗ node_modules not found. Run: npm install"
  exit 1
fi
echo ""

# Run tests
echo "4. Running tests..."
npm test
if [ $? -eq 0 ]; then
  echo "   ✓ All tests passed"
else
  echo "   ✗ Tests failed. Fix errors before deploying."
  exit 1
fi
echo ""

# Check for vulnerabilities
echo "5. Checking for vulnerabilities..."
npm audit --audit-level=high
if [ $? -eq 0 ]; then
  echo "   ✓ No high/critical vulnerabilities"
else
  echo "   ⚠ Vulnerabilities found. Run: npm audit fix"
fi
echo ""

# Check firebase.json
echo "6. Checking firebase.json..."
if [ -f "../firebase.json" ]; then
  echo "   ✓ firebase.json exists"
else
  echo "   ✗ firebase.json not found"
  exit 1
fi
echo ""

# Check firestore indexes
echo "7. Checking Firestore indexes..."
if [ -f "../firestore.indexes.json" ]; then
  echo "   ✓ firestore.indexes.json exists"
else
  echo "   ⚠ firestore.indexes.json not found"
fi
echo ""

echo "=== Verification Complete ==="
echo ""
echo "Ready to deploy? Run:"
echo "  firebase deploy --only functions"
echo ""
