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
from sqlalchemy.orm.attributes import flag_modified
from app.models.adaptive import AdaptiveTask, DevelopmentalDimension, TaskType, Modality


def seed_object_cognition_tasks(db: Session) -> int:
    """Seed object cognition tasks. Returns count of tasks created."""
    existing = (
        db.query(AdaptiveTask)
        .filter(
            AdaptiveTask.dimension == DevelopmentalDimension.OBJECT_COGNITION.value,
            AdaptiveTask.is_assessment == False,  # noqa: E712
        )
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
            AdaptiveTask.dimension == DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
            AdaptiveTask.is_assessment == False,  # noqa: E712
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
                    "target_word": "red ball",
                    "image_hint": "ball",
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
                    "target_word": "yellow bus",
                    "image_hint": "bus",
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
                    "target_word": "white cat",
                    "image_hint": "cat",
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
                    "target_word": "The dog is big",
                    "image_hint": "dog",
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
                    "target_word": "I like apples",
                    "image_hint": "apple",
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
                    "target_word": "She is eating a banana",
                    "image_hint": "banana",
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
                    "target_word": "I like dogs",
                    "image_hint": "dog",
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
                    "target_word": "I ate cereal",
                    "image_hint": "spoon",
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
                    "target_word": "I like to play with blocks",
                    "image_hint": "ball",
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
            == DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
            AdaptiveTask.is_assessment == False,  # noqa: E712
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
        .filter(
            AdaptiveTask.dimension == DevelopmentalDimension.LITERACY.value,
            AdaptiveTask.is_assessment == False,  # noqa: E712
        )
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
        .filter(
            AdaptiveTask.dimension == DevelopmentalDimension.SOCIAL_BEHAVIOR.value,
            AdaptiveTask.is_assessment == False,  # noqa: E712
        )
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
        .filter(
            AdaptiveTask.dimension == DevelopmentalDimension.COGNITIVE_LOGIC.value,
            AdaptiveTask.is_assessment == False,  # noqa: E712
        )
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
                    "options": ["Red Star", "Blue Circle", "Green Square"],
                    "correct_answer": "Red Star",
                    "image_hint": "red_star",
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
                    "options": ["Yellow Triangle", "Blue Circle", "Red Square"],
                    "correct_answer": "Yellow Triangle",
                    "image_hint": "yellow_triangle",
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
                    "instruction_text": "Which goes with Sock?",
                    "items": [
                        {"name": "Sock", "category": "clothing", "pair_id": "A"},
                        {"name": "Shoe", "category": "clothing", "pair_id": "A"},
                        {"name": "Apple", "category": "food", "pair_id": "B"},
                        {"name": "Car", "category": "vehicle", "pair_id": "C"},
                    ],
                    "correct_pair": "A",
                    "options": ["Shoe", "Apple", "Car"],
                    "correct_answer": "Shoe",
                    "image_hint": "shoe",
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
                    "instruction_text": "Which one is red?",
                    "sort_by": "color",
                    "target_value": "red",
                    "items": [
                        {"name": "Red Apple", "color": "red", "is_target": True},
                        {"name": "Blue Ball", "color": "blue", "is_target": False},
                        {"name": "Red Car", "color": "red", "is_target": True},
                        {"name": "Green Frog", "color": "green", "is_target": False},
                        {"name": "Red Hat", "color": "red", "is_target": True},
                    ],
                    "options": ["Red Apple", "Blue Ball", "Green Frog"],
                    "correct_answer": "Red Apple",
                    "image_hint": "red_apple",
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
                    "instruction_text": "Which one is big?",
                    "sort_by": "size",
                    "target_value": "big",
                    "items": [
                        {"name": "Big Bear", "size": "big", "is_target": True},
                        {"name": "Small Mouse", "size": "small", "is_target": False},
                        {"name": "Big Elephant", "size": "big", "is_target": True},
                        {"name": "Small Ant", "size": "small", "is_target": False},
                        {"name": "Big House", "size": "big", "is_target": True},
                    ],
                    "options": ["Big Bear", "Small Mouse", "Small Ant"],
                    "correct_answer": "Big Bear",
                    "image_hint": "bear",
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
                    "instruction_text": "Which one is a circle?",
                    "sort_by": "shape",
                    "target_value": "circle",
                    "items": [
                        {"name": "Ball", "shape": "circle", "is_target": True},
                        {"name": "Book", "shape": "rectangle", "is_target": False},
                        {"name": "Sun", "shape": "circle", "is_target": True},
                        {"name": "Door", "shape": "rectangle", "is_target": False},
                        {"name": "Cookie", "shape": "circle", "is_target": True},
                    ],
                    "options": ["Ball", "Book", "Door"],
                    "correct_answer": "Ball",
                    "image_hint": "ball",
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
                    "options": ["It breaks", "It flies", "It grows"],
                    "correct_answer": "It breaks",
                    "image_hint": "glass",
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
                    "options": [
                        "The light turns on",
                        "The door opens",
                        "The water runs",
                    ],
                    "correct_answer": "The light turns on",
                    "image_hint": "light_switch",
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
                    "options": [
                        "He fell off his bicycle",
                        "He ate ice cream",
                        "He found a toy",
                    ],
                    "correct_answer": "He fell off his bicycle",
                    "image_hint": "boy_crying",
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
                    "instruction_text": "What comes first? Making a sandwich",
                    "scenario": "Making a sandwich",
                    "steps": [
                        {"text": "Get two slices of bread", "order": 1},
                        {"text": "Put cheese on the bread", "order": 2},
                        {"text": "Close the sandwich", "order": 3},
                    ],
                    "options": [
                        "Close the sandwich",
                        "Get two slices of bread",
                        "Put cheese on the bread",
                    ],
                    "correct_answer": "Get two slices of bread",
                    "image_hint": "sandwich",
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
                    "instruction_text": "What comes first? Getting ready for bed",
                    "scenario": "Getting ready for bed",
                    "steps": [
                        {"text": "Brush your teeth", "order": 1},
                        {"text": "Put on pajamas", "order": 2},
                        {"text": "Get into bed", "order": 3},
                    ],
                    "options": ["Get into bed", "Brush your teeth", "Put on pajamas"],
                    "correct_answer": "Brush your teeth",
                    "image_hint": "bed",
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
                    "instruction_text": "What comes first? Planting a flower",
                    "scenario": "Planting a flower",
                    "steps": [
                        {"text": "Dig a hole", "order": 1},
                        {"text": "Put the seed in", "order": 2},
                        {"text": "Cover with soil", "order": 3},
                        {"text": "Water the plant", "order": 4},
                    ],
                    "options": [
                        "Water the plant",
                        "Dig a hole",
                        "Put the seed in",
                        "Cover with soil",
                    ],
                    "correct_answer": "Dig a hole",
                    "image_hint": "flower",
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
                    "options": ["Two", "Four", "Six"],
                    "correct_answer": "Four",
                    "image_hint": "dog",
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
                    "options": ["Tom", "Amy", "Ben"],
                    "correct_answer": "Ben",
                    "image_hint": "height_comparison",
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
                    "options": ["1", "2", "3"],
                    "correct_answer": "2",
                    "image_hint": "apple",
                },
                is_assessment=False,
            ),
        ]
    )

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def _derive_image_hint(content: dict) -> str | None:
    """Derive an image_hint value from task content fields.

    Looks at target.name, target_name, target_word, and similar fields
    to produce a lowercase, underscore-separated hint that maps to a
    Cloudinary asset name.
    """

    def _normalize(name: str) -> str:
        return name.strip().lower().replace(" ", "_")

    # 1. target dict with a "name" key  (match / identify tasks)
    target = content.get("target")
    if isinstance(target, dict):
        name = target.get("name")
        if name:
            return _normalize(name)

    # 2. target_name string  (identify / say_word tasks)
    target_name = content.get("target_name")
    if target_name:
        return _normalize(target_name)

    # 3. target_word string  (literacy tasks)
    target_word = content.get("target_word")
    if target_word:
        return _normalize(target_word)

    # 4. image_name string  (literacy recognize_image tasks)
    image_name = content.get("image_name")
    if image_name:
        return _normalize(image_name)

    # 5. word string  (literacy match_word_image tasks)
    word = content.get("word")
    if word:
        return _normalize(word)

    # 6. target_objects list  (follow_instruction tasks)
    target_objects = content.get("target_objects")
    if isinstance(target_objects, list) and target_objects:
        first = target_objects[0]
        if isinstance(first, str):
            return _normalize(first)

    # 7. function tasks — use the correct choice's name
    choices = content.get("choices")
    if isinstance(choices, list):
        for choice in choices:
            if isinstance(choice, dict) and choice.get("is_correct"):
                name = choice.get("name")
                if name:
                    return _normalize(name)
            # Also handle is_target (used in follow_instruction choices)
            if isinstance(choice, dict) and choice.get("is_target"):
                name = choice.get("name")
                if name:
                    return _normalize(name)

    # 8. classify / abstract tasks — use the first target item's name
    items = content.get("items")
    if isinstance(items, list):
        for item in items:
            if isinstance(item, dict) and item.get("is_target"):
                name = item.get("name")
                if name:
                    return _normalize(name)

    return None


def backfill_task_options(db: Session) -> int:
    """Backfill options/correct_answer for ALL tasks that are missing them.

    Old base tasks only had 'choices' (dict format), 'steps', 'items', or
    'distractors' but no 'options' (string list) or 'correct_answer'.
    This function derives them so the iOS app can render interactive option
    buttons instead of the fallback Got It!/Help UI.

    Covers all dimensions: cognitive_logic, social_behavior, object_cognition,
    language_comprehension, literacy.  Voice-input tasks (imitate, name_object,
    describe, read_word, read_sentence, say_word, build_sentence, conversation)
    are skipped because they use speech recognition, not option buttons.
    """
    # Voice-input task types that intentionally have no options
    voice_task_types = {
        "imitate",
        "name_object",
        "describe",
        "read_word",
        "read_sentence",
        "say_word",
        "build_sentence",
        "conversation",
    }

    tasks = (
        db.query(AdaptiveTask)
        .filter(
            AdaptiveTask.is_assessment == False,  # noqa: E712
        )
        .all()
    )
    updated = 0
    for task in tasks:
        content = task.content
        if not content:
            continue
        if content.get("options"):
            continue
        if task.task_type in voice_task_types:
            continue

        new_options: list[str] = []
        new_correct = ""

        # --- 1. Derive from choices (many task types) ---
        choices = content.get("choices")
        if isinstance(choices, list) and choices:
            first = choices[0]
            if isinstance(first, dict):
                # Dict choices: extract text/name/label
                for ch in choices:
                    text = (
                        ch.get("text")
                        or ch.get("label")
                        or ch.get("name")
                        or ch.get("image_name")
                        or ""
                    )
                    if text:
                        new_options.append(text)
                    if ch.get("is_correct") or ch.get("is_best") or ch.get("is_target"):
                        new_correct = text
            elif isinstance(first, str):
                # String choices: use as-is
                new_options = list(choices)
                new_correct = choices[0] if choices else ""

        # --- 1b. Derive from actions_sequence/objects (follow_instruction L2) ---
        if not new_options:
            actions_seq = content.get("actions_sequence")
            objects = content.get("objects")
            if isinstance(actions_seq, list) and isinstance(objects, list) and objects:
                for obj in objects:
                    if isinstance(obj, dict):
                        name = obj.get("name", "")
                        if name and name not in new_options:
                            new_options.append(name)
                # correct = first action target
                if actions_seq and isinstance(actions_seq[0], dict):
                    new_correct = actions_seq[0].get("target", "")

        # --- 1c. Derive from single action field (expanded imitate_action) ---
        if not new_options:
            action = content.get("action")
            if (
                isinstance(action, str)
                and action
                and task.task_type == "imitate_action"
            ):
                label = action.replace("_", " ").title()
                new_options = [label]
                new_correct = label

        # --- 2. Derive from distractors + target (attend, joint_attention) ---
        if not new_options:
            target = content.get("target")
            distractors = content.get("distractors")
            if isinstance(distractors, list) and distractors and target:
                if isinstance(target, dict):
                    target_name = (
                        target.get("name")
                        or target.get("action")
                        or target.get("emotion")
                        or ""
                    )
                else:
                    target_name = str(target)
                if target_name:
                    new_options.append(target_name)
                    new_correct = target_name
                for d in distractors:
                    if isinstance(d, dict):
                        d_name = (
                            d.get("name") or d.get("action") or d.get("emotion") or ""
                        )
                    else:
                        d_name = str(d)
                    if d_name and d_name not in new_options:
                        new_options.append(d_name)

            # Also handle emotion-based attend tasks
            emotion = content.get("emotion")
            if not new_options and emotion:
                new_options = ["Happy", "Sad"]
                new_correct = emotion.capitalize()

        # --- 3. Derive from sequence (turn_take tasks) ---
        if not new_options:
            sequence = content.get("sequence")
            if isinstance(sequence, list) and sequence:
                if isinstance(sequence[0], dict):
                    labels = []
                    for s in sequence:
                        label = s.get("label") or s.get("action") or ""
                        if label and label not in labels:
                            labels.append(label)
                    new_options = labels[:4]
                elif isinstance(sequence[0], str):
                    unique = list(dict.fromkeys(sequence))
                    new_options = unique[:4]
                if new_options:
                    new_correct = new_options[0]

        # --- 4. Derive from steps (sequence_order, follow_instruction) ---
        if not new_options:
            steps = content.get("steps")
            if isinstance(steps, list) and steps:
                if isinstance(steps[0], dict):
                    sorted_steps = sorted(steps, key=lambda s: s.get("order", 0))
                    new_options = [
                        s.get("text") or s.get("action") or "" for s in steps
                    ]
                    new_correct = (
                        (
                            sorted_steps[0].get("text")
                            or sorted_steps[0].get("action")
                            or ""
                        )
                        if sorted_steps
                        else ""
                    )
                    if not content.get("items"):
                        content["items"] = [
                            s.get("text") or s.get("action") or "" for s in sorted_steps
                        ]
                elif isinstance(steps[0], str):
                    new_options = list(steps)
                    new_correct = steps[0] if steps else ""

        # --- 5. Derive from items (pair, sort, classify, abstract) ---
        if not new_options:
            items = content.get("items")
            if isinstance(items, list) and items:
                if isinstance(items[0], dict):
                    names = list(
                        dict.fromkeys(i.get("name", "") for i in items if i.get("name"))
                    )
                    new_options = names[:6]
                    # Pair tasks
                    pair_id = content.get("correct_pair")
                    if pair_id:
                        for item in items:
                            if (
                                isinstance(item, dict)
                                and item.get("pair_id") == pair_id
                            ):
                                new_correct = item.get("name", "")
                                break
                    # Sort/classify: first target item
                    if not new_correct:
                        for item in items:
                            if isinstance(item, dict) and item.get("is_target"):
                                new_correct = item.get("name", "")
                                break
                    # Abstract (odd-one-out): the odd item
                    if not new_correct:
                        for item in items:
                            if isinstance(item, dict) and item.get("is_odd"):
                                new_correct = item.get("name", "")
                                break
                elif isinstance(items[0], str):
                    new_options = list(items[:6])
                    target_cat = content.get("target_category")
                    if target_cat:
                        new_correct = items[0]

        if new_options:
            content["options"] = new_options
            if new_correct:
                content["correct_answer"] = new_correct
            task.content = content
            flag_modified(task, "content")
            updated += 1

    if updated:
        db.commit()
    return updated


def backfill_target_words(db: Session) -> int:
    """Backfill target_word and image_hint for voice-input tasks.

    Derives target_word from target_phrase (describe), correct_sentence /
    target_sentence (build_sentence), or first example_answers entry
    (conversation) so the iOS speech recognition flow can evaluate the
    child's spoken response.

    Also adds image_hint for build_sentence / conversation tasks that
    are missing it, using a sensible keyword from the task content.
    """
    # Mapping from task content keywords to existing Cloudinary assets
    _KEYWORD_TO_IMAGE: dict[str, str] = {
        "dog": "dog",
        "cat": "cat",
        "ball": "ball",
        "apple": "apple",
        "banana": "banana",
        "bus": "bus",
        "tree": "tree",
        "fish": "fish",
        "bird": "bird",
        "rabbit": "rabbit",
        "car": "car",
        "spoon": "spoon",
        "cup": "cup",
        "hat": "hat",
        "shoe": "shoe",
        "star": "star",
        "moon": "moon",
        "pencil": "pencil",
        "crayon": "crayon",
        "teddy": "teddy_bear",
        "toy": "teddy_bear",
        "block": "ball",
        "food": "apple",
        "cereal": "spoon",
        "milk": "cup",
        "egg": "spoon",
        "play": "ball",
        "happy": "star",
        "family": "star",
        "color": "crayon",
        "blue": "blue",
        "red": "crayon",
        "doctor": "pencil",
    }

    tasks = (
        db.query(AdaptiveTask)
        .filter(
            AdaptiveTask.is_assessment == False,  # noqa: E712
        )
        .all()
    )
    updated = 0
    for task in tasks:
        content = task.content
        if not content:
            continue

        changed = False
        needs_tw = not content.get("target_word")

        new_tw = None
        if needs_tw:
            if task.task_type == "describe":
                new_tw = (
                    content.get("target_phrase")
                    or (content.get("target_phrases", []) or [None])[0]
                )
                # Also derive image_hint from scene for legacy tasks
                if not content.get("image_hint") and content.get("scene"):
                    scene = content["scene"].lower()
                    for word in ["ball", "bus", "cat", "dog", "banana", "tree"]:
                        if word in scene:
                            content["image_hint"] = word
                            break
            elif task.task_type == "build_sentence":
                new_tw = content.get("correct_sentence") or content.get(
                    "target_sentence"
                )
            elif task.task_type == "conversation":
                examples = content.get("example_answers", [])
                if examples:
                    new_tw = examples[0]

            if new_tw:
                content["target_word"] = new_tw
                changed = True

        # Also derive image_hint for voice tasks missing it
        if not content.get("image_hint") and task.task_type in (
            "build_sentence",
            "conversation",
            "describe",
        ):
            # Try to find a keyword from the task content that maps to a
            # known Cloudinary asset
            search_text = " ".join(
                [
                    content.get("target_word", ""),
                    content.get("target_sentence", ""),
                    content.get("question", ""),
                    " ".join(content.get("example_answers", [])),
                ]
            ).lower()
            search_words = set(search_text.split())
            for keyword, asset in _KEYWORD_TO_IMAGE.items():
                if keyword in search_words:
                    content["image_hint"] = asset
                    changed = True
                    break

        if changed:
            task.content = content
            flag_modified(task, "content")
            updated += 1

    if updated:
        db.commit()
    return updated


def backfill_image_hints(db: Session) -> int:
    """Add image_hint to every task whose content is missing it.

    Scans all AdaptiveTask rows, derives image_hint from the content
    dict, and persists the update.  Returns the number of tasks updated.
    """
    tasks = db.query(AdaptiveTask).all()
    updated = 0
    for task in tasks:
        content = task.content
        if not content or content.get("image_hint"):
            continue
        hint = _derive_image_hint(content)
        if hint:
            content["image_hint"] = hint
            task.content = content
            flag_modified(task, "content")
            updated += 1
    if updated:
        db.commit()
    return updated


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
