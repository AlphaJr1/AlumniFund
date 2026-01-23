# DompetAlumni

Transparent alumni community fund management dashboard built with Flutter Web and Firebase.

[![CI/CD Pipeline](https://github.com/AlphaJr1/AlumniFund/actions/workflows/ci.yml/badge.svg)](https://github.com/AlphaJr1/AlumniFund/actions/workflows/ci.yml) [![Live Demo](https://img.shields.io/badge/demo-live-success)](https://unamed.web.app) [![Flutter](https://img.shields.io/badge/Flutter-3.38.5-blue)](https://flutter.dev) [![Firebase](https://img.shields.io/badge/Firebase-Hosting-orange)](https://firebase.google.com)

---

## Features

### Core Functionality
- **Public Dashboard** — Real-time fund transparency with card-based navigation
- **Circular Reveal Animation** — Position-based theme switching (500ms, smooth transitions)
- **Graduation Targets** — Auto-lifecycle management with deadline tracking
- **General Fund** — Community pool with multi-payment support
- **Proof Upload** — Photo submission with admin validation
- **Cloud Functions** — Automated target management and income routing

### Admin Panel
- Validate pending submissions
- Record expenses with proof
- Manage graduation targets
- Configure payment methods & system settings
- View analytics & health monitoring

---

## Quick Start

### Prerequisites
- Flutter SDK ≥ 3.38.5
- Firebase project
- Node.js (for CLI)

### Setup

```bash
# Clone and install
git clone <repository-url>
cd DompetAlumni
flutter pub get

# Configure Firebase
# 1. Create Firebase project
# 2. Enable Firestore, Storage, Auth
# 3. Add firebase_options.dart to lib/
# 4. Deploy rules: firebase deploy --only firestore:rules,storage

# Run locally
flutter run -d chrome

# Build & deploy
flutter build web --release
firebase deploy --only hosting
```

---

## Project Structure

```
lib/
├── models/      # Firestore data models
├── providers/   # Riverpod state management
├── services/    # Firebase services
├── widgets/     # UI components
├── screens/     # App screens
├── utils/       # Helpers & formatters
└── theme/       # AppTheme & colors
```

---

## Key Implementation

### Circular Reveal Animation
**File:** `lib/screens/public_dashboard_screen.dart`  
**Trigger:** Double-tap background  
**Technical:** CustomPainter with inverse path clipping, gradient shader

```dart
// 3-layer Stack architecture
Stack([
  Background(newTheme),           // Layer 1
  AnimationLayer(oldTheme),       // Layer 2 (reveals new)
  CardStackWidget(),              // Layer 3 (always on top)
])
```

### Cloud Functions (5 automated)
**Scheduled:**
- `checkDeadlines` — Hourly expiration checks
- `updateClosingSoonStatus` — Daily H-7 marking
- `cleanupOldSubmissions` — Weekly cleanup

**Triggered:**
- `onTargetClosed` — Analytics logging
- `routeIncome` — Auto allocation

See: [CLOUD_FUNCTIONS.md](CLOUD_FUNCTIONS.md)

---

## Firestore Schema

| Collection | Purpose |
|------------|---------|
| `graduation_targets` | Targets with lifecycle states |
| `transactions` | Income & expense records |
| `general_fund` | Community pool balance |
| `pending_submissions` | Awaiting validation |
| `settings` | App configuration |

---

## Development

### Feature Flags
```dart
// lib/main.dart
const bool kUseFirebase = true;  // Toggle for offline dev
```

### Utilities
```dart
CurrencyFormatter.formatCurrency(250000);  // "Rp 250.000"
DateFormatter.formatDate(DateTime(2026, 4, 28));  // "28 April 2026"
```

---

## Deployment

**Live:** https://unamed.web.app

```bash
flutter build web --release
firebase deploy --only hosting
```

---

## Documentation

- [Firebase Setup](FIREBASE_SETUP.md)
- [Admin Guide](ADMIN_ACCOUNT_SETUP.md)
- [Cloud Functions](CLOUD_FUNCTIONS.md)
- [Backup & Recovery](BACKUP_RECOVERY.md)

---

## License

MIT License

---

Built for transparent alumni community fund management
