"""Tests for the adaptive learning engine."""

import pytest

from app.models.adaptive import (
    DevelopmentalDimension,
    SessionStatus,
    PromptLevel,
)
from app.services.adaptive_engine import (
    AdaptiveEngine,
    CONSECUTIVE_FAIL_LIMIT,
    MAX_LEVEL,
    MIN_LEVEL,
)


class TestProfileManagement:
    """Test developmental profile CRUD."""

    def test_get_or_create_profiles_creates_all_6(self, db, player):
        engine = AdaptiveEngine(db)
        profiles = engine.get_or_create_profiles(player.id)
        assert len(profiles) == 6
        dims = {p.dimension for p in profiles}
        assert dims == {d.value for d in DevelopmentalDimension}

    def test_get_or_create_profiles_default_level_zero(self, db, player):
        engine = AdaptiveEngine(db)
        profiles = engine.get_or_create_profiles(player.id)
        for p in profiles:
            assert p.level == 0
            assert p.assessed is False

    def test_get_or_create_profiles_idempotent(self, db, player):
        engine = AdaptiveEngine(db)
        first = engine.get_or_create_profiles(player.id)
        second = engine.get_or_create_profiles(player.id)
        assert len(first) == len(second)

    def test_get_profile_single_dimension(self, db, player):
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        profile = engine.get_profile(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        assert profile is not None
        assert profile.dimension == DevelopmentalDimension.OBJECT_COGNITION.value
        assert profile.level == 0

    def test_get_profile_nonexistent(self, db, player):
        engine = AdaptiveEngine(db)
        profile = engine.get_profile(player.id, "nonexistent")
        assert profile is None

    def test_update_profile_level(self, db, player):
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        updated = engine.update_profile_level(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value, 3
        )
        assert updated.level == 3

    def test_update_profile_level_clamped_max(self, db, player):
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        updated = engine.update_profile_level(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value, 20
        )
        assert updated.level == MAX_LEVEL

    def test_update_profile_level_clamped_min(self, db, player):
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        updated = engine.update_profile_level(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value, -5
        )
        assert updated.level == MIN_LEVEL


class TestSessionManagement:
    """Test learning session lifecycle."""

    def test_start_session(self, db, player):
        engine = AdaptiveEngine(db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )
        assert session.player_id == player.id
        assert session.session_type == "practice"
        assert session.dimension == DevelopmentalDimension.OBJECT_COGNITION.value
        assert session.status == SessionStatus.ACTIVE.value
        assert session.current_level == 0

    def test_start_session_uses_profile_level(self, db, player):
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        engine.update_profile_level(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value, 2
        )
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )
        assert session.current_level == 2

    def test_end_session(self, db, player):
        engine = AdaptiveEngine(db)
        session = engine.start_session(player.id, "practice")
        ended = engine.end_session(session.id)
        assert ended.status == SessionStatus.COMPLETED.value
        assert ended.ended_at is not None

    def test_end_session_nonexistent(self, db, player):
        engine = AdaptiveEngine(db)
        with pytest.raises(ValueError, match="not found"):
            engine.end_session("nonexistent-id")

    def test_end_session_computes_stats(self, db, player, seeded_db):
        engine = AdaptiveEngine(seeded_db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )
        task_data = engine.get_next_task(
            session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        if task_data:
            engine.process_attempt(
                session.id,
                task_data["task_id"],
                player.id,
                is_correct=True,
                response_time_ms=1500,
            )
            engine.process_attempt(
                session.id,
                task_data["task_id"],
                player.id,
                is_correct=False,
                response_time_ms=2000,
            )
        ended = engine.end_session(session.id)
        assert ended.total_count == 2
        assert ended.correct_count == 1
        assert ended.avg_response_time_ms == 1750.0


class TestTaskSelection:
    """Test adaptive task selection."""

    def test_get_next_task_returns_task(self, db, player, seeded_db):
        engine = AdaptiveEngine(seeded_db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )
        task = engine.get_next_task(
            session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        assert task is not None
        assert task["dimension"] == DevelopmentalDimension.OBJECT_COGNITION.value
        assert task["level"] == 0

    def test_get_next_task_has_required_keys(self, db, player, seeded_db):
        engine = AdaptiveEngine(seeded_db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )
        task = engine.get_next_task(
            session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        required_keys = {
            "task_id",
            "dimension",
            "level",
            "task_type",
            "modalities",
            "content",
            "prompt_level",
            "session_id",
            "confidence_rebuild",
        }
        assert required_keys.issubset(task.keys())

    def test_get_next_task_nonexistent_session(self, db, player):
        engine = AdaptiveEngine(db)
        with pytest.raises(ValueError, match="not found"):
            engine.get_next_task("nonexistent", player.id, "object_cognition")


class TestAttemptProcessing:
    """Test attempt processing and adaptive logic."""

    def test_correct_attempt(self, db, player, seeded_db):
        engine = AdaptiveEngine(seeded_db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )
        task = engine.get_next_task(
            session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        result = engine.process_attempt(
            session.id,
            task["task_id"],
            player.id,
            is_correct=True,
            response_time_ms=1500,
        )
        assert result["is_correct"] is True
        assert result["streak"] >= 1

    def test_incorrect_attempt(self, db, player, seeded_db):
        engine = AdaptiveEngine(seeded_db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )
        task = engine.get_next_task(
            session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        result = engine.process_attempt(
            session.id,
            task["task_id"],
            player.id,
            is_correct=False,
            response_time_ms=2000,
        )
        assert result["is_correct"] is False
        assert result["streak"] == 0

    def test_level_up_after_high_accuracy(self, db, player, seeded_db):
        """5+ correct answers at >=80% should trigger level up."""
        engine = AdaptiveEngine(seeded_db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )

        level_up_triggered = False
        for _ in range(10):
            task = engine.get_next_task(
                session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
            )
            if not task:
                break
            result = engine.process_attempt(
                session.id,
                task["task_id"],
                player.id,
                is_correct=True,
                response_time_ms=1000,
            )
            if result["should_level_up"]:
                level_up_triggered = True
                break

        assert level_up_triggered, (
            "Level up should trigger after consecutive correct answers"
        )

        # Verify profile was updated
        profile = engine.get_profile(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        assert profile.level == 1

    def test_confidence_rebuild_after_consecutive_fails(self, db, player, seeded_db):
        """3 consecutive failures should trigger confidence rebuild."""
        engine = AdaptiveEngine(seeded_db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )

        for i in range(CONSECUTIVE_FAIL_LIMIT):
            task = engine.get_next_task(
                session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
            )
            if not task:
                break
            engine.process_attempt(
                session.id,
                task["task_id"],
                player.id,
                is_correct=False,
                response_time_ms=3000,
            )

        # After 3 fails, next task should show confidence_rebuild
        task = engine.get_next_task(
            session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        if task:
            assert task["confidence_rebuild"] is True

    def test_reward_on_correct_frequency(self, db, player, seeded_db):
        """Reward should be given at configured frequency."""
        engine = AdaptiveEngine(seeded_db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )
        config = engine._get_reinforcement_config(player.id)
        freq = config.reward_frequency  # default 3

        rewards_received = []
        for i in range(freq + 1):
            task = engine.get_next_task(
                session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
            )
            if not task:
                break
            result = engine.process_attempt(
                session.id,
                task["task_id"],
                player.id,
                is_correct=True,
                response_time_ms=1000,
            )
            if result["reward"]:
                rewards_received.append(i + 1)

        assert len(rewards_received) > 0, "Should receive at least one reward"

    def test_result_keys(self, db, player, seeded_db):
        engine = AdaptiveEngine(seeded_db)
        session = engine.start_session(
            player.id, "practice", DevelopmentalDimension.OBJECT_COGNITION.value
        )
        task = engine.get_next_task(
            session.id, player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        result = engine.process_attempt(
            session.id,
            task["task_id"],
            player.id,
            is_correct=True,
            response_time_ms=1000,
        )
        expected_keys = {
            "attempt_id",
            "is_correct",
            "score",
            "reward",
            "streak",
            "accuracy",
            "should_level_up",
            "should_level_down",
            "confidence_rebuild",
            "next_action",
            "level_change",
        }
        assert expected_keys.issubset(result.keys())


class TestHelperMethods:
    """Test internal helper methods."""

    def test_compute_accuracy_empty(self, db):
        engine = AdaptiveEngine(db)
        assert engine._compute_accuracy([]) == 0.0

    def test_count_consecutive_fails_empty(self, db):
        engine = AdaptiveEngine(db)
        assert engine._count_consecutive_fails([]) == 0

    def test_count_streak_empty(self, db):
        engine = AdaptiveEngine(db)
        assert engine._count_streak([]) == 0

    def test_determine_prompt_level_high_accuracy(self, db, player):
        engine = AdaptiveEngine(db)
        config = engine._get_reinforcement_config(player.id)
        level = engine._determine_prompt_level(0.9, config)
        assert level == PromptLevel.INDEPENDENT.value

    def test_determine_prompt_level_low_accuracy(self, db, player):
        engine = AdaptiveEngine(db)
        config = engine._get_reinforcement_config(player.id)
        level = engine._determine_prompt_level(0.3, config)
        assert level == PromptLevel.FULL.value

    def test_generate_reward(self, db, player):
        engine = AdaptiveEngine(db)
        config = engine._get_reinforcement_config(player.id)
        reward = engine._generate_reward(config)
        assert "type" in reward
        assert "message" in reward


class TestModalityRecommendation:
    """Test modality recommendation logic."""

    def test_default_modality_is_touch(self, db, player):
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        result = engine.recommend_modality(player.id)
        assert result["recommended_modality"] == "touch"

    def test_modality_upgrades_with_levels(self, db, player):
        """Higher profile levels should recommend more advanced modalities."""
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        # Set all profiles to level 3
        for dim in DevelopmentalDimension:
            engine.update_profile_level(player.id, dim.value, 3)
        result = engine.recommend_modality(player.id)
        # With high levels, should recommend text or voice
        assert result["recommended_modality"] in ("text", "voice")


class TestAssessment:
    """Test the run_assessment method."""

    def test_run_assessment_empty_results(self, db, player):
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        result = engine.run_assessment(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value, []
        )
        assert result["level"] == 0
        assert result["assessed"] is False

    def test_run_assessment_sets_level(self, db, player):
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        results = [
            {"level": 0, "is_correct": True},
            {"level": 0, "is_correct": True},
            {"level": 1, "is_correct": True},
            {"level": 1, "is_correct": True},
            {"level": 2, "is_correct": False},
        ]
        result = engine.run_assessment(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value, results
        )
        assert result["level"] == 1  # Passed level 0 and 1, failed level 2
        assert result["assessed"] is True

    def test_run_assessment_updates_profile(self, db, player):
        engine = AdaptiveEngine(db)
        engine.get_or_create_profiles(player.id)
        results = [
            {"level": 0, "is_correct": True},
            {"level": 1, "is_correct": True},
        ]
        engine.run_assessment(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value, results
        )
        profile = engine.get_profile(
            player.id, DevelopmentalDimension.OBJECT_COGNITION.value
        )
        assert profile.assessed is True
        assert profile.level == 1
