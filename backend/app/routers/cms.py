"""
Content Management System (CMS) API routes.

Provides CRUD operations for adaptive tasks with batch import/export support.
Supports JSON and CSV formats for import/export.
"""

import csv
import io
import json
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.models.adaptive import AdaptiveTask, DevelopmentalDimension, TaskType
from app.schemas.adaptive import (
    AdaptiveTaskCreate,
    AdaptiveTaskResponse,
)

router = APIRouter(prefix="/cms", tags=["cms"])

VALID_DIMENSIONS = [d.value for d in DevelopmentalDimension]
VALID_TASK_TYPES = [t.value for t in TaskType]


class AdaptiveTaskUpdate(AdaptiveTaskCreate):
    """Schema for updating a task (same fields as create)."""

    pass


# ── Stats ────────────────────────────────────────────────────────────────


@router.get("/stats")
def cms_stats(db: Session = Depends(get_db)):
    """Get task counts grouped by dimension and level."""
    rows = (
        db.query(
            AdaptiveTask.dimension,
            AdaptiveTask.level,
            AdaptiveTask.is_assessment,
            func.count(AdaptiveTask.id),
        )
        .group_by(
            AdaptiveTask.dimension, AdaptiveTask.level, AdaptiveTask.is_assessment
        )
        .all()
    )

    by_dimension: dict = {}
    total = 0
    assessment_total = 0

    for dimension, level, is_assessment, count in rows:
        total += count
        if is_assessment:
            assessment_total += count

        if dimension not in by_dimension:
            by_dimension[dimension] = {"total": 0, "levels": {}}
        by_dimension[dimension]["total"] += count
        level_key = str(level)
        if level_key not in by_dimension[dimension]["levels"]:
            by_dimension[dimension]["levels"][level_key] = 0
        by_dimension[dimension]["levels"][level_key] += count

    return {
        "total": total,
        "assessment_total": assessment_total,
        "practice_total": total - assessment_total,
        "by_dimension": by_dimension,
        "dimensions": VALID_DIMENSIONS,
        "task_types": VALID_TASK_TYPES,
    }


# ── List with pagination & search ────────────────────────────────────────


@router.get("/tasks", response_model=dict)
def list_tasks_paginated(
    dimension: Optional[str] = None,
    level: Optional[int] = None,
    task_type: Optional[str] = None,
    is_assessment: Optional[bool] = None,
    search: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """List tasks with pagination, filtering, and search."""
    query = db.query(AdaptiveTask)

    if dimension:
        if dimension not in VALID_DIMENSIONS:
            raise HTTPException(
                status_code=400, detail=f"Invalid dimension: {dimension}"
            )
        query = query.filter(AdaptiveTask.dimension == dimension)

    if level is not None:
        query = query.filter(AdaptiveTask.level == level)

    if task_type:
        query = query.filter(AdaptiveTask.task_type == task_type)

    if is_assessment is not None:
        query = query.filter(AdaptiveTask.is_assessment == is_assessment)

    # Text search across content JSON (cast to string for LIKE)
    if search:
        from sqlalchemy import cast, String

        search_escaped = search.replace("%", "\\%").replace("_", "\\_")
        query = query.filter(
            cast(AdaptiveTask.content, String).like(f"%{search_escaped}%", escape="\\")
        )

    total = query.count()
    tasks = (
        query.order_by(
            AdaptiveTask.dimension, AdaptiveTask.level, AdaptiveTask.created_at
        )
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    return {
        "tasks": [AdaptiveTaskResponse.model_validate(t) for t in tasks],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
    }


# ── Update ───────────────────────────────────────────────────────────────


@router.put("/tasks/{task_id}", response_model=AdaptiveTaskResponse)
def update_task(
    task_id: str,
    task_data: AdaptiveTaskUpdate,
    db: Session = Depends(get_db),
):
    """Update an existing task."""
    task = db.query(AdaptiveTask).filter(AdaptiveTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail=f"Task {task_id} not found")

    if task_data.dimension not in VALID_DIMENSIONS:
        raise HTTPException(
            status_code=400, detail=f"Invalid dimension: {task_data.dimension}"
        )

    task.dimension = task_data.dimension
    task.level = task_data.level
    task.task_type = task_data.task_type
    task.modalities = task_data.modalities
    task.content = task_data.content
    task.metadata_info = task_data.metadata_info
    task.is_assessment = task_data.is_assessment

    db.commit()
    db.refresh(task)
    return AdaptiveTaskResponse.model_validate(task)


# ── Batch Delete ─────────────────────────────────────────────────────────


@router.post("/tasks/batch-delete")
def batch_delete_tasks(
    task_ids: list[str],
    db: Session = Depends(get_db),
):
    """Delete multiple tasks by ID."""
    deleted = 0
    for task_id in task_ids:
        task = db.query(AdaptiveTask).filter(AdaptiveTask.id == task_id).first()
        if task:
            db.delete(task)
            deleted += 1
    db.commit()
    return {"deleted": deleted, "requested": len(task_ids)}


# ── Export ───────────────────────────────────────────────────────────────


@router.get("/export/json")
def export_tasks_json(
    dimension: Optional[str] = None,
    is_assessment: Optional[bool] = None,
    db: Session = Depends(get_db),
):
    """Export tasks as JSON file."""
    query = db.query(AdaptiveTask)
    if dimension:
        query = query.filter(AdaptiveTask.dimension == dimension)
    if is_assessment is not None:
        query = query.filter(AdaptiveTask.is_assessment == is_assessment)

    tasks = query.order_by(AdaptiveTask.dimension, AdaptiveTask.level).all()

    export_data = []
    for t in tasks:
        export_data.append(
            {
                "id": t.id,
                "dimension": t.dimension,
                "level": t.level,
                "task_type": t.task_type,
                "modalities": t.modalities,
                "content": t.content,
                "metadata_info": t.metadata_info,
                "is_assessment": t.is_assessment,
            }
        )

    output = json.dumps(export_data, ensure_ascii=False, indent=2)
    filename = f"tasks_export{'_' + dimension if dimension else ''}.json"

    return StreamingResponse(
        io.BytesIO(output.encode("utf-8")),
        media_type="application/json",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("/export/csv")
def export_tasks_csv(
    dimension: Optional[str] = None,
    is_assessment: Optional[bool] = None,
    db: Session = Depends(get_db),
):
    """Export tasks as CSV file."""
    query = db.query(AdaptiveTask)
    if dimension:
        query = query.filter(AdaptiveTask.dimension == dimension)
    if is_assessment is not None:
        query = query.filter(AdaptiveTask.is_assessment == is_assessment)

    tasks = query.order_by(AdaptiveTask.dimension, AdaptiveTask.level).all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(
        [
            "id",
            "dimension",
            "level",
            "task_type",
            "modalities",
            "content",
            "metadata_info",
            "is_assessment",
        ]
    )

    for t in tasks:
        writer.writerow(
            [
                t.id,
                t.dimension,
                t.level,
                t.task_type,
                json.dumps(t.modalities, ensure_ascii=False),
                json.dumps(t.content, ensure_ascii=False),
                json.dumps(t.metadata_info, ensure_ascii=False)
                if t.metadata_info
                else "",
                t.is_assessment,
            ]
        )

    filename = f"tasks_export{'_' + dimension if dimension else ''}.csv"

    return StreamingResponse(
        io.BytesIO(output.getvalue().encode("utf-8")),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


# ── Import ───────────────────────────────────────────────────────────────


@router.post("/import/json")
async def import_tasks_json(
    file: UploadFile = File(...),
    overwrite: bool = Query(False, description="If true, update existing tasks by ID"),
    db: Session = Depends(get_db),
):
    """Import tasks from a JSON file.

    Expected format: array of task objects with fields:
    dimension, level, task_type, modalities, content, metadata_info, is_assessment

    If a task has an 'id' field and overwrite=true, the existing task will be updated.
    Otherwise, new tasks are created.
    """
    try:
        raw = await file.read()
        data = json.loads(raw.decode("utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        raise HTTPException(status_code=400, detail=f"Invalid JSON file: {e}")

    if not isinstance(data, list):
        raise HTTPException(
            status_code=400, detail="Expected a JSON array of task objects"
        )

    created = 0
    updated = 0
    errors = []

    for idx, item in enumerate(data):
        try:
            dimension = item.get("dimension", "")
            if dimension not in VALID_DIMENSIONS:
                errors.append(f"Row {idx}: invalid dimension '{dimension}'")
                continue

            task_type = item.get("task_type", "")
            if task_type not in VALID_TASK_TYPES:
                errors.append(f"Row {idx}: invalid task_type '{task_type}'")
                continue

            existing_id = item.get("id")
            if existing_id and overwrite:
                existing = (
                    db.query(AdaptiveTask)
                    .filter(AdaptiveTask.id == existing_id)
                    .first()
                )
                if existing:
                    existing.dimension = dimension
                    existing.level = item.get("level", 0)
                    existing.task_type = task_type
                    existing.modalities = item.get("modalities", [])
                    existing.content = item.get("content", {})
                    existing.metadata_info = item.get("metadata_info")
                    existing.is_assessment = item.get("is_assessment", False)
                    updated += 1
                    continue

            task = AdaptiveTask(
                dimension=dimension,
                level=item.get("level", 0),
                task_type=task_type,
                modalities=item.get("modalities", []),
                content=item.get("content", {}),
                metadata_info=item.get("metadata_info"),
                is_assessment=item.get("is_assessment", False),
            )
            db.add(task)
            created += 1

        except Exception as e:
            errors.append(f"Row {idx}: {str(e)}")

    db.commit()
    return {
        "created": created,
        "updated": updated,
        "errors": errors,
        "total_processed": len(data),
    }


@router.post("/import/csv")
async def import_tasks_csv(
    file: UploadFile = File(...),
    overwrite: bool = Query(False, description="If true, update existing tasks by ID"),
    db: Session = Depends(get_db),
):
    """Import tasks from a CSV file.

    Expected columns: dimension, level, task_type, modalities (JSON), content (JSON),
    metadata_info (JSON), is_assessment

    Optional 'id' column for overwrite mode.
    """
    try:
        raw = await file.read()
        text = raw.decode("utf-8")
    except UnicodeDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid CSV file encoding: {e}")

    reader = csv.DictReader(io.StringIO(text))
    created = 0
    updated = 0
    errors = []
    row_count = 0

    for idx, row in enumerate(reader):
        row_count += 1
        try:
            dimension = row.get("dimension", "").strip()
            if dimension not in VALID_DIMENSIONS:
                errors.append(f"Row {idx + 1}: invalid dimension '{dimension}'")
                continue

            task_type = row.get("task_type", "").strip()
            if task_type not in VALID_TASK_TYPES:
                errors.append(f"Row {idx + 1}: invalid task_type '{task_type}'")
                continue

            modalities = json.loads(row.get("modalities", "[]"))
            content = json.loads(row.get("content", "{}"))
            metadata_raw = row.get("metadata_info", "").strip()
            metadata_info = json.loads(metadata_raw) if metadata_raw else None
            is_assessment_raw = row.get("is_assessment", "false").strip().lower()
            is_assessment = is_assessment_raw in ("true", "1", "yes")
            level = int(row.get("level", "0"))

            existing_id = row.get("id", "").strip()
            if existing_id and overwrite:
                existing = (
                    db.query(AdaptiveTask)
                    .filter(AdaptiveTask.id == existing_id)
                    .first()
                )
                if existing:
                    existing.dimension = dimension
                    existing.level = level
                    existing.task_type = task_type
                    existing.modalities = modalities
                    existing.content = content
                    existing.metadata_info = metadata_info
                    existing.is_assessment = is_assessment
                    updated += 1
                    continue

            task = AdaptiveTask(
                dimension=dimension,
                level=level,
                task_type=task_type,
                modalities=modalities,
                content=content,
                metadata_info=metadata_info,
                is_assessment=is_assessment,
            )
            db.add(task)
            created += 1

        except (json.JSONDecodeError, ValueError) as e:
            errors.append(f"Row {idx + 1}: {str(e)}")

    db.commit()
    return {
        "created": created,
        "updated": updated,
        "errors": errors,
        "total_processed": row_count,
    }
