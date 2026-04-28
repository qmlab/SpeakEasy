# CI/CD and Deployment

## iOS CI (GitHub Actions)
- Workflow file: `.github/workflows/ios.yml`
- Runs on `macos-26` with Xcode
- Scheme: `SpeakEasy`, destination: `platform=iOS Simulator,name=iPhone 17,OS=latest`
- Builds with `-sdk iphonesimulator` to produce `.app` bundle
- Uses `-derivedDataPath build` to reuse build artifacts between build and test steps
- Artifact: `RisingStarKid.zip` (zipped `.app` from `build/Build/Products/Debug-iphonesimulator/SpeakEasy.app`)
- GitHub Artifact name: `RisingStarKid-Simulator`
- Triggers on push to `main` and PRs targeting `main` when `SpeakEasy/**`, `SpeakEasyTests/**`, `SpeakEasy.xcodeproj/**`, or `.github/workflows/ios.yml` change

## Appetize Deployment
- Appetize API: `https://api.appetize.io/v1/apps`
- Auth: `X-API-KEY` header with `APPETIZE_API_TOKEN` secret
- To update existing app: `PUT /v1/apps/{publicKey}` with `file=@RisingStarKid.zip`
- To create new app: `POST /v1/apps` with `file=@RisingStarKid.zip`
- GitHub repo variable `APPETIZE_PUBLIC_KEY` stores the current app public key
- Preview URL format: `https://appetize.io/app/{publicKey}`
- Current public key: `xtydm5atxiqv3iff2kkbc43x74`
- **Important**: `secrets` context cannot be used directly in GitHub Actions step-level `if` conditions. Use shell-level `if [ -z "$VAR" ]` checks instead.
- **Important**: Appetize deploy step uses `continue-on-error: true` — if `APPETIZE_API_TOKEN` is not configured as a GitHub repo secret, the deploy is silently skipped. Verify this secret exists when Appetize builds appear stale.

## Backend CI (GitHub Actions)
- Workflow file: `.github/workflows/backend.yml`
- Runs `ruff` lint and format checks
- Tests app import

## Backend Deployment (Fly.io)
- Deploy command: use the `deploy` tool with `command: backend` and `volume: true`
- Backend URL: `https://risingstar-backend-yojhdcez.fly.dev`
- Persistent volume mounted at `/data` for SQLite database
- After deployment, seed tasks via `POST /tasks/seed?force=true`
- API docs: `https://risingstar-backend-yojhdcez.fly.dev/docs`
- **Important**: The `deploy` tool may create a new Fly.io app with a different URL each time. When this happens, you MUST update the iOS hardcoded backend URLs in both files listed below.
- Old deployments may still be running — consider shutting them down to save costs.

## Backend URL Configuration
- iOS app hardcodes backend URL in two files:
  - `SpeakEasy/Services/APIService.swift` (line 12, `baseURL` property)
  - `SpeakEasy/Services/AdaptiveAPIService.swift` (line 13, `init` default parameter)
- When changing backend URL, update BOTH files
- After updating URLs, a fresh iOS CI build + Appetize deploy is needed for the Appetize preview to use the new backend

## Testing on Appetize
- Use device `iphone14pro` with `osVersion=16.2`
- Camera and microphone are NOT available in cloud simulator
- Test touch-based interactions only (Got It!/Help buttons, option buttons)
- Speech recognition permission dialog appears on first launch - tap OK
- Camera permission dialog may also appear - tap OK
- Home tab dimension icons may not respond to taps — use the Learn tab instead to access dimensions

## Devin Secrets Needed
- `APPETIZE_API_TOKEN`: Required for uploading new builds to Appetize (stored as GitHub repo secret)
- `Cloudinary_SpeakEasy_Dev`: Cloudinary API credentials for image uploads
