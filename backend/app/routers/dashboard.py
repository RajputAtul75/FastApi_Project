"""
Dashboard aggregation endpoint.

Provides a single GET /api/v1/dashboard that returns everything the
Flutter DashboardScreen needs in one round-trip:
  • total balance (income – expense over all time)
  • current-month income / expense
  • last 5 transactions
  • daily spending for the past 7 days (chart data)
"""

from datetime import date, timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select, func, case, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.transaction import Transaction

router = APIRouter()


# ---------- Response schemas ----------

class RecentTransaction(BaseModel):
    id: int
    merchant_name: str
    amount: float
    date: str
    category: str | None
    is_debit: bool


class ChartPoint(BaseModel):
    label: str  # e.g. "Mon", "Tue" or "05/12"
    amount: float


class DashboardResponse(BaseModel):
    total_balance: float
    monthly_income: float
    monthly_expense: float
    recent_transactions: list[RecentTransaction]
    chart_data: list[ChartPoint]


# ---------- Endpoint ----------

@router.get("/", response_model=DashboardResponse)
async def get_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return all aggregated dashboard data for the authenticated user."""
    user_id = current_user.id
    today = date.today()
    first_of_month = today.replace(day=1)

    # 1. Total balance (all-time income minus all-time expense)
    balance_stmt = select(
        func.coalesce(
            func.sum(
                case(
                    (Transaction.is_debit == False, Transaction.amount),
                    else_=0,
                )
            ),
            0,
        ).label("total_income"),
        func.coalesce(
            func.sum(
                case(
                    (Transaction.is_debit == True, Transaction.amount),
                    else_=0,
                )
            ),
            0,
        ).label("total_expense"),
    ).where(Transaction.user_id == user_id)

    bal_result = await db.execute(balance_stmt)
    bal_row = bal_result.one()
    total_income_all = float(bal_row.total_income)
    total_expense_all = float(bal_row.total_expense)
    total_balance = round(total_income_all - total_expense_all, 2)

    # 2. Current-month income & expense
    monthly_stmt = select(
        func.coalesce(
            func.sum(
                case(
                    (Transaction.is_debit == False, Transaction.amount),
                    else_=0,
                )
            ),
            0,
        ).label("monthly_income"),
        func.coalesce(
            func.sum(
                case(
                    (Transaction.is_debit == True, Transaction.amount),
                    else_=0,
                )
            ),
            0,
        ).label("monthly_expense"),
    ).where(
        Transaction.user_id == user_id,
        Transaction.date >= first_of_month,
    )

    mon_result = await db.execute(monthly_stmt)
    mon_row = mon_result.one()
    monthly_income = round(float(mon_row.monthly_income), 2)
    monthly_expense = round(float(mon_row.monthly_expense), 2)

    # 3. Recent 5 transactions
    recent_stmt = (
        select(Transaction)
        .where(Transaction.user_id == user_id)
        .order_by(Transaction.date.desc(), Transaction.id.desc())
        .limit(5)
    )
    recent_result = await db.execute(recent_stmt)
    recent_rows = recent_result.scalars().all()
    recent_transactions = [
        RecentTransaction(
            id=t.id,
            merchant_name=t.merchant_name,
            amount=t.amount,
            date=t.date.isoformat(),
            category=t.category,
            is_debit=t.is_debit,
        )
        for t in recent_rows
    ]

    # 4. Chart data — daily expense for last 7 days
    seven_days_ago = today - timedelta(days=6)
    chart_stmt = (
        select(
            Transaction.date,
            func.sum(Transaction.amount).label("daily_total"),
        )
        .where(
            Transaction.user_id == user_id,
            Transaction.is_debit == True,
            Transaction.date >= seven_days_ago,
        )
        .group_by(Transaction.date)
        .order_by(Transaction.date)
    )
    chart_result = await db.execute(chart_stmt)
    chart_rows = {row.date: float(row.daily_total) for row in chart_result.all()}

    # Fill in zeroes for days with no spending
    chart_data: list[ChartPoint] = []
    for i in range(7):
        d = seven_days_ago + timedelta(days=i)
        chart_data.append(
            ChartPoint(
                label=d.strftime("%a"),  # Mon, Tue, ...
                amount=chart_rows.get(d, 0.0),
            )
        )

    return DashboardResponse(
        total_balance=total_balance,
        monthly_income=monthly_income,
        monthly_expense=monthly_expense,
        recent_transactions=recent_transactions,
        chart_data=chart_data,
    )
