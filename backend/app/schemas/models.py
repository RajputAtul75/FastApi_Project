"""Pydantic schemas for NyayaAI API request/response models."""
from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import datetime


# --- Enums / Constants ---
PRIORITIES = ["Low", "Medium", "High", "Critical"]
STATUSES = ["Submitted", "Assigned", "In Progress", "Resolved"]
CATEGORIES = [
    "Road & Infrastructure", "Electricity", "Water Supply",
    "Sanitation", "Waste Management", "Public Safety",
    "Healthcare", "Education", "Other"
]
DEPARTMENTS = [
    "Municipal Corporation", "Electricity Department", "Water Department",
    "Sanitation Department", "Police Department", "Health Department",
    "Education Department", "General Administration", "Other"
]


# --- Request Models ---
class GrievanceCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    description: str = Field(..., min_length=10, max_length=5000)
    location: Optional[str] = Field(None, max_length=500)
    category: Optional[str] = None
    image: Optional[dict] = None  # {"url": "...", "public_id": "..."}


class StatusUpdate(BaseModel):
    status: Literal["Submitted", "Assigned", "In Progress", "Resolved"]


class DepartmentUpdate(BaseModel):
    department: str = Field(..., min_length=1, max_length=200)


class AnalyzeRequest(BaseModel):
    text: str = Field(..., min_length=5, max_length=5000)


# --- Response Models ---
class AIClassification(BaseModel):
    category: str
    issue_type: str
    priority: str
    department: str
    summary: str


class ImageInfo(BaseModel):
    url: str
    public_id: str


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
    image: Optional[ImageInfo] = None
    created_at: str
    updated_at: str
    ai_status: Optional[str] = None


class AnalyzeResponse(BaseModel):
    classification: AIClassification
    ai_status: str  # "success" or "fallback"


class DashboardStats(BaseModel):
    total: int
    by_status: dict
    by_priority: dict
    by_category: dict
    by_department: dict


class HealthResponse(BaseModel):
    status: str
    database: str
    timestamp: str


class ImageUploadResponse(BaseModel):
    url: str
    public_id: str
