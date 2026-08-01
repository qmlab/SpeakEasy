---
name: testing-ios-gestures
description: Test iOS gesture and interaction changes (SwiftUI DragGesture, LongPressGesture, etc.) when only a Linux VM is available. Use when verifying drag/touch interaction PRs.
---

# Testing iOS Gesture Changes

## Constraints
- **No iOS simulator on Linux VM** — gesture timing/responsiveness cannot be tested
- **Appetize build might be stale** — check if `APPETIZE_API_TOKEN` is configured in GitHub Secrets
- **Real-device testing requires TestFlight** — user must verify timing on their device
- **CI build-and-test confirms compilation** — if CI passes, gesture code compiles correctly

## What You CAN Verify (Code Correctness)

### Sequenced Gesture Pattern
The standard pattern for eliminating iOS gesture disambiguation delay:
```swift
LongPressGesture(minimumDuration: 0.01)
    .sequenced(before: DragGesture(minimumDistance: 0))
    .onChanged { value in
        switch value {
        case .first(true):  // Touch-down — instant feedback
        case .second(true, let drag):  // Actual dragging
        default: break
        }
    }
    .onEnded { value in
        guard case .second(true, let drag?) = value else { return }
        // Use drag.translation, drag.location
    }
```

### Verification Checklist
1. `LongPressGesture(minimumDuration: 0.01)` — near-instant recognition
2. `.sequenced(before: DragGesture(...))` — proper chaining
3. `.first(true)` case sets the dragged item state immediately
4. `.second(true, let drag)` safely unwraps optional `DragGesture.Value`
5. `onEnded` uses `guard case .second(true, let drag?) = value` for pattern matching
6. `drag.translation` / `drag.location` used (NOT `value.translation`)
7. No standalone `DragGesture` remaining in drag interaction paths
8. `coordinateSpace: .global` preserved where needed (for drop detection)

### Grep Commands
```bash
# Find all DragGesture instances
grep -n "DragGesture" SpeakEasy/Views/LearningSessionView.swift

# Verify sequenced pattern
grep -n "LongPressGesture\|sequenced\|\.first(true)\|\.second(true" SpeakEasy/Views/LearningSessionView.swift
```

## Backend API Verification
Verify drag tasks are available for the iOS app:
```bash
# Health check
curl -s https://risingstar-backend.fly.dev/health

# Check drag_sort tasks exist
curl -s "https://risingstar-backend.fly.dev/tasks/?dimension=object_cognition&interaction_mode=drag_sort&limit=5"
```

## What Requires Real Device Testing
- Gesture recognition timing (does touch-down feel instant?)
- Whether 10ms LongPress causes false activations on quick taps
- Tap-to-enlarge still works (distance < 10 check)
- No accidental drags on light touches
- Drag-and-drop accuracy to category buckets

## Key Files
- `SpeakEasy/Views/LearningSessionView.swift` — both drag gestures (~lines 1449 and 1652)
- `SpeakEasy/Views/StoryAssessmentView.swift` — has a DragGesture used as tap detector (don't modify)

## Backend URL
- Production: `https://risingstar-backend.fly.dev`
- The skill file `testing-backend-api/SKILL.md` has an outdated URL — the correct one is above

## Devin Secrets Needed
- None for code verification or backend API testing
- `APPETIZE_API_TOKEN` (GitHub Secret, not available to Devin) for Appetize UI testing
