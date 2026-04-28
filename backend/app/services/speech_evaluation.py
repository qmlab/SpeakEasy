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
import re
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

    # Also check if the spoken text contains the target as a substring
    # (e.g. child says "it's an apple" for target "apple")
    target_pattern = r"\b" + re.escape(target_lower) + r"\b"
    if (len(target_lower) >= 3 and re.search(target_pattern, spoken_lower)) or (
        spoken_lower in target_lower
        and len(spoken_lower) >= 3
        and len(spoken_lower) / len(target_lower) >= 0.5
    ):
        similarity = max(similarity, 0.85)

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
    strict_mode: bool = False,
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

    # Check keyword match — also check partial matches (keyword
    # contained within a spoken word, e.g. "apples" matches "apple")
    spoken_words = set(spoken_lower.split())
    keywords_lower = [k.lower() for k in keywords]
    matched_keywords = spoken_words & set(keywords_lower)

    # Partial keyword matching: "apples" contains "apple"
    if not matched_keywords:
        for spoken_word in spoken_words:
            for kw in keywords_lower:
                if (
                    len(kw) >= 3
                    and len(spoken_word) >= 3
                    and (kw in spoken_word or spoken_word in kw)
                ):
                    matched_keywords.add(kw)
                    break

    if matched_keywords:
        return {
            "is_accepted": True,
            "score": 0.8,
            "feedback": "good_answer",
            "evaluation_method": "keyword_fallback",
        }

    # Check similarity against example answers — lowered threshold
    # for young children who may give approximate answers
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

    # If the child said at least one meaningful word, give benefit
    # of the doubt — but only for truly open-ended questions, not
    # when checking against a specific correct answer
    if not strict_mode:
        word_count = len(spoken_lower.split())
        filler_words = {"um", "uh", "ah", "hmm", "hm", "oh", "a", "the", "i"}
        meaningful_words = spoken_words - filler_words
        if meaningful_words and word_count >= 2:
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
    strict_mode: bool = False,
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
            strict_mode=strict_mode,
        )

    # Build LLM prompt
    base_url = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    examples_text = ""
    if example_answers:
        examples_text = "\n\nExample acceptable answers:\n" + "\n".join(
            f"- {a}" for a in example_answers
        )

    if strict_mode:
        system_prompt = (
            "You are evaluating a young child's (age 3-7) spoken response in a "
            "language learning app. The child's speech has been transcribed and "
            "may contain pronunciation errors or stuttering.\n\n"
            "The child must answer with the CORRECT answer. Rules:\n"
            "1. Accept if the child's response is semantically equivalent to the "
            "correct answer, even with poor pronunciation or grammar.\n"
            "2. Accept partial matches: 'doggy' for 'dog', 'kitty' for 'cat'.\n"
            "3. Accept if the child clearly said the right word but with speech "
            "errors (e.g. 'daw' for 'dog').\n"
            "4. REJECT if the child said a completely different word or concept.\n"
            "5. Respond ONLY with valid JSON: "
            '{"is_accepted": true/false, "score": 0.0-1.0, "feedback": "..."}\n'
            '   - feedback must be one of: "excellent", "good_answer", "good_try", '
            '"try_again", "no_response"\n'
            "   - score: 0.9-1.0 for clear correct answers, 0.5-0.8 for "
            "approximate but recognizable, 0.0-0.4 for wrong answers"
        )
    else:
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
        f'Question asked: "{question}"\nChild\'s response: "{spoken}"{examples_text}'
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
            strict_mode=strict_mode,
        )
