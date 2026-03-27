# Testing Rising Star Kid Backend

## Prerequisites
- Python 3.11+
- Poetry installed
- No external services required (SQLite local DB, Cloudinary optional)

## Devin Secrets Needed
- None required for backend testing (Cloudinary credentials are optional)

## Server Setup
```bash
cd backend
# Remove old DB for fresh start
rm -f risingstar.db
# Start server
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The server auto-creates tables on startup. No migrations needed (uses SQLAlchemy `create_all()`).

## Seeding Test Data
```bash
# Seeds all dimensions (object_cognition=17, language_expression=15, language_comprehension=15)
curl -s -X POST http://localhost:8000/tasks/seed
```
Seeding is idempotent - re-seeding returns counts of 0 without duplicating.

## Key Testing Flows

### 1. Full Adaptive Session Flow
```bash
# Create player
curl -s -X POST http://localhost:8000/players/ -H 'Content-Type: application/json' -d '{"name":"TestChild","age":5}'
# Note: player ID is a UUID, not integer

# Get profiles (auto-creates 6 dimensions at level 0)
curl -s http://localhost:8000/adaptive/profiles/{player_id}

# Start session
curl -s -X POST http://localhost:8000/adaptive/sessions/start -H 'Content-Type: application/json' -d '{"player_id":"{id}","dimension":"language_expression","session_type":"learning"}'

# Get next task
curl -s 'http://localhost:8000/adaptive/sessions/{session_id}/next-task?player_id={id}&dimension=language_expression'

# Submit attempt
curl -s -X POST http://localhost:8000/adaptive/attempts -H 'Content-Type: application/json' -d '{"session_id":"{sid}","task_id":"{tid}","player_id":"{pid}","is_correct":true,"response_time_ms":1500}'

# End session
curl -s -X POST http://localhost:8000/adaptive/sessions/{session_id}/end
```

### 2. Level-Up Testing
- Level-up triggers when accuracy >= 80% over the accuracy window
- With 100% accuracy, level-up may trigger after ~5 attempts (not necessarily 10)
- After level-up, subsequent tasks come from the new level with different task types
- To test specific levels, use: `PUT /adaptive/profiles/{player_id}/{dimension}` with `{"level": N}`

### 3. Task Type Expectations by Dimension

**language_expression**: L0=imitate, L1=name_object, L2=describe, L3=build_sentence, L4=conversation

**language_comprehension**: L0=point_to, L1=follow_instruction, L2=follow_instruction(multi-step), L3=story_comprehension, L4=infer_meaning

**object_cognition**: L0=match/say_word/find_object, L1=identify, L2=classify, L3=function, L4=abstract

### 4. Speech Evaluation
```bash
curl -s -X POST http://localhost:8000/adaptive/evaluate-speech -H 'Content-Type: application/json' -d '{"target":"apple","spoken":"aple"}'
```
- Case insensitive comparison
- Empty spoken string returns similarity=0.0 with feedback="no_response"
- Feedback tiers: perfect (1.0), excellent (>=0.9), good_try (>=threshold), keep_trying, try_again

### 5. Modality Recommendation
```bash
curl -s http://localhost:8000/adaptive/modality/{player_id}
```
Priority: text (literacy>=2) > voice (OC>=2 & expr>=2) > image_exchange (expr>=1) > touch (default)

## Common Gotchas
- Player IDs are UUIDs, not integers
- Session endpoints use `/sessions/start`, `/sessions/{id}/end`, `/sessions/{id}/next-task` (not `/session/`)
- Attempt submission uses `/attempts` (not `/session/{id}/attempt`)
- The `next-task` endpoint requires query params: `player_id` and `dimension`
- Port 8000 may already be in use from previous runs - use `fuser -k 8000/tcp` to clear
- No CI is configured on this repo
# Testing Rising Star Kid Backend

## Setup & Server

- Backend lives in `backend/` directory
- Uses Poetry for dependency management
- Database: SQLite file `risingstar.db` in `backend/` directory
- Start server: `poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000` from `backend/`
- Fresh DB for testing: delete `risingstar.db` before starting server
- No CI configured — run lint/tests locally

## Key API Endpoints

- `GET /` — Root, returns app name "Rising Star Kid"
- `GET /health` — Health check, returns `{"status": "healthy"}`
- `POST /players/` — Create player with `{"name": "...", "age": N}`
- `POST /tasks/seed` — Seed all tasks (idempotent). Returns `{"counts": {dimension: count}}`. Expected: 92 total (17+15+15+15+15+15)
- `GET /tasks/?limit=200` — List tasks. **Default limit is 50**, pass `?limit=200` to get all
- `GET /adaptive/profiles/{player_id}` — Get player profiles. Response structure: `{"player_id": ..., "player_name": ..., "dimensions": [...], "overall_level": ...}`. Profiles are in `dimensions` array, each with `dimension` and `level` keys
- `POST /adaptive/sessions/start` — Start session with `{"player_id": ..., "dimension": ..., "session_type": "practice"}`
- `GET /adaptive/sessions/{session_id}/next-task?player_id=...&dimension=...` — Get next adaptive task
- `POST /adaptive/attempts` — Submit attempt with `{"session_id": ..., "task_id": ..., "player_id": ..., "is_correct": bool, "response_data": {...}, "response_time_ms": N}`
- `POST /adaptive/sessions/{session_id}/end` — End session
- `POST /adaptive/evaluate-speech` — Speech evaluation
- `GET /adaptive/modality/{player_id}` — Modality recommendation

## 6 Dimensions & Expected Task Types per Level

| Dimension | Level 0 | Level 1 | Level 2 | Level 3 | Level 4 |
|---|---|---|---|---|---|
| object_cognition | match | identify | classify | function | abstract |
| language_expression | imitate | name_object | describe | build_sentence | conversation |
| language_comprehension | point_to | follow_instruction | story_comprehension | infer_meaning | — |
| literacy | recognize_image | match_word_image | read_word | read_sentence | read_passage |
| social_behavior | attend | imitate_action | turn_take | joint_attention | initiate |
| cognitive_logic | pair | sort | cause_effect | sequence_order | reason |

## Adaptive Engine Rules

- ACCURACY_WINDOW = 10 (last N attempts considered)
- LEVEL_UP_THRESHOLD = 0.80 (>=80% accuracy triggers level up)
- LEVEL_DOWN_THRESHOLD = 0.50 (<50% triggers level down)
- CONSECUTIVE_FAIL_LIMIT = 3 (3 consecutive failures → `confidence_rebuild: true`)
- Level range: 0–4
- In practice, 5 consecutive correct answers at a fresh level triggers level-up

## Testing Workflow

1. Kill any existing server: `fuser -k 8000/tcp`
2. Delete old DB: `rm -f backend/risingstar.db`
3. Start server from `backend/` dir
4. Seed tasks: `curl -s -X POST http://localhost:8000/tasks/seed`
5. Create player: `curl -s -X POST http://localhost:8000/players/ -H 'Content-Type: application/json' -d '{"name":"TestKid","age":5}'`
6. Test each dimension: start session → get task → submit attempts → verify level-up
7. Verify cross-dimension independence via profiles endpoint
8. Test confidence rebuild: 3 consecutive `is_correct: false` → check for `confidence_rebuild: true`
