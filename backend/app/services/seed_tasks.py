"""
Seed tasks for the adaptive learning system.

Phase 1: Object Cognition dimension with 5 levels (0-4).
Phase 2: Language Expression and Language Comprehension dimensions.
Phase 3: Literacy, Social Behavior, and Cognitive Logic dimensions.

Object Cognition levels:
  Level 0: Simple matching - match identical objects
  Level 1: Identification - identify named objects from choices
  Level 2: Classification - group objects by category
  Level 3: Function understanding - what is this object used for?
  Level 4: Abstract association - relate objects by abstract properties

Language Expression levels:
  Level 0: Imitation - repeat a word after audio prompt
  Level 1: Naming - say the name of a shown object
  Level 2: Description - describe with a short phrase
  Level 3: Sentence building - construct a sentence from word cards
  Level 4: Conversation - answer open-ended questions

Language Comprehension levels:
  Level 0: Point-to - touch the named object
  Level 1: Simple instructions - follow a one-step instruction
  Level 2: Multi-step instructions - follow a 2-3 step sequence
  Level 3: Story comprehension - answer questions about a short story
  Level 4: Inference - predict what happens next

Literacy levels:
  Level 0: Image recognition - identify objects from pictures
  Level 1: Word-image matching - match a written word to its picture
  Level 2: Word reading - read a single word aloud
  Level 3: Sentence reading - read a short sentence
  Level 4: Passage reading - read a short passage and answer questions

Social Behavior levels:
  Level 0: Attending - look at or respond to a social cue
  Level 1: Imitation - copy a demonstrated action
  Level 2: Turn-taking - take turns in a structured activity
  Level 3: Joint attention - follow or direct shared attention
  Level 4: Initiation - start a social interaction independently

Cognitive Logic levels:
  Level 0: Pairing - match identical or related items
  Level 1: Sorting - sort items by one attribute (color, size, shape)
  Level 2: Cause and effect - identify what causes what
  Level 3: Sequencing - put events or steps in the correct order
  Level 4: Reasoning - solve simple logic puzzles
"""

from sqlalchemy.orm import Session
from app.models.adaptive import AdaptiveTask, DevelopmentalDimension, TaskType, Modality


def seed_object_cognition_tasks(db: Session) -> int:
    """Seed object cognition tasks. Returns count of tasks created."""
    existing = (
        db.query(AdaptiveTask)
        .filter(AdaptiveTask.dimension == DevelopmentalDimension.OBJECT_COGNITION.value)
        .count()
    )

    if existing > 0:
        return 0

    tasks = []

    # ---- Level 0: Simple Matching ----
    tasks.extend(
        [
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
        ]
    )

    # ---- Level 1: Identification ----
    tasks.extend(
        [
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
                is_assessment=False,
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
        ]
    )

    # ---- Level 2: Classification ----
    tasks.extend(
        [
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
                is_assessment=False,
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
        ]
    )

    # ---- Level 3: Function Understanding ----
    tasks.extend(
        [
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
                is_assessment=False,
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
        ]
    )

    # ---- Level 4: Abstract Association ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
                level=4,
                task_type=TaskType.ABSTRACT.value,
                modalities=[
                    Modality.TOUCH.value,
                    Modality.VOICE.value,
                    Modality.TEXT.value,
                ],
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
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
                level=4,
                task_type=TaskType.ABSTRACT.value,
                modalities=[
                    Modality.TOUCH.value,
                    Modality.VOICE.value,
                    Modality.TEXT.value,
                ],
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
                modalities=[
                    Modality.TOUCH.value,
                    Modality.VOICE.value,
                    Modality.TEXT.value,
                ],
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
        ]
    )

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def seed_language_expression_tasks(db: Session) -> int:
    """Seed language expression tasks. Returns count of tasks created."""
    existing = (
        db.query(AdaptiveTask)
        .filter(
            AdaptiveTask.dimension == DevelopmentalDimension.LANGUAGE_EXPRESSION.value
        )
        .count()
    )

    if existing > 0:
        return 0

    tasks = []

    # ---- Level 0: Imitation ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=0,
                task_type=TaskType.IMITATE.value,
                modalities=[Modality.VOICE.value],
                content={
                    "instruction_audio": "Listen and repeat: Dog",
                    "instruction_text": "Say: Dog",
                    "target_word": "Dog",
                    "accept_threshold": 0.5,
                    "syllables": 1,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=0,
                task_type=TaskType.IMITATE.value,
                modalities=[Modality.VOICE.value],
                content={
                    "instruction_audio": "Listen and repeat: Cat",
                    "instruction_text": "Say: Cat",
                    "target_word": "Cat",
                    "accept_threshold": 0.5,
                    "syllables": 1,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=0,
                task_type=TaskType.IMITATE.value,
                modalities=[Modality.VOICE.value],
                content={
                    "instruction_audio": "Listen and repeat: Ball",
                    "instruction_text": "Say: Ball",
                    "target_word": "Ball",
                    "accept_threshold": 0.5,
                    "syllables": 1,
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 1: Naming ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=1,
                task_type=TaskType.NAME_OBJECT.value,
                modalities=[Modality.VOICE.value, Modality.IMAGE_EXCHANGE.value],
                content={
                    "instruction_audio": "What is this? Say the word!",
                    "instruction_text": "What is this?",
                    "target_word": "Apple",
                    "target_category": "Food",
                    "accept_threshold": 0.6,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=1,
                task_type=TaskType.NAME_OBJECT.value,
                modalities=[Modality.VOICE.value, Modality.IMAGE_EXCHANGE.value],
                content={
                    "instruction_audio": "What is this? Say the word!",
                    "instruction_text": "What is this?",
                    "target_word": "Car",
                    "target_category": "Vehicles",
                    "accept_threshold": 0.6,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=1,
                task_type=TaskType.NAME_OBJECT.value,
                modalities=[Modality.VOICE.value, Modality.IMAGE_EXCHANGE.value],
                content={
                    "instruction_audio": "What is this? Say the word!",
                    "instruction_text": "What is this?",
                    "target_word": "Cup",
                    "target_category": "Household",
                    "accept_threshold": 0.6,
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 2: Description ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=2,
                task_type=TaskType.DESCRIBE.value,
                modalities=[Modality.VOICE.value],
                content={
                    "instruction_audio": "Tell me about this picture!",
                    "instruction_text": "Describe what you see",
                    "scene": "A red ball on the grass",
                    "target_phrases": ["red ball", "ball grass", "red", "ball"],
                    "accept_threshold": 0.4,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=2,
                task_type=TaskType.DESCRIBE.value,
                modalities=[Modality.VOICE.value],
                content={
                    "instruction_audio": "Tell me about this picture!",
                    "instruction_text": "Describe what you see",
                    "scene": "A big yellow bus",
                    "target_phrases": ["big bus", "yellow bus", "big", "bus"],
                    "accept_threshold": 0.4,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=2,
                task_type=TaskType.DESCRIBE.value,
                modalities=[Modality.VOICE.value],
                content={
                    "instruction_audio": "Tell me about this picture!",
                    "instruction_text": "Describe what you see",
                    "scene": "A small white cat sleeping",
                    "target_phrases": ["white cat", "cat sleeping", "small cat", "cat"],
                    "accept_threshold": 0.4,
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 3: Sentence Building ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=3,
                task_type=TaskType.BUILD_SENTENCE.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Put the words in order to make a sentence!",
                    "instruction_text": "Make a sentence",
                    "word_cards": ["The", "dog", "is", "big"],
                    "correct_order": [0, 1, 2, 3],
                    "target_sentence": "The dog is big",
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=3,
                task_type=TaskType.BUILD_SENTENCE.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Put the words in order to make a sentence!",
                    "instruction_text": "Make a sentence",
                    "word_cards": ["I", "like", "apples"],
                    "correct_order": [0, 1, 2],
                    "target_sentence": "I like apples",
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=3,
                task_type=TaskType.BUILD_SENTENCE.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Put the words in order to make a sentence!",
                    "instruction_text": "Make a sentence",
                    "word_cards": ["She", "is", "eating", "a", "banana"],
                    "correct_order": [0, 1, 2, 3, 4],
                    "target_sentence": "She is eating a banana",
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 4: Conversation ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=4,
                task_type=TaskType.CONVERSATION.value,
                modalities=[Modality.VOICE.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Answer the question!",
                    "instruction_text": "Answer the question",
                    "question": "What is your favorite animal?",
                    "example_answers": [
                        "I like dogs",
                        "My favorite animal is a cat",
                        "I love fish",
                    ],
                    "keywords": [
                        "dog",
                        "cat",
                        "bird",
                        "fish",
                        "rabbit",
                        "animal",
                        "like",
                        "love",
                        "favorite",
                    ],
                    "accept_threshold": 0.3,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=4,
                task_type=TaskType.CONVERSATION.value,
                modalities=[Modality.VOICE.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Answer the question!",
                    "instruction_text": "Answer the question",
                    "question": "What did you eat for breakfast?",
                    "example_answers": ["I ate cereal", "I had milk", "I ate eggs"],
                    "keywords": [
                        "ate",
                        "eat",
                        "breakfast",
                        "cereal",
                        "milk",
                        "eggs",
                        "bread",
                        "juice",
                    ],
                    "accept_threshold": 0.3,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
                level=4,
                task_type=TaskType.CONVERSATION.value,
                modalities=[Modality.VOICE.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Answer the question!",
                    "instruction_text": "Answer the question",
                    "question": "What do you like to play with?",
                    "example_answers": [
                        "I like to play with blocks",
                        "I play with my toys",
                        "I like balls",
                    ],
                    "keywords": ["play", "toy", "ball", "block", "game", "like", "fun"],
                    "accept_threshold": 0.3,
                },
                is_assessment=False,
            ),
        ]
    )

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def seed_language_comprehension_tasks(db: Session) -> int:
    """Seed language comprehension tasks. Returns count of tasks created."""
    existing = (
        db.query(AdaptiveTask)
        .filter(
            AdaptiveTask.dimension
            == DevelopmentalDimension.LANGUAGE_COMPREHENSION.value
        )
        .count()
    )

    if existing > 0:
        return 0

    tasks = []

    # ---- Level 0: Point-to ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=0,
                task_type=TaskType.POINT_TO.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Touch the dog!",
                    "instruction_text": "Touch the dog",
                    "target_name": "Dog",
                    "choices": [
                        {"name": "Dog", "category": "Animals", "is_correct": True},
                        {"name": "Cat", "category": "Animals", "is_correct": False},
                        {"name": "Ball", "category": "Toys", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=0,
                task_type=TaskType.POINT_TO.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Touch the apple!",
                    "instruction_text": "Touch the apple",
                    "target_name": "Apple",
                    "choices": [
                        {"name": "Banana", "category": "Food", "is_correct": False},
                        {"name": "Apple", "category": "Food", "is_correct": True},
                        {"name": "Car", "category": "Vehicles", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=0,
                task_type=TaskType.POINT_TO.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Touch the cup!",
                    "instruction_text": "Touch the cup",
                    "target_name": "Cup",
                    "choices": [
                        {"name": "Shoe", "category": "Clothing", "is_correct": False},
                        {"name": "Cup", "category": "Household", "is_correct": True},
                        {"name": "Tree", "category": "Nature", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 1: Simple Instructions ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=1,
                task_type=TaskType.FOLLOW_INSTRUCTION.value,
                modalities=[Modality.TOUCH.value, Modality.VOICE.value],
                content={
                    "instruction_audio": "Give me the ball!",
                    "instruction_text": "Give me the ball",
                    "steps": 1,
                    "action": "select",
                    "target_objects": ["Ball"],
                    "choices": [
                        {"name": "Ball", "category": "Toys", "is_target": True},
                        {"name": "Cup", "category": "Household", "is_target": False},
                        {"name": "Book", "category": "Household", "is_target": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=1,
                task_type=TaskType.FOLLOW_INSTRUCTION.value,
                modalities=[Modality.TOUCH.value, Modality.VOICE.value],
                content={
                    "instruction_audio": "Put the hat on!",
                    "instruction_text": "Put the hat on",
                    "steps": 1,
                    "action": "select",
                    "target_objects": ["Hat"],
                    "choices": [
                        {"name": "Shirt", "category": "Clothing", "is_target": False},
                        {"name": "Hat", "category": "Clothing", "is_target": True},
                        {"name": "Shoe", "category": "Clothing", "is_target": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=1,
                task_type=TaskType.FOLLOW_INSTRUCTION.value,
                modalities=[Modality.TOUCH.value, Modality.VOICE.value],
                content={
                    "instruction_audio": "Show me the biggest one!",
                    "instruction_text": "Show me the biggest one",
                    "steps": 1,
                    "action": "select",
                    "target_objects": ["Big Bear"],
                    "choices": [
                        {"name": "Small Bear", "category": "Toys", "is_target": False},
                        {"name": "Medium Bear", "category": "Toys", "is_target": False},
                        {"name": "Big Bear", "category": "Toys", "is_target": True},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 2: Multi-step Instructions ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=2,
                task_type=TaskType.FOLLOW_INSTRUCTION.value,
                modalities=[Modality.TOUCH.value, Modality.VOICE.value],
                content={
                    "instruction_audio": "First pick up the cup, then put it on the table!",
                    "instruction_text": "First pick up the cup, then put it on the table",
                    "steps": 2,
                    "actions_sequence": [
                        {"action": "select", "target": "Cup"},
                        {"action": "place", "target": "Table"},
                    ],
                    "objects": [
                        {"name": "Cup", "category": "Household"},
                        {"name": "Ball", "category": "Toys"},
                        {"name": "Table", "category": "Household"},
                        {"name": "Chair", "category": "Household"},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=2,
                task_type=TaskType.FOLLOW_INSTRUCTION.value,
                modalities=[Modality.TOUCH.value, Modality.VOICE.value],
                content={
                    "instruction_audio": "Pick up the red ball and give it to the bear!",
                    "instruction_text": "Pick up the red ball and give it to the bear",
                    "steps": 2,
                    "actions_sequence": [
                        {"action": "select", "target": "Red Ball"},
                        {"action": "give", "target": "Bear"},
                    ],
                    "objects": [
                        {"name": "Red Ball", "category": "Toys"},
                        {"name": "Blue Ball", "category": "Toys"},
                        {"name": "Bear", "category": "Toys"},
                        {"name": "Dog", "category": "Animals"},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=2,
                task_type=TaskType.FOLLOW_INSTRUCTION.value,
                modalities=[Modality.TOUCH.value, Modality.VOICE.value],
                content={
                    "instruction_audio": "First clap your hands, then touch your nose, then sit down!",
                    "instruction_text": "Clap, touch nose, sit down",
                    "steps": 3,
                    "actions_sequence": [
                        {"action": "select", "target": "Clap"},
                        {"action": "select", "target": "Touch Nose"},
                        {"action": "select", "target": "Sit Down"},
                    ],
                    "objects": [
                        {"name": "Clap", "category": "Actions"},
                        {"name": "Touch Nose", "category": "Actions"},
                        {"name": "Sit Down", "category": "Actions"},
                        {"name": "Jump", "category": "Actions"},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 3: Story Comprehension ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=3,
                task_type=TaskType.STORY_COMPREHENSION.value,
                modalities=[
                    Modality.TOUCH.value,
                    Modality.VOICE.value,
                    Modality.TEXT.value,
                ],
                content={
                    "story_audio": "The dog is hungry. He goes to his bowl. He eats his food. Now he is happy!",
                    "story_text": "The dog is hungry. He goes to his bowl. He eats his food. Now he is happy!",
                    "question_audio": "Why is the dog happy?",
                    "question_text": "Why is the dog happy?",
                    "choices": [
                        {"text": "He ate his food", "is_correct": True},
                        {"text": "He went for a walk", "is_correct": False},
                        {"text": "He found a toy", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=3,
                task_type=TaskType.STORY_COMPREHENSION.value,
                modalities=[
                    Modality.TOUCH.value,
                    Modality.VOICE.value,
                    Modality.TEXT.value,
                ],
                content={
                    "story_audio": "It is raining outside. Mom gives Amy an umbrella. Amy opens the umbrella and goes outside.",
                    "story_text": "It is raining outside. Mom gives Amy an umbrella. Amy opens the umbrella and goes outside.",
                    "question_audio": "What did Mom give Amy?",
                    "question_text": "What did Mom give Amy?",
                    "choices": [
                        {"text": "A coat", "is_correct": False},
                        {"text": "An umbrella", "is_correct": True},
                        {"text": "A hat", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=3,
                task_type=TaskType.STORY_COMPREHENSION.value,
                modalities=[
                    Modality.TOUCH.value,
                    Modality.VOICE.value,
                    Modality.TEXT.value,
                ],
                content={
                    "story_audio": "Tom has a red car. He puts the car in a box. He gives the box to his friend.",
                    "story_text": "Tom has a red car. He puts the car in a box. He gives the box to his friend.",
                    "question_audio": "Where did Tom put the car?",
                    "question_text": "Where did Tom put the car?",
                    "choices": [
                        {"text": "On the table", "is_correct": False},
                        {"text": "In a bag", "is_correct": False},
                        {"text": "In a box", "is_correct": True},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 4: Inference ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=4,
                task_type=TaskType.INFER_MEANING.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "story_audio": "The sky is dark. There are big clouds. The wind is blowing.",
                    "story_text": "The sky is dark. There are big clouds. The wind is blowing.",
                    "question_audio": "What will happen next?",
                    "question_text": "What will happen next?",
                    "choices": [
                        {"text": "It will rain", "is_correct": True},
                        {"text": "It will be sunny", "is_correct": False},
                        {"text": "It will snow", "is_correct": False},
                    ],
                    "reasoning": "Dark sky and big clouds usually mean rain",
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=4,
                task_type=TaskType.INFER_MEANING.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "story_audio": "Lisa is smiling. She just opened a big present.",
                    "story_text": "Lisa is smiling. She just opened a big present.",
                    "question_audio": "How does Lisa feel?",
                    "question_text": "How does Lisa feel?",
                    "choices": [
                        {"text": "Sad", "is_correct": False},
                        {"text": "Happy", "is_correct": True},
                        {"text": "Angry", "is_correct": False},
                    ],
                    "reasoning": "Smiling after opening a present means she is happy",
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
                level=4,
                task_type=TaskType.INFER_MEANING.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "story_audio": "The cat sees a mouse. The cat starts running very fast.",
                    "story_text": "The cat sees a mouse. The cat starts running very fast.",
                    "question_audio": "What is the cat doing?",
                    "question_text": "What is the cat doing?",
                    "choices": [
                        {"text": "Sleeping", "is_correct": False},
                        {"text": "Eating", "is_correct": False},
                        {"text": "Chasing the mouse", "is_correct": True},
                    ],
                    "reasoning": "Cats chase mice when they see them",
                },
                is_assessment=False,
            ),
        ]
    )

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def seed_literacy_tasks(db: Session) -> int:
    """Seed literacy tasks. Returns count of tasks created."""
    existing = (
        db.query(AdaptiveTask)
        .filter(AdaptiveTask.dimension == DevelopmentalDimension.LITERACY.value)
        .count()
    )

    if existing > 0:
        return 0

    tasks = []

    # ---- Level 0: Image Recognition ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=0,
                task_type=TaskType.RECOGNIZE_IMAGE.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "What is in this picture?",
                    "instruction_text": "What is in this picture?",
                    "image_name": "Apple",
                    "choices": [
                        {"name": "Apple", "is_correct": True},
                        {"name": "Car", "is_correct": False},
                        {"name": "Hat", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=0,
                task_type=TaskType.RECOGNIZE_IMAGE.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "What is in this picture?",
                    "instruction_text": "What is in this picture?",
                    "image_name": "Dog",
                    "choices": [
                        {"name": "Cat", "is_correct": False},
                        {"name": "Dog", "is_correct": True},
                        {"name": "Fish", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=0,
                task_type=TaskType.RECOGNIZE_IMAGE.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "What is in this picture?",
                    "instruction_text": "What is in this picture?",
                    "image_name": "Ball",
                    "choices": [
                        {"name": "Ball", "is_correct": True},
                        {"name": "Cup", "is_correct": False},
                        {"name": "Shoe", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 1: Word-Image Matching ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=1,
                task_type=TaskType.MATCH_WORD_IMAGE.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Find the picture that matches the word.",
                    "instruction_text": "Find the picture for this word.",
                    "word": "Cat",
                    "choices": [
                        {"image_name": "Dog", "is_correct": False},
                        {"image_name": "Cat", "is_correct": True},
                        {"image_name": "Bird", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=1,
                task_type=TaskType.MATCH_WORD_IMAGE.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Find the picture that matches the word.",
                    "instruction_text": "Find the picture for this word.",
                    "word": "Sun",
                    "choices": [
                        {"image_name": "Moon", "is_correct": False},
                        {"image_name": "Star", "is_correct": False},
                        {"image_name": "Sun", "is_correct": True},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=1,
                task_type=TaskType.MATCH_WORD_IMAGE.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Find the picture that matches the word.",
                    "instruction_text": "Find the picture for this word.",
                    "word": "Cup",
                    "choices": [
                        {"image_name": "Cup", "is_correct": True},
                        {"image_name": "Plate", "is_correct": False},
                        {"image_name": "Spoon", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 2: Read Word ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=2,
                task_type=TaskType.READ_WORD.value,
                modalities=[Modality.VOICE.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Read this word out loud.",
                    "instruction_text": "Read this word.",
                    "target_word": "Dog",
                    "accept_threshold": 0.6,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=2,
                task_type=TaskType.READ_WORD.value,
                modalities=[Modality.VOICE.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Read this word out loud.",
                    "instruction_text": "Read this word.",
                    "target_word": "Apple",
                    "accept_threshold": 0.6,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=2,
                task_type=TaskType.READ_WORD.value,
                modalities=[Modality.VOICE.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Read this word out loud.",
                    "instruction_text": "Read this word.",
                    "target_word": "Ball",
                    "accept_threshold": 0.6,
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 3: Read Sentence ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=3,
                task_type=TaskType.READ_SENTENCE.value,
                modalities=[Modality.VOICE.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Read this sentence out loud.",
                    "instruction_text": "Read this sentence.",
                    "target_sentence": "I see a dog.",
                    "accept_threshold": 0.5,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=3,
                task_type=TaskType.READ_SENTENCE.value,
                modalities=[Modality.VOICE.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Read this sentence out loud.",
                    "instruction_text": "Read this sentence.",
                    "target_sentence": "The cat is big.",
                    "accept_threshold": 0.5,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=3,
                task_type=TaskType.READ_SENTENCE.value,
                modalities=[Modality.VOICE.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Read this sentence out loud.",
                    "instruction_text": "Read this sentence.",
                    "target_sentence": "I like apples.",
                    "accept_threshold": 0.5,
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 4: Passage Reading ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=4,
                task_type=TaskType.READ_PASSAGE.value,
                modalities=[Modality.TEXT.value, Modality.TOUCH.value],
                content={
                    "instruction_audio": "Read the story, then answer the question.",
                    "instruction_text": "Read the story, then answer the question.",
                    "passage": "Tom has a red ball. He plays with it every day. Today it is raining, so Tom plays inside.",
                    "question": "Where does Tom play today?",
                    "choices": [
                        {"text": "Outside", "is_correct": False},
                        {"text": "Inside", "is_correct": True},
                        {"text": "At school", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=4,
                task_type=TaskType.READ_PASSAGE.value,
                modalities=[Modality.TEXT.value, Modality.TOUCH.value],
                content={
                    "instruction_audio": "Read the story, then answer the question.",
                    "instruction_text": "Read the story, then answer the question.",
                    "passage": "Lily has a cat. The cat likes to sleep on the bed. Lily gives the cat milk every morning.",
                    "question": "What does the cat like to do?",
                    "choices": [
                        {"text": "Run", "is_correct": False},
                        {"text": "Sleep on the bed", "is_correct": True},
                        {"text": "Play outside", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.LITERACY.value,
                level=4,
                task_type=TaskType.READ_PASSAGE.value,
                modalities=[Modality.TEXT.value, Modality.TOUCH.value],
                content={
                    "instruction_audio": "Read the story, then answer the question.",
                    "instruction_text": "Read the story, then answer the question.",
                    "passage": "Ben goes to school by bus. He sits next to his friend Amy. They talk about their favorite animals.",
                    "question": "How does Ben go to school?",
                    "choices": [
                        {"text": "By car", "is_correct": False},
                        {"text": "By bike", "is_correct": False},
                        {"text": "By bus", "is_correct": True},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def seed_social_behavior_tasks(db: Session) -> int:
    """Seed social behavior tasks. Returns count of tasks created."""
    existing = (
        db.query(AdaptiveTask)
        .filter(AdaptiveTask.dimension == DevelopmentalDimension.SOCIAL_BEHAVIOR.value)
        .count()
    )

    if existing > 0:
        return 0

    tasks = []

    # ---- Level 0: Attending ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=0,
                task_type=TaskType.ATTEND.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Look! Tap the character who is waving at you!",
                    "instruction_text": "Tap the character waving at you.",
                    "scene": "character_waving",
                    "target": {"action": "waving", "position": "center"},
                    "distractors": [
                        {"action": "sleeping", "position": "left"},
                        {"action": "reading", "position": "right"},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=0,
                task_type=TaskType.ATTEND.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Someone is calling your name! Tap who is calling.",
                    "instruction_text": "Tap who is calling you.",
                    "scene": "name_calling",
                    "target": {"action": "calling", "position": "left"},
                    "distractors": [
                        {"action": "eating", "position": "center"},
                        {"action": "playing", "position": "right"},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=0,
                task_type=TaskType.ATTEND.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Look at the face! Is the person happy or sad? Tap the answer.",
                    "instruction_text": "Is this person happy or sad?",
                    "scene": "emotion_recognition",
                    "emotion": "happy",
                    "choices": [
                        {"text": "Happy", "emoji": "smile", "is_correct": True},
                        {"text": "Sad", "emoji": "frown", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 1: Imitation ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=1,
                task_type=TaskType.IMITATE_ACTION.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Watch what the bear does, then do the same!",
                    "instruction_text": "Copy what the bear does.",
                    "demo_action": "clap_hands",
                    "demo_description": "The bear claps his hands.",
                    "choices": [
                        {
                            "action": "clap_hands",
                            "label": "Clap hands",
                            "is_correct": True,
                        },
                        {
                            "action": "stomp_feet",
                            "label": "Stomp feet",
                            "is_correct": False,
                        },
                        {"action": "wave", "label": "Wave", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=1,
                task_type=TaskType.IMITATE_ACTION.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Watch what the bunny does, then do the same!",
                    "instruction_text": "Copy what the bunny does.",
                    "demo_action": "jump",
                    "demo_description": "The bunny jumps up and down.",
                    "choices": [
                        {
                            "action": "sit_down",
                            "label": "Sit down",
                            "is_correct": False,
                        },
                        {"action": "jump", "label": "Jump", "is_correct": True},
                        {"action": "spin", "label": "Spin around", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=1,
                task_type=TaskType.IMITATE_ACTION.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Watch what the duck does, then do the same!",
                    "instruction_text": "Copy what the duck does.",
                    "demo_action": "wave_goodbye",
                    "demo_description": "The duck waves goodbye.",
                    "choices": [
                        {
                            "action": "wave_goodbye",
                            "label": "Wave goodbye",
                            "is_correct": True,
                        },
                        {
                            "action": "clap_hands",
                            "label": "Clap hands",
                            "is_correct": False,
                        },
                        {
                            "action": "nod_head",
                            "label": "Nod head",
                            "is_correct": False,
                        },
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 2: Turn-Taking ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=2,
                task_type=TaskType.TURN_TAKE.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "It's your turn! Roll the dice.",
                    "instruction_text": "Wait for your turn, then roll the dice.",
                    "game": "dice_roll",
                    "sequence": ["bear_rolls", "your_turn", "bear_rolls", "your_turn"],
                    "current_step": 1,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=2,
                task_type=TaskType.TURN_TAKE.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Let's take turns building a tower! Place a block.",
                    "instruction_text": "Take turns placing blocks.",
                    "game": "block_tower",
                    "sequence": [
                        "bunny_places",
                        "your_turn",
                        "bunny_places",
                        "your_turn",
                    ],
                    "current_step": 1,
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=2,
                task_type=TaskType.TURN_TAKE.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Let's take turns picking cards! Wait for your turn.",
                    "instruction_text": "Take turns picking cards.",
                    "game": "card_pick",
                    "sequence": ["duck_picks", "your_turn", "duck_picks", "your_turn"],
                    "current_step": 1,
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 3: Joint Attention ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=3,
                task_type=TaskType.JOINT_ATTENTION.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "The bear is pointing at something! What is it?",
                    "instruction_text": "What is the bear pointing at?",
                    "scene": "bear_pointing",
                    "pointer_direction": "right",
                    "target": {"name": "Butterfly", "position": "right"},
                    "distractors": [
                        {"name": "Rock", "position": "left"},
                        {"name": "Tree", "position": "center"},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=3,
                task_type=TaskType.JOINT_ATTENTION.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "The bunny is looking up! What does the bunny see?",
                    "instruction_text": "What is the bunny looking at?",
                    "scene": "bunny_looking_up",
                    "pointer_direction": "up",
                    "target": {"name": "Bird", "position": "top"},
                    "distractors": [
                        {"name": "Ball", "position": "left"},
                        {"name": "Flower", "position": "right"},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=3,
                task_type=TaskType.JOINT_ATTENTION.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Show the duck where the fish is! Point to the fish.",
                    "instruction_text": "Point to the fish to show the duck.",
                    "scene": "show_duck_fish",
                    "mode": "child_points",
                    "target": {"name": "Fish", "position": "bottom_right"},
                    "distractors": [
                        {"name": "Frog", "position": "bottom_left"},
                        {"name": "Lily pad", "position": "center"},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 4: Initiation ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=4,
                task_type=TaskType.INITIATE.value,
                modalities=[Modality.TOUCH.value, Modality.VOICE.value],
                content={
                    "instruction_audio": "The bear looks lonely. What would you do?",
                    "instruction_text": "The bear looks lonely. What would you do?",
                    "scene": "lonely_bear",
                    "choices": [
                        {
                            "action": "say_hi",
                            "label": "Say hi to the bear",
                            "is_best": True,
                        },
                        {"action": "walk_away", "label": "Walk away", "is_best": False},
                        {"action": "ignore", "label": "Do nothing", "is_best": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=4,
                task_type=TaskType.INITIATE.value,
                modalities=[Modality.TOUCH.value, Modality.VOICE.value],
                content={
                    "instruction_audio": "You want to play with the bunny. What do you say?",
                    "instruction_text": "You want to play with the bunny. What do you say?",
                    "scene": "ask_to_play",
                    "choices": [
                        {
                            "action": "ask_play",
                            "label": "Can I play with you?",
                            "is_best": True,
                        },
                        {
                            "action": "take_toy",
                            "label": "Take the toy",
                            "is_best": False,
                        },
                        {"action": "cry", "label": "Cry", "is_best": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
                level=4,
                task_type=TaskType.INITIATE.value,
                modalities=[Modality.TOUCH.value, Modality.VOICE.value],
                content={
                    "instruction_audio": "The duck dropped his toy. What would you do?",
                    "instruction_text": "The duck dropped his toy. What would you do?",
                    "scene": "help_duck",
                    "choices": [
                        {
                            "action": "pick_up",
                            "label": "Pick it up and give it back",
                            "is_best": True,
                        },
                        {"action": "laugh", "label": "Laugh", "is_best": False},
                        {"action": "ignore", "label": "Keep walking", "is_best": False},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def seed_cognitive_logic_tasks(db: Session) -> int:
    """Seed cognitive logic tasks. Returns count of tasks created."""
    existing = (
        db.query(AdaptiveTask)
        .filter(AdaptiveTask.dimension == DevelopmentalDimension.COGNITIVE_LOGIC.value)
        .count()
    )

    if existing > 0:
        return 0

    tasks = []

    # ---- Level 0: Pairing ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=0,
                task_type=TaskType.PAIR.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Find the two that are the same!",
                    "instruction_text": "Find the matching pair.",
                    "items": [
                        {
                            "name": "Red Star",
                            "color": "red",
                            "shape": "star",
                            "pair_id": "A",
                        },
                        {
                            "name": "Blue Circle",
                            "color": "blue",
                            "shape": "circle",
                            "pair_id": "B",
                        },
                        {
                            "name": "Red Star",
                            "color": "red",
                            "shape": "star",
                            "pair_id": "A",
                        },
                        {
                            "name": "Green Square",
                            "color": "green",
                            "shape": "square",
                            "pair_id": "C",
                        },
                    ],
                    "correct_pair": "A",
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=0,
                task_type=TaskType.PAIR.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Find the two that are the same!",
                    "instruction_text": "Find the matching pair.",
                    "items": [
                        {
                            "name": "Yellow Triangle",
                            "color": "yellow",
                            "shape": "triangle",
                            "pair_id": "A",
                        },
                        {
                            "name": "Blue Circle",
                            "color": "blue",
                            "shape": "circle",
                            "pair_id": "B",
                        },
                        {
                            "name": "Red Square",
                            "color": "red",
                            "shape": "square",
                            "pair_id": "C",
                        },
                        {
                            "name": "Yellow Triangle",
                            "color": "yellow",
                            "shape": "triangle",
                            "pair_id": "A",
                        },
                    ],
                    "correct_pair": "A",
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=0,
                task_type=TaskType.PAIR.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Which two things go together?",
                    "instruction_text": "Find the pair that goes together.",
                    "items": [
                        {"name": "Sock", "category": "clothing", "pair_id": "A"},
                        {"name": "Shoe", "category": "clothing", "pair_id": "A"},
                        {"name": "Apple", "category": "food", "pair_id": "B"},
                        {"name": "Car", "category": "vehicle", "pair_id": "C"},
                    ],
                    "correct_pair": "A",
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 1: Sorting ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=1,
                task_type=TaskType.SORT.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Sort by color! Put the red ones together.",
                    "instruction_text": "Put all the red items together.",
                    "sort_by": "color",
                    "target_value": "red",
                    "items": [
                        {"name": "Red Apple", "color": "red", "is_target": True},
                        {"name": "Blue Ball", "color": "blue", "is_target": False},
                        {"name": "Red Car", "color": "red", "is_target": True},
                        {"name": "Green Frog", "color": "green", "is_target": False},
                        {"name": "Red Hat", "color": "red", "is_target": True},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=1,
                task_type=TaskType.SORT.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Sort by size! Which ones are big?",
                    "instruction_text": "Find all the big items.",
                    "sort_by": "size",
                    "target_value": "big",
                    "items": [
                        {"name": "Big Bear", "size": "big", "is_target": True},
                        {"name": "Small Mouse", "size": "small", "is_target": False},
                        {"name": "Big Elephant", "size": "big", "is_target": True},
                        {"name": "Small Ant", "size": "small", "is_target": False},
                        {"name": "Big House", "size": "big", "is_target": True},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=1,
                task_type=TaskType.SORT.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Sort by shape! Find all the circles.",
                    "instruction_text": "Find all the circles.",
                    "sort_by": "shape",
                    "target_value": "circle",
                    "items": [
                        {"name": "Ball", "shape": "circle", "is_target": True},
                        {"name": "Book", "shape": "rectangle", "is_target": False},
                        {"name": "Sun", "shape": "circle", "is_target": True},
                        {"name": "Door", "shape": "rectangle", "is_target": False},
                        {"name": "Cookie", "shape": "circle", "is_target": True},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 2: Cause and Effect ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=2,
                task_type=TaskType.CAUSE_EFFECT.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "What happens when you drop a glass?",
                    "instruction_text": "What happens when you drop a glass?",
                    "cause": "Drop a glass",
                    "choices": [
                        {"text": "It breaks", "is_correct": True},
                        {"text": "It flies", "is_correct": False},
                        {"text": "It grows", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=2,
                task_type=TaskType.CAUSE_EFFECT.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "What happens when you press the light switch?",
                    "instruction_text": "What happens when you press the light switch?",
                    "cause": "Press the light switch",
                    "choices": [
                        {"text": "The light turns on", "is_correct": True},
                        {"text": "The door opens", "is_correct": False},
                        {"text": "The water runs", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=2,
                task_type=TaskType.CAUSE_EFFECT.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Why is the boy crying?",
                    "instruction_text": "Why is the boy crying?",
                    "cause": "Boy is crying",
                    "scene_description": "A boy fell off his bicycle.",
                    "choices": [
                        {"text": "He fell off his bicycle", "is_correct": True},
                        {"text": "He ate ice cream", "is_correct": False},
                        {"text": "He found a toy", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 3: Sequencing ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=3,
                task_type=TaskType.SEQUENCE_ORDER.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "Put these in order! What happens first, second, third?",
                    "instruction_text": "Put these steps in the right order.",
                    "scenario": "Making a sandwich",
                    "steps": [
                        {"text": "Get two slices of bread", "order": 1},
                        {"text": "Put cheese on the bread", "order": 2},
                        {"text": "Close the sandwich", "order": 3},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=3,
                task_type=TaskType.SEQUENCE_ORDER.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "What is the correct order?",
                    "instruction_text": "Put these steps in the right order.",
                    "scenario": "Getting ready for bed",
                    "steps": [
                        {"text": "Brush your teeth", "order": 1},
                        {"text": "Put on pajamas", "order": 2},
                        {"text": "Get into bed", "order": 3},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=3,
                task_type=TaskType.SEQUENCE_ORDER.value,
                modalities=[Modality.TOUCH.value],
                content={
                    "instruction_audio": "What is the correct order?",
                    "instruction_text": "Put these steps in the right order.",
                    "scenario": "Planting a flower",
                    "steps": [
                        {"text": "Dig a hole", "order": 1},
                        {"text": "Put the seed in", "order": 2},
                        {"text": "Cover with soil", "order": 3},
                        {"text": "Water the plant", "order": 4},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    # ---- Level 4: Reasoning ----
    tasks.extend(
        [
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=4,
                task_type=TaskType.REASON.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "All dogs have four legs. Max is a dog. How many legs does Max have?",
                    "instruction_text": "All dogs have four legs. Max is a dog. How many legs does Max have?",
                    "logic_type": "deduction",
                    "premises": ["All dogs have four legs", "Max is a dog"],
                    "choices": [
                        {"text": "Two", "is_correct": False},
                        {"text": "Four", "is_correct": True},
                        {"text": "Six", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=4,
                task_type=TaskType.REASON.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "Tom is taller than Amy. Amy is taller than Ben. Who is the shortest?",
                    "instruction_text": "Tom is taller than Amy. Amy is taller than Ben. Who is the shortest?",
                    "logic_type": "comparison",
                    "premises": ["Tom is taller than Amy", "Amy is taller than Ben"],
                    "choices": [
                        {"text": "Tom", "is_correct": False},
                        {"text": "Amy", "is_correct": False},
                        {"text": "Ben", "is_correct": True},
                    ],
                },
                is_assessment=False,
            ),
            AdaptiveTask(
                dimension=DevelopmentalDimension.COGNITIVE_LOGIC.value,
                level=4,
                task_type=TaskType.REASON.value,
                modalities=[Modality.TOUCH.value, Modality.TEXT.value],
                content={
                    "instruction_audio": "There are 3 apples. You eat 1. How many are left?",
                    "instruction_text": "There are 3 apples. You eat 1. How many are left?",
                    "logic_type": "arithmetic",
                    "premises": ["Start with 3 apples", "Eat 1 apple"],
                    "choices": [
                        {"text": "1", "is_correct": False},
                        {"text": "2", "is_correct": True},
                        {"text": "3", "is_correct": False},
                    ],
                },
                is_assessment=False,
            ),
        ]
    )

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def seed_all_tasks(db: Session) -> dict:
    """Seed all task dimensions. Returns counts per dimension."""
    from app.services.seed_assessment import seed_assessment_tasks

    results = {}
    results["object_cognition"] = seed_object_cognition_tasks(db)
    results["language_expression"] = seed_language_expression_tasks(db)
    results["language_comprehension"] = seed_language_comprehension_tasks(db)
    results["literacy"] = seed_literacy_tasks(db)
    results["social_behavior"] = seed_social_behavior_tasks(db)
    results["cognitive_logic"] = seed_cognitive_logic_tasks(db)
    results["assessment"] = seed_assessment_tasks(db)
    return results
