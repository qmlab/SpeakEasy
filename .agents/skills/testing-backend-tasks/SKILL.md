# Testing SpeakEasy Backend Tasks & SVG Assets

## Environment Setup

1. Start the backend:
   ```bash
   cd backend && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```
   Note: `poetry run` prefix may not be needed if deps are installed globally.
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

### Dimension-Specific SVG Variants

When tasks need visually distinct versions of similar objects (e.g. size comparison tasks), create variant SVGs with descriptive suffixes:
- `pencil_long.svg` / `crayon_short.svg` — for "Which is Longer?" comparison tasks
- `puppy.svg` (distinct from `dog.svg`) — baby animal with different proportions (bigger eyes, floppy ears)
- Always update `manifest.json` when adding new SVGs (categories array + image_hint_aliases + total_images count)

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

### Finding specific tasks by question_id
```bash
curl -s "http://localhost:8000/tasks/?dimension=cognitive_logic&level=2&limit=50" | python3 -c "
import json, sys
tasks = json.load(sys.stdin)
for t in tasks:
    qid = t['content'].get('question_id', '')
    if qid in ('Q093', 'Q292'):  # adjust IDs as needed
        print(json.dumps(t['content'], indent=2))
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
6. **Language expression answer leaks** — For non-imitate language_expression tasks (describe, conversation, name_object), the target_word should NOT be displayed in the UI. This suppression is handled client-side in `LearningSessionView.swift` instructionCard(). The backend still stores target_word; verify the iOS suppression logic is correct when changing task types.
7. **`inline_images` flag** — When a task has `"inline_images": true` in its content, the sequence items are rendered as tappable image cards instead of text. Used for analogy tasks (e.g. dog→puppy, cat→?) where visual representation helps comprehension.

## iOS-Only Changes (Cannot Test Without Device)

Some changes are purely in Swift and cannot be verified via backend API:
- Camera feature removal (CameraLearningView, CameraService)
- Navigation tab restructuring (ContentView.swift)
- Answer leak suppression in instructionCard (LearningSessionView.swift)
- hasVisualContentAboveOptions layout logic

For these, verify the code logic by reading the Swift files and checking CI (Xcode build) passes.

## Devin Secrets Needed

No secrets needed for backend testing. The backend runs locally without authentication.
