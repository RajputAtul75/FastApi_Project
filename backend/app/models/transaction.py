from typing import Optional
from datetime import date, datetime, timezone
from sqlalchemy import String, Float, Boolean, Date, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    merchant_name: Mapped[str] = mapped_column(String(500), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    date: Mapped[__import__('datetime').date] = mapped_column(Date, nullable=False)
    category: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    raw_description: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)
    is_debit: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    user = relationship("User", back_populates="transactions")
