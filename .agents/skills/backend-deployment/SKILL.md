# Backend Deployment & Testing

## Stack
- FastAPI backend at `backend/app/main.py`
- SQLite database with persistent volume at `/data/app.db` on Fly.io
- Poetry for dependency management
- Ruff for linting/formatting

## Running Locally
```bash
cd backend
poetry install
uvicorn app.main:app --reload --port 8000
```

## Linting
```bash
cd backend
python -m ruff check app/
python -m ruff format app/
```

## Database Migrations
- SQLite's `create_all()` only creates new tables, does NOT add columns to existing tables
- All schema migrations go in `run_migrations()` in `backend/app/main.py`
- Pattern: check table exists → check column exists via `inspect()` → `ALTER TABLE ADD COLUMN`
- Migrations run unconditionally at app startup (not gated behind flags)
- Use SQLAlchemy `inspect()` for database-agnostic column detection (not SQLite PRAGMA)

## Deploying to Fly.io
- Deploy with persistent volume enabled for SQLite storage
- After deploying, seed the database: `POST /tasks/seed?force=true`
- Deployed URL: configured per environment
- The `force=true` flag deletes and re-seeds expanded tasks with latest JSON data

## Seeding Tasks
- Seed endpoint: `POST /tasks/seed?force=true`
- Loads base tasks + expanded tasks from JSON files in `backend/app/resources/tasks/`
- Also runs backfill operations for target_words, image_hints, and options
- Expected ~360 tasks total (300 practice + 60 assessment) across 6 dimensions and levels 0-9

## API Testing
- Health check: `GET /health`
- Session start: `POST /adaptive/sessions/start` with `{"player_id": "...", "session_type": "practice", "dimension": "object_cognition"}`
- Next task: `GET /adaptive/sessions/{session_id}/next-task?player_id=...&dimension=...`
- API docs: `GET /docs` (Swagger UI)

## 6 Developmental Dimensions
- object_cognition
- language_expression
- language_comprehension
- literacy
- social_behavior
- cognitive_logic
