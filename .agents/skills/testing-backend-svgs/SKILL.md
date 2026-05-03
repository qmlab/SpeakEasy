# Testing Backend SVGs & Task Image Audit

## Overview
The SpeakEasy backend serves SVG images for task illustrations at `/task-images/{name}.svg` and real photo PNGs for object recognition tasks via `/adaptive/photo-urls`. Tasks reference images via `image_hint`, `options`, and `sequence` fields in their JSON content.

## Backend Setup
- Start the backend: `cd backend && poetry run uvicorn app.main:app --reload --port 8000`
- Fresh DB for testing: `cd backend && rm -f test.db && DATABASE_URL="sqlite:///./test.db" poetry run uvicorn app.main:app --host 0.0.0.0 --port 8200`
- API docs: `http://localhost:8000/docs`
- SVG endpoint: `http://localhost:8000/task-images/{name}.svg`
- Photo URLs endpoint: `GET /adaptive/photo-urls` — returns `{"photos": {"apple": "https://...", ...}}`
- Image files location: `backend/app/resources/images/`
- Photo URL mapping: `backend/app/resources/images/photo_urls.json`
- Manifest: `backend/app/resources/images/manifest.json`

## Real Photo PNG System

### Architecture
- 205 object photos hosted on Cloudinary as 400x400 PNGs under `risingstar/photos/`
- Photos also uploaded to `risingstar/task_images/` path (SVG fallback path) so even old iOS builds get real photos
- Sources: Unsplash (primary) and Pexels (fallback) — free license photos
- Served via `GET /adaptive/photo-urls` endpoint (cached in-memory on backend)
- **Important**: The photo URL cache is loaded once at startup from `photo_urls.json`. After updating the JSON file, the backend must be restarted to pick up changes.
- iOS `RemoteImageView` fallback chain: bundled xcasset → real photo URL → Cloudinary SVG → SF Symbol
- Deployed backend: `https://risingstar-backend-yojhdcez.fly.dev`

### Critical: Bundled SVG Override Issue
**Root cause of persistent SVG display**: iOS `UIImage(named:)` in `RemoteImageView` checks local xcassets FIRST. If a bundled SVG exists in `Assets.xcassets/TaskImages/`, it's used immediately and Cloudinary real photos are never loaded — regardless of what the backend returns.

**Solution**: Delete bundled SVG imagesets for any item that has a real photo on Cloudinary. Only keep SVGs for:
- Dimension icons (dim_*)
- Reward icons (reward_*)
- Abstract shapes (circle_shape, square_shape, triangle_shape)
- Gestures/emotions (happy_face, sad_face, eating, sleeping, waving, etc.)
- Items with no real photo equivalent (heart, father, mother)

**Dual-path upload**: When uploading new photos, always upload to BOTH paths:
1. `risingstar/photos/{name}` — primary path used by photo_urls.json
2. `risingstar/task_images/{name}` — fallback path that old iOS builds may use

This ensures even old iOS builds that fall back to the SVG URL path will get real photos instead of SVGs.

### Testing Photo URLs
```python
import urllib.request, json

# 1. Verify endpoint returns all photos
resp = urllib.request.urlopen('http://localhost:8200/adaptive/photo-urls')
data = json.loads(resp.read())
assert len(data['photos']) == 205
assert all('cloudinary' in u and u.endswith('.png') for u in data['photos'].values())
assert all('dgpir7tqk' in u for u in data['photos'].values())  # correct cloud_name

# 2. Check for duplicate URLs
urls = list(data['photos'].values())
assert len(urls) == len(set(urls)), "Duplicate photo URLs found!"

# 3. Verify sample images load (use concurrent requests for speed)
import concurrent.futures, subprocess
def check_url(name_url):
    name, url = name_url
    result = subprocess.run(
        ['curl', '-s', '-o', '/dev/null', '-w', '%{http_code}', '--max-time', '10', '-I', url],
        capture_output=True, text=True, timeout=15
    )
    return (name, result.stdout.strip())

with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
    results = list(executor.map(check_url, data['photos'].items()))
failures = [(n, s) for n, s in results if s != '200']
assert len(failures) == 0, f"Failed URLs: {failures}"
```

### Testing SVG Fallback Path
When verifying that old iOS builds will see real photos (not SVGs), check the `task_images/` path:
```python
# Verify user-reported SVG items are real photos at task_images path
items = ['car', 'flower', 'rabbit', 'basketball', 'scissors', 'boat', 'guitar',
         'cake', 'pear', 'key', 'frog', 'clock', 'moon', 'sun', 'strawberry']
base = 'https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/task_images'
for name in items:
    req = urllib.request.Request(f"{base}/{name}", method='HEAD')
    resp = urllib.request.urlopen(req)
    size = int(resp.headers.get('Content-Length', 0))
    assert size > 20000, f"{name} is {size}B — likely still SVG (real photos are >50KB)"
```

### Visual Verification
When verifying photo quality, check that:
- Images are real photographs (not cartoon SVGs)
- **Objects are fully visible** — not cropped to show only half the object
- Objects are recognizable to a child (this is a children's learning app)
- No broken/missing images
- Photos are appropriately zoomed — show the whole object, not an extreme close-up of a detail
- Object is centered and large enough to identify at small display sizes

Key items to always spot-check (these have had quality issues in the past):
- `volcano` — should show eruption with lava (was previously cloud-like)
- `microscope` — should show a lab microscope
- `chair` — should show a complete chair (legs visible)
- `brush` — should show the full paintbrush (not just bristle close-up)
- `hen` — should show a clear chicken close-up (was previously too small)
- `pencil` — should show a recognizable pencil (was previously yellow blob)
- `screwdriver` — should show 1-2 screwdrivers (not 20+ tools)

### Updating Photos
To replace/update individual photos:
1. Find a suitable photo on Unsplash or Pexels (free license)
2. Download at 400x400 resolution (use `?w=400&h=400&fit=crop` for Unsplash CDN)
3. Upload to Cloudinary using the API (cloud_name: `dgpir7tqk`, use `Cloudinary_SpeakEasy_Dev` secret for API key:secret)
4. Upload to BOTH paths: `risingstar/photos/{name}` AND `risingstar/task_images/{name}`
5. Use `overwrite=True`, `format='png'`, `invalidate=True`
6. Update the URL (with new version number) in `photo_urls.json`
7. Backend cache clears on restart — redeploy after changes
8. After deploying, seed DB: `POST /tasks/seed?force=true`
9. Verify via `GET /adaptive/photo-urls` that the new URL is served

### CDN Cache Invalidation
Cloudinary CDN may cache old versions. When replacing photos:
- Use `invalidate=True` in upload call
- If stale images persist, destroy the old resource first: `cloudinary.uploader.destroy(public_id, invalidate=True)` then re-upload
- Verify by fetching with `f_png` format param: `https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/task_images/{name}`

### Common Pitfalls
- **Bundled SVG override**: If users report seeing SVGs despite backend having real photos, check `Assets.xcassets/TaskImages/` for bundled SVG imagesets. Delete any that have real photo equivalents.
- **Stale cache**: If you start the backend before pulling latest code, the in-memory cache will have old photo URLs. Always restart after code changes.
- **Photo quality**: Unsplash `?fit=crop` may crop important parts of the object. Always visually verify downloaded photos before uploading to Cloudinary.
- **Pexels/Unsplash rate limiting**: Both services may block automated downloads. Use browser to find correct photo IDs, then download with direct URLs. Wikimedia Commons blocks after ~5 requests.
- **Duplicate photos**: When downloading many photos at once, verify with MD5 hashing that no two objects share the same image file.
- **Abstract vs physical**: Not all task images need real photos — shapes, colors, numbers, letters, arrows, and emotions should remain as SVGs.

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

## Devin Secrets Needed
- `Cloudinary_SpeakEasy_Dev` — API key:secret for uploading photos to Cloudinary (format: `api_key:api_secret`)
- No other secrets needed for read-only API testing
