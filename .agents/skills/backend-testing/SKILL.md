# Backend Testing

## Local Backend Setup

```bash
cd backend
poetry install --no-root
DATABASE_URL=sqlite:///./test_story.db poetry run uvicorn app.main:app --host 0.0.0.0 --port 8001
```

- Use a separate test database (e.g. `test_story.db`) to avoid corrupting production data
- Port 8000 may be in use; use 8001 as fallback
- Health check: `GET /health` → `{"status": "healthy"}`

## Story Assessment API Endpoints

- `GET /story/list` — List available stories
- `POST /story/start/{player_id}` with `{"story_id": "bunny_birthday"}` — Start assessment
- `GET /story/{assessment_id}/next-scene` — Get next scene (includes adaptive branching)
- `POST /story/{assessment_id}/respond` with `{"scene_index": N, "selected_option": "..."}` — Submit response
- `POST /story/{assessment_id}/complete` — Complete and update profiles

## Key Testing Patterns

- **Adaptive branching**: Answer S1 wrong → S3 should serve fallback question (`is_fallback: true`)
- **Path traversal**: `story_id: "../../etc/passwd"` must return 404
- **Negative index**: `scene_index: -1` must return 400
- **Profile downgrade prevention**: Re-running with all wrong answers must NOT decrease profile levels
- **Image hints padding**: `image_hints` array must match `options` length after padding

## Deployed Backend

- URL: `https://risingstar-backend-zclkfobb.fly.dev/`
- Uses persistent volume at `/data` for SQLite storage
- Deploy command: use Devin's deploy tool with `backend` command, `volume: true`

## Player Creation for Tests

```bash
curl -X POST http://localhost:8001/players/ -H 'Content-Type: application/json' -d '{"name": "TestKid", "age": 4}'
```
