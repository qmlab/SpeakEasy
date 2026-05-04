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
- Deployed backend: `https://risingstar-backend-yojhdcez.fly.dev`

## Real Photo PNG System

### Architecture
- 202 object photos hosted on Cloudinary as 400x400 PNGs
- **Primary path**: `risingstar/photos/{name}` — canonical photo URLs stored in `photo_urls.json`
- **Fallback path**: `risingstar/task_images/{name}` — also contains real photos (replaced original SVGs)
- Sources: Unsplash (primary) and Pexels (fallback) — free license photos
- Served via `GET /adaptive/photo-urls` endpoint (cached in-memory on backend)
- **Important**: The photo URL cache is loaded once at startup from `photo_urls.json`. After updating the JSON file, the backend must be restarted to pick up changes.
- iOS `RemoteImageView` fallback chain: bundled xcasset → real photo URL → Cloudinary fallback (`task_images/`) → SF Symbol
- Deployed backend: `https://risingstar-backend-yojhdcez.fly.dev`

### SVG Fallback Path Strategy
The iOS app's `RemoteImageView` uses a fallback URL pattern:
```
https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/task_images/{normalizedName}
```
This path originally served cartoon SVGs. All 202 real photos have been uploaded to BOTH paths:
- `risingstar/photos/{name}` (canonical, referenced in photo_urls.json)
- `risingstar/task_images/{name}` (fallback, so even old iOS builds show real photos)

This means even iOS builds without the `@ObservedObject` cache reactivity fix (PR #151) will display real photos instead of SVGs.

### Testing Photo URLs
```python
import urllib.request, json

# 1. Verify endpoint returns all photos
resp = urllib.request.urlopen('http://localhost:8200/adaptive/photo-urls')
data = json.loads(resp.read())
assert len(data['photos']) == 202  # current count as of PR #154
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

### Testing SVG Fallback Path (Critical)
To verify SVGs have been replaced at the fallback path, check file sizes:
```bash
# Real photos are typically 50KB-400KB; SVGs rendered as PNG are 2-5KB
for name in car flower rabbit basketball scissors key frog clock; do
    result=$(curl -s -o /dev/null -w "%{http_code} %{size_download}" \
        "https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/task_images/$name")
    echo "$name: $result"  # expect HTTP 200, size > 50000
done
```
A file size <20KB at the `task_images/` path indicates the SVG was NOT replaced.

### Visual Verification
When verifying photo quality, check that:
- Images are real photographs (not cartoon SVGs)
- **Objects are fully visible** — not cropped to show only half the object
- Objects are recognizable to a child (this is a children's learning app)
- No broken/missing images
- Photos are appropriately zoomed — show the whole object, not an extreme close-up of a detail

Key items to always spot-check (these have had quality issues in the past):
- `volcano` — should show eruption with lava (was previously cloud-like)
- `microscope` — should show a lab microscope
- `chair` — should show a complete chair (legs visible)
- `brush` — should show the full paintbrush (not just bristle close-up)
- `dog` — should show a recognizable dog (was previously duck-like)
- `rocket` — should show a rocket (was previously lightning-like)
- `binoculars` — should show person using binoculars (was previously Mount Fuji)

### Updating Photos
To replace/update individual photos:
1. Find a suitable photo on Unsplash or Pexels (free license)
2. Download at 400x400 resolution (use `?w=400&h=400&fit=crop` for Unsplash CDN)
3. Upload to Cloudinary using the API (cloud_name: `dgpir7tqk`, use `Cloudinary_SpeakEasy_Dev` secret for API key:secret)
4. Use `public_id='risingstar/photos/{object_name}'`, `overwrite=True`, `resource_type='image'`, `format='png'`
5. **Also upload to fallback path**: `public_id='risingstar/task_images/{object_name}'` with same parameters
6. Update the URL in `photo_urls.json`
7. Backend cache clears on restart — redeploy after changes
8. After deploying, verify via `GET /adaptive/photo-urls` that the new URL is served

### Cloudinary CDN Cache Invalidation (Important)
When replacing images at `task_images/` path, Cloudinary CDN may cache the old transformed version (especially `f_png` format). Symptoms: the raw `.png` URL serves the new image but `f_png/risingstar/task_images/{name}` still serves the old tiny SVG.

**Fix procedure:**
```python
import cloudinary, cloudinary.uploader

# 1. Destroy the old resource first
cloudinary.uploader.destroy(f"risingstar/task_images/{name}", invalidate=True)

# 2. Re-upload from local file (not URL — URL-based upload might hit the same CDN cache)
result = cloudinary.uploader.upload(
    local_file_path,
    public_id=f"risingstar/task_images/{name}",
    overwrite=True,
    resource_type="image",
    format="png",
    invalidate=True
)

# 3. Wait ~30 seconds for CDN propagation
# 4. Verify with: curl -s -o /dev/null -w "%{size_download}" \
#    "https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/task_images/{name}"
# Size should be >20KB (real photo), not 2-5KB (cached SVG)
```

**Key points:**
- Always download the source photo to a local file first, then upload from local — URL-based uploads might resolve to the cached CDN version
- `invalidate=True` on both destroy and upload is required
- CDN propagation takes ~30 seconds after destroy+re-upload
- Verify using the `f_png` URL format (not raw `.png`) since that's what iOS uses

### Common Pitfalls
- **Stale cache**: If you start the backend before pulling latest code, the in-memory cache will have old photo URLs. Always restart after code changes.
- **CDN cache**: Cloudinary CDN caches `f_png` transformations separately. See "CDN Cache Invalidation" section above.
- **Photo quality**: Unsplash `?fit=crop` may crop important parts of the object. Always visually verify downloaded photos before uploading to Cloudinary.
- **Duplicate photos**: When downloading many photos at once, verify with MD5 hashing that no two objects share the same image file.
- **Abstract vs physical**: Not all task images need real photos — shapes, colors, numbers, letters, arrows, and emotions should remain as SVGs.
- **Upload from local files**: When batch-uploading to task_images/, always download to local first then upload from file path. URL-based uploads may hit CDN cache and upload the old cached version.

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
