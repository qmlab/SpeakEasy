# Testing Backend Task Data Changes

This skill covers how to verify backend task JSON data changes (image_hints, instructions, options, multi-select flags) for the Rising Star Kid adaptive learning platform.

## Environment Setup

1. Start the local backend from the PR branch:
   ```bash
   cd backend && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &
   ```
2. Force reseed with updated task data:
   ```bash
   curl -s -X POST "http://localhost:8000/tasks/seed?force=true"
   ```
   This replaces all existing tasks with the data from the JSON files in the current branch.

## Key API Endpoints

- `GET /tasks/?dimension={dim}&limit=100` — List all tasks for a dimension
- `GET /tasks/{task_id}` — Get a specific task by ID
- `POST /tasks/seed?force=true` — Force reseed all tasks from JSON files
- `GET /tasks/stats/expanded` — Get task count statistics

## Task Data Structure

Tasks are stored with a `content` JSON column that includes:
- `instruction_text` / `instruction_audio` — Task instructions
- `image_hint` — Maps to SVG images on Cloudinary and locally
- `options` / `correct_answer` — Answer choices
- `multi_select` — Boolean flag for multi-select tasks
- `instruction_zh` — Chinese translation of instructions

## Testing Checklist

### For image_hint changes:
1. Query tasks via API and verify `content.image_hint` values are correct
2. Verify Cloudinary images are accessible: `curl -o /dev/null -w "%{http_code}" "https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/task_images/{image_hint}"`
3. Verify local SVG files exist in `backend/app/resources/images/`
4. Verify `manifest.json` has matching aliases in `image_hint_aliases`

### For instruction wording changes:
1. Query tasks and check `content.instruction_text` matches expected wording
2. Verify no old wording patterns remain (e.g., "in the box" for multi-select tasks)

### For multi-select changes:
1. Filter tasks where `content.multi_select == true`
2. Verify `correct_answer` contains comma-separated values
3. Verify each correct answer item exists in `options` array

## Important Notes

- The **deployed backend** (Fly.io) runs from `main` branch. PR branch changes won't appear there until merged + force reseeded.
- After merging, you must POST to `https://risingstar-backend-zclkfobb.fly.dev/tasks/seed?force=true` to update the deployed DB.
- Some tasks legitimately use "hat" as image_hint (tasks about actual hats). Don't flag these as errors.
- The `seed_expanded.py` file reads task JSONs and builds the `content` dict via `_build_content()`. Image hints flow from JSON → `_build_content()` → DB `content` column → API response.
- Cloudinary base URL: `https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/task_images/`

## Devin Secrets Needed

- `CLOUDINARY_API_KEY` — For uploading new images to Cloudinary
- `CLOUDINARY_API_SECRET` — For uploading new images to Cloudinary
- No secrets needed for read-only API testing
