---
name: testing-appetize
description: Test the Rising Star Kid iOS app on Appetize simulator. Use when verifying iOS UI changes, navigation flows, or interaction behaviors.
---

# Testing on Appetize iOS Simulator

## Appetize App URL
```
https://appetize.io/app/xtydm5atxiqv3iff2kkbc43x74
```

## Known Limitations
- **Scrolling**: Browser scroll events may not propagate into the Appetize simulator. The `scroll` action and mouse wheel do not reliably scroll within iOS views. The Appetize JS API (`window.session`) only exposes `allowInteractions`, `rotate`, `end` — no `swipe` method.
- **Workaround for scrolling**: If you need to reach UI elements below the fold, try:
  1. Navigate via a different tab (e.g., Home tab has dimension icons directly)
  2. Use smaller device/scale settings
  3. If scrolling is critical, consider API-level testing as an alternative for backend-only changes
- **Stale builds**: `APPETIZE_API_TOKEN` is NOT configured in GitHub Secrets as of June 2026. CI skips Appetize deployment. The build on Appetize may be outdated and still point to dead backend URLs.
- **Gesture timing**: Appetize adds 100-300ms network latency per touch interaction (browser → Appetize servers → simulator). This makes it impossible to measure gesture response time improvements. For timing-sensitive changes (like DragGesture minimumDistance), use TestFlight real-device testing instead.
- **No drag verification**: Even with an updated build, drag gesture delay improvements cannot be meaningfully verified through Appetize due to inherent network latency.

## App Navigation
1. Tap "Tap to Start" or wait for auto-start
2. Dismiss permission dialogs (Speech Recognition → OK, Camera → OK)
3. Tap "Continue as Guest" to enter without auth
4. **Home tab**: Shows DimensionHub with 6 dimension icons in 2x3 grid
5. **Learn tab**: Shows dimension cards with "Start" buttons — requires scrolling for dimensions 3-6
6. **Camera tab**: Object detection (requires camera permission)
7. **Progress tab**: Learning analytics
8. **Settings tab**: Version info, logout

## Dimension Order (in code enum)
1. objectCognition (orange trophy icon)
2. languageExpression (blue wave icon)
3. languageComprehension (green headphones icon)
4. literacy (purple book icon)
5. socialBehavior (pink/red people icon)
6. cognitiveLogic (cyan/teal brain icon)

## Drag Interaction Tasks
- **drag** (drag-to-arrange): `interaction_mode == "drag"` — reorder shapes to match reference image. Found in seed_tasks.py (4 tasks).
- **drag_sort** (drag-to-category): `interaction_mode == "drag_sort"` — drag items into category buckets. Found in object_cognition_expanded.json (141 tasks) and seed_tasks.py (3 tasks).
- Drag tasks appear at **higher difficulty levels** — a new player starts at level 0 with simple identify/tap tasks.
- Drag tasks are rendered in a **non-scrollable VStack** (not ScrollView) to avoid gesture conflict.

## When API Testing is Sufficient
For **backend-only changes** (e.g., seed_expanded.py, task JSON), API-level testing is conclusive because:
- The iOS rendering logic is unchanged
- `displayOptions` returns `options ?? []` — presence of options determines UI behavior
- No need to navigate through Appetize to prove the fix works

## When Appetize UI Testing is Needed
- iOS code changes (SwiftUI views, models, services)
- New UI components or layout changes
- Interaction flow changes (button behavior, navigation)
- Image display verification

## When TestFlight Testing is Required
- Gesture timing/responsiveness changes (DragGesture, minimumDistance, etc.)
- Audio/speech features
- Camera/AR features
- Real device performance

## Backend API Testing Flow
```bash
# 1. Health check
curl https://risingstar-backend.fly.dev/health

# 2. Create guest player
curl -X POST https://risingstar-backend.fly.dev/auth/guest \
  -H "Content-Type: application/json" \
  -d '{"device_id": "test-device-001"}'

# 3. Start session (use player_id from step 2)
curl -X POST https://risingstar-backend.fly.dev/adaptive/sessions/start \
  -H "Content-Type: application/json" \
  -d '{"player_id": "PLAYER_ID", "dimension": "object_cognition", "session_type": "learning"}'

# 4. Get next task (use session_id from step 3)
curl "https://risingstar-backend.fly.dev/adaptive/sessions/SESSION_ID/next-task?player_id=PLAYER_ID&dimension=object_cognition"
```

## Devin Secrets Needed
- `APPETIZE_PUBLIC_KEY`: xtydm5atxiqv3iff2kkbc43x74 (public, found in CI logs)
- `APPETIZE_API_TOKEN`: Required for uploading new builds (stored as GitHub repo secret) — currently NOT configured
- `FLY_API_TOKEN`: For backend deployment management on Fly.io
