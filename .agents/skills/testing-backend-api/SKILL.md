---
name: testing-backend-api
description: Test the Rising Star Kid backend API endpoints. Use when verifying backend changes, task seeding, or adaptive session flow.
---

# Testing Rising Star Kid Backend API

## Backend URL
- Deployed: `https://risingstar-backend.fly.dev`
- Local: `http://localhost:8000`

## Starting Local Backend
```bash
cd backend
poetry run uvicorn app.main:app --reload --port 8000
```

For isolated testing with a fresh database:
```bash
cd backend
rm -f test.db && DATABASE_URL="sqlite:///./test.db" uvicorn app.main:app --host 0.0.0.0 --port 8200
```

## Re-seeding After Changes
After any changes to seed files (`seed_expanded.py`, `seed_tasks.py`, task JSON files), you must re-seed:
```bash
curl -X POST http://localhost:8000/tasks/seed?force=true
# or for deployed:
curl -X POST https://risingstar-backend.fly.dev/tasks/seed?force=true
```

## Key API Endpoints for Testing
- `POST /auth/guest` with body `{"device_id": "test-xxx"}` — Create guest player
- `POST /tasks/seed` — Seed all tasks into DB
- `GET /tasks/?dimension=object_cognition&limit=500` — List tasks with filters
- `POST /adaptive/sessions/start` with body `{"player_id": "...", "session_type": "practice", "dimension": "object_cognition"}` — Start adaptive session
- `GET /adaptive/sessions/{session_id}/next-task?player_id={pid}&dimension=object_cognition` — Get next task
- `POST /adaptive/attempts` with body `{"session_id": "...", "task_id": "...", "player_id": "...", "is_correct": true, "score": 1, "response_time_ms": 2000}` — Submit attempt
- `POST /adaptive/sessions/{session_id}/end` — End session

## Testing Repeat-Prevention Logic
The adaptive engine has smart repeat-prevention:
- **Correctly answered today**: excluded from selection for rest of day (UTC midnight boundary, cross-session)
- **Incorrectly answered**: excluded for 3-question cooldown (session-scoped), then eligible again

Test flow:
1. Create guest player → seed tasks → start session
2. Get task, submit correct → verify task never reappears in subsequent draws
3. Get task, submit incorrect → verify task doesn't appear in next 3 draws
4. Submit 3 filler correct answers → verify incorrect task can reappear (probabilistic)
5. End session, start new → verify correct exclusion persists, incorrect cooldown resets

Note: Tests 3-5 involve random selection, so the "can reappear" check is probabilistic. With ~30 eligible tasks, a task may not appear in 30 random draws ~34% of the time. The deterministic checks (task excluded during cooldown, correct exclusion persists cross-session) are the reliable assertions.

## Testing Cognitive Task Transformations
For backend-only changes to task transformation logic (`seed_expanded.py`), API-level testing is sufficient because:
- iOS `displayOptions` returns `options ?? []` — if options is non-empty, option buttons render
- No iOS code changes needed for backend task format changes
- Verify: each task has `content.options` (non-empty array) and `content.correct_answer` (string present in options)

## Task Types and Expected Formats
| Type | Level | Expected Fields |
|------|-------|------------------|
| pair | 0 | options (3 items), correct_answer, image_hint, instruction_text "Which goes with X?" |
| sort | 1 | options (shuffled items), correct_answer (first in order), items |
| cause_effect | 2 | options (3 items, shuffled), correct_answer (from correct_effect) |
| sequence_order | 3 | options (shuffled steps), correct_answer (first step), instruction "What comes first?" |
| reason | 4 | options + correct_answer (passthrough from JSON) |

## Bilingual Verification
For tasks with `options_zh`, verify positional correspondence:
- `options[i]` should be the English translation of `options_zh[i]`
- This is achieved via `zip` + `shuffle` pattern in seed code

## Expanded vs Base Tasks
- Expanded tasks: from `*_expanded.json` files
- Base tasks: from `seed_tasks.py` (older, may have different data patterns)
- When testing PR changes to expanded task logic, filter by task names or check task counts to distinguish

## Testing Sort Task Categories
Sort tasks use `interaction_mode: "drag_sort"` in the JSON files. To verify category distribution:
```python
# Parse from JSON file directly (not via API — API stores categories in content blob)
import json
data = json.load(open("backend/app/resources/tasks/object_cognition_expanded.json"))
levels = data["levels"]  # dict with string keys "0", "1", etc.
for lvl_key in sorted(levels.keys(), key=lambda x: int(x)):
    tasks = levels[lvl_key]
    task_list = tasks if isinstance(tasks, list) else tasks.get("tasks", [])
    sort_tasks = [t for t in task_list if t.get("interaction_mode") == "drag_sort"]
    cats = set()
    for t in sort_tasks:
        cats.update(t.get("sort_categories", []))
    if cats:
        print(f"Level {lvl_key}: {sorted(cats)}")
```

Via API, sort tasks are identified by searching for "sort" in the stringified task content:
```bash
curl -s "https://risingstar-backend.fly.dev/tasks/?dimension=object_cognition&level=0&limit=500" | \
  python3 -c "import json,sys; tasks=json.load(sys.stdin); print(len([t for t in tasks if 'sort' in str(t)]))"
```

## Testing Image Replacements
Verify Cloudinary URLs are accessible and serve valid images:
```bash
# Check all URLs in photo_urls.json return HTTP 200 with image content
python3 -c "
import json, urllib.request
data = json.load(open('backend/app/resources/images/photo_urls.json'))
for name, url in data['photos'].items():
    req = urllib.request.Request(url, method='HEAD')
    resp = urllib.request.urlopen(req, timeout=10)
    ok = resp.status == 200 and 'image/' in resp.headers.get('Content-Type','')
    if not ok: print(f'FAIL {name}: {resp.status}')
print('All URLs OK')
"
```

Images are uploaded to Cloudinary at TWO paths:
- `risingstar/photos/{name}` — primary path used by photo_urls.json
- `risingstar/task_images/{name}` — secondary path used by some task references

Always upload to both paths with `invalidate=True` for CDN cache clearing.

## Re-seeding After Task JSON Changes
After modifying task JSON files, you MUST re-seed the deployed backend:
```bash
curl -s -X POST "https://risingstar-backend.fly.dev/tasks/seed?force=true"
```
Without `?force=true`, existing tasks are not updated.

## Testing Sort Category Representative Image Overlap
The iOS app uses `representativeImage(for:excludeItems:)` to pick a category icon that doesn't match any item being sorted. To verify this works correctly, simulate the Swift logic in Python:

```python
# Fetch all sort tasks from API and check no item matches the chosen rep image
import json, urllib.request
url = "https://risingstar-backend.fly.dev/tasks/?dimension=object_cognition&limit=2000"
tasks = json.loads(urllib.request.urlopen(url).read())
sort_tasks = [t for t in tasks if t.get('content', {}).get('sort_categories')]
# For each task, check that the rep image for each category is NOT in the task's options
```

Key: the `excludeItems` parameter is populated from `task.content.displayOptions` (which maps to `options` in the API response).

## Testing iOS Layout Changes (Code Review Only)
Some changes are purely iOS SwiftUI and cannot be tested via API:
- **Flash timing**: Check `showNextFlash()` in `LearningSessionView.swift` for timing constants
- **ScrollView layout**: Verify `interactionArea` is NOT inside `ScrollView` in `taskContentView()`
- **Gesture recognition**: Check for `LongPressGesture.sequenced(before: DragGesture)` pattern

For these, verify code logic + CI (Xcode build) passes. Real-device testing requires TestFlight.

## Guest Auth Response Format
The `/auth/guest` endpoint returns the player ID in the `id` field (NOT `player_id`):
```json
{"id": "uuid-here", "name": "Guest_XXX", "device_id": "...", "is_guest": true}
```

## Backend Redeployment
After merging changes to task JSON files, the backend Docker image must be redeployed to Fly.io (not just re-seeded). Re-seeding only reloads from the JSON bundled in the running Docker image. Use:
```bash
cd backend && flyctl deploy --remote-only -a risingstar-backend
curl -s -X POST "https://risingstar-backend.fly.dev/tasks/seed?force=true"
```
Requires `FLY_API_TOKEN` environment variable.

## Backend URL
The current deployed backend URL is `https://risingstar-backend.fly.dev` (migrated from older URLs which no longer exist).

## Devin Secrets Needed
- No secrets needed for API testing (backend is publicly accessible)
- `Cloudinary_SpeakEasy_Dev` — API_KEY:API_SECRET format, for image upload/verification
- `CLOUDINARY_CLOUD_NAME` is `dgpir7tqk`
- `FLY_API_TOKEN` — for backend redeployment to Fly.io
