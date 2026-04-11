# Testing SpeakEasy Backend Tasks & SVG Assets

## Environment Setup

1. Start the backend:
   ```bash
   cd backend && poetry run python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```
2. Reseed the database after any task data changes:
   ```bash
   curl -X POST "http://localhost:8000/tasks/seed?force=true"
   ```

## SVG Assets

- SVG files are stored at `backend/app/resources/images/*.svg`
- They are served via the backend at `/task-images/{name}.svg`
- To verify an SVG renders, open `http://localhost:8000/task-images/{name}.svg` in a browser
- Option names containing `/` (e.g. `shy/anxious`) are saved with `_` substitution (`shy_anxious.svg`)
- The iOS app must apply the same `/ -> _` sanitization when constructing image URLs

## Task Data Verification

### Checking image_hints via API
```bash
curl -s "http://localhost:8000/tasks/?dimension=social_behavior&limit=200" | python3 -c "
import json, sys
tasks = json.load(sys.stdin)
for t in tasks:
    hint = t['content'].get('image_hint', 'NONE')
    instr = t['content'].get('instruction_text', '')[:60]
    print(f'hint={hint:30s} instr={instr}')
"
```

### Cross-checking option SVGs exist
```bash
curl -s "http://localhost:8000/tasks/?limit=1000" | python3 -c "
import json, sys, os
tasks = json.load(sys.stdin)
img_dir = 'backend/app/resources/images'
all_svgs = set(f[:-4] for f in os.listdir(img_dir) if f.endswith('.svg'))
missing = set()
for t in tasks:
    for opt in t['content'].get('options', []):
        if isinstance(opt, str) and len(opt.split()) <= 2:
            key = opt.lower().replace(' ', '_').replace('/', '_')
            if key not in all_svgs:
                missing.add(opt)
print(f'Missing: {len(missing)}')
for m in sorted(missing): print(f'  - {m}')
"
```

## Key Rules

1. **All task option SVGs must exist** — no "?" placeholders allowed. Single-word and two-word options trigger image grid display on iOS.
2. **Social behavior images must match question context** — show the actual scenario (e.g. friend crying, gift exchange), not generic objects (hat, star, clock).
3. **Language comprehension tasks should NOT have image_hint** for expanded tasks where the image would give away the listening comprehension answer. Exception: "Touch the X" tasks that need the image to show what to touch.
4. **`instructionReferencesPicture()` in LearningSessionView.swift** determines when to show the image_hint above options. Be careful with phrases like "point to the" which can leak answers for identify-type tasks.
5. **`pendingSilenceWork` in SpeechService.swift** must be accessed on the main queue (inside `DispatchQueue.main.async`) to avoid data races.

## Devin Secrets Needed

No secrets needed for backend testing. The backend runs locally without authentication.
