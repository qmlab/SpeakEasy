"""
AI Personalization Service for Rising Star Kid.

Provides LLM-powered content generation for:
- Social stories tailored to a child's social behavior level
- Behavior guidance for parents/therapists
- Natural-language progress summaries
- Personalized task content generation

When an OpenAI-compatible API key is configured (OPENAI_API_KEY env var),
real LLM calls are made.  Otherwise the service falls back to rich,
template-based generation so the app works out of the box without any
external dependency.
"""

import os
import json
import logging
import re
from typing import Optional

import httpx
from sqlalchemy.orm import Session
from sqlalchemy import desc, func

from app.models.adaptive import (
    DevelopmentalProfile,
    LearningSession,
    TaskAttempt,
    AdaptiveTask,
    DevelopmentalDimension,
)
from app.models.player import Player
from app.schemas.ai import (
    SocialStoryResponse,
    BehaviorGuidanceResponse,
    ProgressSummaryResponse,
    TaskContentResponse,
)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Dimension metadata used by both LLM prompts and template fallback
# ---------------------------------------------------------------------------

DIMENSION_LABELS: dict[str, str] = {
    "object_cognition": "物体认知 (Object Cognition)",
    "language_expression": "语言表达 (Language Expression)",
    "language_comprehension": "语言理解 (Language Comprehension)",
    "literacy": "识字 (Literacy)",
    "social_behavior": "社交行为 (Social Behavior)",
    "cognitive_logic": "认知逻辑 (Cognitive Logic)",
}

LEVEL_DESCRIPTIONS: dict[str, list[str]] = {
    "object_cognition": [
        "matching identical objects",
        "identifying objects by name",
        "classifying objects into categories",
        "understanding object functions",
        "abstract associations between objects",
    ],
    "language_expression": [
        "imitating sounds and words",
        "naming familiar objects",
        "describing pictures and events",
        "building simple sentences",
        "engaging in short conversations",
    ],
    "language_comprehension": [
        "pointing to named objects",
        "following single-step instructions",
        "comprehending short stories",
        "inferring meaning from context",
        "understanding complex multi-step narratives",
    ],
    "literacy": [
        "recognizing images",
        "matching words to images",
        "reading single words",
        "reading simple sentences",
        "reading short passages",
    ],
    "social_behavior": [
        "attending to social stimuli",
        "imitating actions of others",
        "taking turns in simple activities",
        "sharing joint attention with others",
        "initiating social interactions",
    ],
    "cognitive_logic": [
        "pairing related items",
        "sorting objects by attributes",
        "understanding cause and effect",
        "sequencing events in order",
        "reasoning through novel problems",
    ],
}

# ---------------------------------------------------------------------------
# Social story templates (one per social_behavior level)
# ---------------------------------------------------------------------------

_SOCIAL_STORY_TEMPLATES: list[dict] = [
    {
        "title": "Looking at My Friend",
        "story": (
            "When someone says my name, I can look at them. "
            "Looking at people helps me know what is happening. "
            "I will try to look when someone calls me. "
            "That makes people happy, and I feel good too."
        ),
        "target_skill": "Attending to social stimuli",
        "practice_tips": [
            "Call the child's name and gently redirect their gaze",
            "Use an interesting toy near your face to draw attention",
            "Praise immediately when the child makes eye contact",
        ],
    },
    {
        "title": "Copy Cat Game",
        "story": (
            "Sometimes my friend does something fun, like clapping or waving. "
            "I can try to do the same thing! It is like a copy game. "
            "When I copy what my friend does, we both laugh. "
            "Copying is a way to play together."
        ),
        "target_skill": "Imitating actions",
        "practice_tips": [
            "Start with simple, exaggerated actions (clapping, stomping)",
            "Use a mirror so the child can see themselves imitating",
            "Celebrate every attempt, even partial imitations",
        ],
    },
    {
        "title": "My Turn, Your Turn",
        "story": (
            "When I play with a friend, we take turns. "
            "First it is my turn, then it is my friend's turn. "
            "Waiting can be hard, but I can do it. "
            "Taking turns makes the game fun for everyone."
        ),
        "target_skill": "Turn-taking",
        "practice_tips": [
            "Use a visual timer to make the wait concrete",
            "Practice with highly motivating activities first",
            "Use a 'turn card' the child can hold when it is their turn",
        ],
    },
    {
        "title": "Look What I Found!",
        "story": (
            "Sometimes I see something interesting, like a bird or a funny picture. "
            "I can point to it and look at my friend to share. "
            "When we both look at the same thing, it feels nice. "
            "Sharing what I see is a way to connect with others."
        ),
        "target_skill": "Joint attention",
        "practice_tips": [
            "Model pointing to interesting things during daily routines",
            "Follow the child's gaze and comment on what they see",
            "Use bubbles or balloons as natural joint-attention targets",
        ],
    },
    {
        "title": "I Can Start a Game",
        "story": (
            "I want to play with my friend. I can go to them and say 'Let's play!' "
            "or show them a toy. Starting a game by myself is brave. "
            "My friend might say yes! Then we play together. "
            "Even if they are busy, I can try again later."
        ),
        "target_skill": "Initiating social interactions",
        "practice_tips": [
            "Role-play initiating with stuffed animals first",
            "Create visual scripts the child can reference",
            "Set up structured play dates with coached peers",
        ],
    },
]

# ---------------------------------------------------------------------------
# Behavior guidance templates (by dimension)
# ---------------------------------------------------------------------------

_GUIDANCE_BY_DIMENSION: dict[str, list[str]] = {
    "object_cognition": [
        "Use real objects during daily routines—let the child sort laundry by color or match socks.",
        "Label objects consistently; use the same word each time so the child builds a stable mapping.",
        "Create a 'function box': put objects in a box and ask 'What do we do with this?' to practice function understanding.",
    ],
    "language_expression": [
        "Model language one step above the child's current level (if they use single words, model two-word phrases).",
        "Wait 5-10 seconds after asking a question to give the child processing time.",
        "Use 'sabotage' strategies: give a closed container or a toy with missing pieces to create communication opportunities.",
    ],
    "language_comprehension": [
        "Pair verbal instructions with gestures or visual supports initially.",
        "Break multi-step instructions into single steps and gradually chain them.",
        "Read the same short story repeatedly; familiarity supports comprehension growth.",
    ],
    "literacy": [
        "Label objects around the house with their written names to build word-object associations.",
        "Use finger-tracking while reading together so the child follows text left to right.",
        "Create personalized books with photos of the child's own experiences and simple captions.",
    ],
    "social_behavior": [
        "Practice social skills in structured, low-stimulation environments before generalization.",
        "Use video modeling: show short clips of peers demonstrating the target social skill.",
        "Create a visual 'social script' card the child can reference during interactions.",
    ],
    "cognitive_logic": [
        "Use everyday sorting opportunities: sorting groceries, organizing toys by category.",
        "Ask 'what happens next?' during daily routines to build sequencing skills.",
        "Play simple cause-and-effect toys (e.g., pop-up toys, light switches) to reinforce the concept.",
    ],
}

# ---------------------------------------------------------------------------
# LLM client wrapper
# ---------------------------------------------------------------------------


class _LLMClient:
    """Thin wrapper around an OpenAI-compatible chat-completions API."""

    def __init__(self) -> None:
        self.api_key: str = os.getenv("OPENAI_API_KEY", "")
        self.base_url: str = os.getenv(
            "OPENAI_BASE_URL", "https://api.openai.com/v1"
        )
        self.model: str = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        self.enabled: bool = bool(self.api_key)

    def call(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> Optional[str]:
        """Synchronous chat-completion call. Returns None on failure."""
        if not self.enabled:
            return None
        try:
            with httpx.Client(timeout=30.0) as client:
                resp = client.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": self.model,
                        "messages": [
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": user_prompt},
                        ],
                        "temperature": temperature,
                        "max_tokens": max_tokens,
                    },
                )
                resp.raise_for_status()
                data = resp.json()
                return data["choices"][0]["message"]["content"]
        except Exception as exc:
            logger.warning("LLM call failed, falling back to templates: %s", exc)
            return None


_llm = _LLMClient()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


class AIService:
    """High-level AI personalization service."""

    def __init__(self, db: Session):
        self.db = db

    # -- helpers --

    def _get_player(self, player_id: str) -> Player:
        player = self.db.query(Player).filter(Player.id == player_id).first()
        if not player:
            raise ValueError(f"Player {player_id} not found")
        return player

    def _get_profiles(self, player_id: str) -> list[DevelopmentalProfile]:
        return (
            self.db.query(DevelopmentalProfile)
            .filter(DevelopmentalProfile.player_id == player_id)
            .all()
        )

    def _get_recent_sessions(
        self, player_id: str, limit: int = 5
    ) -> list[LearningSession]:
        return (
            self.db.query(LearningSession)
            .filter(LearningSession.player_id == player_id)
            .order_by(desc(LearningSession.started_at))
            .limit(limit)
            .all()
        )

    def _profile_summary_text(self, profiles: list[DevelopmentalProfile]) -> str:
        lines: list[str] = []
        for p in profiles:
            label = DIMENSION_LABELS.get(p.dimension, p.dimension)
            descs = LEVEL_DESCRIPTIONS.get(p.dimension, [])
            ability = descs[p.level] if p.level < len(descs) else "advanced"
            lines.append(f"- {label}: Level {p.level} – currently {ability}")
        return "\n".join(lines)

    # ----------------------------------------------------------------
    # 1. Social Story Generation
    # ----------------------------------------------------------------

    def generate_social_story(
        self,
        player_id: str,
        scenario: Optional[str] = None,
        language: str = "en",
    ) -> dict:
        """Generate a personalized social story.

        If an LLM is available it generates a fully custom story.
        Otherwise it picks the best-fit template based on social_behavior level.
        """
        player = self._get_player(player_id)
        profiles = self._get_profiles(player_id)
        profile_text = self._profile_summary_text(profiles)

        social_profile = next(
            (p for p in profiles if p.dimension == "social_behavior"), None
        )
        social_level = social_profile.level if social_profile else 0

        # Try LLM first
        lang_instruction = "Respond in Chinese (简体中文)." if language == "zh" else "Respond in English."
        system_prompt = (
            "You are an expert ABA therapist and children's story author. "
            "Write a short, personalized social story for a child with autism. "
            "The story must be in first person, use simple concrete language, "
            "and follow Carol Gray's Social Stories™ guidelines. "
            "Return valid JSON with keys: title, story, target_skill, practice_tips (list of 3 strings). "
            f"{lang_instruction}"
        )
        scenario_text = f"Specific scenario requested: {scenario}" if scenario else "No specific scenario; create one appropriate for the level."
        user_prompt = (
            f"Child profile:\n{profile_text}\n\n"
            f"Child's name: {player.name}\n"
            f"Social behavior level: {social_level}\n"
            f"Current ability: {LEVEL_DESCRIPTIONS['social_behavior'][min(social_level, len(LEVEL_DESCRIPTIONS['social_behavior']) - 1)]}\n"
            f"{scenario_text}\n\n"
            "Generate a social story."
        )

        llm_response = _llm.call(system_prompt, user_prompt, temperature=0.8)
        if llm_response:
            try:
                result = self._parse_json_response(llm_response)
                result["source"] = "llm"
                result["player_id"] = player_id
                # Validate against the response schema before returning
                SocialStoryResponse(**result)
                return result
            except Exception:
                logger.warning("Failed to parse/validate LLM social story response")

        # Template fallback
        template = _SOCIAL_STORY_TEMPLATES[min(social_level, len(_SOCIAL_STORY_TEMPLATES) - 1)]
        return {
            "player_id": player_id,
            "title": template["title"],
            "story": template["story"],
            "target_skill": template["target_skill"],
            "practice_tips": template["practice_tips"],
            "social_level": social_level,
            "source": "template",
        }

    # ----------------------------------------------------------------
    # 2. Behavior Guidance
    # ----------------------------------------------------------------

    def generate_behavior_guidance(
        self,
        player_id: str,
        dimension: Optional[str] = None,
        concern: Optional[str] = None,
        language: str = "en",
    ) -> dict:
        """Generate behavior guidance for parents/therapists.

        If a specific dimension is given, guidance is scoped to that area.
        Otherwise guidance covers all dimensions.
        """
        player = self._get_player(player_id)
        profiles = self._get_profiles(player_id)
        profile_text = self._profile_summary_text(profiles)

        sessions = self._get_recent_sessions(player_id, limit=5)
        session_summary = self._sessions_summary_text(sessions)

        # Try LLM
        lang_instruction = "Respond in Chinese (简体中文)." if language == "zh" else "Respond in English."
        system_prompt = (
            "You are a Board Certified Behavior Analyst (BCBA) providing guidance "
            "to parents and therapists of a child with autism. "
            "Give practical, evidence-based recommendations. "
            "Return valid JSON with keys: summary (string), recommendations (list of objects "
            "with keys: dimension, priority (high/medium/low), suggestion, rationale), "
            "home_activities (list of strings). "
            f"{lang_instruction}"
        )
        concern_text = f"Specific concern: {concern}" if concern else ""
        dim_text = f"Focus on dimension: {dimension}" if dimension else "Cover all dimensions."
        user_prompt = (
            f"Child: {player.name}\n"
            f"Profile:\n{profile_text}\n\n"
            f"Recent sessions:\n{session_summary}\n\n"
            f"{dim_text}\n{concern_text}\n\n"
            "Generate behavior guidance."
        )

        llm_response = _llm.call(system_prompt, user_prompt, temperature=0.6)
        if llm_response:
            try:
                result = self._parse_json_response(llm_response)
                result["source"] = "llm"
                result["player_id"] = player_id
                # Validate against the response schema before returning
                BehaviorGuidanceResponse(**result)
                return result
            except Exception:
                logger.warning("Failed to parse/validate LLM guidance response")

        # Template fallback
        recommendations = []
        target_dims = [dimension] if dimension else [d.value for d in DevelopmentalDimension]
        for dim in target_dims:
            profile = next((p for p in profiles if p.dimension == dim), None)
            level = profile.level if profile else 0
            tips = _GUIDANCE_BY_DIMENSION.get(dim, [])
            if tips:
                recommendations.append({
                    "dimension": dim,
                    "dimension_label": DIMENSION_LABELS.get(dim, dim),
                    "current_level": level,
                    "priority": "high" if level <= 1 else ("medium" if level <= 3 else "low"),
                    "suggestions": tips,
                })

        struggling_dims = [r["dimension_label"] for r in recommendations if r["priority"] == "high"]
        if struggling_dims:
            summary = f"{player.name} would benefit most from focused support in: {', '.join(struggling_dims)}."
        else:
            summary = f"{player.name} is making good progress across all dimensions. Continue current activities."

        home_activities = [
            "Set aside 10-15 minutes of structured 1-on-1 practice daily",
            "Use visual schedules to help the child predict and prepare for activities",
            "End each practice session with a preferred activity (Premack principle)",
        ]

        return {
            "player_id": player_id,
            "summary": summary,
            "recommendations": recommendations,
            "home_activities": home_activities,
            "source": "template",
        }

    # ----------------------------------------------------------------
    # 3. Progress Summary
    # ----------------------------------------------------------------

    def generate_progress_summary(
        self,
        player_id: str,
        language: str = "en",
    ) -> dict:
        """Generate a natural-language progress summary for parents/therapists."""
        player = self._get_player(player_id)
        profiles = self._get_profiles(player_id)
        profile_text = self._profile_summary_text(profiles)

        recent_sessions = self._get_recent_sessions(player_id, limit=10)
        session_summary = self._sessions_summary_text(recent_sessions)

        # Compute true lifetime stats (not capped by the recent-sessions window)
        total_sessions = (
            self.db.query(func.count(LearningSession.id))
            .filter(LearningSession.player_id == player_id)
            .scalar()
            or 0
        )
        total_attempts = (
            self.db.query(func.sum(LearningSession.total_count))
            .filter(LearningSession.player_id == player_id)
            .scalar()
            or 0
        )
        total_attempts = int(total_attempts)
        total_correct = (
            self.db.query(func.sum(LearningSession.correct_count))
            .filter(LearningSession.player_id == player_id)
            .scalar()
            or 0
        )
        total_correct = int(total_correct)
        overall_accuracy = (total_correct / total_attempts * 100) if total_attempts > 0 else 0

        # Dimension-level analysis
        dim_analysis: list[dict] = []
        for p in profiles:
            label = DIMENSION_LABELS.get(p.dimension, p.dimension)
            descs = LEVEL_DESCRIPTIONS.get(p.dimension, [])
            current = descs[p.level] if p.level < len(descs) else "advanced"
            next_skill = descs[p.level + 1] if p.level + 1 < len(descs) else None
            status = "advanced" if p.level >= 3 else ("progressing" if p.level >= 1 else "beginning")
            dim_analysis.append({
                "dimension": p.dimension,
                "dimension_label": label,
                "level": p.level,
                "current_ability": current,
                "next_skill": next_skill,
                "status": status,
            })

        # Try LLM for richer narrative
        lang_instruction = "Respond in Chinese (简体中文)." if language == "zh" else "Respond in English."
        system_prompt = (
            "You are a developmental specialist writing a progress report for parents "
            "of a child with autism. Write a warm, encouraging yet honest summary. "
            "Return valid JSON with keys: narrative (string, 3-5 paragraphs), "
            "strengths (list of strings), areas_for_growth (list of strings), "
            "next_steps (list of strings). "
            f"{lang_instruction}"
        )
        user_prompt = (
            f"Child: {player.name}\n"
            f"Profile:\n{profile_text}\n\n"
            f"Recent sessions ({total_sessions}):\n{session_summary}\n\n"
            f"Overall accuracy: {overall_accuracy:.1f}%\n"
            f"Total task attempts: {total_attempts}\n\n"
            "Generate a progress summary report."
        )

        llm_response = _llm.call(system_prompt, user_prompt, temperature=0.6)
        if llm_response:
            try:
                result = self._parse_json_response(llm_response)
                result["source"] = "llm"
                result["player_id"] = player_id
                result["dimensions"] = dim_analysis
                result["stats"] = {
                    "total_sessions": total_sessions,
                    "total_attempts": total_attempts,
                    "overall_accuracy": round(overall_accuracy, 1),
                }
                # Validate against the response schema before returning
                ProgressSummaryResponse(**result)
                return result
            except Exception:
                logger.warning("Failed to parse/validate LLM progress response")

        # Template fallback
        strengths = [
            d["dimension_label"]
            for d in dim_analysis
            if d["status"] in ("advanced", "progressing")
        ]
        growth_areas = [
            d["dimension_label"]
            for d in dim_analysis
            if d["status"] == "beginning"
        ]
        next_steps = []
        for d in dim_analysis:
            if d["next_skill"]:
                next_steps.append(
                    f"{d['dimension_label']}: work toward {d['next_skill']}"
                )

        if strengths:
            narrative = (
                f"{player.name} has been making wonderful progress! "
                f"Strong areas include: {', '.join(strengths)}. "
            )
        else:
            narrative = (
                f"{player.name} is at the beginning of their learning journey. "
                "Every small step is meaningful progress. "
            )

        if growth_areas:
            narrative += (
                f"Areas that would benefit from more focused practice: "
                f"{', '.join(growth_areas)}. "
            )

        narrative += (
            f"Across {total_sessions} total sessions, {player.name} has attempted "
            f"{total_attempts} tasks with an overall accuracy of {overall_accuracy:.0f}%. "
            "Keep up the great work!"
        )

        return {
            "player_id": player_id,
            "narrative": narrative,
            "strengths": strengths if strengths else ["Starting the learning journey"],
            "areas_for_growth": growth_areas if growth_areas else ["Building foundations across all areas"],
            "next_steps": next_steps if next_steps else ["Continue daily practice sessions"],
            "dimensions": dim_analysis,
            "stats": {
                "total_sessions": total_sessions,
                "total_attempts": total_attempts,
                "overall_accuracy": round(overall_accuracy, 1),
            },
            "source": "template",
        }

    # ----------------------------------------------------------------
    # 4. Personalized Task Content Generation
    # ----------------------------------------------------------------

    def generate_task_content(
        self,
        player_id: str,
        dimension: str,
        task_type: str,
        interests: Optional[list[str]] = None,
        language: str = "en",
        count: int = 3,
    ) -> dict:
        """Generate personalized task content based on child's profile and interests.

        This creates task content JSON that can be used to seed new
        AdaptiveTask rows tailored to the individual child.
        """
        player = self._get_player(player_id)
        profiles = self._get_profiles(player_id)
        profile = next((p for p in profiles if p.dimension == dimension), None)
        level = profile.level if profile else 0

        interests_text = ", ".join(interests) if interests else "animals, vehicles, food"

        # Try LLM
        lang_instruction = "Respond in Chinese (简体中文)." if language == "zh" else "Respond in English."
        system_prompt = (
            "You are a curriculum designer for children with autism. "
            "Generate task content for adaptive learning exercises. "
            "Tasks must be age-appropriate, use concrete language, and incorporate "
            "the child's interests to maximize engagement. "
            f"Return valid JSON with key 'tasks' containing a list of {count} objects, "
            "each with keys: instruction (string), correct_answer (string), "
            "options (list of strings, 2-4 choices), image_hint (string describing what image to show), "
            "difficulty_note (string). "
            f"{lang_instruction}"
        )
        descs = LEVEL_DESCRIPTIONS.get(dimension, [])
        level_desc = descs[level] if level < len(descs) else "advanced"
        user_prompt = (
            f"Child: {player.name}\n"
            f"Dimension: {DIMENSION_LABELS.get(dimension, dimension)}\n"
            f"Current level: {level} ({level_desc})\n"
            f"Task type: {task_type}\n"
            f"Child's interests: {interests_text}\n"
            f"Number of tasks: {count}\n\n"
            "Generate personalized task content."
        )

        llm_response = _llm.call(system_prompt, user_prompt, temperature=0.9, max_tokens=2048)
        if llm_response:
            try:
                result = self._parse_json_response(llm_response)
                result["source"] = "llm"
                result["player_id"] = player_id
                result["dimension"] = dimension
                result["task_type"] = task_type
                result["level"] = level
                # Validate against the response schema before returning
                TaskContentResponse(**result)
                return result
            except Exception:
                logger.warning("Failed to parse/validate LLM task content response")

        # Template fallback — generate simple tasks based on dimension + level
        tasks = self._generate_template_tasks(
            dimension, level, task_type, interests_text, count
        )

        return {
            "player_id": player_id,
            "dimension": dimension,
            "task_type": task_type,
            "level": level,
            "tasks": tasks,
            "source": "template",
        }

    # ----------------------------------------------------------------
    # 5. AI Configuration Status
    # ----------------------------------------------------------------

    def get_ai_status(self) -> dict:
        """Return current AI configuration status."""
        return {
            "llm_enabled": _llm.enabled,
            "model": _llm.model if _llm.enabled else None,
            "base_url": _llm.base_url if _llm.enabled else None,
            "fallback_mode": "template" if not _llm.enabled else "llm_with_template_fallback",
            "supported_features": [
                "social_story_generation",
                "behavior_guidance",
                "progress_summary",
                "task_content_generation",
            ],
        }

    # ----------------------------------------------------------------
    # Internal helpers
    # ----------------------------------------------------------------

    def _sessions_summary_text(self, sessions: list[LearningSession]) -> str:
        if not sessions:
            return "No recent sessions."
        lines: list[str] = []
        for s in sessions:
            acc = (s.correct_count / s.total_count * 100) if s.total_count else 0
            lines.append(
                f"- {s.dimension or 'mixed'} | {s.tasks_completed} tasks | "
                f"{acc:.0f}% accuracy | level {s.current_level}"
            )
        return "\n".join(lines)

    def _parse_json_response(self, text: str) -> dict:
        """Extract JSON from an LLM response that may include markdown fences."""
        text = text.strip()
        # Search for markdown code fences anywhere in the text
        fence_match = re.search(r"```(?:json)?\s*\n?(.*?)```", text, re.DOTALL | re.IGNORECASE)
        if fence_match:
            text = fence_match.group(1).strip()
        return json.loads(text)

    def _generate_template_tasks(
        self,
        dimension: str,
        level: int,
        task_type: str,
        interests: str,
        count: int,
    ) -> list[dict]:
        """Generate template-based task content as fallback."""
        interest_items = [i.strip() for i in interests.split(",")]
        tasks: list[dict] = []

        # Templates by dimension
        templates = _TASK_TEMPLATES.get(dimension, {}).get(level, [])
        if not templates:
            templates = _DEFAULT_TASK_TEMPLATES

        for i in range(count):
            interest = interest_items[i % len(interest_items)]
            template = templates[i % len(templates)]
            task = {
                "instruction": template["instruction"].format(interest=interest),
                "correct_answer": template["correct_answer"].format(interest=interest),
                "options": [opt.format(interest=interest) for opt in template["options"]],
                "image_hint": template["image_hint"].format(interest=interest),
                "difficulty_note": f"Level {level} - {task_type}",
            }
            tasks.append(task)

        return tasks


# ---------------------------------------------------------------------------
# Task content templates for fallback generation
# ---------------------------------------------------------------------------

_DEFAULT_TASK_TEMPLATES: list[dict] = [
    {
        "instruction": "Point to the {interest}",
        "correct_answer": "{interest}",
        "options": ["{interest}", "chair", "cup", "book"],
        "image_hint": "A picture of a {interest}",
    },
    {
        "instruction": "Find the {interest}",
        "correct_answer": "{interest}",
        "options": ["{interest}", "ball", "shoe", "hat"],
        "image_hint": "Several objects including a {interest}",
    },
    {
        "instruction": "Which one is a {interest}?",
        "correct_answer": "{interest}",
        "options": ["{interest}", "pencil", "spoon", "clock"],
        "image_hint": "Multiple items with a {interest} among them",
    },
]

_TASK_TEMPLATES: dict[str, dict[int, list[dict]]] = {
    "object_cognition": {
        0: [
            {
                "instruction": "Match this {interest} to the same one",
                "correct_answer": "{interest}",
                "options": ["{interest}", "ball", "cup"],
                "image_hint": "Two identical pictures of a {interest} and distractors",
            },
            {
                "instruction": "Find the one that looks the same as this {interest}",
                "correct_answer": "{interest}",
                "options": ["{interest}", "book", "shoe"],
                "image_hint": "A {interest} with matching and non-matching options",
            },
            {
                "instruction": "Which one matches this {interest}?",
                "correct_answer": "{interest}",
                "options": ["{interest}", "chair", "hat"],
                "image_hint": "Matching exercise with {interest}",
            },
        ],
        1: [
            {
                "instruction": "Where is the {interest}?",
                "correct_answer": "{interest}",
                "options": ["{interest}", "table", "lamp"],
                "image_hint": "Several objects; child must identify {interest}",
            },
            {
                "instruction": "Point to the {interest}",
                "correct_answer": "{interest}",
                "options": ["{interest}", "fork", "blanket"],
                "image_hint": "A scene containing a {interest}",
            },
            {
                "instruction": "Show me the {interest}",
                "correct_answer": "{interest}",
                "options": ["{interest}", "pillow", "bottle"],
                "image_hint": "Objects spread out including a {interest}",
            },
        ],
    },
    "language_expression": {
        0: [
            {
                "instruction": "Say '{interest}' after me",
                "correct_answer": "{interest}",
                "options": ["{interest}"],
                "image_hint": "A picture of a {interest} with the word below",
            },
            {
                "instruction": "Can you say '{interest}'?",
                "correct_answer": "{interest}",
                "options": ["{interest}"],
                "image_hint": "Colorful image of a {interest}",
            },
            {
                "instruction": "Repeat: {interest}",
                "correct_answer": "{interest}",
                "options": ["{interest}"],
                "image_hint": "A {interest} with audio prompt icon",
            },
        ],
    },
    "language_comprehension": {
        0: [
            {
                "instruction": "Point to the {interest}",
                "correct_answer": "{interest}",
                "options": ["{interest}", "table", "lamp"],
                "image_hint": "Several objects including a {interest}",
            },
            {
                "instruction": "Where is the {interest}?",
                "correct_answer": "{interest}",
                "options": ["{interest}", "chair", "cup"],
                "image_hint": "A scene with a {interest} among other items",
            },
            {
                "instruction": "Show me the {interest}",
                "correct_answer": "{interest}",
                "options": ["{interest}", "ball", "hat"],
                "image_hint": "Objects spread out including a {interest}",
            },
        ],
        1: [
            {
                "instruction": "Give me the {interest}",
                "correct_answer": "{interest}",
                "options": ["{interest}", "spoon", "shoe"],
                "image_hint": "A {interest} among other items on a table",
            },
            {
                "instruction": "Put the {interest} on the table",
                "correct_answer": "{interest}",
                "options": ["{interest}", "book", "bottle"],
                "image_hint": "A {interest} and a table in a room scene",
            },
            {
                "instruction": "Pick up the {interest} and give it to me",
                "correct_answer": "{interest}",
                "options": ["{interest}", "blanket", "fork"],
                "image_hint": "A {interest} within reach of the child",
            },
        ],
    },
    "literacy": {
        0: [
            {
                "instruction": "What is in this picture? A {interest}!",
                "correct_answer": "{interest}",
                "options": ["{interest}", "tree", "cloud"],
                "image_hint": "A clear photo of a {interest}",
            },
            {
                "instruction": "Look at the picture. This is a {interest}",
                "correct_answer": "{interest}",
                "options": ["{interest}", "rock", "flower"],
                "image_hint": "A bright, simple image of a {interest}",
            },
            {
                "instruction": "Can you find the {interest} in the picture?",
                "correct_answer": "{interest}",
                "options": ["{interest}", "grass", "sun"],
                "image_hint": "Picture scene with a {interest}",
            },
        ],
    },
    "social_behavior": {
        0: [
            {
                "instruction": "Look at the person who is talking about {interest}",
                "correct_answer": "person talking",
                "options": ["person talking", "wall", "floor"],
                "image_hint": "A person speaking, pointing to a {interest}",
            },
            {
                "instruction": "Watch the person show you the {interest}",
                "correct_answer": "watching",
                "options": ["watching", "looking away", "eyes closed"],
                "image_hint": "A friendly person holding a {interest}",
            },
            {
                "instruction": "Look here! See the {interest}?",
                "correct_answer": "looking",
                "options": ["looking", "not looking"],
                "image_hint": "Arrow pointing to a {interest} on screen",
            },
        ],
    },
    "cognitive_logic": {
        0: [
            {
                "instruction": "Which one goes with the {interest}?",
                "correct_answer": "{interest} pair",
                "options": ["{interest} pair", "unrelated item 1", "unrelated item 2"],
                "image_hint": "A {interest} and its natural pair",
            },
            {
                "instruction": "Find the partner for this {interest}",
                "correct_answer": "matching pair",
                "options": ["matching pair", "wrong item 1", "wrong item 2"],
                "image_hint": "Pairing exercise with {interest}-related items",
            },
            {
                "instruction": "These two go together: {interest} and...",
                "correct_answer": "correct pair",
                "options": ["correct pair", "distractor 1", "distractor 2"],
                "image_hint": "Association pairing with {interest}",
            },
        ],
    },
}
