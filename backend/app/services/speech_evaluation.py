"""
Speech evaluation service for language expression tasks.

Provides text similarity scoring to evaluate spoken responses against
target words/phrases.  Uses Levenshtein-based similarity (consistent
with the existing say-word game logic) so no external API is needed.

Also provides AI-powered evaluation for open-ended questions where there
is no single correct answer (e.g. "What is your favorite animal?").
"""

import logging
import os
from difflib import SequenceMatcher
from typing import Optional

import httpx

logger = logging.getLogger(__name__)


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


# ---------------------------------------------------------------------------
# AI-powered open-ended evaluation
# ---------------------------------------------------------------------------


def _keyword_fallback(
    question: str,
    spoken: str,
    example_answers: list[str],
    keywords: list[str],
) -> dict:
    """Fallback evaluation when no LLM is available.

    Accepts the response if it contains at least one relevant keyword
    OR is similar enough to any example answer, AND is more than just
    a single filler word.
    """
    spoken_lower = spoken.strip().lower()

    # Reject empty / very short responses that are likely noise
    if len(spoken_lower.split()) < 1:
        return {
            "is_accepted": False,
            "score": 0.0,
            "feedback": "no_response",
            "evaluation_method": "keyword_fallback",
        }

    # Check keyword match
    spoken_words = set(spoken_lower.split())
    keywords_lower = [k.lower() for k in keywords]
    matched_keywords = spoken_words & set(keywords_lower)

    if matched_keywords:
        # Spoken text contains a relevant keyword — accept
        return {
            "is_accepted": True,
            "score": 0.8,
            "feedback": "good_answer",
            "evaluation_method": "keyword_fallback",
        }

    # Check similarity against example answers
    best_sim = 0.0
    for example in example_answers:
        sim = SequenceMatcher(None, spoken_lower, example.lower()).ratio()
        best_sim = max(best_sim, sim)

    if best_sim >= 0.4:
        return {
            "is_accepted": True,
            "score": round(0.5 + best_sim * 0.5, 2),
            "feedback": "good_answer",
            "evaluation_method": "keyword_fallback",
        }

    # If the child said at least two words, give benefit of the doubt
    # for very young children who may use unconventional phrasing
    if len(spoken_lower.split()) >= 2:
        return {
            "is_accepted": True,
            "score": 0.6,
            "feedback": "good_try",
            "evaluation_method": "keyword_fallback",
        }

    return {
        "is_accepted": False,
        "score": round(best_sim, 2),
        "feedback": "try_again",
        "evaluation_method": "keyword_fallback",
    }


def evaluate_open_ended(
    question: str,
    spoken: str,
    example_answers: Optional[list[str]] = None,
    keywords: Optional[list[str]] = None,
) -> dict:
    """Evaluate an open-ended spoken response using AI.

    For questions like "What is your favorite animal?" there is no single
    correct answer.  This function uses an LLM to judge whether the child's
    response is a reasonable answer to the question.

    Falls back to keyword matching when no LLM API key is configured.

    Args:
        question: The open-ended question that was asked.
        spoken: What the child actually said (transcribed text).
        example_answers: Optional list of example acceptable answers.
        keywords: Optional list of relevant keywords.

    Returns:
        dict with is_accepted, score (0-1), feedback, evaluation_method.
    """
    if not spoken or not spoken.strip():
        return {
            "is_accepted": False,
            "score": 0.0,
            "feedback": "no_response",
            "evaluation_method": "none",
        }

    api_key = os.getenv("OPENAI_API_KEY", "")
    if not api_key:
        return _keyword_fallback(
            question,
            spoken,
            example_answers or [],
            keywords or [],
        )

    # Build LLM prompt
    base_url = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    examples_text = ""
    if example_answers:
        examples_text = (
            "\n\nExample acceptable answers:\n"
            + "\n".join(f"- {a}" for a in example_answers)
        )

    system_prompt = (
        "You are evaluating a young child's (age 3-7) spoken response to an "
        "open-ended question in a language learning app for children with autism. "
        "The child's speech has been transcribed and may contain errors.\n\n"
        "Rules:\n"
        "1. Be VERY lenient — any response that attempts to answer the question "
        "should be accepted, even if grammar is poor or the answer is unusual.\n"
        "2. Accept creative or unexpected answers (e.g. 'dinosaur' for favorite "
        "animal is perfectly fine).\n"
        "3. Accept partial answers or single words that are relevant.\n"
        "4. Only reject responses that are completely unrelated to the question, "
        "or are just noise/filler words like 'um' or 'uh'.\n"
        "5. Respond ONLY with valid JSON: "
        '{"is_accepted": true/false, "score": 0.0-1.0, "feedback": "..."}\n'
        '   - feedback must be one of: "excellent", "good_answer", "good_try", '
        '"try_again", "no_response"\n'
        "   - score: 0.9-1.0 for clear relevant answers, 0.6-0.8 for partial/"
        "unusual but acceptable, 0.0-0.5 for unrelated"
    )

    user_prompt = (
        f"Question asked: \"{question}\"\n"
        f"Child's response: \"{spoken}\""
        f"{examples_text}"
    )

    try:
        with httpx.Client(timeout=15.0) as client:
            resp = client.post(
                f"{base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": model,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt},
                    ],
                    "temperature": 0.1,
                    "max_tokens": 100,
                },
            )
            resp.raise_for_status()
            data = resp.json()
            content = data["choices"][0]["message"]["content"]

            import json

            # Strip markdown fences if present
            content = content.strip()
            if content.startswith("```"):
                content = content.split("\n", 1)[-1]
                content = content.rsplit("```", 1)[0]
                content = content.strip()

            result = json.loads(content)
            return {
                "is_accepted": bool(result.get("is_accepted", False)),
                "score": float(result.get("score", 0.0)),
                "feedback": result.get("feedback", "good_try"),
                "evaluation_method": "ai",
            }
    except Exception as exc:
        logger.warning("LLM open-ended evaluation failed, using fallback: %s", exc)
        return _keyword_fallback(
            question,
            spoken,
            example_answers or [],
            keywords or [],
        )
