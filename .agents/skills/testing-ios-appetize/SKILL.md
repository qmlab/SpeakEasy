# Testing Rising Star Kid iOS App on Appetize

## Overview
The iOS app is deployed to Appetize via CI (GitHub Actions). Each push to `main` triggers a build that uploads the `.app` artifact and deploys it to Appetize.

## Appetize URL
- The Appetize public key is stored as a GitHub secret `APPETIZE_PUBLIC_KEY`
- App URL format: `https://appetize.io/app/{PUBLIC_KEY}`
- Use device: iPhone 14 Pro, iOS 16.2 for consistent testing

## Devin Secrets Needed
- `APPETIZE_API_TOKEN` — for uploading builds to Appetize (stored in GitHub secrets)
- `APPETIZE_PUBLIC_KEY` — the app's public key on Appetize (stored in GitHub secrets)

## Navigation Flow
1. **Launch** → Speech recognition permission dialog → tap "OK"
2. **Login screen** → "Rising Star Kid" branding with star → tap "Continue as Guest"
3. **Camera permission** dialog may appear → tap "OK"
4. **DimensionHubView** → shows 6 dimension cards (Object Cognition, Language Expression, etc.), greeting, Level indicator
5. **Bottom tab bar**: Home, Learn, Camera, Progress, Settings
6. **Learn tab** → tap to see dimension cards list → tap a dimension card (e.g., "Object Cognition") to start learning session
7. **Learning session** → shows instruction card with:
   - "Hear Again" button (orange capsule, speaker icon)
   - Target image in colored circle
   - Target word with speaker icon (tappable for audio)
   - "Find with Camera" button
   - Option buttons with thumbnail images
8. **Camera view** → opens from "Find with Camera" button, shows close (X) button at top-left, "Hint" button at bottom

## Simulator Limitations
- **No real camera feed**: Camera view shows black screen on simulator (expected)
- **No audio output**: Cannot verify text-to-speech / auto-speak functionality
- **No microphone**: Cannot test voice input / speech recognition
- **No YOLO bounding boxes**: Without camera feed, object detection produces no results (expected)
- **Appetize interaction**: Taps on the simulator may need precise coordinates; the Appetize iframe captures events differently than native iOS

## Testing Tips
- When tapping buttons in the simulator, try clicking directly on the text/icon rather than the surrounding area
- The "Learn" tab in the bottom navigation bar is a reliable way to access dimension cards
- Tapping dimension cards from the Home tab's "My Development" grid may require very precise coordinates; the Learn tab's list layout is easier to tap
- Wait 3-5 seconds after guest login for DimensionHubView to load (API call to backend)
- Camera permission dialog appears once after first login
- Task counter ("Task 1", "Task 2", etc.) and accuracy indicator are at the top of learning session
- Option buttons may need scrolling to see all choices

## Backend
- Backend API: deployed on Fly.io at `https://risingstar-backend-zclkfobb.fly.dev/`
- API docs: `https://risingstar-backend-zclkfobb.fly.dev/docs`
- If tasks don't load, check if backend is running and accessible

## CI/CD
- iOS CI workflow: `.github/workflows/ios.yml` — builds on push to main, deploys to Appetize
- TestFlight workflow: `.github/workflows/testflight.yml` — builds and uploads to TestFlight
- Both workflows need `lfs: true` in checkout step for the YOLOv3 model (62MB via Git LFS)
- Backend CI: `.github/workflows/backend.yml` — runs pytest

## Known Issues
- Git LFS bandwidth: GitHub free tier allows 1GB/month (~16 CI runs with 62MB model). Monitor usage.
- The app name in Appetize header may still show "SpeakEasy v1.0" even though the app itself shows "Rising Star Kid" — this is the Appetize metadata, not the app.
