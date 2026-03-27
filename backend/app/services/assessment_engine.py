"""
AssessmentEngine - Gamified initial assessment for Rising Star Kid.

Manages a game-like assessment flow where an animal character guides the child
through activities that secretly evaluate all 6 developmental dimensions.

Key design:
- Each dimension is tested at levels 0, 1, 2 (adaptive: stop if level fails)
- Animal characters provide narrative framing so it feels like play
- ~12-18 activities total, ~30-45 seconds each = 6-10 minutes
- Results set initial levels for all DevelopmentalProfile entries
- Assessment state is persisted to the database (survives server restarts)
"""

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.adaptive import (
    DevelopmentalProfile,
    DevelopmentalDimension,
    AdaptiveTask,
    Assessment,
)
from app.models.player import Player


# -- Animal Characters --

CHARACTERS = [
    {
        "name": "Bunny",
        "emoji": "🐰",
        "greeting": "Hi there! I'm Bunny! Let's play together!",
        "encouragement": [
            "You're doing great!",
            "Wow, nice job!",
            "Keep going, you're amazing!",
        ],
        "celebration": "Yay! We did it together! You're a superstar!",
    },
    {
        "name": "Fox",
        "emoji": "🦊",
        "greeting": "Hello friend! I'm Fox! Want to play a fun game?",
        "encouragement": [
            "That's awesome!",
            "You're so smart!",
            "Great thinking!",
        ],
        "celebration": "We had so much fun! You're incredible!",
    },
    {
        "name": "Panda",
        "emoji": "🐼",
        "greeting": "Hey! I'm Panda! Let's have fun together!",
        "encouragement": [
            "Wonderful!",
            "You're the best!",
            "So proud of you!",
        ],
        "celebration": "That was the best game ever! You're a champion!",
    },
]

# Dimension order for assessment (interleave to keep it varied)
DIMENSION_ORDER = [
    DevelopmentalDimension.OBJECT_COGNITION.value,
    DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
    DevelopmentalDimension.COGNITIVE_LOGIC.value,
    DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
    DevelopmentalDimension.LITERACY.value,
    DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
]

# Narrative intros per dimension
DIMENSION_NARRATIVES = {
    DevelopmentalDimension.OBJECT_COGNITION.value: {
        0: "{name} lost some things! Can you help find them?",
        1: "{name} wants to know what these things are!",
        2: "{name} is sorting toys. Can you help put them in the right group?",
    },
    DevelopmentalDimension.LANGUAGE_COMPREHENSION.value: {
        0: "{name} wants to show you something! Can you point to it?",
        1: "{name} needs your help! Listen carefully!",
        2: "{name} has a little story. Can you help answer?",
    },
    DevelopmentalDimension.COGNITIVE_LOGIC.value: {
        0: "{name} is playing a matching game! Can you find the pairs?",
        1: "{name} needs help putting things in order!",
        2: "{name} is curious - what happens next?",
    },
    DevelopmentalDimension.LANGUAGE_EXPRESSION.value: {
        0: "{name} wants to hear you talk! Can you say this word?",
        1: "{name} found something cool! What is it?",
        2: "{name} wants to chat! Tell {name} about this picture!",
    },
    DevelopmentalDimension.LITERACY.value: {
        0: "{name} found some pictures! Do you know what they are?",
        1: "{name} is learning to read! Can you match the word?",
        2: "{name} wants you to read this word!",
    },
    DevelopmentalDimension.SOCIAL_BEHAVIOR.value: {
        0: "{name} is waving at you! Can you look at {name}?",
        1: "{name} is doing something fun! Can you do it too?",
        2: "It's {name}'s turn, then your turn! Let's take turns!",
    },
}

STORY_INTRO = (
    "{emoji} {greeting}\n\n"
    "{name} needs your help on a fun adventure! "
    "There are games to play and things to find. "
    "Let's go!"
)

MAX_ASSESSMENT_LEVEL = 2  # Only test up to level 2 during assessment


class AssessmentEngine:
    def __init__(self, db: Session):
        self.db = db

    def start_assessment(self, player_id: str) -> dict:
        """Start a new gamified assessment for a player."""
        player = self.db.query(Player).filter(Player.id == player_id).first()
        if not player:
            raise ValueError(f"Player {player_id} not found")

        # Pick a random character
        import random

        character = random.choice(CHARACTERS)

        assessment_id = str(uuid.uuid4())

        # Build activity queue
        activities = self._build_activity_queue()

        # Build initial dimension state
        dimension_state: dict[str, dict] = {}
        for dim in DIMENSION_ORDER:
            dimension_state[dim] = {
                "current_level": 0,
                "results": [],
                "done": False,
                "assessed_level": 0,
            }

        # Persist to database
        assessment = Assessment(
            id=assessment_id,
            player_id=player_id,
            character=character,
            started_at=datetime.utcnow(),
            activities=activities,
            current_index=0,
            dimension_state=dimension_state,
            activity_task_ids={},
        )
        self.db.add(assessment)
        self.db.commit()

        story_intro = STORY_INTRO.format(
            emoji=character["emoji"],
            greeting=character["greeting"],
            name=character["name"],
        )

        return {
            "assessment_id": assessment_id,
            "player_id": player_id,
            "character": {
                "name": character["name"],
                "emoji": character["emoji"],
                "greeting": character["greeting"],
            },
            "story_intro": story_intro,
            "total_activities": len(activities),
        }

    def get_next_activity(self, assessment_id: str) -> Optional[dict]:
        """Get the next activity in the assessment game."""
        assessment = self._get_assessment(assessment_id)
        activities = assessment.activities
        current_index = assessment.current_index

        if current_index >= len(activities):
            return None

        activity = activities[current_index]
        dimension = activity["dimension"]
        level = activity["level"]
        character = assessment.character

        # Get narrative
        dim_narratives = DIMENSION_NARRATIVES.get(dimension, {})
        narrative_template = dim_narratives.get(
            level, "{name} has a challenge for you!"
        )
        narrative = narrative_template.format(name=character["name"])

        # Fetch a task from the database and cache its ID
        task = self._find_assessment_task(dimension, level)

        if not task:
            # Skip this activity if no task available
            assessment.current_index = current_index + 1
            self.db.commit()
            return self.get_next_activity(assessment_id)

        # Cache so process_response uses the same task
        task_ids = dict(assessment.activity_task_ids or {})
        task_ids[str(current_index)] = task.id
        assessment.activity_task_ids = task_ids
        self.db.commit()

        content = task.content or {}

        return {
            "activity_index": current_index,
            "total_activities": len(activities),
            "dimension": dimension,
            "level": level,
            "character": {
                "name": character["name"],
                "emoji": character["emoji"],
            },
            "content": {
                "instruction": content.get("instruction", "Can you do this?"),
                "narrative": narrative,
                "image_hint": content.get("image_hint"),
                "options": content.get("options"),
                "correct_answer": content.get("correct_answer"),
                "target_word": content.get("target_word"),
                "interaction_type": self._get_interaction_type(dimension, level),
            },
            "is_last": current_index >= len(activities) - 1,
        }

    def process_response(
        self,
        assessment_id: str,
        activity_index: int,
        selected_option: Optional[str] = None,
        spoken_text: Optional[str] = None,
        response_time_ms: Optional[int] = None,
        interaction_type: str = "touch",
    ) -> dict:
        """Process a child's response to an assessment activity."""
        assessment = self._get_assessment(assessment_id)
        activities = assessment.activities

        if activity_index >= len(activities):
            raise ValueError("Activity index out of range")

        activity = activities[activity_index]
        dimension = activity["dimension"]
        level = activity["level"]

        # Look up the cached task (same one shown in get_next_activity)
        task_ids = assessment.activity_task_ids or {}
        cached_task_id = task_ids.get(str(activity_index))
        if cached_task_id:
            task = (
                self.db.query(AdaptiveTask)
                .filter(AdaptiveTask.id == cached_task_id)
                .first()
            )
        else:
            task = self._find_assessment_task(dimension, level)
        is_correct = self._evaluate_response(
            task, selected_option, spoken_text, interaction_type
        )

        # Update dimension state (must copy to trigger SQLAlchemy change detection)
        dim_state = dict(assessment.dimension_state)
        dim_entry = dict(dim_state[dimension])
        dim_results = list(dim_entry["results"])
        dim_results.append(
            {
                "level": level,
                "is_correct": is_correct,
                "response_time_ms": response_time_ms,
            }
        )
        dim_entry["results"] = dim_results

        # Update assessed level
        if is_correct and level >= dim_entry["assessed_level"]:
            dim_entry["assessed_level"] = level

        # Adaptive logic: if failed, mark dimension done (don't test higher levels)
        current_index = assessment.current_index
        if not is_correct:
            dim_entry["done"] = True
            # Remove future activities for this dimension at higher levels
            new_activities = [
                a
                for i, a in enumerate(activities)
                if i <= current_index
                or a["dimension"] != dimension
                or a["level"] <= level
            ]
            assessment.activities = new_activities
            activities = new_activities

        dim_state[dimension] = dim_entry
        assessment.dimension_state = dim_state

        # Move to next activity
        assessment.current_index = current_index + 1
        self.db.commit()

        # Generate feedback
        import random

        character = assessment.character
        if is_correct:
            encouragement = random.choice(character["encouragement"])
            feedback = {
                "message": encouragement,
                "emoji": "⭐",
                "is_correct": True,
            }
        else:
            feedback = {
                "message": f"That's okay! {character['name']} thinks you're great!",
                "emoji": "💪",
                "is_correct": False,
            }

        should_continue = assessment.current_index < len(activities)
        progress = assessment.current_index / len(activities) if activities else 1.0

        return {
            "is_correct": is_correct,
            "feedback": feedback,
            "should_continue": should_continue,
            "progress_fraction": round(min(progress, 1.0), 3),
        }

    def complete_assessment(self, assessment_id: str) -> dict:
        """Complete the assessment and update developmental profiles."""
        assessment = self._get_assessment(assessment_id)
        assessment.completed = True
        assessment.completed_at = datetime.utcnow()

        dim_state = assessment.dimension_state
        character = assessment.character

        # Calculate results per dimension
        dimension_results = []
        total_correct = 0
        total_count = 0

        for dim in DIMENSION_ORDER:
            dim_entry = dim_state.get(dim, {})
            results = dim_entry.get("results", [])
            correct = sum(1 for r in results if r["is_correct"])
            count = len(results)
            total_correct += correct
            total_count += count

            # Determine assessed level
            assessed_level = 0
            for r in results:
                if r["is_correct"] and r["level"] >= assessed_level:
                    assessed_level = r["level"]

            # Get dimension metadata
            dim_enum = DevelopmentalDimension(dim)
            dim_info = _get_dimension_display_info(dim_enum)

            dimension_results.append(
                {
                    "dimension": dim,
                    "dimension_label": dim_info["label"],
                    "assessed_level": assessed_level,
                    "max_tested_level": max((r["level"] for r in results), default=0),
                    "correct_count": correct,
                    "total_count": count,
                    "accuracy": round(correct / count, 3) if count > 0 else 0.0,
                    "icon": dim_info["icon"],
                    "color": dim_info["color"],
                }
            )

            # Stage the developmental profile update (no commit yet)
            self._update_profile(assessment.player_id, dim, assessed_level)

        # Commit assessment completion + all profile updates in a single transaction
        self.db.commit()

        overall_level = (
            sum(d["assessed_level"] for d in dimension_results) / len(dimension_results)
            if dimension_results
            else 0.0
        )

        duration = None
        if assessment.completed_at and assessment.started_at:
            duration = int(
                (assessment.completed_at - assessment.started_at).total_seconds()
            )

        return {
            "assessment_id": assessment_id,
            "player_id": assessment.player_id,
            "dimensions": dimension_results,
            "overall_level": round(overall_level, 2),
            "total_activities": total_count,
            "total_correct": total_correct,
            "duration_seconds": duration,
            "character_message": character["celebration"],
        }

    def get_results(self, assessment_id: str) -> Optional[dict]:
        """Get results for a completed or in-progress assessment."""
        assessment = (
            self.db.query(Assessment).filter(Assessment.id == assessment_id).first()
        )
        if not assessment:
            return None

        dim_state = assessment.dimension_state or {}
        dimension_results = []
        for dim in DIMENSION_ORDER:
            dim_entry = dim_state.get(dim, {})
            results = dim_entry.get("results", [])
            correct = sum(1 for r in results if r["is_correct"])
            count = len(results)

            assessed_level = 0
            for r in results:
                if r["is_correct"] and r["level"] >= assessed_level:
                    assessed_level = r["level"]

            dim_enum = DevelopmentalDimension(dim)
            dim_info = _get_dimension_display_info(dim_enum)

            dimension_results.append(
                {
                    "dimension": dim,
                    "dimension_label": dim_info["label"],
                    "assessed_level": assessed_level,
                    "max_tested_level": max((r["level"] for r in results), default=0),
                    "correct_count": correct,
                    "total_count": count,
                    "accuracy": round(correct / count, 3) if count > 0 else 0.0,
                    "icon": dim_info["icon"],
                    "color": dim_info["color"],
                }
            )

        overall_level = (
            sum(d["assessed_level"] for d in dimension_results) / len(dimension_results)
            if dimension_results
            else 0.0
        )

        return {
            "assessment_id": assessment_id,
            "player_id": assessment.player_id,
            "dimensions": dimension_results,
            "overall_level": round(overall_level, 2),
            "completed": assessment.completed,
            "started_at": (
                assessment.started_at.isoformat() if assessment.started_at else None
            ),
            "completed_at": (
                assessment.completed_at.isoformat() if assessment.completed_at else None
            ),
        }

    # -- Internal helpers --

    def _build_activity_queue(self) -> list[dict]:
        """Build the sequence of assessment activities.

        Strategy: For each dimension, plan level 0, 1, 2.
        Interleave dimensions to keep variety.
        """
        activities = []

        # Round 1: all dimensions at level 0
        for dim in DIMENSION_ORDER:
            activities.append({"dimension": dim, "level": 0})

        # Round 2: all dimensions at level 1
        for dim in DIMENSION_ORDER:
            activities.append({"dimension": dim, "level": 1})

        # Round 3: all dimensions at level 2
        for dim in DIMENSION_ORDER:
            activities.append({"dimension": dim, "level": 2})

        return activities

    def _find_assessment_task(
        self, dimension: str, level: int
    ) -> Optional[AdaptiveTask]:
        """Find an assessment task for the given dimension and level."""
        # First try assessment-specific tasks
        task = (
            self.db.query(AdaptiveTask)
            .filter(
                AdaptiveTask.dimension == dimension,
                AdaptiveTask.level == level,
                AdaptiveTask.is_assessment == True,  # noqa: E712
            )
            .order_by(func.random())
            .first()
        )

        if not task:
            # Fall back to any task at this dimension/level
            task = (
                self.db.query(AdaptiveTask)
                .filter(
                    AdaptiveTask.dimension == dimension,
                    AdaptiveTask.level == level,
                )
                .order_by(func.random())
                .first()
            )

        return task

    def _evaluate_response(
        self,
        task: Optional[AdaptiveTask],
        selected_option: Optional[str],
        spoken_text: Optional[str],
        interaction_type: str,
    ) -> bool:
        """Evaluate whether the child's response is correct."""
        if not task:
            return False

        content = task.content or {}
        correct_answer = content.get("correct_answer", "")

        if interaction_type == "voice" and spoken_text is not None:
            # Simple similarity check for speech
            target = correct_answer.lower().strip()
            spoken = spoken_text.lower().strip()
            if not target or not spoken:
                return False
            # Check if spoken text contains the target or is similar enough
            if target in spoken or spoken in target:
                return True
            # Levenshtein-like simple check
            common = sum(1 for a, b in zip(target, spoken) if a == b)
            similarity = common / max(len(target), len(spoken), 1)
            return similarity >= 0.6

        if selected_option is not None:
            return selected_option.lower().strip() == correct_answer.lower().strip()

        return False

    def _get_interaction_type(self, dimension: str, level: int) -> str:
        """Determine the primary interaction type for a dimension/level."""
        voice_dimensions = {
            DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
        }
        if dimension in voice_dimensions:
            return "voice"
        return "touch"

    def _update_profile(
        self, player_id: str, dimension: str, assessed_level: int
    ) -> None:
        """Update developmental profile with assessment results."""
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
            profile.level = assessed_level
            profile.assessed = True
            profile.last_assessed_at = datetime.utcnow()
            profile.updated_at = datetime.utcnow()

    def _get_assessment(self, assessment_id: str) -> Assessment:
        """Get assessment from database or raise error."""
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
                f"Assessment {assessment_id} not found or already completed"
            )
        return assessment


def _get_dimension_display_info(dim: DevelopmentalDimension) -> dict:
    """Get display info for a dimension (label, icon, color)."""
    info = {
        DevelopmentalDimension.OBJECT_COGNITION: {
            "label": "Object Cognition",
            "icon": "cube.fill",
            "color": "orange",
        },
        DevelopmentalDimension.LANGUAGE_EXPRESSION: {
            "label": "Language Expression",
            "icon": "mouth.fill",
            "color": "blue",
        },
        DevelopmentalDimension.LANGUAGE_COMPREHENSION: {
            "label": "Language Comprehension",
            "icon": "ear.fill",
            "color": "green",
        },
        DevelopmentalDimension.LITERACY: {
            "label": "Literacy",
            "icon": "book.fill",
            "color": "purple",
        },
        DevelopmentalDimension.SOCIAL_BEHAVIOR: {
            "label": "Social Behavior",
            "icon": "person.2.fill",
            "color": "pink",
        },
        DevelopmentalDimension.COGNITIVE_LOGIC: {
            "label": "Cognitive Logic",
            "icon": "brain.head.profile",
            "color": "cyan",
        },
    }
    return info.get(dim, {"label": dim.value, "icon": "questionmark", "color": "gray"})
