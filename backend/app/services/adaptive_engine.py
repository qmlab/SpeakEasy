"""
AdaptiveEngine - Core adaptive learning logic for Rising Star Kid.

Implements simplified Bayesian Knowledge Tracking combined with rule-based
difficulty adjustment for autism-specific learning paths.

Key behaviors:
- Accuracy >80% over recent window -> level up / reduce prompts
- Accuracy <50% -> level down / increase prompts / switch modality
- 3 consecutive failures -> confidence rebuild (switch to mastered tasks)
- Engagement drop -> switch activity type or trigger reward
"""

from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, desc, Integer

from app.models.adaptive import (
    DevelopmentalProfile,
    LearningSession,
    AdaptiveTask,
    TaskAttempt,
    ReinforcementConfig,
    DevelopmentalDimension,
    SessionType,
    SessionStatus,
    PromptLevel,
    PromptStrategy,
    RewardType,
)
from app.models.player import Player


# -- Constants --
ACCURACY_WINDOW = 10  # Number of recent attempts to consider
LEVEL_UP_THRESHOLD = 0.80
LEVEL_DOWN_THRESHOLD = 0.50
CONSECUTIVE_FAIL_LIMIT = 3
MAX_LEVEL = 4
MIN_LEVEL = 0


class AdaptiveEngine:
    def __init__(self, db: Session):
        self.db = db

    # ---- Profile Management ----

    def get_or_create_profiles(self, player_id: str) -> list[DevelopmentalProfile]:
        """Get all developmental profiles for a player, creating defaults if needed."""
        profiles = (
            self.db.query(DevelopmentalProfile)
            .filter(DevelopmentalProfile.player_id == player_id)
            .all()
        )

        existing_dims = {p.dimension for p in profiles}
        all_dims = [d.value for d in DevelopmentalDimension]

        for dim in all_dims:
            if dim not in existing_dims:
                profile = DevelopmentalProfile(
                    player_id=player_id,
                    dimension=dim,
                    level=0,
                    assessed=False,
                )
                self.db.add(profile)
                profiles.append(profile)

        self.db.commit()
        for p in profiles:
            self.db.refresh(p)
        return profiles

    def get_profile(self, player_id: str, dimension: str) -> Optional[DevelopmentalProfile]:
        """Get a single profile for a specific dimension."""
        return (
            self.db.query(DevelopmentalProfile)
            .filter(
                DevelopmentalProfile.player_id == player_id,
                DevelopmentalProfile.dimension == dimension,
            )
            .first()
        )

    def update_profile_level(
        self, player_id: str, dimension: str, new_level: int
    ) -> DevelopmentalProfile:
        """Update a player's level in a specific dimension."""
        profile = self.get_profile(player_id, dimension)
        if not profile:
            profiles = self.get_or_create_profiles(player_id)
            profile = next(p for p in profiles if p.dimension == dimension)

        profile.level = max(MIN_LEVEL, min(MAX_LEVEL, new_level))
        profile.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(profile)
        return profile

    # ---- Session Management ----

    def start_session(
        self,
        player_id: str,
        session_type: str,
        dimension: Optional[str] = None,
    ) -> LearningSession:
        """Start a new learning session."""
        profiles = self.get_or_create_profiles(player_id)

        current_level = 0
        if dimension:
            profile = next((p for p in profiles if p.dimension == dimension), None)
            if profile:
                current_level = profile.level

        session = LearningSession(
            player_id=player_id,
            session_type=session_type,
            dimension=dimension,
            status=SessionStatus.ACTIVE.value,
            current_level=current_level,
        )
        self.db.add(session)
        self.db.commit()
        self.db.refresh(session)
        return session

    def end_session(self, session_id: str) -> LearningSession:
        """End a learning session and compute summary stats."""
        session = self.db.query(LearningSession).filter(LearningSession.id == session_id).first()
        if not session:
            raise ValueError(f"Session {session_id} not found")

        session.ended_at = datetime.utcnow()
        session.status = SessionStatus.COMPLETED.value

        attempts = (
            self.db.query(TaskAttempt)
            .filter(TaskAttempt.session_id == session_id)
            .all()
        )

        session.total_count = len(attempts)
        session.correct_count = sum(1 for a in attempts if a.is_correct)
        session.tasks_completed = session.total_count

        if attempts:
            response_times = [a.response_time_ms for a in attempts if a.response_time_ms]
            if response_times:
                session.avg_response_time_ms = sum(response_times) / len(response_times)

            prompted = sum(1 for a in attempts if a.prompt_level > 0)
            session.prompt_dependency_rate = prompted / len(attempts)

        self.db.commit()
        self.db.refresh(session)
        return session

    # ---- Task Selection ----

    def get_next_task(
        self,
        session_id: str,
        player_id: str,
        dimension: str,
    ) -> Optional[dict]:
        """Select the next task based on current level and adaptive logic."""
        session = self.db.query(LearningSession).filter(LearningSession.id == session_id).first()
        if not session:
            raise ValueError(f"Session {session_id} not found")

        profile = self.get_profile(player_id, dimension)
        current_level = profile.level if profile else 0

        recent_attempts = self._get_recent_attempts(player_id, dimension)
        consecutive_fails = self._count_consecutive_fails(recent_attempts)
        recent_accuracy = self._compute_accuracy(recent_attempts)

        # Confidence rebuild: switch to easier mastered tasks
        confidence_rebuild = False
        if consecutive_fails >= CONSECUTIVE_FAIL_LIMIT:
            confidence_rebuild = True
            target_level = max(MIN_LEVEL, current_level - 1)
        else:
            target_level = current_level

        # Get reinforcement config
        config = self._get_reinforcement_config(player_id)
        prompt_level = self._determine_prompt_level(recent_accuracy, config)

        # Find an appropriate task
        task = self._select_task(
            dimension=dimension,
            level=target_level,
            is_assessment=(session.session_type == SessionType.ASSESSMENT.value),
            exclude_task_ids=self._get_recent_task_ids(session_id),
        )

        if not task:
            # Prefer repeating at the target level before moving to adjacent
            # levels so children get enough practice before harder content.
            task = self._select_task(
                dimension=dimension,
                level=target_level,
                is_assessment=False,
                exclude_task_ids=[],
            )

        if not task:
            # Try adjacent levels if no task found at target level at all
            for offset in [1, -1, 2, -2]:
                alt_level = target_level + offset
                if MIN_LEVEL <= alt_level <= MAX_LEVEL:
                    task = self._select_task(
                        dimension=dimension,
                        level=alt_level,
                        is_assessment=(session.session_type == SessionType.ASSESSMENT.value),
                        exclude_task_ids=self._get_recent_task_ids(session_id),
                    )
                    if task:
                        break

        if not task:
            return None

        return {
            "task_id": task.id,
            "dimension": task.dimension,
            "level": task.level,
            "task_type": task.task_type,
            "modalities": task.modalities,
            "content": task.content,
            "prompt_level": prompt_level,
            "session_id": session_id,
            "confidence_rebuild": confidence_rebuild,
        }

    def _select_task(
        self,
        dimension: str,
        level: int,
        is_assessment: bool,
        exclude_task_ids: list[str],
    ) -> Optional[AdaptiveTask]:
        """Select a task matching criteria."""
        query = self.db.query(AdaptiveTask).filter(
            AdaptiveTask.dimension == dimension,
            AdaptiveTask.level == level,
        )

        if is_assessment:
            query = query.filter(AdaptiveTask.is_assessment == True)  # noqa: E712

        if exclude_task_ids:
            query = query.filter(AdaptiveTask.id.notin_(exclude_task_ids))

        # Randomize selection using SQL
        task = query.order_by(func.random()).first()
        return task

    def _get_recent_task_ids(self, session_id: str) -> list[str]:
        """Get task IDs already used in this session to avoid immediate repeats."""
        attempts = (
            self.db.query(TaskAttempt.task_id)
            .filter(TaskAttempt.session_id == session_id)
            .all()
        )
        return [a.task_id for a in attempts if a.task_id]

    # ---- Attempt Processing ----

    def process_attempt(
        self,
        session_id: str,
        task_id: str,
        player_id: str,
        is_correct: bool,
        score: int = 0,
        response_time_ms: Optional[int] = None,
        prompt_level: int = 0,
        response_data: Optional[dict] = None,
    ) -> dict:
        """Process a task attempt and return adaptive feedback."""
        attempt = TaskAttempt(
            session_id=session_id,
            task_id=task_id,
            player_id=player_id,
            is_correct=is_correct,
            score=score,
            response_time_ms=response_time_ms,
            prompt_level=prompt_level,
            response_data=response_data or {},
        )
        self.db.add(attempt)

        # Update session counters
        session = self.db.query(LearningSession).filter(LearningSession.id == session_id).first()
        if session:
            session.total_count = (session.total_count or 0) + 1
            if is_correct:
                session.correct_count = (session.correct_count or 0) + 1
            session.tasks_completed = session.total_count

        self.db.commit()
        self.db.refresh(attempt)

        # Get task dimension
        task = self.db.query(AdaptiveTask).filter(AdaptiveTask.id == task_id).first()
        dimension = task.dimension if task else (session.dimension if session else None)

        # Compute adaptive feedback scoped to the task's level so that
        # stale accuracy from a previous level cannot trigger an unintended
        # level change immediately after promotion/demotion.
        task_level = task.level if task else None
        profile = None
        if dimension:
            profile = self.get_profile(player_id, dimension)

        recent_attempts = self._get_recent_attempts(player_id, dimension, level=task_level)
        accuracy = self._compute_accuracy(recent_attempts)
        consecutive_fails = self._count_consecutive_fails(recent_attempts)
        streak = self._count_streak(recent_attempts)

        should_level_up = accuracy >= LEVEL_UP_THRESHOLD and len(recent_attempts) >= ACCURACY_WINDOW // 2
        should_level_down = accuracy <= LEVEL_DOWN_THRESHOLD and len(recent_attempts) >= ACCURACY_WINDOW // 2
        confidence_rebuild = consecutive_fails >= CONSECUTIVE_FAIL_LIMIT

        # Apply level changes (reuse profile fetched above)
        level_change = 0
        if dimension and profile:
            if should_level_up and profile.level < MAX_LEVEL:
                profile.level += 1
                level_change = 1
                if session:
                    session.current_level = profile.level
            elif should_level_down and profile.level > MIN_LEVEL:
                profile.level -= 1
                level_change = -1
                if session:
                    session.current_level = profile.level
            profile.updated_at = datetime.utcnow()
            self.db.commit()

        # Determine reward
        config = self._get_reinforcement_config(player_id)
        reward = None
        if is_correct and session:
            correct_in_session = session.correct_count or 0
            if correct_in_session % config.reward_frequency == 0:
                reward = self._generate_reward(config)

        # Determine next action
        if confidence_rebuild:
            next_action = "confidence_rebuild"
        elif should_level_up:
            next_action = "level_up"
        elif should_level_down:
            next_action = "level_down"
        else:
            next_action = "continue"

        return {
            "attempt_id": attempt.id,
            "is_correct": is_correct,
            "score": score,
            "reward": reward,
            "streak": streak,
            "accuracy": round(accuracy, 3),
            "should_level_up": should_level_up,
            "should_level_down": should_level_down,
            "confidence_rebuild": confidence_rebuild,
            "next_action": next_action,
            "level_change": level_change,
        }

    # ---- Assessment ----

    def run_assessment(self, player_id: str, dimension: str, results: list[dict]) -> dict:
        """Process assessment results and set initial level."""
        if not results:
            return {"dimension": dimension, "level": 0, "assessed": False}

        # Simple assessment: find highest level with >= 60% accuracy
        level_scores: dict[int, list[bool]] = {}
        for r in results:
            level = r.get("level", 0)
            correct = r.get("is_correct", False)
            if level not in level_scores:
                level_scores[level] = []
            level_scores[level].append(correct)

        assessed_level = 0
        for level in sorted(level_scores.keys()):
            scores = level_scores[level]
            if not scores:
                continue
            accuracy = sum(scores) / len(scores)
            if accuracy >= 0.6:
                assessed_level = level
            else:
                break

        profile = self.get_profile(player_id, dimension)
        if not profile:
            profiles = self.get_or_create_profiles(player_id)
            profile = next(p for p in profiles if p.dimension == dimension)

        profile.level = assessed_level
        profile.assessed = True
        profile.last_assessed_at = datetime.utcnow()
        profile.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(profile)

        return {
            "dimension": dimension,
            "level": assessed_level,
            "assessed": True,
        }

    # ---- Helper Methods ----

    def _get_recent_attempts(
        self, player_id: str, dimension: Optional[str] = None, level: Optional[int] = None
    ) -> list[TaskAttempt]:
        """Get recent attempts for accuracy computation.
        
        When level is provided, only attempts on tasks at that level are
        considered.  This prevents stale high-accuracy from a previous
        level from triggering an unintended level-up right after promotion.
        """
        query = (
            self.db.query(TaskAttempt)
            .filter(TaskAttempt.player_id == player_id)
            .order_by(desc(TaskAttempt.created_at))
        )

        if dimension or level is not None:
            query = query.join(AdaptiveTask, TaskAttempt.task_id == AdaptiveTask.id)
            if dimension:
                query = query.filter(AdaptiveTask.dimension == dimension)
            if level is not None:
                query = query.filter(AdaptiveTask.level == level)

        return query.limit(ACCURACY_WINDOW).all()

    def _compute_accuracy(self, attempts: list[TaskAttempt]) -> float:
        """Compute accuracy over a list of attempts."""
        if not attempts:
            return 0.0
        correct = sum(1 for a in attempts if a.is_correct)
        return correct / len(attempts)

    def _count_consecutive_fails(self, attempts: list[TaskAttempt]) -> int:
        """Count consecutive failures from the most recent attempt."""
        count = 0
        for a in attempts:
            if not a.is_correct:
                count += 1
            else:
                break
        return count

    def _count_streak(self, attempts: list[TaskAttempt]) -> int:
        """Count consecutive correct answers from the most recent attempt."""
        count = 0
        for a in attempts:
            if a.is_correct:
                count += 1
            else:
                break
        return count

    def _get_reinforcement_config(self, player_id: str) -> ReinforcementConfig:
        """Get or create reinforcement config for a player."""
        config = (
            self.db.query(ReinforcementConfig)
            .filter(ReinforcementConfig.player_id == player_id)
            .first()
        )
        if not config:
            config = ReinforcementConfig(player_id=player_id)
            self.db.add(config)
            self.db.commit()
            self.db.refresh(config)
        return config

    def _determine_prompt_level(
        self, recent_accuracy: float, config: ReinforcementConfig
    ) -> int:
        """Determine prompt level based on recent accuracy and strategy."""
        if config.prompt_strategy == PromptStrategy.MOST_TO_LEAST.value:
            if recent_accuracy >= LEVEL_UP_THRESHOLD:
                return PromptLevel.INDEPENDENT.value
            elif recent_accuracy >= LEVEL_DOWN_THRESHOLD:
                return PromptLevel.PARTIAL.value
            else:
                return PromptLevel.FULL.value
        elif config.prompt_strategy == PromptStrategy.LEAST_TO_MOST.value:
            if recent_accuracy >= LEVEL_UP_THRESHOLD:
                return PromptLevel.INDEPENDENT.value
            elif recent_accuracy >= LEVEL_DOWN_THRESHOLD:
                return PromptLevel.PARTIAL.value
            else:
                return PromptLevel.FULL.value
        else:
            # graduated_guidance - same logic but could be customized
            if recent_accuracy >= 0.70:
                return PromptLevel.INDEPENDENT.value
            elif recent_accuracy >= 0.40:
                return PromptLevel.PARTIAL.value
            else:
                return PromptLevel.FULL.value

    def _generate_reward(self, config: ReinforcementConfig) -> dict:
        """Generate a reward based on reinforcement config."""
        reward_type = config.reward_type

        rewards = {
            RewardType.ANIMATION.value: {
                "type": "animation",
                "name": "star_burst",
                "message": "Great job!",
            },
            RewardType.SOUND.value: {
                "type": "sound",
                "name": "cheer",
                "message": "Awesome!",
            },
            RewardType.POINTS.value: {
                "type": "points",
                "amount": 10,
                "message": "You earned 10 points!",
            },
            RewardType.STICKER.value: {
                "type": "sticker",
                "name": "gold_star",
                "message": "You earned a sticker!",
            },
        }

        return rewards.get(reward_type, rewards[RewardType.ANIMATION.value])

    # ---- Dashboard Queries ----

    def get_dashboard_summary(self, player_id: str) -> dict:
        """Get comprehensive dashboard data for a player."""
        player = self.db.query(Player).filter(Player.id == player_id).first()
        if not player:
            raise ValueError(f"Player {player_id} not found")

        profiles = self.get_or_create_profiles(player_id)

        recent_sessions = (
            self.db.query(LearningSession)
            .filter(LearningSession.player_id == player_id)
            .order_by(desc(LearningSession.started_at))
            .limit(10)
            .all()
        )

        total_sessions = (
            self.db.query(func.count(LearningSession.id))
            .filter(LearningSession.player_id == player_id)
            .scalar()
            or 0
        )

        total_tasks = (
            self.db.query(func.sum(LearningSession.tasks_completed))
            .filter(
                LearningSession.player_id == player_id,
                LearningSession.status == SessionStatus.COMPLETED.value,
            )
            .scalar()
            or 0
        )

        total_correct = (
            self.db.query(func.sum(LearningSession.correct_count))
            .filter(
                LearningSession.player_id == player_id,
                LearningSession.status == SessionStatus.COMPLETED.value,
            )
            .scalar()
            or 0
        )

        total_count = (
            self.db.query(func.sum(LearningSession.total_count))
            .filter(
                LearningSession.player_id == player_id,
                LearningSession.status == SessionStatus.COMPLETED.value,
            )
            .scalar()
            or 0
        )

        overall_accuracy = (total_correct / total_count) if total_count > 0 else 0.0

        # Calculate streak days
        streak_days = self._compute_streak_days(player_id)

        # Count mastered and struggling tasks
        mastered, struggling = self._count_mastery(player_id)

        return {
            "player_id": player_id,
            "player_name": player.name,
            "dimensions": profiles,
            "recent_sessions": recent_sessions,
            "total_sessions": total_sessions,
            "total_tasks_completed": int(total_tasks),
            "overall_accuracy": round(overall_accuracy, 3),
            "streak_days": streak_days,
            "mastered_tasks": mastered,
            "struggling_tasks": struggling,
        }

    def get_dimension_progress(self, player_id: str, dimension: str) -> dict:
        """Get detailed progress for a specific dimension."""
        profile = self.get_profile(player_id, dimension)
        if not profile:
            profiles = self.get_or_create_profiles(player_id)
            profile = next(p for p in profiles if p.dimension == dimension)

        sessions = (
            self.db.query(LearningSession)
            .filter(
                LearningSession.player_id == player_id,
                LearningSession.dimension == dimension,
                LearningSession.status == SessionStatus.COMPLETED.value,
            )
            .order_by(LearningSession.started_at)
            .all()
        )

        history = []
        accuracy_trend = []
        for s in sessions:
            accuracy = (s.correct_count / s.total_count) if s.total_count > 0 else 0.0
            history.append({
                "session_id": s.id,
                "date": s.started_at.isoformat() if s.started_at else None,
                "level": s.current_level,
                "accuracy": round(accuracy, 3),
                "tasks_completed": s.tasks_completed,
            })
            accuracy_trend.append(round(accuracy, 3))

        # Count mastered tasks at this dimension
        mastered_count = (
            self.db.query(func.count(TaskAttempt.id))
            .join(AdaptiveTask, TaskAttempt.task_id == AdaptiveTask.id)
            .filter(
                TaskAttempt.player_id == player_id,
                AdaptiveTask.dimension == dimension,
                TaskAttempt.is_correct == True,  # noqa: E712
            )
            .scalar()
            or 0
        )

        total_count = (
            self.db.query(func.count(TaskAttempt.id))
            .join(AdaptiveTask, TaskAttempt.task_id == AdaptiveTask.id)
            .filter(
                TaskAttempt.player_id == player_id,
                AdaptiveTask.dimension == dimension,
            )
            .scalar()
            or 0
        )

        return {
            "dimension": dimension,
            "current_level": profile.level,
            "history": history,
            "mastered_count": mastered_count,
            "total_count": total_count,
            "accuracy_trend": accuracy_trend,
        }

    def _compute_streak_days(self, player_id: str) -> int:
        """Compute consecutive days with at least one completed session."""
        sessions = (
            self.db.query(LearningSession.started_at)
            .filter(
                LearningSession.player_id == player_id,
                LearningSession.status == SessionStatus.COMPLETED.value,
            )
            .order_by(desc(LearningSession.started_at))
            .all()
        )

        if not sessions:
            return 0

        dates = sorted(set(s.started_at.date() for s in sessions if s.started_at), reverse=True)
        if not dates:
            return 0

        today = datetime.utcnow().date()
        if dates[0] < today - timedelta(days=1):
            return 0

        streak = 1
        for i in range(1, len(dates)):
            if dates[i - 1] - dates[i] == timedelta(days=1):
                streak += 1
            else:
                break

        return streak

    def _count_mastery(self, player_id: str) -> tuple[int, int]:
        """Count mastered and struggling task types."""
        # Group attempts by task, compute accuracy
        task_stats = (
            self.db.query(
                TaskAttempt.task_id,
                func.count(TaskAttempt.id).label("total"),
                func.sum(
                    func.cast(TaskAttempt.is_correct, Integer)
                ).label("correct"),
            )
            .filter(TaskAttempt.player_id == player_id)
            .group_by(TaskAttempt.task_id)
            .all()
        )

        mastered = 0
        struggling = 0
        for stat in task_stats:
            if stat.total >= 3:
                accuracy = (stat.correct or 0) / stat.total
                if accuracy >= LEVEL_UP_THRESHOLD:
                    mastered += 1
                elif accuracy <= LEVEL_DOWN_THRESHOLD:
                    struggling += 1

        return mastered, struggling
