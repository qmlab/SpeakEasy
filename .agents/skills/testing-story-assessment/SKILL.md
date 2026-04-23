# Testing Story Assessment Feature

## Overview
The story assessment feature (e.g., Bunny's Birthday Party) combines a narrative with embedded assessment questions across 6 developmental dimensions. It has both backend (story data, scene flow) and iOS (TTS, UI, interactions) components.

## Backend API Testing

### Setup
1. Backend is deployed on Fly.io. Check health: `GET /health`
2. Create a test player: `POST /auth/guest` with `{"device_id": "test-xyz"}`
3. Start a story: `POST /story/start/{player_id}` with `{"story_id": "bunny_birthday"}`
4. Get scenes: `GET /story/{assessment_id}/next-scene`
5. Respond: `POST /story/{assessment_id}/respond` with `{"scene_index": N, "selected_option": "...", "response_time_ms": 3000}`
6. Complete: `POST /story/{assessment_id}/complete`

### Key Things to Verify
- Story data is served from `backend/app/resources/stories/bunny_birthday.json`
- Options are **shuffled at serve time** — order differs from JSON source
- When options are shuffled, `tap_regions` are also reordered to match
- Adaptive branching: scenes with `requires_correct` may serve a `fallback` version if the prerequisite was answered incorrectly
- Scene responses return `is_correct`, `feedback`, and `should_continue`

### Backend Deployment
- Uses the Devin `deploy` tool with `command=backend`, `dir=backend/`, `volume=true`
- **Important**: Remove `.venv/` and `*.db` files before deploying — they bloat the package beyond the 100MB limit
- Deployed URL pattern: `https://risingstar-backend-{id}.fly.dev/`
- Persistent volume at `/data` for SQLite database

## iOS Testing (Requires Device/Simulator)

The following features can only be tested on a real iOS device or simulator:
- **TTS (Text-to-Speech)**: AVSpeechSynthesizer voice output, rate, pitch settings
- **Tap-on-image interaction**: Tapping regions on story images (uses normalized 0-1 coordinates)
- **Emoji rendering**: Large emoji icons in option buttons for non-literate children
- **SwiftUI layout**: Option button layout, image overlays, feedback animations

### Key iOS Files
- `SpeakEasy/Views/StoryAssessmentView.swift` — Main story UI, tap handling, option buttons
- `SpeakEasy/Services/SpeechService.swift` — TTS with `speak()` and `speakStorytelling()` methods
- `SpeakEasy/Services/AdaptiveAPIService.swift` — API client for story endpoints

### TestFlight
- CI automatically builds and deploys to TestFlight on push to main
- Check GitHub Actions for build status

## Devin Secrets Needed
- No secrets needed for backend API testing (guest auth is unauthenticated)
- For iOS CI/TestFlight: Apple signing certificates and provisioning profiles (managed via GitHub Secrets)
