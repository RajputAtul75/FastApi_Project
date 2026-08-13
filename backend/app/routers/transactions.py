"""
Transactions – list with pagination + JWT auth.
"""

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.transaction import Transaction

router = APIRouter()


# ---------- Response schemas ----------

class TransactionOut(BaseModel):
    id: int
    merchant_name: str
    amount: float
    date: str
    category: str | None
    is_debit: bool

    model_config = {"from_attributes": True}


class PaginatedTransactions(BaseModel):
    items: list[TransactionOut]
    total: int
    limit: int
    offset: int


# ---------- Endpoints ----------

@router.get("/", response_model=PaginatedTransactions)
async def list_transactions(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    category: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return paginated transactions for the authenticated user."""
    base = select(Transaction).where(Transaction.user_id == current_user.id)

    if category:
        base = base.where(Transaction.category == category)

    # Total count
    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await db.execute(count_stmt)).scalar() or 0

    # Paginated rows
    rows_stmt = (
        base
        .order_by(Transaction.date.desc(), Transaction.id.desc())
        .limit(limit)
        .offset(offset)
    )
    result = await db.execute(rows_stmt)
    rows = result.scalars().all()

    return PaginatedTransactions(
        items=[
            TransactionOut(
                id=t.id,
                merchant_name=t.merchant_name,
                amount=t.amount,
                date=t.date.isoformat(),
                category=t.category,
                is_debit=t.is_debit,
            )
            for t in rows
        ],
        total=total,
        limit=limit,
        offset=offset,
    )
