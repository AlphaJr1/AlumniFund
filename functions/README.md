# Firebase Cloud Functions

Automated processes and system intelligence untuk Dompet Alumni.

## 📁 Struktur Direktori

```
functions/
├── index.js              # Main entry point
├── package.json          # Dependencies
├── .gitignore            
├── scheduled/            # Time-triggered functions (cron jobs)
│   ├── checkDeadlines.js
│   ├── updateClosingSoonStatus.js
│   └── cleanupOldSubmissions.js
├── triggers/             # Event-triggered functions
│   ├── onTargetClosed.js
│   └── routeIncome.js
└── helpers/              # Shared utilities
    ├── constants.js      # System configurations
    ├── retryUtils.js     # Retry logic
    ├── transferExcess.js # Transfer excess funds
    ├── autoOpenTarget.js # Auto-open next target
    └── analytics.js      # Analytics logging
```

## 🚀 Development Setup

### Prerequisites
- Node.js 18+
- Firebase CLI v15+
- Firebase project configured

### Local Development
```bash
# Install dependencies
cd functions
npm install

# Start emulators
firebase emulators:start

# Test specific function
firebase functions:shell
```

## 📋 Cloud Functions Overview

### Scheduled Functions
1. **checkDeadlines** - Hourly (`0 * * * *`)
   - Auto-close targets past deadline
   - Transfer excess to general fund
   - Auto-open next target

2. **updateClosingSoonStatus** - Daily midnight (`0 0 * * *`)
   - Mark targets as closing_soon at H-7

3. **cleanupOldSubmissions** - Weekly Sunday 2AM (`0 2 * * 0`)
   - Delete rejected submissions >30 days old

### Triggered Functions
1. **onTargetClosed** - Firestore trigger
   - Log analytics
   - Auto-archive after graduations

2. **routeIncome** - Firestore trigger
   - Auto-route income to active target or general fund

## 🔧 Configuration

Lihat `helpers/constants.js` untuk semua konfigurasi sistem.

## 📦 Deployment

```bash
# Deploy semua functions
npm run deploy

# Deploy specific function
firebase deploy --only functions:checkDeadlines

# View logs
npm run logs
```

## 🧪 Testing

```bash
# Unit tests
npm test

# Emulator testing
firebase emulators:start --only functions,firestore
```

## 📝 Status

- ✅ Infrastructure setup complete
- ⏳ Functions implementation in progress
- ⏳ Testing suite pending
- ⏳ Deployment pending
