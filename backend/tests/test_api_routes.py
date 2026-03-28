"""Tests for API routes using FastAPI TestClient."""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app


@pytest.fixture
def client():
    """Create a test client with an in-memory database.

    Uses StaticPool so every connection shares the same in-memory DB.
    """
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    TestSession = sessionmaker(bind=engine)

    def override_get_db():
        session = TestSession()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)


class TestRootAndHealth:
    """Test basic endpoints."""

    def test_root(self, client):
        resp = client.get("/")
        assert resp.status_code == 200
        data = resp.json()
        assert "Rising Star Kid" in data["message"]

    def test_health(self, client):
        resp = client.get("/health")
        assert resp.status_code == 200
        assert resp.json() == {"status": "healthy"}


class TestPlayerRoutes:
    """Test player CRUD routes."""

    def test_create_player(self, client):
        resp = client.post("/players/", json={"name": "TestChild", "age": 5})
        assert resp.status_code == 200
        data = resp.json()
        assert data["name"] == "TestChild"
        assert "id" in data

    def test_list_players(self, client):
        client.post("/players/", json={"name": "Child1"})
        client.post("/players/", json={"name": "Child2"})
        resp = client.get("/players/")
        assert resp.status_code == 200
        players = resp.json()
        assert len(players) >= 2


class TestTaskRoutes:
    """Test task seeding and listing routes."""

    def test_seed_tasks(self, client):
        resp = client.post("/tasks/seed")
        assert resp.status_code == 200
        data = resp.json()
        assert "counts" in data
        # First seed should create tasks (original 128 + expanded tasks)
        list_resp = client.get("/tasks/?limit=500")
        assert list_resp.status_code == 200
        assert len(list_resp.json()) >= 128  # At least 92 practice + 36 assessment

    def test_seed_idempotent(self, client):
        client.post("/tasks/seed")
        resp = client.post("/tasks/seed")
        assert resp.status_code == 200
        counts = resp.json()["counts"]
        # Second seed should return 0s for practice dimensions
        for dim in [
            "object_cognition",
            "language_expression",
            "language_comprehension",
            "literacy",
            "social_behavior",
            "cognitive_logic",
        ]:
            assert counts[dim] == 0


def _setup(client):
    """Seed tasks and create a player, return player_id."""
    client.post("/tasks/seed")
    resp = client.post("/players/", json={"name": "TestChild", "age": 5})
    assert resp.status_code == 200, f"Failed to create player: {resp.text}"
    return resp.json()["id"]


class TestAdaptiveRoutes:
    """Test adaptive learning routes."""

    def test_get_profiles(self, client):
        player_id = _setup(client)
        resp = client.get(f"/adaptive/profiles/{player_id}")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["dimensions"]) == 6

    def test_start_session(self, client):
        player_id = _setup(client)
        resp = client.post(
            "/adaptive/sessions/start",
            json={
                "player_id": player_id,
                "dimension": "object_cognition",
                "session_type": "practice",
            },
        )
        assert resp.status_code == 200
        assert resp.json()["status"] == "active"

    def test_get_next_task(self, client):
        player_id = _setup(client)
        session_resp = client.post(
            "/adaptive/sessions/start",
            json={
                "player_id": player_id,
                "dimension": "object_cognition",
                "session_type": "practice",
            },
        )
        session_id = session_resp.json()["id"]
        resp = client.get(
            f"/adaptive/sessions/{session_id}/next-task",
            params={"player_id": player_id, "dimension": "object_cognition"},
        )
        assert resp.status_code == 200
        task = resp.json()
        assert task["dimension"] == "object_cognition"

    def test_submit_attempt(self, client):
        player_id = _setup(client)
        session_resp = client.post(
            "/adaptive/sessions/start",
            json={
                "player_id": player_id,
                "dimension": "object_cognition",
                "session_type": "practice",
            },
        )
        session_id = session_resp.json()["id"]
        task_resp = client.get(
            f"/adaptive/sessions/{session_id}/next-task",
            params={"player_id": player_id, "dimension": "object_cognition"},
        )
        task_id = task_resp.json()["task_id"]
        resp = client.post(
            "/adaptive/attempts",
            json={
                "session_id": session_id,
                "task_id": task_id,
                "player_id": player_id,
                "is_correct": True,
                "response_time_ms": 1500,
            },
        )
        assert resp.status_code == 200
        assert resp.json()["is_correct"] is True

    def test_speech_evaluation(self, client):
        resp = client.post(
            "/adaptive/evaluate-speech",
            json={
                "target": "apple",
                "spoken": "apple",
            },
        )
        assert resp.status_code == 200
        assert resp.json()["similarity_score"] == 1.0

    def test_modality_recommendation(self, client):
        player_id = _setup(client)
        resp = client.get(f"/adaptive/modality/{player_id}")
        assert resp.status_code == 200
        assert "recommended_modality" in resp.json()


class TestAssessmentRoutes:
    """Test gamified assessment routes."""

    def test_start_assessment(self, client):
        player_id = _setup(client)
        resp = client.post(f"/assessment/start/{player_id}")
        assert resp.status_code == 200
        data = resp.json()
        assert "assessment_id" in data
        assert data["total_activities"] == 18

    def test_get_next_activity(self, client):
        player_id = _setup(client)
        start = client.post(f"/assessment/start/{player_id}").json()
        resp = client.get(f"/assessment/{start['assessment_id']}/next-activity")
        assert resp.status_code == 200
        assert resp.json()["activity_index"] == 0

    def test_respond_to_activity(self, client):
        player_id = _setup(client)
        start = client.post(f"/assessment/start/{player_id}").json()
        activity = client.get(
            f"/assessment/{start['assessment_id']}/next-activity"
        ).json()
        resp = client.post(
            f"/assessment/{start['assessment_id']}/respond",
            json={
                "activity_index": 0,
                "selected_option": activity["content"]["correct_answer"],
                "response_time_ms": 1500,
            },
        )
        assert resp.status_code == 200
        assert resp.json()["is_correct"] is True

    def test_complete_assessment(self, client):
        player_id = _setup(client)
        start = client.post(f"/assessment/start/{player_id}").json()
        aid = start["assessment_id"]

        # Answer all activities
        while True:
            act_resp = client.get(f"/assessment/{aid}/next-activity")
            if act_resp.status_code != 200:
                break
            act = act_resp.json()
            if act is None:
                break
            client.post(
                f"/assessment/{aid}/respond",
                json={
                    "activity_index": act["activity_index"],
                    "selected_option": act["content"].get("correct_answer", ""),
                    "response_time_ms": 1000,
                },
            )

        resp = client.post(f"/assessment/{aid}/complete")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["dimensions"]) == 6

    def test_get_results(self, client):
        player_id = _setup(client)
        start = client.post(f"/assessment/start/{player_id}").json()
        resp = client.get(f"/assessment/{start['assessment_id']}/results")
        assert resp.status_code == 200

    def test_start_assessment_invalid_player(self, client):
        resp = client.post("/assessment/start/nonexistent")
        assert resp.status_code == 404

    def test_get_results_invalid_assessment(self, client):
        resp = client.get("/assessment/nonexistent/results")
        assert resp.status_code == 404


class TestDashboardRoutes:
    """Test dashboard routes."""

    def test_dashboard_summary(self, client):
        player_id = _setup(client)
        # Create profiles first
        client.get(f"/adaptive/profiles/{player_id}")
        resp = client.get(f"/dashboard/{player_id}/summary")
        assert resp.status_code == 200
        data = resp.json()
        assert "total_sessions" in data
        assert "dimensions" in data


class TestAIRoutes:
    """Test AI service routes."""

    def _ai_setup(self, client):
        player_id = _setup(client)
        # Ensure profiles exist
        client.get(f"/adaptive/profiles/{player_id}")
        return player_id

    def test_ai_status(self, client):
        resp = client.get("/ai/status")
        assert resp.status_code == 200
        data = resp.json()
        assert "llm_enabled" in data

    def test_social_story(self, client):
        player_id = self._ai_setup(client)
        resp = client.post(
            "/ai/social-story",
            json={
                "player_id": player_id,
                "scenario": "going to the park",
            },
        )
        assert resp.status_code == 200
        assert "story" in resp.json()

    def test_behavior_guidance(self, client):
        player_id = self._ai_setup(client)
        resp = client.post(
            "/ai/behavior-guidance",
            json={
                "player_id": player_id,
            },
        )
        assert resp.status_code == 200

    def test_progress_summary(self, client):
        player_id = self._ai_setup(client)
        resp = client.post(
            "/ai/progress-summary",
            json={
                "player_id": player_id,
            },
        )
        assert resp.status_code == 200

    def test_generate_tasks(self, client):
        player_id = self._ai_setup(client)
        resp = client.post(
            "/ai/generate-tasks",
            json={
                "player_id": player_id,
                "dimension": "object_cognition",
                "task_type": "match",
                "interests": ["dinosaurs"],
            },
        )
        assert resp.status_code == 200
