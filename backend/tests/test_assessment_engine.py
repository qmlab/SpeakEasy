"""Tests for the gamified assessment engine."""

import pytest

from app.models.adaptive import (
    DevelopmentalProfile,
    Assessment,
)
from app.services.assessment_engine import (
    AssessmentEngine,
    DIMENSION_ORDER,
)


class TestStartAssessment:
    """Test assessment start."""

    def test_start_creates_assessment(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        result = engine.start_assessment(player.id)
        assert "assessment_id" in result
        assert result["player_id"] == player.id
        assert result["total_activities"] == 18  # 6 dims x 3 levels

    def test_start_assigns_character(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        result = engine.start_assessment(player.id)
        character = result["character"]
        assert character["name"] in ("Bunny", "Fox", "Panda")
        assert "emoji" in character
        assert "greeting" in character

    def test_start_has_story_intro(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        result = engine.start_assessment(player.id)
        assert "story_intro" in result
        assert result["character"]["name"] in result["story_intro"]

    def test_start_persists_to_db(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        result = engine.start_assessment(player.id)
        assessment = (
            seeded_db.query(Assessment)
            .filter(Assessment.id == result["assessment_id"])
            .first()
        )
        assert assessment is not None
        assert assessment.player_id == player.id
        assert assessment.completed is False
        assert assessment.current_index == 0

    def test_start_nonexistent_player(self, db):
        engine = AssessmentEngine(db)
        with pytest.raises(ValueError, match="not found"):
            engine.start_assessment("nonexistent-player")

    def test_start_builds_activity_queue(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        result = engine.start_assessment(player.id)
        assessment = (
            seeded_db.query(Assessment)
            .filter(Assessment.id == result["assessment_id"])
            .first()
        )
        activities = assessment.activities
        assert len(activities) == 18

        # First 6 should be level 0 (one per dimension)
        for i in range(6):
            assert activities[i]["level"] == 0
        # Next 6 should be level 1
        for i in range(6, 12):
            assert activities[i]["level"] == 1
        # Last 6 should be level 2
        for i in range(12, 18):
            assert activities[i]["level"] == 2


class TestGetNextActivity:
    """Test getting the next activity."""

    def test_first_activity(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        activity = engine.get_next_activity(start["assessment_id"])
        assert activity is not None
        assert activity["activity_index"] == 0
        assert activity["level"] == 0
        assert activity["dimension"] == DIMENSION_ORDER[0]

    def test_activity_has_content(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        activity = engine.get_next_activity(start["assessment_id"])
        content = activity["content"]
        assert "instruction" in content
        assert "narrative" in content
        assert "interaction_type" in content

    def test_activity_has_character(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        activity = engine.get_next_activity(start["assessment_id"])
        assert "character" in activity
        assert "name" in activity["character"]
        assert "emoji" in activity["character"]

    def test_caches_task_id(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        engine.get_next_activity(start["assessment_id"])
        assessment = (
            seeded_db.query(Assessment)
            .filter(Assessment.id == start["assessment_id"])
            .first()
        )
        assert "0" in assessment.activity_task_ids

    def test_returns_none_when_complete(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        assessment = (
            seeded_db.query(Assessment)
            .filter(Assessment.id == start["assessment_id"])
            .first()
        )
        # Move index past all activities
        assessment.current_index = len(assessment.activities)
        seeded_db.commit()
        activity = engine.get_next_activity(start["assessment_id"])
        assert activity is None


class TestProcessResponse:
    """Test processing assessment responses."""

    def test_correct_response(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        activity = engine.get_next_activity(start["assessment_id"])
        correct_answer = activity["content"]["correct_answer"]
        result = engine.process_response(
            start["assessment_id"],
            activity_index=0,
            selected_option=correct_answer,
            response_time_ms=1500,
        )
        assert result["is_correct"] is True
        assert result["feedback"]["is_correct"] is True
        assert result["should_continue"] is True

    def test_incorrect_response(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        engine.get_next_activity(start["assessment_id"])
        result = engine.process_response(
            start["assessment_id"],
            activity_index=0,
            selected_option="WRONG_ANSWER",
            response_time_ms=2000,
        )
        assert result["is_correct"] is False
        assert result["feedback"]["is_correct"] is False

    def test_incorrect_response_removes_higher_levels(self, db, player, seeded_db):
        """Wrong answer should remove future activities for that dimension at higher levels."""
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        activity = engine.get_next_activity(start["assessment_id"])
        dimension = activity["dimension"]

        # Answer wrong
        engine.process_response(
            start["assessment_id"],
            activity_index=0,
            selected_option="WRONG",
            response_time_ms=1000,
        )

        # Check activities were shortened
        assessment = (
            seeded_db.query(Assessment)
            .filter(Assessment.id == start["assessment_id"])
            .first()
        )
        remaining_for_dim = [
            a
            for a in assessment.activities
            if a["dimension"] == dimension and a["level"] > 0
        ]
        assert len(remaining_for_dim) == 0, (
            f"Higher-level activities for {dimension} should be removed after wrong answer"
        )

    def test_advances_current_index(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        activity = engine.get_next_activity(start["assessment_id"])
        engine.process_response(
            start["assessment_id"],
            activity_index=0,
            selected_option=activity["content"]["correct_answer"],
            response_time_ms=1000,
        )
        assessment = (
            seeded_db.query(Assessment)
            .filter(Assessment.id == start["assessment_id"])
            .first()
        )
        assert assessment.current_index == 1

    def test_progress_fraction(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        activity = engine.get_next_activity(start["assessment_id"])
        result = engine.process_response(
            start["assessment_id"],
            activity_index=0,
            selected_option=activity["content"]["correct_answer"],
            response_time_ms=1000,
        )
        assert 0.0 < result["progress_fraction"] <= 1.0


class TestCompleteAssessment:
    """Test assessment completion."""

    def _run_full_assessment(self, engine, assessment_id, all_correct=True):
        """Helper to run through all activities."""
        while True:
            activity = engine.get_next_activity(assessment_id)
            if activity is None:
                break
            if all_correct:
                answer = activity["content"].get("correct_answer", "")
            else:
                answer = "WRONG"
            result = engine.process_response(
                assessment_id,
                activity_index=activity["activity_index"],
                selected_option=answer,
                response_time_ms=1500,
            )
            if not result["should_continue"]:
                break

    def test_complete_returns_results(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        self._run_full_assessment(engine, start["assessment_id"])
        result = engine.complete_assessment(start["assessment_id"])
        assert result["assessment_id"] == start["assessment_id"]
        assert result["player_id"] == player.id
        assert len(result["dimensions"]) == 6

    def test_complete_all_correct_level_2(self, db, player, seeded_db):
        """All correct answers should result in level 2 for all dimensions."""
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        self._run_full_assessment(engine, start["assessment_id"], all_correct=True)
        result = engine.complete_assessment(start["assessment_id"])
        for dim_result in result["dimensions"]:
            assert dim_result["assessed_level"] == 2, (
                f"{dim_result['dimension']} should be level 2"
            )

    def test_complete_updates_profiles(self, db, player, seeded_db):
        """Completing assessment should update developmental profiles."""
        engine = AssessmentEngine(seeded_db)
        # Ensure profiles exist
        from app.services.adaptive_engine import AdaptiveEngine

        adaptive = AdaptiveEngine(seeded_db)
        adaptive.get_or_create_profiles(player.id)

        start = engine.start_assessment(player.id)
        self._run_full_assessment(engine, start["assessment_id"], all_correct=True)
        engine.complete_assessment(start["assessment_id"])

        # Check profiles were updated
        profiles = (
            seeded_db.query(DevelopmentalProfile)
            .filter(DevelopmentalProfile.player_id == player.id)
            .all()
        )
        for profile in profiles:
            assert profile.level == 2, (
                f"Profile {profile.dimension} should be level 2 after all-correct assessment"
            )

    def test_complete_marks_assessment_done(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        self._run_full_assessment(engine, start["assessment_id"])
        engine.complete_assessment(start["assessment_id"])
        assessment = (
            seeded_db.query(Assessment)
            .filter(Assessment.id == start["assessment_id"])
            .first()
        )
        assert assessment.completed is True
        assert assessment.completed_at is not None

    def test_complete_has_duration(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        self._run_full_assessment(engine, start["assessment_id"])
        result = engine.complete_assessment(start["assessment_id"])
        assert result["duration_seconds"] is not None
        assert result["duration_seconds"] >= 0

    def test_complete_has_character_message(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        self._run_full_assessment(engine, start["assessment_id"])
        result = engine.complete_assessment(start["assessment_id"])
        assert "character_message" in result
        assert len(result["character_message"]) > 0


class TestGetResults:
    """Test getting assessment results."""

    def test_get_results_active_assessment(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        # Answer one activity
        activity = engine.get_next_activity(start["assessment_id"])
        engine.process_response(
            start["assessment_id"],
            activity_index=0,
            selected_option=activity["content"]["correct_answer"],
            response_time_ms=1000,
        )
        result = engine.get_results(start["assessment_id"])
        assert result is not None
        assert result["completed"] is False

    def test_get_results_completed_assessment(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)

        # Run full assessment
        while True:
            activity = engine.get_next_activity(start["assessment_id"])
            if activity is None:
                break
            engine.process_response(
                start["assessment_id"],
                activity_index=activity["activity_index"],
                selected_option=activity["content"].get("correct_answer", ""),
                response_time_ms=1500,
            )

        engine.complete_assessment(start["assessment_id"])
        result = engine.get_results(start["assessment_id"])
        assert result is not None
        assert result["completed"] is True
        assert len(result["dimensions"]) == 6

    def test_get_results_nonexistent(self, db):
        engine = AssessmentEngine(db)
        result = engine.get_results("nonexistent-id")
        assert result is None

    def test_get_results_has_timestamps(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        result = engine.get_results(start["assessment_id"])
        assert "started_at" in result
        assert result["started_at"] is not None

    def test_dimension_results_have_required_keys(self, db, player, seeded_db):
        engine = AssessmentEngine(seeded_db)
        start = engine.start_assessment(player.id)
        activity = engine.get_next_activity(start["assessment_id"])
        engine.process_response(
            start["assessment_id"],
            activity_index=0,
            selected_option=activity["content"]["correct_answer"],
            response_time_ms=1000,
        )
        result = engine.get_results(start["assessment_id"])
        for dim in result["dimensions"]:
            required_keys = {
                "dimension",
                "dimension_label",
                "assessed_level",
                "max_tested_level",
                "correct_count",
                "total_count",
                "accuracy",
                "icon",
                "color",
            }
            assert required_keys.issubset(dim.keys()), (
                f"Dimension result missing keys: {required_keys - dim.keys()}"
            )


class TestDBPersistence:
    """Test that assessment state survives session recreation (simulating restart)."""

    def test_state_persists_across_engine_instances(self, db, player, seeded_db):
        """Simulates server restart by creating new engine instances."""
        # Engine 1: start assessment and answer one activity
        engine1 = AssessmentEngine(seeded_db)
        start = engine1.start_assessment(player.id)
        assessment_id = start["assessment_id"]

        activity = engine1.get_next_activity(assessment_id)
        engine1.process_response(
            assessment_id,
            activity_index=0,
            selected_option=activity["content"]["correct_answer"],
            response_time_ms=1000,
        )

        # Engine 2: new instance (simulates restart)
        engine2 = AssessmentEngine(seeded_db)
        next_activity = engine2.get_next_activity(assessment_id)

        # Should continue from index 1, not restart from 0
        assert next_activity is not None
        assert next_activity["activity_index"] == 1

    def test_results_persist_after_completion(self, db, player, seeded_db):
        """Results should be queryable from a new engine instance."""
        engine1 = AssessmentEngine(seeded_db)
        start = engine1.start_assessment(player.id)
        assessment_id = start["assessment_id"]

        # Run full assessment
        while True:
            activity = engine1.get_next_activity(assessment_id)
            if activity is None:
                break
            engine1.process_response(
                assessment_id,
                activity_index=activity["activity_index"],
                selected_option=activity["content"].get("correct_answer", ""),
                response_time_ms=1000,
            )
        engine1.complete_assessment(assessment_id)

        # New engine instance
        engine2 = AssessmentEngine(seeded_db)
        result = engine2.get_results(assessment_id)
        assert result is not None
        assert result["completed"] is True
        assert len(result["dimensions"]) == 6
