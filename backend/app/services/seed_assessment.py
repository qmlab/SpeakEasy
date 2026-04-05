"""
Seed assessment-specific tasks for the gamified initial assessment.

These tasks are marked with is_assessment=True and cover levels 0-2
for all 6 developmental dimensions. They use simpler, more accessible
content suitable for initial evaluation.
"""

from sqlalchemy.orm import Session
from app.models.adaptive import AdaptiveTask, DevelopmentalDimension, TaskType, Modality


def seed_assessment_tasks(db: Session) -> int:
    """Seed assessment-specific tasks. Returns count of tasks created."""
    existing_tasks = (
        db.query(AdaptiveTask)
        .filter(AdaptiveTask.is_assessment == True)  # noqa: E712
        .all()
    )

    if existing_tasks:
        # Verify content format — assessment tasks must use "instruction"
        # key (not "instruction_audio" from regular seeds). If stale
        # tasks exist with the wrong format, delete them and re-seed.
        sample = existing_tasks[0]
        content = sample.content or {}
        if "instruction" in content and "correct_answer" in content:
            return 0  # Already seeded with correct format

        # Stale assessment tasks with wrong content format — remove them
        for task in existing_tasks:
            db.delete(task)
        db.commit()

    tasks = []

    # ================================================================
    # OBJECT COGNITION - Assessment Tasks (Levels 0-2)
    # ================================================================

    # Level 0: Simple matching
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
                level=0,
                task_type=TaskType.MATCH.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Find the same one!",
                    "correct_answer": "Apple",
                    "options": ["Apple", "Car", "Dog"],
                    "image_hint": "apple",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
                level=0,
                task_type=TaskType.MATCH.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Which one is the same?",
                    "correct_answer": "Ball",
                    "options": ["Ball", "Cup", "Hat"],
                    "image_hint": "ball",
                },
            ),
        ]
    )

    # Level 1: Identification (includes image recognition)
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
                level=1,
                task_type=TaskType.RECOGNIZE_IMAGE.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "What is in this picture?",
                    "correct_answer": "Sun",
                    "options": ["Sun", "Moon", "Cloud"],
                    "image_hint": "sun",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
                level=1,
                task_type=TaskType.RECOGNIZE_IMAGE.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "What do you see?",
                    "correct_answer": "House",
                    "options": ["House", "Car", "Tree"],
                    "image_hint": "house",
                },
            ),
        ]
    )

    # Level 2: Classification
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
                level=2,
                task_type=TaskType.CLASSIFY.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Which one is a fruit?",
                    "correct_answer": "Apple",
                    "options": ["Apple", "Car", "Chair"],
                    "image_hint": "fruit",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
                level=2,
                task_type=TaskType.CLASSIFY.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Which one is an animal?",
                    "correct_answer": "Dog",
                    "options": ["Dog", "Table", "Book"],
                    "image_hint": "animals",
                },
            ),
        ]
    )

    # ================================================================
    # LANGUAGE EXPRESSION - Assessment Tasks (Levels 0-2)
    # ================================================================

    # Level 0: Imitation
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=0,
                task_type=TaskType.IMITATE.value,
                modalities=[Modality.VOICE.value],
                is_assessment=True,
                content={
                    "instruction": "Can you say this word?",
                    "correct_answer": "ball",
                    "target_word": "Ball",
                    "image_hint": "ball",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=0,
                task_type=TaskType.IMITATE.value,
                modalities=[Modality.VOICE.value],
                is_assessment=True,
                content={
                    "instruction": "Say this word!",
                    "correct_answer": "cat",
                    "target_word": "Cat",
                    "image_hint": "cat",
                },
            ),
        ]
    )

    # Level 1: Naming objects
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=1,
                task_type=TaskType.NAME_OBJECT.value,
                modalities=[Modality.VOICE.value],
                is_assessment=True,
                content={
                    "instruction": "What is this?",
                    "correct_answer": "apple",
                    "image_hint": "apple",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=1,
                task_type=TaskType.NAME_OBJECT.value,
                modalities=[Modality.VOICE.value],
                is_assessment=True,
                content={
                    "instruction": "What do you see?",
                    "correct_answer": "dog",
                    "image_hint": "dog",
                },
            ),
        ]
    )

    # Level 2: Describing
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=2,
                task_type=TaskType.DESCRIBE.value,
                modalities=[Modality.VOICE.value],
                is_assessment=True,
                content={
                    "instruction": "Tell me about this picture!",
                    "correct_answer": "red",
                    "image_hint": "red_apple",
                    "target_word": "red apple",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=2,
                task_type=TaskType.DESCRIBE.value,
                modalities=[Modality.VOICE.value],
                is_assessment=True,
                content={
                    "instruction": "What color is this?",
                    "correct_answer": "blue",
                    "image_hint": "blue_sky",
                    "target_word": "blue sky",
                },
            ),
        ]
    )

    # ================================================================
    # LANGUAGE COMPREHENSION - Assessment Tasks (Levels 0-2)
    # ================================================================

    # Level 0: Point to
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=0,
                task_type=TaskType.POINT_TO.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Touch the star!",
                    "correct_answer": "Star",
                    "options": ["Star", "Moon", "Sun"],
                    "image_hint": "star",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=0,
                task_type=TaskType.POINT_TO.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Where is the flower?",
                    "correct_answer": "Flower",
                    "options": ["Flower", "Tree", "Rock"],
                    "image_hint": "flower",
                },
            ),
        ]
    )

    # Level 1: Follow instruction
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=1,
                task_type=TaskType.FOLLOW_INSTRUCTION.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Touch the big one!",
                    "correct_answer": "Big ball",
                    "options": ["Big ball", "Small ball", "Medium ball"],
                    "image_hint": "balls",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=1,
                task_type=TaskType.FOLLOW_INSTRUCTION.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Find the red one!",
                    "correct_answer": "Red car",
                    "options": ["Red car", "Blue car", "Green car"],
                    "image_hint": "cars",
                },
            ),
        ]
    )

    # Level 2: Story comprehension
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=2,
                task_type=TaskType.STORY_COMPREHENSION.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "The cat sat on the mat. Where is the cat?",
                    "correct_answer": "On the mat",
                    "options": ["On the mat", "Under the table", "In the box"],
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=2,
                task_type=TaskType.STORY_COMPREHENSION.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "The boy ate an apple. What did the boy eat?",
                    "correct_answer": "Apple",
                    "options": ["Apple", "Cake", "Cookie"],
                },
            ),
        ]
    )

    # ================================================================
    # LITERACY - Assessment Tasks (Levels 0-2)
    # ================================================================

    # Level 0: Letter Recognition
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=0,
                task_type=TaskType.MATCH_WORD_IMAGE.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Touch the letter A.",
                    "correct_answer": "A",
                    "options": ["A", "B", "C"],
                    "image_hint": "letter",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=0,
                task_type=TaskType.MATCH_WORD_IMAGE.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Touch the letter B.",
                    "correct_answer": "B",
                    "options": ["B", "D", "P"],
                    "image_hint": "letter",
                },
            ),
        ]
    )

    # Level 1: Match word to image
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=1,
                task_type=TaskType.MATCH_WORD_IMAGE.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Which picture shows 'CAT'?",
                    "correct_answer": "Cat",
                    "options": ["Cat", "Dog", "Bird"],
                    "target_word": "CAT",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=1,
                task_type=TaskType.MATCH_WORD_IMAGE.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Which picture shows 'FISH'?",
                    "correct_answer": "Fish",
                    "options": ["Fish", "Frog", "Fox"],
                    "target_word": "FISH",
                },
            ),
        ]
    )

    # Level 2: Read word
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=2,
                task_type=TaskType.READ_WORD.value,
                modalities=[Modality.VOICE.value, Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Can you read this word?",
                    "correct_answer": "Dog",
                    "target_word": "DOG",
                    "options": ["Dog", "Dig", "Dug"],
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=2,
                task_type=TaskType.READ_WORD.value,
                modalities=[Modality.VOICE.value, Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "What does this word say?",
                    "correct_answer": "Hat",
                    "target_word": "HAT",
                    "options": ["Hat", "Hot", "Hit"],
                },
            ),
        ]
    )

    # ================================================================
    # SOCIAL BEHAVIOR - Assessment Tasks (Levels 0-2)
    # ================================================================

    # Level 0: Attending
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=0,
                task_type=TaskType.ATTEND.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Bunny is waving! Can you wave back? Tap the wave!",
                    "correct_answer": "Wave",
                    "options": ["Wave", "Jump", "Sleep"],
                    "image_hint": "wave",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=0,
                task_type=TaskType.ATTEND.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Look! Someone is smiling! Tap the happy face!",
                    "correct_answer": "Happy",
                    "options": ["Happy", "Sad", "Angry"],
                    "image_hint": "faces",
                },
            ),
        ]
    )

    # Level 1: Imitate action
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=1,
                task_type=TaskType.IMITATE_ACTION.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Bunny clapped! What did Bunny do?",
                    "correct_answer": "Clap",
                    "options": ["Clap", "Dance", "Run"],
                    "image_hint": "clap",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=1,
                task_type=TaskType.IMITATE_ACTION.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Fox jumped! Can you show what Fox did?",
                    "correct_answer": "Jump",
                    "options": ["Jump", "Sit", "Sleep"],
                    "image_hint": "jump",
                },
            ),
        ]
    )

    # Level 2: Turn taking
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=2,
                task_type=TaskType.TURN_TAKE.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "It's your turn! Bunny went first. Now you pick a color!",
                    "correct_answer": "Blue",
                    "options": ["Blue", "Red", "Green"],
                    "image_hint": "colors",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=2,
                task_type=TaskType.TURN_TAKE.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Fox picked a star. Now it's your turn! Pick a shape!",
                    "correct_answer": "Circle",
                    "options": ["Circle", "Square", "Triangle"],
                    "image_hint": "shapes",
                },
            ),
        ]
    )

    # ================================================================
    # COGNITIVE LOGIC - Assessment Tasks (Levels 0-2)
    # ================================================================

    # Level 0: Pairing
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=0,
                task_type=TaskType.PAIR.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Which one goes with the shoe?",
                    "correct_answer": "Sock",
                    "options": ["Sock", "Hat", "Glove"],
                    "image_hint": "shoe",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=0,
                task_type=TaskType.PAIR.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Find the match for the cup!",
                    "correct_answer": "Saucer",
                    "options": ["Saucer", "Plate", "Bowl"],
                    "image_hint": "cup",
                },
            ),
        ]
    )

    # Level 1: Sorting
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=1,
                task_type=TaskType.SORT.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Which one is the biggest?",
                    "correct_answer": "Elephant",
                    "options": ["Elephant", "Cat", "Mouse"],
                    "image_hint": "animals_sizes",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=1,
                task_type=TaskType.SORT.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "Which color is different?",
                    "correct_answer": "Blue",
                    "options": ["Blue", "Red", "Red"],
                    "image_hint": "colors",
                },
            ),
        ]
    )

    # Level 2: Cause and effect
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=2,
                task_type=TaskType.CAUSE_EFFECT.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "What happens when it rains?",
                    "correct_answer": "Puddles",
                    "options": ["Puddles", "Snow", "Stars"],
                    "image_hint": "rain",
                },
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=2,
                task_type=TaskType.CAUSE_EFFECT.value,
                modalities=[Modality.TOUCH.value],
                is_assessment=True,
                content={
                    "instruction": "You blow a candle. What happens?",
                    "correct_answer": "It goes out",
                    "options": ["It goes out", "It gets bigger", "It turns blue"],
                    "image_hint": "candle",
                },
            ),
        ]
    )

    # Persist all tasks
    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)
