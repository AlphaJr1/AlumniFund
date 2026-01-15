# Brief: Smart Loading Screen Behavior

**Created:** 2026-01-12  
**Status:** Planned (Not Implemented)  
**Priority:** Medium  
**Category:** UX Enhancement

---

## User Request

**Context:**
Setelah mengimplementasikan loading screen dengan animated gradient dan warmup screen, user menyadari bahwa splash screen muncul pada SETIAP refresh (Ctrl/Cmd+R), yang bisa terasa repetitif untuk user yang sering refresh.

**Desired Behavior:**
- **Ctrl/Cmd + R** (soft refresh) → Skip splash screen, langsung ke warmup/dashboard dengan skeleton loaders
- **First visit** atau **Ctrl/Cmd + Shift + R** (hard refresh) → Full splash screen experience

**Goal:**
Meningkatkan UX dengan memberikan pengalaman yang lebih cepat untuk refresh biasa, sambil tetap mempertahankan splash screen yang menarik untuk first impression.

---

## Technical Analysis

### Challenge
- Flutter web melakukan **full app reload** untuk semua jenis refresh
- Browser JavaScript **tidak bisa mendeteksi** perbedaan antara soft refresh (Ctrl+R) vs hard refresh (Ctrl+Shift+R)
- Browser API tidak expose informasi tentang jenis reload
- Flutter tidak preserve state saat page refresh

### Browser Limitation
```javascript
// ❌ TIDAK TERSEDIA
window.addEventListener('reload', (event) => {
  console.log(event.isSoftReload); // No such property exists
});
```

---

## Proposed Solutions

### ✅ Option 1: Session-Based Skip (RECOMMENDED)

**Concept:**
Gunakan `sessionStorage` untuk track apakah user sudah melihat splash dalam session ini.

**Behavior:**
- **New tab/window** → Full splash screen
- **Refresh dalam tab yang sama** → Skip HTML splash, langsung warmup
- **Close tab** → sessionStorage cleared, next open shows splash

**Implementation:**

#### index.html
```javascript
// Check if user already visited in this session
window.addEventListener('DOMContentLoaded', () => {
  const hasVisited = sessionStorage.getItem('splashShown');
  const loadingScreen = document.getElementById('loading-screen');
  
  if (hasVisited === 'true') {
    // User already saw splash in this session, skip it
    loadingScreen.style.display = 'none';
  } else {
    // First visit in this session, show splash
    sessionStorage.setItem('splashShown', 'true');
  }
});
```

#### Warmup Screen Adjustment
Warmup screen tetap berjalan normal, tapi sekarang:
- Jika HTML splash di-skip: Warmup appears immediately
- Jika HTML splash shown: Warmup appears after HTML splash fades

**Pros:**
- ✅ Simple implementation (~10 lines)
- ✅ Clear UX: new tab = splash, refresh = faster
- ✅ Auto-cleanup (sessionStorage cleared on tab close)
- ✅ No magic numbers or arbitrary timers
- ✅ User has control (new tab if want splash)

**Cons:**
- ❌ Warmup screen tetap ada (unavoidable - data must load)
- ❌ Private/incognito mode always shows splash

---

### Option 2: Time-Based Skip

**Concept:**
Track last visit time dengan `localStorage`, skip splash jika baru visit dalam X menit terakhir.

**Implementation:**
```javascript
const SKIP_DURATION = 15 * 60 * 1000; // 15 minutes
const lastVisit = localStorage.getItem('lastVisit');
const now = Date.now();

if (lastVisit && (now - parseInt(lastVisit) < SKIP_DURATION)) {
  // Skip splash
  document.getElementById('loading-screen').style.display = 'none';
} else {
  // Show splash and update timestamp
  localStorage.setItem('lastVisit', now.toString());
}
```

**Pros:**
- ✅ Works across tabs
- ✅ Persistent across browser sessions (until timeout)

**Cons:**
- ❌ Magic number (15 min arbitrary)
- ❌ localStorage doesn't auto-clear
- ❌ Requires manual cleanup logic
- ❌ Less intuitive UX

---

### Option 3: PWA with Service Worker (ADVANCED)

**Concept:**
Implement Progressive Web App dengan service worker untuk cache assets dan data.

**Implementation:**
1. Setup service worker
2. Cache app shell (HTML, CSS, JS)
3. Cache API responses
4. Conditional splash based on cache hit

**Pros:**
- ✅ True offline-first experience
- ✅ Fastest possible subsequent loads
- ✅ Professional PWA features (install, notifications)
- ✅ Asset caching = instant load

**Cons:**
- ❌ Complex setup and maintenance
- ❌ Cache invalidation challenges
- ❌ Still needs warmup for fresh data
- ❌ Significant development effort

---

## Recommended Implementation Plan

**Phase 1: Session-Based Skip** (Easy Win)
1. Add sessionStorage check to `index.html`
2. Hide/show loading screen conditionally
3. Test:
   - New tab → Shows splash ✅
   - Refresh → Skips splash ✅
   - Close + reopen → Shows splash ✅

**Phase 2 (Optional): Time-Based Enhancement**
1. Add localStorage tracking
2. Implement time-based logic
3. Add cleanup on app init

**Phase 3 (Future): PWA Migration**
1. Create service worker
2. Implement caching strategy
3. Add offline support
4. Enable app installation

---

## User Experience Flow

### Current (After Warmup Implementation)
```
EVERY LOAD:
1. HTML Splash (animated gradient) - 2s
2. Warmup Screen (preload data) - 1-2s
3. Dashboard (fully loaded) - instant
Total: ~3-4s
```

### After Session-Based Skip
```
FIRST VISIT (new tab):
1. HTML Splash (animated gradient) - 2s
2. Warmup Screen (preload data) - 1-2s
3. Dashboard (fully loaded) - instant
Total: ~3-4s

REFRESH (same tab):
1. [SKIPPED]
2. Warmup Screen (preload data) - 1-2s
3. Dashboard (fully loaded) - instant
Total: ~1-2s (50% faster!)
```

---

## Implementation Checklist

When ready to implement:

### Session-Based Skip
- [ ] Add sessionStorage check to index.html
- [ ] Test new tab behavior
- [ ] Test refresh behavior
- [ ] Test private/incognito mode
- [ ] Update user documentation

### Time-Based Skip (Optional)
- [ ] Implement localStorage time tracking
- [ ] Add configurable timeout constant
- [ ] Implement cleanup on old entries
- [ ] Test cross-tab behavior
- [ ] Test after timeout expiry

### PWA (Future)
- [ ] Research Flutter PWA setup
- [ ] Create service worker configuration
- [ ] Implement caching strategy
- [ ] Test offline functionality
- [ ] Add installation prompt

---

## Related Files

Current implementation:
- `web/index.html` - HTML splash screen
- `lib/screens/warmup_screen.dart` - Data preloading
- `lib/router/app_router.dart` - Routing configuration

Will need to modify:
- `web/index.html` - Add sessionStorage logic

---

## Notes for Future Implementation

1. **Testing is critical** - Verify behavior across:
   - Normal refresh (Ctrl+R)
   - Hard refresh (Ctrl+Shift+R)
   - New tab/window
   - Private/incognito mode
   - Different browsers (Chrome, Firefox, Safari)

2. **User preference option** - Consider adding setting to:
   - Always show splash
   - Always skip splash
   - Smart skip (recommended default)

3. **Analytics** - Track:
   - Splash skip rate
   - Time to interactive
   - User engagement with splash

4. **Accessibility** - Ensure skip logic doesn't break:
   - Screen reader announcements
   - Keyboard navigation
   - Reduced motion preferences

---

## Expected Impact

**Metrics to track:**
- ⏱️ Average load time reduction: ~50% on refresh
- 👍 User satisfaction with refresh speed
- 📊 Splash view rate vs skip rate
- 🔄 Refresh frequency patterns

**Success criteria:**
- [ ] Refresh ~50% faster than first visit
- [ ] No broken UX in any scenario
- [ ] Positive user feedback on speed
- [ ] No increase in error rates

---

## References

- Current walkthrough: `C:\Users\pbm\.gemini\antigravity\brain\21fcc193-0845-4e23-92b7-9177a78959af\walkthrough.md`
- sessionStorage API: https://developer.mozilla.org/en-US/docs/Web/API/Window/sessionStorage
- localStorage API: https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage
- Service Worker API: https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API
