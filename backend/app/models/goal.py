from typing import Optional
from datetime import date
from sqlalchemy import String, Float, Date, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Goal(Base):
    __tablename__ = "goals"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    target_amount: Mapped[float] = mapped_column(Float, nullable=False)
    current_amount: Mapped[float] = mapped_column(Float, default=0.0)
    deadline: Mapped[Optional[__import__('datetime').date]] = mapped_column(Date, nullable=True)

    # Relationships
    user = relationship("User", back_populates="goals")
