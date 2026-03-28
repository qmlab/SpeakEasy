# CI/CD and Deployment

## iOS CI (GitHub Actions)
- Workflow file: `.github/workflows/ios.yml`
- Runs on `macos-latest` with Xcode
- Scheme: `SpeakEasy`, destination: `platform=iOS Simulator,name=iPhone 16,OS=latest`
- Builds with `-sdk iphonesimulator` to produce `.app` bundle
- Uses `-derivedDataPath build` to reuse build artifacts between build and test steps
- Artifact: `RisingStarKid.zip` (zipped `.app` from `build/Build/Products/Debug-iphonesimulator/SpeakEasy.app`)
- GitHub Artifact name: `RisingStarKid-Simulator`

## Appetize Deployment
- Appetize API: `https://api.appetize.io/v1/apps`
- Auth: `X-API-KEY` header with `APPETIZE_API_TOKEN` secret
- To update existing app: `PUT /v1/apps/{publicKey}` with `file=@RisingStarKid.zip`
- To create new app: `POST /v1/apps` with `file=@RisingStarKid.zip`
- GitHub repo variable `APPETIZE_PUBLIC_KEY` stores the current app public key
- Preview URL format: `https://appetize.io/app/{publicKey}`
- Current public key: `3kzgcggsjfoorh65l6koubytti`
- **Important**: `secrets` context cannot be used directly in GitHub Actions step-level `if` conditions. Use shell-level `if [ -z "$VAR" ]` checks instead.

## Backend CI (GitHub Actions)
- Workflow file: `.github/workflows/backend.yml`
- Runs `ruff` lint and format checks
- Tests app import

## Backend Deployment (Fly.io)
- Deploy command: use the `deploy` tool with `command: backend` and `volume: true`
- Backend URL: `https://risingstar-backend-zclkfobb.fly.dev`
- Persistent volume mounted at `/data` for SQLite database
- After deployment, seed tasks via `POST /tasks/seed`
- API docs: `https://risingstar-backend-zclkfobb.fly.dev/docs`

## Backend URL Configuration
- iOS app hardcodes backend URL in two files:
  - `SpeakEasy/Services/APIService.swift` (line 12, `baseURL` property)
  - `SpeakEasy/Services/AdaptiveAPIService.swift` (line 13, `init` default parameter)
- When changing backend URL, update BOTH files

## Testing on Appetize
- Use device `iphone14pro` with `osVersion=16.2`
- Camera and microphone are NOT available in cloud simulator
- Test touch-based interactions only (Got It!/Help buttons, option buttons)
- Speech recognition permission dialog appears on first launch - tap OK
- Camera permission dialog may also appear - tap Don't Allow
