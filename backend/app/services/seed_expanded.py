"""
Expanded seed tasks loader.

Reads task definitions from JSON resource files and creates AdaptiveTask objects.
This supplements the original seed_tasks.py with additional content covering:
- 8 tasks per level per dimension (vs original 3-4)
- Bilingual content (English + Chinese)
- More diverse object categories and scenarios
- Expanded assessment tasks for levels 3-4
"""

import json
from pathlib import Path

from sqlalchemy.orm import Session

from app.models.adaptive import AdaptiveTask, DevelopmentalDimension, Modality, TaskType

RESOURCES_DIR = Path(__file__).parent.parent / "resources" / "tasks"

# Map dimension strings to enum values
DIMENSION_MAP = {
    "object_cognition": DevelopmentalDimension.OBJECT_COGNITION,
    "language_expression": DevelopmentalDimension.LANGUAGE_EXPRESSION,
    "language_comprehension": DevelopmentalDimension.LANGUAGE_COMPREHENSION,
    "literacy": DevelopmentalDimension.LITERACY,
    "social_behavior": DevelopmentalDimension.SOCIAL_BEHAVIOR,
    "cognitive_logic": DevelopmentalDimension.COGNITIVE_LOGIC,
}

# Map task type strings to enum values
TASK_TYPE_MAP = {t.value: t for t in TaskType}

# Default modalities per task type
DEFAULT_MODALITIES = {
    "match": [Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
    "identify": [Modality.TOUCH.value, Modality.VOICE.value],
    "classify": [Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
    "function": [Modality.TOUCH.value, Modality.VOICE.value],
    "abstract": [Modality.TOUCH.value, Modality.VOICE.value, Modality.TEXT.value],
    "imitate": [Modality.VOICE.value],
    "name_object": [Modality.VOICE.value, Modality.IMAGE_EXCHANGE.value],
    "describe": [Modality.VOICE.value, Modality.IMAGE_EXCHANGE.value],
    "build_sentence": [Modality.TOUCH.value, Modality.TEXT.value],
    "conversation": [Modality.VOICE.value],
    "point_to": [Modality.TOUCH.value],
    "follow_instruction": [Modality.TOUCH.value, Modality.VOICE.value],
    "story_comprehension": [Modality.TOUCH.value, Modality.VOICE.value],
    "infer_meaning": [Modality.TOUCH.value, Modality.VOICE.value],
    "recognize_image": [Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
    "match_word_image": [Modality.TOUCH.value, Modality.TEXT.value],
    "read_word": [Modality.VOICE.value, Modality.TEXT.value],
    "read_sentence": [Modality.VOICE.value, Modality.TEXT.value],
    "read_passage": [Modality.VOICE.value, Modality.TEXT.value, Modality.TOUCH.value],
    "attend": [Modality.TOUCH.value],
    "imitate_action": [Modality.TOUCH.value],
    "turn_take": [Modality.TOUCH.value],
    "joint_attention": [Modality.TOUCH.value, Modality.VOICE.value],
    "initiate": [Modality.TOUCH.value, Modality.VOICE.value],
    "pair": [Modality.TOUCH.value],
    "sort": [Modality.TOUCH.value],
    "cause_effect": [Modality.TOUCH.value, Modality.VOICE.value],
    "sequence_order": [Modality.TOUCH.value],
    "reason": [Modality.TOUCH.value, Modality.VOICE.value, Modality.TEXT.value],
    "say_word": [Modality.VOICE.value],
    "find_object": [Modality.TOUCH.value],
}


def _build_content(task_type: str, task_data: dict) -> dict:
    """Build task content dict from JSON task data, matching existing format."""
    content = {}

    # Add instruction fields (bilingual)
    if "instruction" in task_data:
        content["instruction_audio"] = task_data["instruction"]
        content["instruction_text"] = task_data["instruction"]
        if "instruction_zh" in task_data:
            content["instruction_zh"] = task_data["instruction_zh"]

    # Copy all fields except meta fields
    skip_keys = {"instruction", "instruction_zh"}
    for key, value in task_data.items():
        if key not in skip_keys:
            content[key] = value

    return content


def _load_dimension_tasks(db: Session, json_path: Path) -> int:
    """Load expanded tasks from a dimension JSON file."""
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    dimension_str = data["dimension"]
    dimension_enum = DIMENSION_MAP.get(dimension_str)
    if not dimension_enum:
        return 0

    # Check if expanded tasks already exist for this dimension
    # Query specifically for tasks with the expanded_v1 source marker
    expanded_exists = (
        db.query(AdaptiveTask)
        .filter(
            AdaptiveTask.dimension == dimension_enum.value,
            AdaptiveTask.is_assessment == False,  # noqa: E712
            AdaptiveTask.metadata_info.isnot(None),
        )
        .all()
    )
    for task in expanded_exists:
        if task.metadata_info and task.metadata_info.get("source") == "expanded_v1":
            return 0

    tasks = []
    levels = data.get("levels", {})

    for level_str, level_data in levels.items():
        level = int(level_str)
        task_type_str = level_data.get("task_type", "")
        task_type_enum = TASK_TYPE_MAP.get(task_type_str)
        if not task_type_enum:
            continue

        modalities = DEFAULT_MODALITIES.get(task_type_str, [Modality.TOUCH.value])

        for task_data in level_data.get("tasks", []):
            content = _build_content(task_type_str, task_data)

            task = AdaptiveTask(
                dimension=dimension_enum.value,
                level=level,
                task_type=task_type_enum.value,
                modalities=modalities,
                content=content,
                metadata_info={"source": "expanded_v1", "bilingual": True},
                is_assessment=False,
            )
            tasks.append(task)

    for task in tasks:
        db.add(task)

    if tasks:
        db.commit()

    return len(tasks)


def _load_assessment_tasks(db: Session) -> int:
    """Load expanded assessment tasks from JSON."""
    json_path = RESOURCES_DIR / "assessment_expanded.json"
    if not json_path.exists():
        return 0

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Check if expanded assessment tasks already exist
    existing_assessments = (
        db.query(AdaptiveTask)
        .filter(
            AdaptiveTask.is_assessment == True,  # noqa: E712
            AdaptiveTask.metadata_info.isnot(None),
        )
        .all()
    )
    for task in existing_assessments:
        if task.metadata_info and task.metadata_info.get("source") == "expanded_v1":
            return 0

    tasks = []
    dimensions = data.get("dimensions", {})

    for dim_str, levels in dimensions.items():
        dimension_enum = DIMENSION_MAP.get(dim_str)
        if not dimension_enum:
            continue

        for level_str, level_tasks in levels.items():
            level = int(level_str)

            for task_data in level_tasks:
                task_type_str = task_data.get("task_type", "")
                task_type_enum = TASK_TYPE_MAP.get(task_type_str)
                if not task_type_enum:
                    continue

                modalities = task_data.get(
                    "modalities",
                    DEFAULT_MODALITIES.get(task_type_str, [Modality.TOUCH.value]),
                )

                content = task_data.get("content", {})

                task = AdaptiveTask(
                    dimension=dimension_enum.value,
                    level=level,
                    task_type=task_type_enum.value,
                    modalities=modalities,
                    content=content,
                    metadata_info={"source": "expanded_v1", "assessment": True},
                    is_assessment=True,
                )
                tasks.append(task)

    for task in tasks:
        db.add(task)

    if tasks:
        db.commit()

    return len(tasks)


def seed_expanded_tasks(db: Session) -> dict:
    """Seed all expanded tasks from JSON resource files.

    Returns dict with counts per dimension + assessment.
    """
    results = {}

    # Load expanded practice tasks for each dimension
    dimension_files = {
        "object_cognition": "object_cognition_expanded.json",
        "language_expression": "language_expression_expanded.json",
        "language_comprehension": "language_comprehension_expanded.json",
        "literacy": "literacy_expanded.json",
        "social_behavior": "social_behavior_expanded.json",
        "cognitive_logic": "cognitive_logic_expanded.json",
    }

    for dim_name, filename in dimension_files.items():
        json_path = RESOURCES_DIR / filename
        if json_path.exists():
            count = _load_dimension_tasks(db, json_path)
            results[f"{dim_name}_expanded"] = count

    # Load expanded assessment tasks
    results["assessment_expanded"] = _load_assessment_tasks(db)

    return results


def get_expanded_task_stats() -> dict:
    """Get statistics about available expanded tasks (from JSON files, no DB needed)."""
    stats = {}

    dimension_files = [
        "object_cognition_expanded.json",
        "language_expression_expanded.json",
        "language_comprehension_expanded.json",
        "literacy_expanded.json",
        "social_behavior_expanded.json",
        "cognitive_logic_expanded.json",
    ]

    total_practice = 0
    for filename in dimension_files:
        json_path = RESOURCES_DIR / filename
        if json_path.exists():
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            dim_name = data["dimension"]
            task_count = 0
            for level_data in data.get("levels", {}).values():
                task_count += len(level_data.get("tasks", []))
            stats[dim_name] = task_count
            total_practice += task_count

    # Assessment stats
    assessment_path = RESOURCES_DIR / "assessment_expanded.json"
    if assessment_path.exists():
        with open(assessment_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        assessment_count = 0
        for levels in data.get("dimensions", {}).values():
            for level_tasks in levels.values():
                assessment_count += len(level_tasks)
        stats["assessment"] = assessment_count
        total_practice += assessment_count

    stats["total"] = total_practice
    return stats
