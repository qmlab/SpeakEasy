"""
Expanded seed tasks loader.

Reads task definitions from JSON resource files and creates AdaptiveTask objects.
This supplements the original seed_tasks.py with additional content covering:
- Research-based 300-question autism neurodevelopmental assessment bank
- 10 difficulty levels (0-9) per dimension
- Bilingual content (English + Chinese)
- Scaffolding hints and distractors for every question
- Mapped from 5 research domains to 6 app dimensions
"""

import json
import random
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
    """Build task content dict from JSON task data, matching existing format.

    For cognitive task types (pair, sort, cause_effect, sequence_order) the raw
    JSON fields are transformed into the standard ``options`` /
    ``correct_answer`` format that the iOS client already understands so that
    interactive option buttons are rendered instead of the generic "Got It!"
    fallback.
    """
    content = {}

    # Add instruction fields (bilingual)
    if "instruction" in task_data:
        content["instruction_audio"] = task_data["instruction"]
        content["instruction_text"] = task_data["instruction"]
        if "instruction_zh" in task_data:
            content["instruction_zh"] = task_data["instruction_zh"]

    # ------------------------------------------------------------------
    # Cognitive task type transformations
    # ------------------------------------------------------------------
    if task_type == "pair":
        # Pair tasks: "Which goes with X?" — show pair[1] + distractors as
        # options so the child picks the correct match.
        pair = task_data.get("pair", [])
        distractors = task_data.get("distractors", [])
        if len(pair) >= 2:
            # Rewrite instruction to reference the first item
            content["instruction_text"] = f"Which goes with {pair[0]}?"
            content["instruction_audio"] = content["instruction_text"]
            pair_zh = task_data.get("pair_zh", [])
            distractors_zh = task_data.get("distractors_zh", [])
            if len(pair_zh) >= 2:
                content["instruction_zh"] = f"哪个和{pair_zh[0]}是一对？"

            # The first pair item becomes the target shown as image
            content["target_word"] = pair[0]
            content["image_hint"] = task_data.get(
                "image_hint", pair[0].lower().replace(" ", "_")
            )

            # Build shuffled options: correct answer + distractors
            opts = [pair[1]] + list(distractors)
            # Shuffle EN and ZH options with the same permutation
            if len(pair_zh) >= 2 and len(distractors_zh) >= len(distractors):
                opts_zh = [pair_zh[1]] + list(distractors_zh)
                combined = list(zip(opts, opts_zh))
                random.shuffle(combined)
                opts, opts_zh = zip(*combined) if combined else ([], [])
                content["options"] = list(opts)
                content["options_zh"] = list(opts_zh)
            else:
                random.shuffle(opts)
                content["options"] = opts
            content["correct_answer"] = pair[1]
        else:
            # Fallback: copy raw fields
            for key, value in task_data.items():
                if key not in {"instruction", "instruction_zh"}:
                    content[key] = value

    elif task_type == "cause_effect":
        # Cause/effect: options already present, just map correct_effect →
        # correct_answer so iOS can check the answer.
        content["correct_answer"] = task_data.get("correct_effect", "")
        options = list(task_data.get("options", []))
        options_zh_raw = task_data.get("options_zh", [])
        if options_zh_raw and len(options_zh_raw) >= len(options):
            combined = list(zip(options, options_zh_raw))
            random.shuffle(combined)
            options, options_zh = zip(*combined) if combined else ([], [])
            content["options"] = list(options)
            content["options_zh"] = list(options_zh)
        else:
            random.shuffle(options)
            content["options"] = options
            if "options_zh" in task_data:
                content["options_zh"] = task_data["options_zh"]
        if "correct_effect_zh" in task_data:
            content["correct_answer_zh"] = task_data["correct_effect_zh"]
        if "image_hint" in task_data:
            content["image_hint"] = task_data["image_hint"]

    elif task_type == "sort":
        # Sort tasks: "Which comes first / next?" — present items as options
        # with the first item in correct order as the answer.
        items = task_data.get("items", [])
        correct_order = task_data.get("correct_order", [])
        if items and correct_order:
            first_idx = correct_order[0]
            content["correct_answer"] = items[first_idx]
            shuffled = list(items)
            random.shuffle(shuffled)
            content["options"] = shuffled
            content["items"] = items
        if "items_zh" in task_data:
            content["items_zh"] = task_data["items_zh"]
        if "image_hint" in task_data:
            content["image_hint"] = task_data["image_hint"]

    elif task_type == "sequence_order":
        # Sequence tasks: "What comes first?" — present steps as options with
        # the first step as the correct answer.
        steps = task_data.get("steps", [])
        correct_order = task_data.get("correct_order", [])
        if steps and correct_order:
            first_idx = correct_order[0]
            content["correct_answer"] = steps[first_idx]
            shuffled = list(steps)
            random.shuffle(shuffled)
            content["options"] = shuffled
            content["items"] = steps
            if "story_title" in task_data:
                content["instruction_text"] = (
                    f"What comes first? {task_data['story_title']}"
                )
                content["instruction_audio"] = content["instruction_text"]
            if "story_title_zh" in task_data:
                content["instruction_zh"] = (
                    f"什么是第一步？{task_data['story_title_zh']}"
                )
        if "steps_zh" in task_data:
            content["items_zh"] = task_data["steps_zh"]

    elif task_type == "describe":
        # Describe tasks: child sees an image and says what they see.
        # Map target_phrase → target_word so iOS voice input can evaluate.
        skip_keys = {"instruction", "instruction_zh"}
        for key, value in task_data.items():
            if key not in skip_keys:
                content[key] = value
        # Derive target_word from target_phrase so speech recognition works
        tp = task_data.get("target_phrase", "")
        if tp and "target_word" not in content:
            content["target_word"] = tp
        # Also support legacy target_phrases array
        if not tp:
            tps = task_data.get("target_phrases", [])
            if tps and "target_word" not in content:
                content["target_word"] = tps[0]
        # Derive image_hint from scene description for legacy tasks
        if "image_hint" not in content and "scene" in task_data:
            scene = task_data["scene"].lower()
            for word in ["ball", "bus", "cat", "dog", "banana", "tree"]:
                if word in scene:
                    content["image_hint"] = word
                    break

    elif task_type == "build_sentence":
        # Sentence building: child arranges/says a sentence.
        # Map correct_sentence → target_word for voice evaluation.
        skip_keys = {"instruction", "instruction_zh"}
        for key, value in task_data.items():
            if key not in skip_keys:
                content[key] = value
        cs = task_data.get("correct_sentence") or task_data.get("target_sentence", "")
        if cs and "target_word" not in content:
            content["target_word"] = cs
        # Populate options + items from words array so the iOS
        # ordering UI shows word cards instead of just an image.
        words = task_data.get("words") or task_data.get("word_cards")
        if words and not content.get("options"):
            import hashlib
            import random as _rand

            seed = int(hashlib.md5(" ".join(words).encode()).hexdigest(), 16) % (2**32)
            shuffled = list(words)
            _local_rand = _rand.Random(seed)
            _local_rand.shuffle(shuffled)
            while shuffled == list(words) and len(words) > 1 and len(set(words)) > 1:
                _local_rand.shuffle(shuffled)
            content["options"] = shuffled
            if not content.get("items"):
                content["items"] = list(words)
            if cs and not content.get("correct_answer"):
                content["correct_answer"] = cs
        # Add flexible acceptance threshold for voice evaluation
        if "accept_threshold" not in content:
            content["accept_threshold"] = 0.3

    elif task_type == "conversation":
        # Conversation: open-ended response evaluated by AI.
        # No fixed target_word — the LLM judges whether the child's
        # answer is a reasonable response to the question.
        skip_keys = {"instruction", "instruction_zh"}
        for key, value in task_data.items():
            if key not in skip_keys:
                content[key] = value
        # Mark as open-ended so iOS routes to AI evaluation
        content["open_ended"] = True
        # Add flexible acceptance threshold for keyword fallback
        if "accept_threshold" not in content:
            content["accept_threshold"] = 0.3

    else:
        # All other task types: copy fields verbatim (existing behaviour)
        skip_keys = {"instruction", "instruction_zh"}
        for key, value in task_data.items():
            if key not in skip_keys:
                content[key] = value

    # ------------------------------------------------------------------
    # Auto-detect ordering / sequential-tap tasks
    # ------------------------------------------------------------------
    # Tasks that have a `steps` field contain the correct ordering.
    # Ensure `items` is populated (iOS uses this to trigger the ordering UI)
    # and that `options` are the shuffled version the child picks from.
    if "steps" in task_data and task_data["steps"]:
        steps = task_data["steps"]
        if "items" not in content:
            content["items"] = list(steps)  # correct order
        if "options" not in content or not content["options"]:
            shuffled = list(steps)
            random.shuffle(shuffled)
            # Avoid presenting options in the already-correct order
            while shuffled == list(steps) and len(steps) > 1 and len(set(steps)) > 1:
                random.shuffle(shuffled)
            content["options"] = shuffled
        if "correct_answer" not in content or not content["correct_answer"]:
            content["correct_answer"] = steps[0]

    # Memory-sequence tasks: instructions like "Remember: 3, 7. Tap them in
    # order." currently have a single composite option ("3 then 7").  Break
    # them into individual tappable items so the ordering UI can be used.
    inst_lower = (task_data.get("instruction") or "").lower()
    if (
        "tap them in order" in inst_lower or "tap in order" in inst_lower
    ) and "items" not in content:
        # Try to extract individual items from instruction
        # Pattern: "Remember: 3, 7. Tap them in order."
        import re

        match = re.search(
            r"remember[^:]*:\s*(.+?)\.", task_data.get("instruction", ""), re.IGNORECASE
        )
        if match:
            raw = match.group(1)
            items = [s.strip() for s in raw.split(",") if s.strip()]
            if len(items) >= 2:
                content["items"] = list(items)  # correct order
                shuffled = list(items)
                random.shuffle(shuffled)
                while shuffled == list(items) and len(items) > 1 and len(set(items)) > 1:
                    random.shuffle(shuffled)
                content["options"] = shuffled
                content["correct_answer"] = items[0]

    return content


def _load_dimension_tasks(db: Session, json_path: Path, force: bool = False) -> int:
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
    existing_expanded = [
        t
        for t in expanded_exists
        if t.metadata_info and t.metadata_info.get("source") == "expanded_v1"
    ]
    if existing_expanded and not force:
        return 0

    # If force re-seed, delete old expanded tasks first
    if existing_expanded and force:
        for t in existing_expanded:
            db.delete(t)
        db.flush()

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

            # Preserve research metadata
            meta = {
                "source": "expanded_v1",
                "bilingual": True,
                "version": data.get("version", "research_v2"),
            }
            if "question_id" in task_data:
                meta["question_id"] = task_data["question_id"]
            if "source_test" in task_data:
                meta["source_test"] = task_data["source_test"]
            if "sub_domain" in task_data:
                meta["sub_domain"] = task_data["sub_domain"]

            task = AdaptiveTask(
                dimension=dimension_enum.value,
                level=level,
                task_type=task_type_enum.value,
                modalities=modalities,
                content=content,
                metadata_info=meta,
                is_assessment=False,
            )
            tasks.append(task)

    for task in tasks:
        db.add(task)

    if tasks:
        db.commit()

    return len(tasks)


def _load_assessment_tasks(db: Session, force: bool = False) -> int:
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
    existing_expanded = [
        t
        for t in existing_assessments
        if t.metadata_info and t.metadata_info.get("source") == "expanded_v1"
    ]
    if existing_expanded and not force:
        return 0

    if existing_expanded and force:
        for t in existing_expanded:
            db.delete(t)
        db.flush()

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


def seed_expanded_tasks(db: Session, force: bool = False) -> dict:
    """Seed all expanded tasks from JSON resource files.

    Args:
        db: Database session.
        force: If True, delete existing expanded tasks and re-seed.

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
            count = _load_dimension_tasks(db, json_path, force=force)
            results[f"{dim_name}_expanded"] = count

    # Load expanded assessment tasks
    results["assessment_expanded"] = _load_assessment_tasks(db, force=force)

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
