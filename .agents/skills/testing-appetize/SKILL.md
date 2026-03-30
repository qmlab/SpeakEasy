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

## Devin Secrets Needed
- `APPETIZE_PUBLIC_KEY`: xtydm5atxiqv3iff2kkbc43x74 (public, found in CI logs)
- `APPETIZE_API_TOKEN`: Required for uploading new builds (stored as GitHub repo secret)
