from sqlalchemy import String, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Budget(Base):
    __tablename__ = "budgets"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    category: Mapped[str] = mapped_column(String(100), nullable=False)
    monthly_limit: Mapped[float] = mapped_column(Float, nullable=False)
    month_year: Mapped[str] = mapped_column(String(7), nullable=False)  # "2026-04"

    # Relationships
    user = relationship("User", back_populates="budgets")
