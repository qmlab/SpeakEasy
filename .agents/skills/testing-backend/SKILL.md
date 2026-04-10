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
# Start server (use a unique port if 8000 is busy)
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The server auto-creates tables on startup. No migrations needed (uses SQLAlchemy `create_all()`).

You can also use a custom DB path: `DATABASE_URL=sqlite:///./test.db poetry run uvicorn app.main:app --port 8099`

## Seeding Test Data
```bash
# Seeds all dimensions including expanded tasks
curl -s -X POST http://localhost:8000/tasks/seed
# Use ?force=true to re-seed even if tasks already exist
curl -s -X POST http://localhost:8000/tasks/seed?force=true
```
Expected counts (approximate): object_cognition=20, language_expression=15, language_comprehension=15, literacy=11, social_behavior=15, cognitive_logic=19, plus expanded tasks (50-85 per dimension).

## Per-Dimension MAX_LEVEL

Dimensions have different maximum levels:
- **language_comprehension**: levels 0-16 (levels 10-16 have reading comprehension tasks moved from literacy)
- **All other dimensions**: levels 0-9 (DEFAULT_MAX_LEVEL = 9)

The `max_level_for(dimension)` function in `adaptive_engine.py` handles this. When testing level capping:
```bash
# This should clamp to 9 (object_cognition max is 9)
curl -s -X PUT http://localhost:8000/adaptive/profiles/{player_id}/object_cognition \
  -H 'Content-Type: application/json' -d '{"level": 15}'

# This should stay at 15 (language_comprehension max is 16)
curl -s -X PUT http://localhost:8000/adaptive/profiles/{player_id}/language_comprehension \
  -H 'Content-Type: application/json' -d '{"level": 15}'
```

## Key API Endpoints

- `GET /health` — Health check
- `POST /players/` — Create player with `{"name": "...", "age": N}`
- `POST /tasks/seed` — Seed all tasks (idempotent)
- `GET /tasks/?dimension=literacy&level=3&limit=10` — List tasks filtered by dimension/level
- `GET /adaptive/profiles/{player_id}` — Get all dimension profiles
- `PUT /adaptive/profiles/{player_id}/{dimension}` — Update profile level
- `POST /adaptive/sessions/start` — Start session with `{"player_id": ..., "dimension": ..., "session_type": "practice"}`
- `GET /adaptive/sessions/{session_id}/next-task?player_id=...&dimension=...` — Get next task
- `POST /adaptive/attempts` — Submit attempt
- `POST /adaptive/sessions/{session_id}/end` — End session
- `GET /task-images/{name}.svg` — Serve SVG images

## Literacy Curriculum (Levels 0-9)

| Level | Skill | Example |
|-------|-------|---------|
| 0 | Letter recognition | "Touch the letter A" |
| 1 | Letter-sound matching | "Which letter makes the 'mmm' sound?" |
| 2 | Rhyming | "Which word rhymes with Cat?" |
| 3 | CVC word building | "What word do these letters make? C-A-T" |
| 4 | Sight words | "Touch the word 'the'" |
| 5 | Spelling | "How do you spell the word Dog?" |
| 6 | Word families | "Which word belongs to the -at family?" |
| 7 | Beginning/ending sounds | "Which word starts with the same sound as Ball?" |
| 8 | Advanced spelling | "Which is the correct spelling?" |
| 9 | Word reading | "Read this word: elephant" |

**Important**: Literacy tasks should test letter/word/phonics skills, NOT reading comprehension. Reading comprehension tasks belong in language_comprehension (levels 10-16).

## Language Comprehension Extended Levels (10-16)

| Level | Skill | Example |
|-------|-------|---------|
| 10 | Basic comprehension | Story questions ("How many does Ben have now?") |
| 11 | Inference | Drawing conclusions from passages |
| 12 | Main idea | Identifying central themes |
| 13 | Vocabulary in context | Word meaning from context clues |
| 14 | Character analysis | Understanding character traits |
| 15 | Argument analysis | Evaluating claims and evidence |
| 16 | Literary analysis | Analyzing literary techniques |

## Adaptive Engine Rules

- ACCURACY_WINDOW = 10 (last N attempts considered)
- LEVEL_UP_THRESHOLD = 0.80 (>=80% accuracy triggers level up)
- LEVEL_DOWN_THRESHOLD = 0.50 (<50% triggers level down)
- CONSECUTIVE_FAIL_LIMIT = 3 (3 consecutive failures → confidence_rebuild: true)
- Level range: 0 to max_level_for(dimension)

## Common Gotchas
- Player IDs are UUIDs, not integers
- Session response uses `id` field, not `session_id`
- The `next-task` endpoint requires query params: `player_id` and `dimension`
- Port may already be in use — use `fuser -k 8000/tcp` or `kill $(fuser 8000/tcp 2>/dev/null)` to clear
- `lsof` may not be available — use `ss -tlnp | grep PORT` or `fuser PORT/tcp` instead
- Seeding is idempotent unless `?force=true` is passed
- SVGs are served from `/task-images/` static mount, not from a dynamic endpoint
