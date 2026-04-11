# Testing Backend SVGs & Task Image Audit

## Overview
The SpeakEasy backend serves SVG images for task illustrations at `/task-images/{name}.svg`. Tasks reference images via `image_hint`, `options`, and `sequence` fields in their JSON content. This skill covers auditing and testing SVG coverage.

## Backend Setup
- Start the backend: `cd backend && uvicorn app.main:app --reload --port 8000`
- API docs: `http://localhost:8000/docs`
- SVG endpoint: `http://localhost:8000/task-images/{name}.svg`
- Image files location: `backend/app/resources/images/`
- Manifest: `backend/app/resources/images/manifest.json`

## Auditing Missing SVGs

### Steps
1. Query tasks by dimension: `GET /tasks/?dimension={dimension_name}&limit=200`
2. Extract `image_hint`, `options`, and `sequence` values from task content
3. Normalize names: lowercase, replace spaces with underscores, replace `/` with underscores
4. Cross-reference against available `.svg` files in the images directory
5. Filter out text phrases (3+ words, verb phrases, abstract concepts) — these display as text buttons and don't need SVGs

### Key Dimensions to Audit
- `object_cognition` (cognitive skills)
- `cognitive_logic`
- `literacy`
- `language_comprehension`
- `language_expression`
- `social_behavior`

### What Needs SVGs vs Text
- **Needs SVG**: Concrete objects (apple, car, dog), colored shapes (red_circle), geometric patterns, scene hints (boy_crying, animals)
- **Text-only OK**: Abstract reasoning answers ("It wilts", "President"), names ("Amy", "Ben"), multi-word action phrases ("Brush your teeth")

## Testing SVGs

### Bulk HTTP Test
```python
import urllib.request
for name in svg_names:
    resp = urllib.request.urlopen(f'http://localhost:8000/task-images/{name}.svg')
    assert resp.status == 200
    assert '<svg' in resp.read().decode()
```

### Visual Spot-Check
Open representative SVGs in browser to verify they render as recognizable icons:
- Pick one from each category (concrete object, colored shape, geometric, scene, arrow, number)
- Verify non-blank, correct colors, recognizable to a child

### Manifest Consistency
- `total_images` in manifest.json should equal actual SVG file count on disk
- All new SVGs should appear in `image_hint_aliases`

## Generating New SVGs
- SVGs use 100x100 viewBox with simple shapes
- Concrete objects: circular icon with background circle (`cx=50 cy=50 r=46`)
- Geometric shapes: no background circle, just the shapes
- Use consistent color palette from existing SVGs
- Write a Python script to batch-generate, output to `backend/app/resources/images/`

## Running Backend Tests
```bash
python -m pytest backend/tests/ -q
```
Expect 125+ tests to pass.

## Devin Secrets Needed
None — backend testing uses local server with no authentication required.
