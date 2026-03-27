"""
Seed tasks for the adaptive learning system.

Phase 1: Object Cognition dimension with 5 levels (0-4).

Level 0: Simple matching - match identical objects
Level 1: Identification - identify named objects from choices
Level 2: Classification - group objects by category
Level 3: Function understanding - what is this object used for?
Level 4: Abstract association - relate objects by abstract properties
"""

from sqlalchemy.orm import Session
from app.models.adaptive import AdaptiveTask, DevelopmentalDimension, TaskType, Modality


def seed_object_cognition_tasks(db: Session) -> int:
    """Seed object cognition tasks. Returns count of tasks created."""
    existing = db.query(AdaptiveTask).filter(
        AdaptiveTask.dimension == DevelopmentalDimension.OBJECT_COGNITION.value
    ).count()

    if existing > 0:
        return 0

    tasks = []

    # ---- Level 0: Simple Matching ----
    tasks.extend([
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=0,
            task_type=TaskType.MATCH.value,
            modalities=[Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
            content={
                "instruction_audio": "Find the same one!",
                "instruction_text": "Find the same one!",
                "target": {"name": "Dog", "category": "Animals"},
                "choices": [
                    {"name": "Dog", "category": "Animals", "is_correct": True},
                    {"name": "Cat", "category": "Animals", "is_correct": False},
                    {"name": "Ball", "category": "Toys", "is_correct": False},
                ],
            },
            is_assessment=True,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=0,
            task_type=TaskType.MATCH.value,
            modalities=[Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
            content={
                "instruction_audio": "Find the same one!",
                "instruction_text": "Find the same one!",
                "target": {"name": "Apple", "category": "Food"},
                "choices": [
                    {"name": "Apple", "category": "Food", "is_correct": True},
                    {"name": "Ball", "category": "Toys", "is_correct": False},
                    {"name": "Car", "category": "Vehicles", "is_correct": False},
                ],
            },
            is_assessment=False,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=0,
            task_type=TaskType.MATCH.value,
            modalities=[Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
            content={
                "instruction_audio": "Find the same one!",
                "instruction_text": "Find the same one!",
                "target": {"name": "Car", "category": "Vehicles"},
                "choices": [
                    {"name": "Banana", "category": "Food", "is_correct": False},
                    {"name": "Car", "category": "Vehicles", "is_correct": True},
                    {"name": "Hat", "category": "Clothing", "is_correct": False},
                ],
            },
            is_assessment=False,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=0,
            task_type=TaskType.MATCH.value,
            modalities=[Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
            content={
                "instruction_audio": "Find the same one!",
                "instruction_text": "Find the same one!",
                "target": {"name": "Cup", "category": "Household"},
                "choices": [
                    {"name": "Shoe", "category": "Clothing", "is_correct": False},
                    {"name": "Tree", "category": "Nature", "is_correct": False},
                    {"name": "Cup", "category": "Household", "is_correct": True},
                ],
            },
            is_assessment=False,
        ),
    ])

    # ---- Level 1: Identification ----
    tasks.extend([
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=1,
            task_type=TaskType.IDENTIFY.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value],
            content={
                "instruction_audio": "Where is the dog?",
                "instruction_text": "Where is the dog?",
                "target_name": "Dog",
                "choices": [
                    {"name": "Dog", "category": "Animals", "is_correct": True},
                    {"name": "Cat", "category": "Animals", "is_correct": False},
                    {"name": "Bird", "category": "Animals", "is_correct": False},
                    {"name": "Fish", "category": "Animals", "is_correct": False},
                ],
            },
            is_assessment=True,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=1,
            task_type=TaskType.IDENTIFY.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value],
            content={
                "instruction_audio": "Where is the banana?",
                "instruction_text": "Where is the banana?",
                "target_name": "Banana",
                "choices": [
                    {"name": "Apple", "category": "Food", "is_correct": False},
                    {"name": "Banana", "category": "Food", "is_correct": True},
                    {"name": "Orange", "category": "Food", "is_correct": False},
                    {"name": "Milk", "category": "Food", "is_correct": False},
                ],
            },
            is_assessment=False,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=1,
            task_type=TaskType.IDENTIFY.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value],
            content={
                "instruction_audio": "Where is the chair?",
                "instruction_text": "Where is the chair?",
                "target_name": "Chair",
                "choices": [
                    {"name": "Table", "category": "Household", "is_correct": False},
                    {"name": "Lamp", "category": "Household", "is_correct": False},
                    {"name": "Chair", "category": "Household", "is_correct": True},
                    {"name": "Bed", "category": "Household", "is_correct": False},
                ],
            },
            is_assessment=False,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=1,
            task_type=TaskType.SAY_WORD.value,
            modalities=[Modality.VOICE.value],
            content={
                "instruction_audio": "What is this? Say the word!",
                "instruction_text": "What is this? Say the word!",
                "target_name": "Cat",
                "target_category": "Animals",
                "accept_threshold": 0.6,
            },
            is_assessment=False,
        ),
    ])

    # ---- Level 2: Classification ----
    tasks.extend([
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=2,
            task_type=TaskType.CLASSIFY.value,
            modalities=[Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
            content={
                "instruction_audio": "Which ones are animals?",
                "instruction_text": "Which ones are animals?",
                "target_category": "Animals",
                "items": [
                    {"name": "Dog", "category": "Animals", "is_target": True},
                    {"name": "Cat", "category": "Animals", "is_target": True},
                    {"name": "Apple", "category": "Food", "is_target": False},
                    {"name": "Car", "category": "Vehicles", "is_target": False},
                    {"name": "Bird", "category": "Animals", "is_target": True},
                    {"name": "Chair", "category": "Household", "is_target": False},
                ],
            },
            is_assessment=True,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=2,
            task_type=TaskType.CLASSIFY.value,
            modalities=[Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
            content={
                "instruction_audio": "Which ones are food?",
                "instruction_text": "Which ones are food?",
                "target_category": "Food",
                "items": [
                    {"name": "Apple", "category": "Food", "is_target": True},
                    {"name": "Dog", "category": "Animals", "is_target": False},
                    {"name": "Banana", "category": "Food", "is_target": True},
                    {"name": "Shirt", "category": "Clothing", "is_target": False},
                    {"name": "Milk", "category": "Food", "is_target": True},
                    {"name": "Ball", "category": "Toys", "is_target": False},
                ],
            },
            is_assessment=False,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=2,
            task_type=TaskType.CLASSIFY.value,
            modalities=[Modality.TOUCH.value, Modality.IMAGE_EXCHANGE.value],
            content={
                "instruction_audio": "Which ones can you ride?",
                "instruction_text": "Which ones can you ride?",
                "target_category": "Vehicles",
                "items": [
                    {"name": "Car", "category": "Vehicles", "is_target": True},
                    {"name": "Tree", "category": "Nature", "is_target": False},
                    {"name": "Bus", "category": "Vehicles", "is_target": True},
                    {"name": "Cup", "category": "Household", "is_target": False},
                    {"name": "Bicycle", "category": "Vehicles", "is_target": True},
                    {"name": "Hat", "category": "Clothing", "is_target": False},
                ],
            },
            is_assessment=False,
        ),
    ])

    # ---- Level 3: Function Understanding ----
    tasks.extend([
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=3,
            task_type=TaskType.FUNCTION.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value],
            content={
                "instruction_audio": "What do you use to drink water?",
                "instruction_text": "What do you use to drink water?",
                "function": "drinking",
                "choices": [
                    {"name": "Cup", "category": "Household", "is_correct": True},
                    {"name": "Spoon", "category": "Household", "is_correct": False},
                    {"name": "Plate", "category": "Household", "is_correct": False},
                    {"name": "Chair", "category": "Household", "is_correct": False},
                ],
            },
            is_assessment=True,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=3,
            task_type=TaskType.FUNCTION.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value],
            content={
                "instruction_audio": "What do you use to eat soup?",
                "instruction_text": "What do you use to eat soup?",
                "function": "eating_soup",
                "choices": [
                    {"name": "Spoon", "category": "Household", "is_correct": True},
                    {"name": "Cup", "category": "Household", "is_correct": False},
                    {"name": "Plate", "category": "Household", "is_correct": False},
                    {"name": "Lamp", "category": "Household", "is_correct": False},
                ],
            },
            is_assessment=False,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=3,
            task_type=TaskType.FUNCTION.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value],
            content={
                "instruction_audio": "What keeps you warm when it's cold?",
                "instruction_text": "What keeps you warm when it's cold?",
                "function": "warmth",
                "choices": [
                    {"name": "Jacket", "category": "Clothing", "is_correct": True},
                    {"name": "Shorts", "category": "Clothing", "is_correct": False},
                    {"name": "Socks", "category": "Clothing", "is_correct": False},
                    {"name": "Hat", "category": "Clothing", "is_correct": False},
                ],
            },
            is_assessment=False,
        ),
    ])

    # ---- Level 4: Abstract Association ----
    tasks.extend([
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=4,
            task_type=TaskType.ABSTRACT.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value, Modality.TEXT.value],
            content={
                "instruction_audio": "Which one does NOT belong?",
                "instruction_text": "Which one does NOT belong?",
                "concept": "odd_one_out",
                "items": [
                    {"name": "Dog", "category": "Animals", "is_odd": False},
                    {"name": "Cat", "category": "Animals", "is_odd": False},
                    {"name": "Car", "category": "Vehicles", "is_odd": True},
                    {"name": "Bird", "category": "Animals", "is_odd": False},
                ],
            },
            is_assessment=True,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=4,
            task_type=TaskType.ABSTRACT.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value, Modality.TEXT.value],
            content={
                "instruction_audio": "Which two things go together?",
                "instruction_text": "Which two things go together?",
                "concept": "association",
                "items": [
                    {"name": "Cup", "category": "Household", "pair": "A"},
                    {"name": "Water", "category": "Food", "pair": "A"},
                    {"name": "Dog", "category": "Animals", "pair": None},
                    {"name": "Car", "category": "Vehicles", "pair": None},
                ],
                "correct_pair": "A",
            },
            is_assessment=False,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=4,
            task_type=TaskType.ABSTRACT.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value, Modality.TEXT.value],
            content={
                "instruction_audio": "What comes next? Sun, Moon, ...",
                "instruction_text": "What comes next? Sun, Moon, ...",
                "concept": "pattern",
                "sequence": [
                    {"name": "Sun", "category": "Nature"},
                    {"name": "Moon", "category": "Nature"},
                ],
                "choices": [
                    {"name": "Star", "category": "Nature", "is_correct": True},
                    {"name": "Dog", "category": "Animals", "is_correct": False},
                    {"name": "Car", "category": "Vehicles", "is_correct": False},
                ],
            },
            is_assessment=False,
        ),
    ])

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def seed_all_tasks(db: Session) -> dict:
    """Seed all task dimensions. Returns counts per dimension."""
    results = {}
    results["object_cognition"] = seed_object_cognition_tasks(db)
    # Future phases will add more dimensions here
    return results
