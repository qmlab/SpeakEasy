"""
Task management API routes.

Handles CRUD for adaptive tasks and seeding.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.adaptive import AdaptiveTask, DevelopmentalDimension
from app.schemas.adaptive import AdaptiveTaskCreate, AdaptiveTaskResponse
from app.services.seed_tasks import (
    seed_all_tasks,
    backfill_image_hints,
    backfill_task_options,
)
from app.services.seed_expanded import seed_expanded_tasks, get_expanded_task_stats

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("/", response_model=list[AdaptiveTaskResponse])
def list_tasks(
    dimension: str = None,
    level: int = None,
    is_assessment: bool = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    """List adaptive tasks with optional filters."""
    query = db.query(AdaptiveTask)

    if dimension:
        valid_dims = [d.value for d in DevelopmentalDimension]
        if dimension not in valid_dims:
            raise HTTPException(
                status_code=400, detail=f"Invalid dimension: {dimension}"
            )
        query = query.filter(AdaptiveTask.dimension == dimension)

    if level is not None:
        query = query.filter(AdaptiveTask.level == level)

    if is_assessment is not None:
        query = query.filter(AdaptiveTask.is_assessment == is_assessment)  # noqa: E712

    tasks = query.offset(offset).limit(limit).all()
    return [AdaptiveTaskResponse.model_validate(t) for t in tasks]


@router.get("/{task_id}", response_model=AdaptiveTaskResponse)
def get_task(task_id: str, db: Session = Depends(get_db)):
    """Get a single adaptive task by ID."""
    task = db.query(AdaptiveTask).filter(AdaptiveTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail=f"Task {task_id} not found")
    return AdaptiveTaskResponse.model_validate(task)


@router.post("/", response_model=AdaptiveTaskResponse)
def create_task(task_data: AdaptiveTaskCreate, db: Session = Depends(get_db)):
    """Create a new adaptive task."""
    valid_dims = [d.value for d in DevelopmentalDimension]
    if task_data.dimension not in valid_dims:
        raise HTTPException(
            status_code=400, detail=f"Invalid dimension: {task_data.dimension}"
        )

    task = AdaptiveTask(
        dimension=task_data.dimension,
        level=task_data.level,
        task_type=task_data.task_type,
        modalities=task_data.modalities,
        content=task_data.content,
        metadata_info=task_data.metadata_info,
        is_assessment=task_data.is_assessment,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return AdaptiveTaskResponse.model_validate(task)


@router.delete("/{task_id}")
def delete_task(task_id: str, db: Session = Depends(get_db)):
    """Delete an adaptive task."""
    task = db.query(AdaptiveTask).filter(AdaptiveTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail=f"Task {task_id} not found")
    db.delete(task)
    db.commit()
    return {"message": f"Task {task_id} deleted"}


@router.post("/seed")
def seed_tasks(force: bool = False, db: Session = Depends(get_db)):
    """Seed the database with default adaptive tasks + expanded content.

    Args:
        force: If True, delete existing expanded tasks and re-seed with
               updated JSON data (e.g. after adding image_hint fields).
    """
    results = seed_all_tasks(db)
    expanded_results = seed_expanded_tasks(db, force=force)
    results.update(expanded_results)

    # Backfill image_hint for any tasks that are missing it
    backfilled = backfill_image_hints(db)
    results["image_hints_backfilled"] = backfilled

    # Backfill options/correct_answer for all tasks missing them
    options_backfilled = backfill_task_options(db)
    results["options_backfilled"] = options_backfilled

    return {
        "message": "Tasks seeded successfully",
        "counts": results,
    }


@router.get("/stats/expanded")
def expanded_task_stats():
    """Get statistics about available expanded task resources."""
    return get_expanded_task_stats()
