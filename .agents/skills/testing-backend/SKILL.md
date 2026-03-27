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
