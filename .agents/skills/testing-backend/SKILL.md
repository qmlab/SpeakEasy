# Testing SpeakEasy Backend

## Prerequisites
- Python 3.11+
- Dependencies: `pip install fastapi sqlalchemy pydantic python-multipart aiofiles levenshtein requests cloudinary httpx uvicorn pytest`

## Running the Backend Locally

```bash
cd backend
# For a fresh DB (useful for testing auto-seeding):
rm -f risingstar.db
# Start server:
PYTHONPATH=. uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The server auto-seeds all tasks (base + expanded) on startup. This is idempotent — existing tasks are skipped.

Database: SQLite at `backend/risingstar.db` (default, local dev).

## Running Unit Tests

```bash
cd backend
PYTHONPATH=. python -m pytest tests/ -x -q
```

Expected: 125+ tests passing.

## Linting

```bash
cd backend
ruff check app/
```

CI runs `poetry run ruff check app/` — watch for E402 (module-level imports not at top).

## API Testing Flow (Adaptive Learning)

The core adaptive learning flow:

1. **Create player**: `POST /players/ {"name": "test", "age": 5}`
2. **Start session**: `POST /adaptive/sessions/start {"player_id": "...", "session_type": "practice", "dimension": "object_cognition"}`
3. **Get next task**: `GET /adaptive/sessions/{session_id}/next-task?player_id=...&dimension=object_cognition`
4. **Submit attempt**: `POST /adaptive/attempts {"session_id": "...", "task_id": "...", "player_id": "...", "is_correct": true, "score": 100, "response_time_ms": 1000}`
5. **End session**: `POST /adaptive/sessions/{session_id}/end`

## Verifying Task Seeding

- **Expanded task stats**: `GET /tasks/stats/expanded` — should show counts per dimension
- **List tasks**: `GET /tasks/?dimension=object_cognition&level=0&limit=200` — verify task count
- **Manual seed** (if needed): `POST /tasks/seed?force=false`

## Key Dimensions

- `object_cognition` (1187 expanded tasks)
- `language_expression` (50)
- `language_comprehension` (85)
- `literacy` (41)
- `social_behavior` (81)
- `cognitive_logic` (49)

## Common Issues

- **Poetry build fails locally**: Install deps directly with pip instead of `pip install -e ".[dev]"`
- **E402 lint errors**: All imports must be at file top in `main.py`; don't add inline imports
- **Auto-seed not working**: Check that `main.py` calls `seed_all_tasks()` and `seed_expanded_tasks()` at module level
- **Options always in same order**: `_shuffle_options()` in `adaptive_engine.py` should shuffle at serve time

## Devin Secrets Needed

No secrets required for local backend testing. Cloudinary is optional (for image uploads only).
