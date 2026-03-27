"""
Speech evaluation service for language expression tasks.

Provides text similarity scoring to evaluate spoken responses against
target words/phrases.  Uses Levenshtein-based similarity (consistent
with the existing say-word game logic) so no external API is needed.
"""

from difflib import SequenceMatcher


def evaluate_speech(
    target: str,
    spoken: str,
    accept_threshold: float = 0.6,
) -> dict:
    """Evaluate a spoken response against the target word/phrase.

    Args:
        target: The expected word or phrase.
        spoken: What the child actually said (transcribed text).
        accept_threshold: Minimum similarity to count as correct (0-1).

    Returns:
        dict with similarity_score, is_accepted, feedback.
    """
    if not target or not spoken:
        return {
            "similarity_score": 0.0,
            "is_accepted": False,
            "feedback": "no_response",
        }

    target_lower = target.strip().lower()
    spoken_lower = spoken.strip().lower()

    # Exact match fast-path
    if target_lower == spoken_lower:
        return {
            "similarity_score": 1.0,
            "is_accepted": True,
            "feedback": "perfect",
        }

    # SequenceMatcher gives a ratio in [0, 1]
    similarity = SequenceMatcher(None, target_lower, spoken_lower).ratio()

    # Determine feedback tier
    if similarity >= 0.9:
        feedback = "excellent"
    elif similarity >= accept_threshold:
        feedback = "good_try"
    elif similarity >= accept_threshold * 0.6:
        feedback = "keep_trying"
    else:
        feedback = "try_again"

    return {
        "similarity_score": round(similarity, 3),
        "is_accepted": similarity >= accept_threshold,
        "feedback": feedback,
    }
