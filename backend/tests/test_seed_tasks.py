"""Tests for task seeding services."""

from app.models.adaptive import AdaptiveTask, DevelopmentalDimension
from app.services.seed_tasks import (
    seed_all_tasks,
    seed_object_cognition_tasks,
    seed_language_expression_tasks,
    seed_language_comprehension_tasks,
    seed_literacy_tasks,
    seed_social_behavior_tasks,
    seed_cognitive_logic_tasks,
)
from app.services.seed_assessment import seed_assessment_tasks


class TestSeedPracticeTasks:
    """Test practice task seeding."""

    def test_seed_object_cognition(self, db):
        count = seed_object_cognition_tasks(db)
        assert count == 17

    def test_seed_language_expression(self, db):
        count = seed_language_expression_tasks(db)
        assert count == 15

    def test_seed_language_comprehension(self, db):
        count = seed_language_comprehension_tasks(db)
        assert count == 15

    def test_seed_literacy(self, db):
        count = seed_literacy_tasks(db)
        assert count == 15

    def test_seed_social_behavior(self, db):
        count = seed_social_behavior_tasks(db)
        assert count == 15

    def test_seed_cognitive_logic(self, db):
        count = seed_cognitive_logic_tasks(db)
        assert count == 19

    def test_seed_all_tasks(self, db):
        result = seed_all_tasks(db)
        total = sum(result.values())
        assert total == 132  # 96 practice + 36 assessment

    def test_seed_idempotent(self, db):
        """Seeding twice should not duplicate tasks."""
        seed_all_tasks(db)
        second = seed_all_tasks(db)
        # Second call should return 0 for all dimensions
        for dim, count in second.items():
            if dim != "assessment":
                assert count == 0, f"Dimension {dim} was re-seeded"

    def test_practice_tasks_not_assessment(self, db):
        """All practice tasks must have is_assessment=False."""
        seed_all_tasks(db)
        practice_tasks = (
            db.query(AdaptiveTask)
            .filter(AdaptiveTask.is_assessment == False)  # noqa: E712
            .all()
        )
        assert len(practice_tasks) == 96

    def test_each_dimension_has_5_levels(self, db):
        """Each dimension should have tasks at levels 0-4."""
        seed_all_tasks(db)
        for dim in DevelopmentalDimension:
            for level in range(5):
                count = (
                    db.query(AdaptiveTask)
                    .filter(
                        AdaptiveTask.dimension == dim.value,
                        AdaptiveTask.level == level,
                        AdaptiveTask.is_assessment == False,  # noqa: E712
                    )
                    .count()
                )
                assert count > 0, f"No tasks for {dim.value} level {level}"


class TestSeedAssessmentTasks:
    """Test assessment task seeding."""

    def test_seed_assessment_tasks(self, db):
        count = seed_assessment_tasks(db)
        assert count == 36

    def test_assessment_tasks_marked_correctly(self, db):
        """All assessment tasks must have is_assessment=True."""
        seed_assessment_tasks(db)
        assessment_tasks = (
            db.query(AdaptiveTask)
            .filter(AdaptiveTask.is_assessment == True)  # noqa: E712
            .all()
        )
        assert len(assessment_tasks) == 36

    def test_assessment_idempotent(self, db):
        """Seeding assessment twice should not duplicate."""
        first = seed_assessment_tasks(db)
        second = seed_assessment_tasks(db)
        assert first == 36
        assert second == 0

    def test_assessment_tasks_per_dimension(self, db):
        """Each dimension should have exactly 6 assessment tasks (2 per level)."""
        seed_assessment_tasks(db)
        for dim in DevelopmentalDimension:
            count = (
                db.query(AdaptiveTask)
                .filter(
                    AdaptiveTask.dimension == dim.value,
                    AdaptiveTask.is_assessment == True,  # noqa: E712
                )
                .count()
            )
            assert count == 6, (
                f"Expected 6 assessment tasks for {dim.value}, got {count}"
            )

    def test_assessment_tasks_levels_0_to_2(self, db):
        """Assessment tasks should only cover levels 0, 1, 2."""
        seed_assessment_tasks(db)
        for dim in DevelopmentalDimension:
            for level in range(3):
                count = (
                    db.query(AdaptiveTask)
                    .filter(
                        AdaptiveTask.dimension == dim.value,
                        AdaptiveTask.level == level,
                        AdaptiveTask.is_assessment == True,  # noqa: E712
                    )
                    .count()
                )
                assert count == 2, (
                    f"Expected 2 assessment tasks for {dim.value} level {level}, got {count}"
                )

    def test_assessment_tasks_have_correct_content_format(self, db):
        """Assessment tasks must have instruction + correct_answer keys."""
        seed_assessment_tasks(db)
        tasks = (
            db.query(AdaptiveTask)
            .filter(AdaptiveTask.is_assessment == True)  # noqa: E712
            .all()
        )
        for task in tasks:
            content = task.content or {}
            assert "instruction" in content, f"Task {task.id} missing 'instruction' key"
            assert "correct_answer" in content, (
                f"Task {task.id} missing 'correct_answer' key"
            )

    def test_seed_replaces_stale_format(self, db):
        """If stale assessment tasks exist (wrong format), they should be replaced."""
        # Seed a stale task with old format (instruction_audio instead of instruction)
        stale_task = AdaptiveTask(
            dimension=DevelopmentalDimension.OBJECT_COGNITION.value,
            level=0,
            task_type="match",
            modalities=["touch"],
            is_assessment=True,
            content={
                "instruction_audio": "Old format",
                "choices": [{"name": "A"}],
            },
        )
        db.add(stale_task)
        db.commit()

        # Seed should detect stale format and replace
        count = seed_assessment_tasks(db)
        assert count == 36

        # Verify all tasks now have correct format
        tasks = (
            db.query(AdaptiveTask)
            .filter(AdaptiveTask.is_assessment == True)  # noqa: E712
            .all()
        )
        for task in tasks:
            content = task.content or {}
            assert "instruction" in content


class TestCombinedSeeding:
    """Test practice + assessment tasks together."""

    def test_total_task_count(self, seeded_db):
        total = seeded_db.query(AdaptiveTask).count()
        assert total == 132

    def test_practice_vs_assessment_counts(self, seeded_db):
        practice = (
            seeded_db.query(AdaptiveTask)
            .filter(AdaptiveTask.is_assessment == False)  # noqa: E712
            .count()
        )
        assessment = (
            seeded_db.query(AdaptiveTask)
            .filter(AdaptiveTask.is_assessment == True)  # noqa: E712
            .count()
        )
        assert practice == 96
        assert assessment == 36

    def test_no_overlap(self, seeded_db):
        """Practice and assessment tasks should not share IDs."""
        practice_ids = set(
            t.id
            for t in seeded_db.query(AdaptiveTask)
            .filter(AdaptiveTask.is_assessment == False)  # noqa: E712
            .all()
        )
        assessment_ids = set(
            t.id
            for t in seeded_db.query(AdaptiveTask)
            .filter(AdaptiveTask.is_assessment == True)  # noqa: E712
            .all()
        )
        assert len(practice_ids & assessment_ids) == 0
