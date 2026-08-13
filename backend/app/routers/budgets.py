"""
Budgets – CRUD for per-category monthly spending limits.

The Flutter app can use these to show "You've spent X% of your Food budget"
alongside transaction data.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.budget import Budget

router = APIRouter()


# ---------- Schemas ----------

class BudgetCreate(BaseModel):
    category: str = Field(..., min_length=1, max_length=100)
    monthly_limit: float = Field(..., gt=0)
    month_year: str = Field(..., pattern=r"^\d{4}-\d{2}$")  # e.g. "2026-05"


class BudgetUpdate(BaseModel):
    monthly_limit: float | None = Field(default=None, gt=0)
    month_year: str | None = Field(default=None, pattern=r"^\d{4}-\d{2}$")


class BudgetResponse(BaseModel):
    id: int
    category: str
    monthly_limit: float
    month_year: str

    model_config = {"from_attributes": True}


# ---------- Endpoints ----------

@router.get("/", response_model=list[BudgetResponse])
async def list_budgets(
    month_year: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return all budgets for the authenticated user, optionally filtered by month."""
    stmt = select(Budget).where(Budget.user_id == current_user.id)
    if month_year:
        stmt = stmt.where(Budget.month_year == month_year)
    stmt = stmt.order_by(Budget.id.desc())

    result = await db.execute(stmt)
    return [
        BudgetResponse(
            id=b.id,
            category=b.category,
            monthly_limit=b.monthly_limit,
            month_year=b.month_year,
        )
        for b in result.scalars().all()
    ]


@router.post("/", response_model=BudgetResponse, status_code=status.HTTP_201_CREATED)
async def create_budget(
    body: BudgetCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a monthly budget for a spending category."""
    # Prevent duplicate budget for same category + month
    existing = await db.execute(
        select(Budget).where(
            Budget.user_id == current_user.id,
            Budget.category == body.category,
            Budget.month_year == body.month_year,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Budget for '{body.category}' in {body.month_year} already exists",
        )

    budget = Budget(
        user_id=current_user.id,
        category=body.category,
        monthly_limit=body.monthly_limit,
        month_year=body.month_year,
    )
    db.add(budget)
    await db.flush()
    await db.refresh(budget)

    return BudgetResponse(
        id=budget.id,
        category=budget.category,
        monthly_limit=budget.monthly_limit,
        month_year=budget.month_year,
    )


@router.patch("/{budget_id}", response_model=BudgetResponse)
async def update_budget(
    budget_id: int,
    body: BudgetUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update an existing budget's limit or month."""
    budget = await _get_user_budget(db, budget_id, current_user.id)

    update_data = body.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(budget, field, value)

    await db.flush()
    await db.refresh(budget)

    return BudgetResponse(
        id=budget.id,
        category=budget.category,
        monthly_limit=budget.monthly_limit,
        month_year=budget.month_year,
    )


@router.delete("/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_budget(
    budget_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a budget."""
    budget = await _get_user_budget(db, budget_id, current_user.id)
    await db.delete(budget)


# ---------- Helpers ----------

async def _get_user_budget(db: AsyncSession, budget_id: int, user_id: int) -> Budget:
    result = await db.execute(
        select(Budget).where(Budget.id == budget_id, Budget.user_id == user_id)
    )
    budget = result.scalar_one_or_none()
    if budget is None:
        raise HTTPException(status_code=404, detail="Budget not found")
    return budget
