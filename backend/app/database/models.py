import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, JSON
from .connection import Base

def generate_uuid():
    return str(uuid.uuid4())

class Grievance(Base):
    __tablename__ = "grievances"

    id = Column(String, primary_key=True, index=True, default=generate_uuid)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    location = Column(String, nullable=True)
    category = Column(String, nullable=True)
    status = Column(String, default="pending")
    department = Column(String, default="unassigned")
    priority = Column(String, default="medium")
    image_data = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
