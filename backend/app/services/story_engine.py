"""
StoryEngine - Story-based assessment for Rising Star Kid.

Replaces the old random-test assessment with interactive stories where
assessment questions are naturally embedded within a narrative.  Each story
covers multiple developmental dimensions so the child feels like they are
playing a story, not taking a test.

Key design:
- Stories are loaded from JSON files in resources/stories/
- Each story has 6-8 scenes, each containing one hidden assessment test
- Adaptive branching: if a prerequisite scene was answered incorrectly,
  the engine serves a fallback (easier) question instead
- State is persisted via the existing Assessment model
- Results update DevelopmentalProfile just like the old assessment
"""

import json
import uuid
from datetime import datetime
from pathlib import Path
from typing import Optional

from sqlalchemy.orm import Session

from app.models.adaptive import (
    Assessment,
    DevelopmentalProfile,
)
from app.models.player import Player


# ---------------------------------------------------------------------------
# Load story data from JSON
# ---------------------------------------------------------------------------

_STORIES_DIR = Path(__file__).parent.parent / "resources" / "stories"


def _load_story(story_id: str) -> dict:
    """Load a story definition from its JSON file."""
    # Sanitize story_id to prevent path traversal
    if not all(c.isalnum() or c in ("_", "-") for c in story_id):
        raise ValueError(f"Invalid story ID: {story_id}")
    path = _STORIES_DIR / f"{story_id}.json"
    if not path.resolve().parent == _STORIES_DIR.resolve():
        raise ValueError(f"Invalid story ID: {story_id}")
    if not path.exists():
        raise FileNotFoundError(f"Story not found: {story_id}")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def list_available_stories() -> list[dict]:
    """Return metadata for all available stories."""
    stories = []
    for path in sorted(_STORIES_DIR.glob("*.json")):
        try:
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
            stories.append(
                {
                    "story_id": data["story_id"],
                    "title": data["title"],
                    "title_zh": data.get("title_zh", data["title"]),
                    "character": data.get("character", ""),
                    "character_emoji": data.get("character_emoji", ""),
                    "estimated_minutes": data.get("estimated_minutes", 5),
                    "scene_count": len(data.get("scenes", [])),
                    "image_url": data.get("intro", {}).get("image_url", ""),
                }
            )
        except (json.JSONDecodeError, KeyError):
            continue
    return stories


# ---------------------------------------------------------------------------
# StoryEngine
# ---------------------------------------------------------------------------


class StoryEngine:
    def __init__(self, db: Session):
        self.db = db

    # -- Public API ----------------------------------------------------------

    def start_story(self, player_id: str, story_id: str) -> dict:
        """Start a story-based assessment for a player."""
        player = self.db.query(Player).filter(Player.id == player_id).first()
        if not player:
            raise ValueError(f"Player {player_id} not found")

        story = _load_story(story_id)
        assessment_id = str(uuid.uuid4())

        # Build scene results tracker
        scene_results: dict[str, dict] = {}
        for scene in story["scenes"]:
            scene_results[scene["scene_id"]] = {
                "answered": False,
                "is_correct": False,
                "used_fallback": False,
                "dimension": scene["test"]["dimension"],
                "level": scene["test"]["level"],
            }

        # Build dimension state for profile updates later
        dimension_state: dict[str, dict] = {}
        for scene in story["scenes"]:
            dim = scene["test"]["dimension"]
            if dim not in dimension_state:
                dimension_state[dim] = {
                    "results": [],
                    "assessed_level": 0,
                }

        character_info = {
            "name": story["character"],
            "emoji": story["character_emoji"],
        }

        # Persist via existing Assessment model
        assessment = Assessment(
            id=assessment_id,
            player_id=player_id,
            character=character_info,
            started_at=datetime.utcnow(),
            activities=[{"story_id": story_id}],  # tag as story
            current_index=0,
            dimension_state=dimension_state,
            activity_task_ids={"scene_results": scene_results},
        )
        self.db.add(assessment)
        self.db.commit()

        intro = story.get("intro", {})

        return {
            "assessment_id": assessment_id,
            "story_id": story_id,
            "player_id": player_id,
            "title": story["title"],
            "title_zh": story.get("title_zh", story["title"]),
            "character": character_info,
            "intro_narration": intro.get("narration", ""),
            "intro_narration_zh": intro.get("narration_zh", ""),
            "intro_image_url": intro.get("image_url", ""),
            "total_scenes": len(story["scenes"]),
        }

    def get_next_scene(self, assessment_id: str) -> Optional[dict]:
        """Get the next scene in the story."""
        assessment = self._get_assessment(assessment_id)
        story_id = assessment.activities[0]["story_id"]
        story = _load_story(story_id)
        scenes = story["scenes"]
        current_index = assessment.current_index

        if current_index >= len(scenes):
            return None

        scene = scenes[current_index]
        scene_results = assessment.activity_task_ids.get("scene_results", {})

        # Check adaptive branching
        use_fallback = False
        if scene.get("requires_correct"):
            prereq_id = scene["requires_correct"]
            prereq = scene_results.get(prereq_id, {})
            if prereq.get("answered") and not prereq.get("is_correct"):
                use_fallback = True

        # Pick the test (main or fallback)
        if use_fallback and scene.get("fallback"):
            test = scene["fallback"]
            is_fallback = True
        else:
            test = scene["test"]
            is_fallback = False

        # Shuffle options at serve time (same logic as adaptive_engine)
        import random

        options = list(test.get("options", []))
        options_zh = list(test.get("options_zh", []))
        image_hints = list(test.get("image_hints", []))
        correct = test["correct_answer"]

        # Pad shorter arrays to match options length so shuffle keeps alignment
        while len(options_zh) < len(options):
            options_zh.append("")
        while len(image_hints) < len(options):
            image_hints.append("")

        if len(options) > 1:
            combined = list(zip(options, options_zh, image_hints))
            random.shuffle(combined)
            options, options_zh, image_hints = [list(t) for t in zip(*combined)]

        return {
            "scene_index": current_index,
            "total_scenes": len(scenes),
            "scene_id": scene["scene_id"],
            "narration": scene["narration"],
            "narration_zh": scene.get("narration_zh", scene["narration"]),
            "image_url": scene.get("image_url", ""),
            "test": {
                "instruction": test["instruction"],
                "instruction_zh": test.get("instruction_zh", test["instruction"]),
                "options": options,
                "options_zh": options_zh,
                "correct_answer": correct,
                "modality": test.get("modality", "touch"),
                "dimension": test["dimension"],
                "level": test["level"],
                "image_hints": image_hints,
            },
            "is_fallback": is_fallback,
            "is_last": current_index >= len(scenes) - 1,
            "character": assessment.character,
            "progress": (current_index) / len(scenes),
        }

    def process_response(
        self,
        assessment_id: str,
        scene_index: int,
        selected_option: Optional[str] = None,
        spoken_text: Optional[str] = None,
        response_time_ms: Optional[int] = None,
    ) -> dict:
        """Process a child's response to a story scene."""
        assessment = self._get_assessment(assessment_id)
        story_id = assessment.activities[0]["story_id"]
        story = _load_story(story_id)
        scenes = story["scenes"]

        if scene_index >= len(scenes):
            raise ValueError(f"Invalid scene index: {scene_index}")

        scene = scenes[scene_index]
        scene_results = dict(assessment.activity_task_ids or {})
        sr = dict(scene_results.get("scene_results", {}))

        # Determine which test was actually served
        use_fallback = False
        if scene.get("requires_correct"):
            prereq_id = scene["requires_correct"]
            prereq = sr.get(prereq_id, {})
            if prereq.get("answered") and not prereq.get("is_correct"):
                use_fallback = True

        if use_fallback and scene.get("fallback"):
            test = scene["fallback"]
        else:
            test = scene["test"]

        # Evaluate correctness
        correct_answer = test["correct_answer"]
        modality = test.get("modality", "touch")
        is_correct = False

        if modality == "voice" and spoken_text is not None:
            is_correct = self._evaluate_voice(correct_answer, spoken_text)
        elif selected_option is not None:
            is_correct = (
                selected_option.lower().strip() == correct_answer.lower().strip()
            )

        # Update scene results
        scene_entry = dict(sr.get(scene["scene_id"], {}))
        scene_entry["answered"] = True
        scene_entry["is_correct"] = is_correct
        scene_entry["used_fallback"] = use_fallback
        scene_entry["dimension"] = test["dimension"]
        scene_entry["level"] = test["level"]
        if response_time_ms is not None:
            scene_entry["response_time_ms"] = response_time_ms
        sr[scene["scene_id"]] = scene_entry
        scene_results["scene_results"] = sr

        # Update dimension state
        dim_state = dict(assessment.dimension_state or {})
        dim = test["dimension"]
        if dim not in dim_state:
            dim_state[dim] = {"results": [], "assessed_level": 0}
        dim_entry = dict(dim_state[dim])
        results_list = list(dim_entry.get("results", []))
        results_list.append(
            {
                "level": test["level"],
                "correct": is_correct,
                "scene_id": scene["scene_id"],
            }
        )
        dim_entry["results"] = results_list
        if is_correct and test["level"] >= dim_entry.get("assessed_level", 0):
            dim_entry["assessed_level"] = test["level"]
        dim_state[dim] = dim_entry

        # Advance to next scene
        assessment.current_index = scene_index + 1
        assessment.dimension_state = dim_state
        assessment.activity_task_ids = scene_results
        self.db.commit()

        # Pick feedback
        if is_correct:
            feedback = scene.get("feedback_correct", "Great job!")
            feedback_zh = scene.get("feedback_correct_zh", feedback)
        else:
            feedback = scene.get("feedback_incorrect", "Nice try!")
            feedback_zh = scene.get("feedback_incorrect_zh", feedback)

        return {
            "is_correct": is_correct,
            "feedback": feedback,
            "feedback_zh": feedback_zh,
            "should_continue": scene_index + 1 < len(scenes),
            "progress": (scene_index + 1) / len(scenes),
        }

    def complete_story(self, assessment_id: str) -> dict:
        """Complete the story assessment and update developmental profiles."""
        assessment = self._get_assessment(assessment_id)
        story_id = assessment.activities[0]["story_id"]
        story = _load_story(story_id)

        dim_state = assessment.dimension_state or {}

        # Calculate per-dimension results
        dimensions = []
        total_correct = 0
        total_tested = 0

        for dim, state in dim_state.items():
            results = state.get("results", [])
            correct = sum(1 for r in results if r.get("correct"))
            total = len(results)
            assessed_level = state.get("assessed_level", 0)

            total_correct += correct
            total_tested += total

            # Update developmental profile
            self._update_profile(assessment.player_id, dim, assessed_level)

            dimensions.append(
                {
                    "dimension": dim,
                    "assessed_level": assessed_level,
                    "correct_count": correct,
                    "total_count": total,
                    "accuracy": correct / total if total > 0 else 0,
                }
            )

        # Mark assessment as completed
        assessment.completed = True
        assessment.completed_at = datetime.utcnow()
        self.db.commit()

        outro = story.get("outro", {})

        return {
            "assessment_id": assessment_id,
            "story_id": story_id,
            "player_id": assessment.player_id,
            "dimensions": dimensions,
            "total_correct": total_correct,
            "total_tested": total_tested,
            "overall_accuracy": (
                total_correct / total_tested if total_tested > 0 else 0
            ),
            "character": assessment.character,
            "outro_narration": outro.get("narration", ""),
            "outro_narration_zh": outro.get("narration_zh", ""),
            "outro_image_url": outro.get("image_url", ""),
        }

    # -- Private helpers -----------------------------------------------------

    def _get_assessment(self, assessment_id: str) -> Assessment:
        assessment = (
            self.db.query(Assessment)
            .filter(
                Assessment.id == assessment_id,
                Assessment.completed == False,  # noqa: E712
            )
            .first()
        )
        if not assessment:
            raise ValueError(
                f"Story session {assessment_id} not found or already completed"
            )
        return assessment

    def _update_profile(
        self, player_id: str, dimension: str, assessed_level: int
    ) -> None:
        profile = (
            self.db.query(DevelopmentalProfile)
            .filter(
                DevelopmentalProfile.player_id == player_id,
                DevelopmentalProfile.dimension == dimension,
            )
            .first()
        )
        if not profile:
            profile = DevelopmentalProfile(
                player_id=player_id,
                dimension=dimension,
                level=assessed_level,
                assessed=True,
                last_assessed_at=datetime.utcnow(),
            )
            self.db.add(profile)
        else:
            if assessed_level > profile.level:
                profile.level = assessed_level
            profile.assessed = True
            profile.last_assessed_at = datetime.utcnow()
            profile.updated_at = datetime.utcnow()

    @staticmethod
    def _evaluate_voice(correct_answer: str, spoken_text: str) -> bool:
        """Fuzzy match for voice responses."""
        target = correct_answer.lower().strip()
        spoken = spoken_text.lower().strip()
        if not target or not spoken:
            return False
        if target in spoken or spoken in target:
            return True
        common = sum(1 for a, b in zip(target, spoken) if a == b)
        similarity = common / max(len(target), len(spoken), 1)
        return similarity >= 0.6
