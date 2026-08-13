"""
Financial Goals – full CRUD.

Maps to the Flutter GoalsScreen which shows goal cards with
title, current amount, target amount, progress, icon, and color.
"""

from datetime import date as date_type

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.goal import Goal

router = APIRouter()


# ---------- Request / Response schemas ----------

class GoalCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    target_amount: float = Field(..., gt=0)
    current_amount: float = Field(default=0.0, ge=0)
    deadline: date_type | None = None


class GoalUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    target_amount: float | None = Field(default=None, gt=0)
    current_amount: float | None = Field(default=None, ge=0)
    deadline: date_type | None = None


class GoalResponse(BaseModel):
    id: int
    name: str
    target_amount: float
    current_amount: float
    deadline: str | None
    progress: float  # 0.0 – 1.0

    model_config = {"from_attributes": True}


def _to_response(g: Goal) -> GoalResponse:
    progress = min(g.current_amount / g.target_amount, 1.0) if g.target_amount else 0.0
    return GoalResponse(
        id=g.id,
        name=g.name,
        target_amount=g.target_amount,
        current_amount=g.current_amount,
        deadline=g.deadline.isoformat() if g.deadline else None,
        progress=round(progress, 4),
    )


# ---------- Endpoints ----------

@router.get("/", response_model=list[GoalResponse])
async def list_goals(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return all financial goals for the authenticated user."""
    result = await db.execute(
        select(Goal)
        .where(Goal.user_id == current_user.id)
        .order_by(Goal.id.desc())
    )
    return [_to_response(g) for g in result.scalars().all()]


@router.post("/", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
async def create_goal(
    body: GoalCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new financial goal."""
    goal = Goal(
        user_id=current_user.id,
        name=body.name,
        target_amount=body.target_amount,
        current_amount=body.current_amount,
        deadline=body.deadline,
    )
    db.add(goal)
    await db.flush()
    await db.refresh(goal)
    return _to_response(goal)


@router.get("/{goal_id}", response_model=GoalResponse)
async def get_goal(
    goal_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single goal by ID."""
    goal = await _get_user_goal(db, goal_id, current_user.id)
    return _to_response(goal)


@router.patch("/{goal_id}", response_model=GoalResponse)
async def update_goal(
    goal_id: int,
    body: GoalUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update a goal (partial update). Use this to add money towards a goal."""
    goal = await _get_user_goal(db, goal_id, current_user.id)

    update_data = body.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(goal, field, value)

    await db.flush()
    await db.refresh(goal)
    return _to_response(goal)


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_goal(
    goal_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a goal."""
    goal = await _get_user_goal(db, goal_id, current_user.id)
    await db.delete(goal)


# ---------- Helpers ----------

async def _get_user_goal(db: AsyncSession, goal_id: int, user_id: int) -> Goal:
    """Fetch a goal and ensure it belongs to the user, or raise 404."""
    result = await db.execute(
        select(Goal).where(Goal.id == goal_id, Goal.user_id == user_id)
    )
    goal = result.scalar_one_or_none()
    if goal is None:
        raise HTTPException(status_code=404, detail="Goal not found")
    return goal
