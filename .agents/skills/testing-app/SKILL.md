# Testing Rising Star Kid App

## Appetize (iOS Simulator)
- Public key: stored as `APPETIZE_PUBLIC_KEY` in GitHub repo secrets
- URL format: `https://appetize.io/app/{public_key}`
- API token: stored as `APPETIZE_API_TOKEN` in GitHub repo secrets
- iOS CI automatically deploys to Appetize on push to main
- Images load slowly on Appetize (~5-10s) — wait before concluding they failed
- Speech recognition does not work on Appetize simulator
- Camera does not work on Appetize simulator
- Dismiss permission dialogs (speech, camera) by tapping "Don't Allow"

## Backend
- Deployed on Fly.io: `https://risingstar-backend-zclkfobb.fly.dev/`
- API docs: `https://risingstar-backend-zclkfobb.fly.dev/docs`
- Deploy command: `deploy command=backend dir=backend volume=true`
- After deploying, run `POST /tasks/seed` to seed/backfill tasks
- Use `?force=true` to force-reseed expanded tasks
- SQLite DB persisted at `/data/app.db` via Fly.io volume

## Image System
- Images stored on Cloudinary (cloud name: `dgpir7tqk`)
- URL format: `https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/task_images/{name}`
- 94 SVGs uploaded, served as PNG via `f_png` transform
- iOS `RemoteImageView` fallback chain: bundled xcassets → Cloudinary PNG → SF Symbol
- Backend tasks must have `image_hint` field in content for images to display
- `backfill_image_hints()` auto-derives hints from task content fields
- Some task types (classify, function, abstract) have no single target object → no image_hint → expected fallback

## Testing Flow
1. Navigate to Appetize URL
2. Tap to start simulator
3. Dismiss permission dialogs
4. Tap "Continue as Guest"
5. Wait for dimension hub to load
6. Tap "Learn" tab at bottom
7. Tap a dimension card (e.g. Object Cognition)
8. Verify task images load (wait ~10s for Cloudinary)
9. Tap "Got It!" or interact to advance tasks

## CI Workflows
- `ios.yml`: Builds iOS app, runs tests, deploys to Appetize (on main)
- `testflight.yml`: Archives and uploads to TestFlight (on main)
- `backend.yml`: Runs backend lint + 125 unit tests
- iOS CI uses `macos-26` runner for iOS 26 SDK compliance

## Lint & Test Commands
- Backend: `ruff check app/ && ruff format --check app/ && python -m pytest tests/ -x -q`
- iOS: Built and tested via Xcode in CI (`xcodebuild test`)
