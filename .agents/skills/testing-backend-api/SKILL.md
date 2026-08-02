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

If the venv is missing, recreate it:
```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate && pip install poetry && poetry install --no-root
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
- `POST /players/` with body `{"name": "TestChild", "birth_date": "2022-01-01"}` — Create player
- `POST /tasks/seed` — Seed all tasks into DB
- `GET /tasks/?dimension=object_cognition&limit=500` — List tasks with filters
- `POST /adaptive/sessions/start` with body `{"player_id": "...", "session_type": "practice", "dimension": "object_cognition"}` — Start adaptive session
- `GET /adaptive/sessions/{session_id}/next-task?player_id={pid}&dimension=object_cognition` — Get next task
- `POST /adaptive/attempts` with body `{"session_id": "...", "task_id": "...", "player_id": "...", "is_correct": true, "score": 1, "response_time_ms": 2000}` — Submit attempt
- `POST /adaptive/sessions/{session_id}/end` — End session

## Story Assessment API Endpoints
Story-based assessment embeds questions within a narrative (e.g., Bunny's Birthday Party).

- `GET /story/list` — List available stories
- `POST /story/start/{player_id}` with body `{"story_id": "bunny_birthday"}` — Start story, returns `assessment_id`
- `GET /story/{assessment_id}/next-scene` — Get next scene (includes test with options, tap_regions, etc.)
- `POST /story/{assessment_id}/respond` with body `{"scene_index": 0, "selected_option": "Apple"}` — Submit response
- `POST /story/{assessment_id}/complete` — Complete story and get results

### Testing tap_regions
Some scenes have `tap_regions` (normalised 0-1 coordinates) for tap-on-image interaction. Key things to verify:

1. **Presence**: Scenes s1, s2, s3, s7 in bunny_birthday have tap_regions; s4, s5, s6, s8 do not
2. **Alignment after shuffle**: `tap_regions[i].label` must equal `options[i]` for all i — the engine shuffles options and re-orders tap_regions to match
3. **Coordinate range**: All x, y, radius values must be in (0, 1)
4. **Fallback scenes**: When adaptive branching triggers a fallback (e.g., s1 wrong → s3 gets fallback), the fallback test has no tap_regions
5. **Label submission**: iOS sends `tap_regions[i].label` as `selected_option` — verify correct/incorrect evaluation works

To test shuffle alignment across multiple sessions:
```bash
for i in 1 2 3 4 5; do
  AID=$(curl -s -X POST "http://localhost:8000/story/start/${PLAYER_ID}" -H 'Content-Type: application/json' -d '{"story_id":"bunny_birthday"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['assessment_id'])")
  curl -s "http://localhost:8000/story/${AID}/next-scene" | python3 -c "
import sys,json; d=json.load(sys.stdin); t=d['test']
print([r['label'] for r in t['tap_regions']])
print(t['options'])
print('Aligned:', all(t['tap_regions'][j]['label']==t['options'][j] for j in range(len(t['options']))))"
done
```

### Testing Adaptive Branching
Some scenes have `requires_correct` pointing to a prerequisite scene. If the prerequisite was answered incorrectly, the engine serves a `fallback` test instead:
- s3_pick_balloon requires s1_find_apple correct
- s7_open_presents requires s2_find_spoon correct

To trigger fallback: answer the prerequisite scene wrong, then advance to the dependent scene. Check `is_fallback: true` in response.

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

## Important Notes
- The iOS app is native Swift — UI testing (tap overlays, animations) requires on-device testing or Appetize
- Story JSON changes require backend redeployment to Fly.io for production
- tap_region coordinates are normalized 0-1 and were estimated visually — may need on-device tuning
- The backend uses SQLite by default; deployed uses persistent volume at /data/app.db

## Devin Secrets Needed
- No secrets needed for API testing (backend is publicly accessible)
- `CLOUDINARY_CLOUD_NAME` (dgpir7tqk) for image URL verification
