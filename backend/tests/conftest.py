"""Shared test fixtures for Rising Star Kid backend tests."""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base


@pytest.fixture
def db():
    """Create an in-memory SQLite database for each test."""
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
    )
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture
def player(db):
    """Create a test player."""
    from app.models.player import Player

    p = Player(id="test-player-1", name="TestChild")
    db.add(p)
    db.commit()
    db.refresh(p)
    return p


@pytest.fixture
def seeded_db(db):
    """Seed all tasks into the test database."""
    from app.services.seed_tasks import seed_all_tasks
    from app.services.seed_assessment import seed_assessment_tasks

    seed_all_tasks(db)
    seed_assessment_tasks(db)
    return db
