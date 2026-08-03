# Testing SVG Illustrations

## Overview
The app uses 155+ SVG illustrations for object_cognition tasks. SVGs are stored in `backend/app/resources/images/` and served via Cloudinary PNG transform.

## Cloudinary URL Pattern
- Base: `https://res.cloudinary.com/dgpir7tqk/image/upload/f_png/risingstar/task_images/{name}`
- The `f_png` transform converts SVG to PNG for iOS AsyncImage compatibility
- Upload uses the `cloudinary` Python SDK with credentials from `Cloudinary_SpeakEasy_Dev` secret

## Devin Secrets Needed
- `Cloudinary_SpeakEasy_Dev` — format: `api_key:api_secret`, cloud_name is `dgpir7tqk`

## Testing SVGs Visually
1. Create an HTML page that loads all SVGs in a grid from Cloudinary PNG URLs
2. Use JavaScript `onload`/`onerror` handlers to count loaded vs failed images
3. Take screenshots of each scroll section to visually verify recognizability
4. Red-border highlight any redesigned/changed SVGs for easy identification

## Uploading SVGs to Cloudinary
```python
import cloudinary, cloudinary.uploader
creds = os.environ.get('Cloudinary_SpeakEasy_Dev', '').split(':')
cloudinary.config(cloud_name='dgpir7tqk', api_key=creds[0], api_secret=creds[1])
cloudinary.uploader.upload(filepath, public_id=f'risingstar/task_images/{name}', overwrite=True, resource_type='image', format='svg')
```

## Common Issues
- **Duplicate XML attributes**: Cloudinary rejects SVGs with duplicate attributes (e.g., two `opacity` attrs on same element). Validate XML before uploading.
- **Cloudinary caching**: After re-uploading, Cloudinary may serve cached versions. Use `?v=timestamp` cache-buster or wait for CDN propagation.
- **SVG viewBox**: All object_cognition SVGs use `viewBox="0 0 120 120"` with a colored circle background. Older SVGs may have used 200x200 — these should be redrawn, not just scaled.

## Batch SVG Generation
- For large batches (100+ SVGs), break generation scripts into multiple parts by category to avoid shell timeout (30s limit)
- Categories: fruits/food, animals, objects, tools, vehicles, music/faces/misc
- Execute each part sequentially and verify completion before moving on
- Use Python `Write` tool or file operations rather than bash heredocs for SVG content

## SVG Quality Checklist
- Each SVG should have a colored circle background with stroke
- Objects should include highlights, shadows, and textures for recognizability
- Animals need proper anatomy (legs, ears, tails, etc.)
- Tools need proper proportions (handles, blades, heads)
- Food items need color variation and texture details
