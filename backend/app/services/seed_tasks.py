"""
Seed tasks for the adaptive learning system.

Phase 1: Object Cognition dimension with 5 levels (0-4).
Phase 2: Language Expression and Language Comprehension dimensions.

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


def seed_language_expression_tasks(db: Session) -> int:
    """Seed language expression tasks. Returns count of tasks created."""
    existing = db.query(AdaptiveTask).filter(
        AdaptiveTask.dimension == DevelopmentalDimension.LANGUAGE_EXPRESSION.value
    ).count()

    if existing > 0:
        return 0

    tasks = []

    # ---- Level 0: Imitation ----
    tasks.extend([
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
            is_assessment=True,
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
    ])

    # ---- Level 1: Naming ----
    tasks.extend([
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
            is_assessment=True,
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
    ])

    # ---- Level 2: Description ----
    tasks.extend([
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
            is_assessment=True,
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
    ])

    # ---- Level 3: Sentence Building ----
    tasks.extend([
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
            is_assessment=True,
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
    ])

    # ---- Level 4: Conversation ----
    tasks.extend([
        AdaptiveTask(
            dimension=DevelopmentalDimension.LANGUAGE_EXPRESSION.value,
            level=4,
            task_type=TaskType.CONVERSATION.value,
            modalities=[Modality.VOICE.value, Modality.TEXT.value],
            content={
                "instruction_audio": "Answer the question!",
                "instruction_text": "Answer the question",
                "question": "What is your favorite animal?",
                "example_answers": ["I like dogs", "My favorite animal is a cat", "I love fish"],
                "keywords": ["dog", "cat", "bird", "fish", "rabbit", "animal", "like", "love", "favorite"],
                "accept_threshold": 0.3,
            },
            is_assessment=True,
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
                "keywords": ["ate", "eat", "breakfast", "cereal", "milk", "eggs", "bread", "juice"],
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
                "example_answers": ["I like to play with blocks", "I play with my toys", "I like balls"],
                "keywords": ["play", "toy", "ball", "block", "game", "like", "fun"],
                "accept_threshold": 0.3,
            },
            is_assessment=False,
        ),
    ])

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def seed_language_comprehension_tasks(db: Session) -> int:
    """Seed language comprehension tasks. Returns count of tasks created."""
    existing = db.query(AdaptiveTask).filter(
        AdaptiveTask.dimension == DevelopmentalDimension.LANGUAGE_COMPREHENSION.value
    ).count()

    if existing > 0:
        return 0

    tasks = []

    # ---- Level 0: Point-to ----
    tasks.extend([
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
            is_assessment=True,
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
    ])

    # ---- Level 1: Simple Instructions ----
    tasks.extend([
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
            is_assessment=True,
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
    ])

    # ---- Level 2: Multi-step Instructions ----
    tasks.extend([
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
            is_assessment=True,
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
    ])

    # ---- Level 3: Story Comprehension ----
    tasks.extend([
        AdaptiveTask(
            dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
            level=3,
            task_type=TaskType.STORY_COMPREHENSION.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value, Modality.TEXT.value],
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
            is_assessment=True,
        ),
        AdaptiveTask(
            dimension=DevelopmentalDimension.LANGUAGE_COMPREHENSION.value,
            level=3,
            task_type=TaskType.STORY_COMPREHENSION.value,
            modalities=[Modality.TOUCH.value, Modality.VOICE.value, Modality.TEXT.value],
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
            modalities=[Modality.TOUCH.value, Modality.VOICE.value, Modality.TEXT.value],
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
    ])

    # ---- Level 4: Inference ----
    tasks.extend([
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
            is_assessment=True,
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
    ])

    for task in tasks:
        db.add(task)

    db.commit()
    return len(tasks)


def seed_all_tasks(db: Session) -> dict:
    """Seed all task dimensions. Returns counts per dimension."""
    results = {}
    results["object_cognition"] = seed_object_cognition_tasks(db)
    results["language_expression"] = seed_language_expression_tasks(db)
    results["language_comprehension"] = seed_language_comprehension_tasks(db)
    return results
