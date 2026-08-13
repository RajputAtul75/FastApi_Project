from pydantic import BaseModel, Field
from typing import Optional, Dict, Any

class GrievanceBase(BaseModel):
    title: str
    description: str
    location: Optional[str] = None
    category: Optional[str] = None

class GrievanceCreate(GrievanceBase):
    image: Optional[Dict[str, Any]] = None

class GrievanceResponse(BaseModel):
    ticket_id: str
    title: str
    description: str
    category: str
    issue_type: str
    priority: str
    department: str
    summary: str
    status: str
    location: Optional[str] = None
    image: Optional[Dict[str, Any]] = None
    created_at: str
    updated_at: str

class StatusUpdate(BaseModel):
    status: str

class DepartmentUpdate(BaseModel):
    department: str

