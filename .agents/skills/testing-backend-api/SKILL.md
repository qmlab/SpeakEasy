# Testing Rising Star Kid Backend API

## Backend URL
- Deployed: `https://risingstar-backend-zclkfobb.fly.dev`
- Local: `http://localhost:8000`

## Starting Local Backend
```bash
cd backend
poetry run uvicorn app.main:app --reload --port 8000
```

## Re-seeding After Changes
After any changes to seed files (`seed_expanded.py`, `seed_tasks.py`, task JSON files), you must re-seed:
```bash
curl -X POST http://localhost:8000/tasks/seed?force=true
# or for deployed:
curl -X POST https://risingstar-backend-zclkfobb.fly.dev/tasks/seed?force=true
```

## Key API Endpoints for Testing
- `GET /cms/tasks?dimension=cognitive_logic&page_size=100` — List all cognitive logic tasks
- `POST /adaptive/sessions/start` with body `{"player_id": "...", "dimension": "cognitive_logic"}` — Start adaptive session
- `GET /adaptive/sessions/{session_id}/next-task?player_id={pid}&dimension=cognitive_logic` — Get next task
- `POST /adaptive/sessions/{session_id}/submit-answer` — Submit answer

## Testing Cognitive Task Transformations
For backend-only changes to task transformation logic (`seed_expanded.py`), API-level testing is sufficient because:
- iOS `displayOptions` returns `options ?? []` — if options is non-empty, option buttons render
- No iOS code changes needed for backend task format changes
- Verify: each task has `content.options` (non-empty array) and `content.correct_answer` (string present in options)

## Task Types and Expected Formats
| Type | Level | Expected Fields |
|------|-------|-----------------|
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
- Expanded tasks: from `cognitive_logic_expanded.json` (40 tasks, 8 per level)
- Base tasks: from `seed_tasks.py` (older, may have different data patterns)
- When testing PR changes to expanded task logic, filter by task names or check task counts to distinguish

## Devin Secrets Needed
- No secrets needed for API testing (backend is publicly accessible)
- `CLOUDINARY_CLOUD_NAME` (dgpir7tqk) for image URL verification
