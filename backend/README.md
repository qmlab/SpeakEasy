# SpeakEasy Backend

Backend API for SpeakEasy iOS app - Teaching non-verbal autistic children to speak and recognize objects.

## Features

### Feature 1: See Picture, Say the Word
- Store object images with names and categories
- Score pronunciation using Levenshtein distance similarity
- Track player attempts and progress

### Feature 2: Find Object in Picture
- Store images with bounding boxes marking object locations
- Validate tap locations against bounding boxes
- Score accuracy based on tap proximity to object center

## Setup

```bash
cd backend
poetry install
```

## Running the Server

```bash
poetry run fastapi dev app/main.py
```

The API will be available at http://localhost:8000

## API Documentation

Once running, visit http://localhost:8000/docs for interactive API documentation.

## API Endpoints

### Players
- `POST /players/` - Create a new player
- `GET /players/` - List all players
- `GET /players/{player_id}` - Get player details
- `GET /players/{player_id}/history` - Get player attempt history
- `GET /players/{player_id}/stats` - Get player statistics

### Objects
- `POST /objects/` - Create a new object
- `GET /objects/` - List all objects (filter by category)
- `GET /objects/categories` - List all categories
- `GET /objects/{object_id}` - Get object details with images
- `POST /objects/{object_id}/images` - Add image with optional bounding boxes
- `POST /objects/{object_id}/images/upload` - Upload image file

### Game
- `POST /game/say-word` - Submit pronunciation attempt
- `POST /game/find-object` - Submit tap location for find game
- `GET /game/random-object` - Get random object for practice
- `GET /game/random-image-with-boxes` - Get random image with bounding boxes
- `GET /game/challenge/{player_id}` - Get a challenge for the player

## Database

Uses SQLite by default. The database file `speakeasy.db` is created automatically.
