---
name: backend-deployment
description: Deploy and manage the Rising Star Kid FastAPI backend on Fly.io. Use when deploying, restarting, or troubleshooting the backend.
---

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
- App name: `risingstar-backend`
- Deployed URL: `https://risingstar-backend.fly.dev`
- Uses `backend/Dockerfile` and `backend/fly.toml` for deployment config
- Requires `FLY_API_TOKEN` secret (org-level) for `flyctl` authentication
- Deploy command: `cd backend && flyctl deploy --ha=false`
- The app uses a persistent volume mounted at `/data` for SQLite storage
- After deploying, seed the database: `curl -X POST https://risingstar-backend.fly.dev/tasks/seed?force=true`
- The `force=true` flag deletes and re-seeds expanded tasks with latest JSON data
- Auto-stop is enabled — machine stops when idle, auto-starts on incoming requests

## Fly.io Management
```bash
# Check app status
flyctl status -a risingstar-backend

# View logs
flyctl logs -a risingstar-backend

# Restart the app
flyctl apps restart risingstar-backend

# SSH into the machine
flyctl ssh console -a risingstar-backend
```

## Seeding Tasks
- Seed endpoint: `POST /tasks/seed?force=true`
- Loads base tasks + expanded tasks from JSON files in `backend/app/resources/tasks/`
- Also runs backfill operations for target_words, image_hints, and options
- Expected ~1,600+ tasks total across 6 dimensions
- Tasks auto-seed on app startup (idempotent)

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

## iOS URL Configuration
- Backend URL is hardcoded in two Swift files:
  - `SpeakEasy/Services/APIService.swift` (`baseURL`)
  - `SpeakEasy/Services/AdaptiveAPIService.swift` (`baseURL` in init)
- If the Fly.io app name changes, both files must be updated

## Devin Secrets Needed
- `FLY_API_TOKEN`: Fly.io API token for deployment and management (org-level)
