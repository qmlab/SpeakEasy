# Testing Backend SVGs & Task Image Audit

## Overview
The SpeakEasy backend serves SVG images for task illustrations at `/task-images/{name}.svg` and real photo PNGs for object recognition tasks via `/adaptive/photo-urls`. Tasks reference images via `image_hint`, `options`, and `sequence` fields in their JSON content.

## Backend Setup
- Start the backend: `cd backend && uvicorn app.main:app --reload --port 8000`
- API docs: `http://localhost:8000/docs`
- SVG endpoint: `http://localhost:8000/task-images/{name}.svg`
- Photo URLs endpoint: `GET /adaptive/photo-urls` — returns `{"photos": {"apple": "https://...", ...}}`
- Image files location: `backend/app/resources/images/`
- Photo URL mapping: `backend/app/resources/images/photo_urls.json`
- Manifest: `backend/app/resources/images/manifest.json`

## Real Photo PNG System

### Architecture
- 106 object photos hosted on Cloudinary as 400x400 PNGs under `risingstar/photos/`
- Source: Wikimedia Commons (CC0/CC-BY-SA), uploaded via Cloudinary API
- Served via `GET /adaptive/photo-urls` endpoint (cached in-memory on backend)
- iOS `RemoteImageView` fallback chain: bundled xcasset → real photo URL → Cloudinary SVG → SF Symbol
- The old SVG fallback path uses `risingstar/task_images/` (cartoon-style icons)

### Testing Photo URLs
```python
import urllib.request, json

# 1. Verify endpoint returns all photos
resp = urllib.request.urlopen('http://localhost:8000/adaptive/photo-urls')
data = json.loads(resp.read())
assert len(data['photos']) == 106
assert all('cloudinary' in u and u.endswith('.png') for u in data['photos'].values())
assert not any('wikimedia' in u for u in data['photos'].values())

# 2. Verify sample images load
for name in ['apple', 'cat', 'dog']:
    url = data['photos'][name]
    req = urllib.request.Request(url, method='HEAD')
    req.add_header('User-Agent', 'Mozilla/5.0')
    resp = urllib.request.urlopen(req, timeout=10)
    assert resp.status == 200
    assert 'image/png' in resp.headers.get('content-type', '')
```

### Visual Verification
Build an HTML grid page loading all 106 Cloudinary URLs to visually confirm:
- Images are real photographs (not cartoon SVGs)
- Objects are recognizable (important for children's learning app)
- No broken/missing images

### Known Image Quality Issues
Some Wikimedia Commons search results may not perfectly match the object name. When updating photos, manually review items like `ruler`, `shirt`, `rain` which might return poor matches from automated search. Consider using more specific Wikimedia file names or alternative sources.

### Updating Photos
To replace/update individual photos:
1. Find a suitable Wikimedia Commons image
2. Upload to Cloudinary using the API (cloud_name: `dgpir7tqk`, use `Cloudinary_SpeakEasy_Dev` secret for API key:secret)
3. Use `public_id='risingstar/photos/{object_name}'`, `format='png'`, `transformation=[{'width': 400, 'height': 400, 'crop': 'fill', 'gravity': 'auto'}]`
4. Update the URL in `photo_urls.json`
5. Backend cache clears on restart — redeploy after changes

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
- `Cloudinary_SpeakEasy_Dev` — API key:secret for uploading/updating photos on Cloudinary (format: `api_key:api_secret`, cloud_name: `dgpir7tqk`)
- No secrets needed for read-only API testing (backend is publicly accessible)
