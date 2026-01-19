#!/usr/bin/env python3
"""
Bulk add objects to the SpeakEasy backend database.
This script adds all 60+ objects from the iOS app's ObjectData.

Usage:
    python bulk_add_objects.py [--url URL]

Default URL: https://speakeasy-backend-jswsybdb.fly.dev
"""

import argparse
import requests
import json

OBJECTS = [
    # Animals
    {"name": "Dog", "category": "Animals"},
    {"name": "Cat", "category": "Animals"},
    {"name": "Bird", "category": "Animals"},
    {"name": "Fish", "category": "Animals"},
    {"name": "Rabbit", "category": "Animals"},
    {"name": "Horse", "category": "Animals"},
    {"name": "Cow", "category": "Animals"},
    {"name": "Pig", "category": "Animals"},
    {"name": "Duck", "category": "Animals"},
    {"name": "Elephant", "category": "Animals"},
    
    # Food
    {"name": "Apple", "category": "Food"},
    {"name": "Banana", "category": "Food"},
    {"name": "Orange", "category": "Food"},
    {"name": "Milk", "category": "Food"},
    {"name": "Bread", "category": "Food"},
    {"name": "Cookie", "category": "Food"},
    {"name": "Water", "category": "Food"},
    {"name": "Juice", "category": "Food"},
    {"name": "Carrot", "category": "Food"},
    {"name": "Grapes", "category": "Food"},
    
    # Toys
    {"name": "Ball", "category": "Toys"},
    {"name": "Teddy Bear", "category": "Toys"},
    {"name": "Blocks", "category": "Toys"},
    {"name": "Doll", "category": "Toys"},
    {"name": "Car Toy", "category": "Toys"},
    {"name": "Puzzle", "category": "Toys"},
    {"name": "Crayons", "category": "Toys"},
    {"name": "Book", "category": "Toys"},
    
    # Household
    {"name": "Chair", "category": "Household"},
    {"name": "Table", "category": "Household"},
    {"name": "Bed", "category": "Household"},
    {"name": "Door", "category": "Household"},
    {"name": "Window", "category": "Household"},
    {"name": "Lamp", "category": "Household"},
    {"name": "Cup", "category": "Household"},
    {"name": "Spoon", "category": "Household"},
    {"name": "Plate", "category": "Household"},
    {"name": "TV", "category": "Household"},
    
    # Nature
    {"name": "Tree", "category": "Nature"},
    {"name": "Flower", "category": "Nature"},
    {"name": "Sun", "category": "Nature"},
    {"name": "Moon", "category": "Nature"},
    {"name": "Star", "category": "Nature"},
    {"name": "Cloud", "category": "Nature"},
    {"name": "Rain", "category": "Nature"},
    {"name": "Grass", "category": "Nature"},
    
    # Vehicles
    {"name": "Car", "category": "Vehicles"},
    {"name": "Bus", "category": "Vehicles"},
    {"name": "Train", "category": "Vehicles"},
    {"name": "Airplane", "category": "Vehicles"},
    {"name": "Boat", "category": "Vehicles"},
    {"name": "Bicycle", "category": "Vehicles"},
    
    # Body Parts
    {"name": "Hand", "category": "Body Parts"},
    {"name": "Foot", "category": "Body Parts"},
    {"name": "Eye", "category": "Body Parts"},
    {"name": "Ear", "category": "Body Parts"},
    {"name": "Nose", "category": "Body Parts"},
    {"name": "Mouth", "category": "Body Parts"},
    {"name": "Head", "category": "Body Parts"},
    {"name": "Arm", "category": "Body Parts"},
    {"name": "Leg", "category": "Body Parts"},
    
    # Clothing
    {"name": "Shirt", "category": "Clothing"},
    {"name": "Pants", "category": "Clothing"},
    {"name": "Shoes", "category": "Clothing"},
    {"name": "Hat", "category": "Clothing"},
    {"name": "Socks", "category": "Clothing"},
    {"name": "Jacket", "category": "Clothing"},
]


def add_objects(base_url: str, skip_existing: bool = True):
    """Add all objects to the database."""
    url = f"{base_url.rstrip('/')}/objects/"
    
    added = 0
    skipped = 0
    failed = 0
    
    # First, get existing objects
    existing_names = set()
    if skip_existing:
        try:
            response = requests.get(url)
            if response.status_code == 200:
                existing = response.json()
                existing_names = {obj["name"].lower() for obj in existing}
                print(f"Found {len(existing_names)} existing objects in database")
        except Exception as e:
            print(f"Warning: Could not fetch existing objects: {e}")
    
    for obj in OBJECTS:
        if obj["name"].lower() in existing_names:
            print(f"  Skipping {obj['name']} (already exists)")
            skipped += 1
            continue
            
        try:
            response = requests.post(
                url,
                json=obj,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code in (200, 201):
                result = response.json()
                print(f"  Added: {obj['name']} (ID: {result['id']})")
                added += 1
            else:
                print(f"  Failed to add {obj['name']}: {response.status_code} - {response.text}")
                failed += 1
                
        except Exception as e:
            print(f"  Error adding {obj['name']}: {e}")
            failed += 1
    
    print(f"\nSummary:")
    print(f"  Added: {added}")
    print(f"  Skipped: {skipped}")
    print(f"  Failed: {failed}")
    print(f"  Total: {len(OBJECTS)}")
    
    return added, skipped, failed


def main():
    parser = argparse.ArgumentParser(description="Bulk add objects to SpeakEasy backend")
    parser.add_argument(
        "--url",
        default="https://speakeasy-backend-jswsybdb.fly.dev",
        help="Backend URL (default: https://speakeasy-backend-jswsybdb.fly.dev)"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Add objects even if they already exist (may create duplicates)"
    )
    
    args = parser.parse_args()
    
    print(f"Adding {len(OBJECTS)} objects to {args.url}")
    print("-" * 50)
    
    add_objects(args.url, skip_existing=not args.force)


if __name__ == "__main__":
    main()
