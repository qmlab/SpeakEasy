# Testing Rising Star Kid Backend API

## Backend URL
- Deployed: `https://risingstar-backend-yojhdcez.fly.dev`
- Alternative: `https://risingstar-backend-zclkfobb.fly.dev`
- Local: `http://localhost:8000`

## Starting Local Backend
```bash
cd backend
poetry install --no-root
poetry run uvicorn app.main:app --reload --port 8000
```

For isolated testing with a fresh database:
```bash
cd backend
rm -f test.db && DATABASE_URL="sqlite:///./test.db" poetry run uvicorn app.main:app --host 0.0.0.0 --port 8200
```

## Re-seeding After Changes
After any changes to seed files (`seed_expanded.py`, `seed_tasks.py`, task JSON files), you must re-seed:
```bash
curl -X POST http://localhost:8000/tasks/seed?force=true
# or for deployed:
curl -X POST https://risingstar-backend-yojhdcez.fly.dev/tasks/seed?force=true
```

**Important**: Re-seeding on the deployed backend only reloads data from the JSON files already deployed on that server. If you changed JSON files in a PR, you must **redeploy** the backend (via Fly.io) to get the new files onto the server, then reseed. Testing against a local backend with the updated code is always reliable.

## Key API Endpoints for Testing
- `POST /auth/guest` with body `{"device_id": "test-xxx"}` — Create guest player
- `POST /tasks/seed` — Seed all tasks into DB
- `GET /tasks/?dimension=object_cognition&limit=500` — List tasks with filters
- `GET /adaptive/photo-urls` — Get all photo URLs (returns `{"photos": {...}}` dict)
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

### Translation Coverage Testing
When verifying translation completeness:
1. **instruction_zh**: Check for English words (3+ letters) using regex `[a-zA-Z]{3,}`. Zero matches = fully translated.
2. **options_zh**: Verify `len(options) == len(options_zh)` for all tasks that have both.
3. **Intentional English exceptions**:
   - Literacy/phonics tasks: options_zh may contain English words (e.g., "Log", "Sit", "The") because these are English reading exercises
   - Literacy tasks may have empty instruction_zh because the instructions are for English-language lessons
   - Numeric options (counting/math tasks): options_zh like `['3', '5', '7', '1']` are correct — numbers are language-neutral
4. **Test across all 6 dimensions**: object_cognition, language_expression, language_comprehension, literacy, social_behavior, cognitive_logic

Example translation verification script:
```python
import json, re, urllib.request
dimensions = ['object_cognition', 'language_expression', 'language_comprehension', 'literacy', 'social_behavior', 'cognitive_logic']
for dim in dimensions:
    url = f'http://localhost:8200/tasks/?dimension={dim}&limit=1500'
    with urllib.request.urlopen(url) as resp:
        tasks = json.loads(resp.read())
    partial = sum(1 for t in tasks if re.search(r'[a-zA-Z]{3,}', t.get('content',{}).get('instruction_zh','') or ''))
    print(f"{dim}: {len(tasks)} tasks, {partial} with English in instruction_zh")
```

## Expanded vs Base Tasks
- **Expanded tasks**: from `*_expanded.json` files, identified by Q-prefixed question_id (e.g., "Q351")
- **Base tasks**: from `seed_tasks.py` (older, UUID-style IDs), may lack instruction_zh and options_zh
- When testing PR changes to expanded task files, filter by Q-prefixed question_id to distinguish
- Base tasks (currently ~36 in object_cognition) may not have translations — this is a known gap, not a regression

## Photo URL Verification
The `/adaptive/photo-urls` endpoint returns `{"photos": {"item_name": "cloudinary_url", ...}}`.
- Verify count matches expected total (currently 206)
- Verify replaced photos have updated version numbers (e.g., `v1778810674` in URL)
- Verify HTTP 200 and file size >20KB (real photos, not SVG remnants)
- Check both `photos/` and `task_images/` Cloudinary paths for dual-path uploads

## Deployment
- Backend is deployed on Fly.io. Deployment requires `FLY_API_TOKEN`.
- If `FLY_API_TOKEN` is not available, test locally and note that deployed backend needs redeployment.
- After deployment, always reseed: `POST /tasks/seed?force=true`

## Devin Secrets Needed
- No secrets needed for local API testing
- `FLY_API_TOKEN` for deploying to Fly.io (not always available)
- `Cloudinary_SpeakEasy_Dev` for uploading photos to Cloudinary
