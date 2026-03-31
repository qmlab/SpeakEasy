# Testing SpeakEasy (Rising Star Kid)

## Backend Testing

### Deployed Backend
- URL: `https://risingstar-backend-zclkfobb.fly.dev`
- API docs: `https://risingstar-backend-zclkfobb.fly.dev/docs`
- Re-seed endpoint: `POST /tasks/seed`
- Task query: `GET /tasks/?dimension=<dimension>&limit=100`

### After Backend Changes
1. Deploy: use the `deploy` tool with `backend` command, `volume=true`, dir=`/home/ubuntu/repos/SpeakEasy/backend`
2. Re-seed: `curl -s -X POST https://risingstar-backend-zclkfobb.fly.dev/tasks/seed`
3. Verify via API: query tasks and check field presence/values with python one-liners

### Key Data Patterns
- **build_sentence tasks**: Must have `options` key (NOT `display_options`). iOS `TaskContent` CodingKeys only decodes `options`. Using `display_options` will silently result in empty arrays on iOS.
- **Shuffle validation**: Options should differ from items (correct order). Use `hashlib.md5` for deterministic seeding, not `hash()` which is non-deterministic across Python process restarts.
- **Infinite loop guard**: When shuffling, add `len(set(words)) > 1` check to prevent infinite loops with all-identical word lists.
- **conversation tasks**: `instruction_text` should be the actual question, not generic text like "Answer the question".

## iOS / Appetize Testing

### Appetize Access
- The Appetize public key is stored as a GitHub repo variable `APPETIZE_PUBLIC_KEY`
- Appetize URL format: `https://appetize.io/app/<PUBLIC_KEY>`
- The iOS CI workflow (`.github/workflows/ios.yml`) automatically deploys to Appetize on push to main when `APPETIZE_API_TOKEN` secret is configured

### Build Timing
- After merging a PR that changes iOS files (`SpeakEasy/**`), the iOS CI takes ~10-15 minutes to build and deploy to Appetize
- The Appetize header shows the app name and version — check this to confirm which build is running
- If the Appetize build is old, iOS-specific UI changes cannot be visually verified

### Testing Language Expression Tasks on Appetize
1. Launch app → dismiss speech recognition permission dialog (tap "OK")
2. Dismiss camera permission dialog (tap "OK" or "Don't Allow")
3. Tap "Continue as Guest"
4. Navigate to "Learn" tab (bottom nav)
5. Tap "Language Expression" dimension card
6. Tasks start at level 1 (imitate/name_object). build_sentence tasks are level 3.
7. To reach build_sentence tasks, either:
   - Use skip button to advance through earlier tasks
   - Or verify via API that the backend returns correct data

### Key iOS Behaviors to Verify
- **Skip button**: Should appear on every task below the interaction area. Label says "Skip" with forward.fill icon.
- **build_sentence ordering UI**: `isSortingTask()` must return true for task_type="build_sentence". Shows tappable word cards, not just an image.
- **Auto-listen**: Should NOT activate after TTS for sorting tasks (sort, sequence_order, build_sentence). Check `isSorting` variable in onChange handler.

## Devin Secrets Needed
- `Cloudinary_SpeakEasy_Dev` — for image upload/management
- `APPETIZE_API_TOKEN` — stored as GitHub repo secret, not needed locally

## Lint & Format
- Backend: `ruff check` and `ruff format --check` from `/home/ubuntu/repos/SpeakEasy/backend`
- iOS: Xcode build via CI (no local Xcode available)
