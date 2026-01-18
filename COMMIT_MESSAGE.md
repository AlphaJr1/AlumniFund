feat: Implement complete onboarding feedback system with admin panel

## 🎯 Feature Summary
Implemented end-to-end onboarding feedback collection system dengan admin management panel.

## ✨ New Features

### Public Features
- **Feedback Modal**: Optional survey setelah tutorial completion
  - Auto-show setelah step 5 (replaced step 6)
  - Anonymous user tracking (localStorage UUID + browser fingerprint)
  - Device info collection (browser, screen resolution, timezone)
  - 500 character limit dengan real-time counter
  - Graceful error handling

### Admin Features
- **Feedback List Screen** (`/admin/feedbacks`)
  - Filter chips: All, Unread, Read dengan counts
  - Feedback preview cards dengan badges
  - Tap to view full details
  
- **Feedback Detail Modal**
  - Full feedback content
  - User identification info (anonymous ID + fingerprint)
  - Device information display
  - Copy-to-clipboard functionality
  - Mark as read action
  
- **Dashboard Stat Card**
  - Total feedback count
  - Unread badge (highlighted)
  - Quick "View All" navigation

## 📦 New Files (13)

### Models & Services
- `lib/models/onboarding_feedback_model.dart` - Feedback data model
- `lib/services/user_identifier_service.dart` - Anonymous tracking
- `lib/services/feedback_service.dart` - Firestore operations

### Providers
- `lib/providers/feedback_provider.dart` - State management dengan filtering

### Widgets
- `lib/widgets/onboarding_feedback_modal.dart` - Public submission modal
- `lib/widgets/admin/feedback_card.dart` - List preview card
- `lib/widgets/admin/feedback_detail_modal.dart` - Detail view modal
- `lib/widgets/admin/feedback_stat_card.dart` - Dashboard stats

### Screens
- `lib/screens/admin/views/feedback_list_screen.dart` - Feedback management

### Infrastructure
- `firestore.rules` - Comprehensive security rules (13 collections)
- `.github/workflows/ci.yml` - GitHub Actions CI/CD pipeline

## 🔧 Modified Files (6)

- `lib/providers/onboarding_provider.dart` - Added modal trigger logic
- `lib/widgets/onboarding_overlay.dart` - Integrated feedback modal
- `lib/screens/admin/views/dashboard_overview.dart` - Added stat card
- `lib/router/app_router.dart` - Added feedback route  
- `lib/screens/warmup_screen.dart` - Added error handling & timeout
- `pubspec.yaml` - Added crypto dependency

## 🐛 Critical Fixes

1. **Firestore Permission Errors** - Missing collections di rules
   - Added comprehensive rules untuk 13 collections
   - Fixed collection name mismatch (system_config → settings)
   
2. **Warmup Screen Stuck** - Settings init error blocked app
   - Added 5-second timeout dengan graceful fallback
   - Changed check: `hasValue || hasError`
   
3. **FeedbackStatCard Overflow** - 60px overflow warning
   - Wrapped dengan SingleChildScrollView
   - Reduced padding, font sizes, spacing
   - Added overflow: ellipsis untuk text

4. **Feedback Modal Not Showing** - Wrong button handler
   - Fixed "Selesai" button → call completeCurrentStep()
   - Added debug logging untuk flow tracing

## 🔒 Security

### Firestore Rules Deployed
- **Public create**: onboarding_feedbacks, income_submissions
- **Public read**: general_fund, targets, transactions, settings, analytics
- **Admin only**: admin_users, write permissions, delete operations
- **Helper function**: isAdmin() untuk cleaner rules

## 🧪 Testing

✅ Manual testing complete:
- Feedback submission flow (dengan & tanpa text)
- Admin panel (list, detail, filtering, mark as read)
- Firestore permissions (public create, admin read)
- Responsive layouts (mobile, tablet, desktop)
- Error handling & edge cases

## 📊 Code Quality

- `flutter analyze`: 280 issues (mostly info warnings, 0 errors)
- All critical flows tested & verified
- Documentation complete (walkthrough.md)

## 🚀 Deployment

- ✅ Firestore rules deployed to production
- ✅ App running without errors
- ✅ CI/CD pipeline configured (.github/workflows/ci.yml)

## 🔗 Related

- Collection: `onboarding_feedbacks`
- Admin Route: `/admin/feedbacks`
- Dependencies: crypto ^3.0.3

---

**Files changed:** 19 (+13 new, ~6 modified)  
**Lines changed:** ~2,500+ lines added  
**Status:** ✅ Ready for production
