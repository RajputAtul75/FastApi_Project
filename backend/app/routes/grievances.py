"""Grievance API routes."""
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from app.schemas.models import (
    GrievanceCreate, GrievanceResponse, StatusUpdate,
    DepartmentUpdate, STATUSES,
)
from app.database.connection import get_collection
from app.services.ai_service import analyze_grievance
from app.utils.helpers import generate_ticket_id

router = APIRouter(prefix="/api", tags=["grievances"])


def _doc_to_response(doc: dict) -> dict:
    """Convert a MongoDB document to a response dict."""
    doc.pop("_id", None)
    return doc


@router.post("/grievances", response_model=GrievanceResponse, status_code=201)
def create_grievance(payload: GrievanceCreate):
    """Create a new grievance with AI classification."""
    try:
        col = get_collection("grievances")
    except Exception:
        raise HTTPException(status_code=503, detail="Database unavailable")

    # AI classification
    classification, ai_status = analyze_grievance(payload.description)

    # Generate ticket ID
    ticket_id = generate_ticket_id()
    now = datetime.now(timezone.utc).isoformat()

    doc = {
        "ticket_id": ticket_id,
        "title": payload.title,
        "description": payload.description,
        "category": payload.category or classification["category"],
        "issue_type": classification["issue_type"],
        "priority": classification["priority"],
        "department": classification["department"],
        "summary": classification["summary"],
        "status": "Submitted",
        "location": payload.location,
        "image": payload.image,
        "created_at": now,
        "updated_at": now,
        "ai_status": ai_status,
    }

    col.insert_one(doc)
    return _doc_to_response(doc)


@router.get("/grievances")
def list_grievances(
    status: Optional[str] = Query(None),
    department: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    priority: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
):
    """List grievances with optional filters."""
    try:
        col = get_collection("grievances")
    except Exception:
        raise HTTPException(status_code=503, detail="Database unavailable")

    query = {}
    if status:
        query["status"] = status
    if department:
        query["department"] = department
    if category:
        query["category"] = category
    if priority:
        query["priority"] = priority

    cursor = col.find(query).sort("created_at", -1).skip(skip).limit(limit)
    total = col.count_documents(query)
    docs = [_doc_to_response(d) for d in cursor]
    return {"grievances": docs, "total": total}


@router.get("/grievances/{ticket_id}", response_model=GrievanceResponse)
def get_grievance(ticket_id: str):
    """Get a single grievance by ticket ID."""
    try:
        col = get_collection("grievances")
    except Exception:
        raise HTTPException(status_code=503, detail="Database unavailable")

    doc = col.find_one({"ticket_id": ticket_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Complaint not found")
    return _doc_to_response(doc)


@router.put("/grievances/{ticket_id}/status")
def update_status(ticket_id: str, payload: StatusUpdate):
    """Update grievance status."""
    try:
        col = get_collection("grievances")
    except Exception:
        raise HTTPException(status_code=503, detail="Database unavailable")

    now = datetime.now(timezone.utc).isoformat()
    result = col.update_one(
        {"ticket_id": ticket_id},
        {"$set": {"status": payload.status, "updated_at": now}},
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Complaint not found")
    return {"message": "Status updated", "status": payload.status}


@router.put("/grievances/{ticket_id}/department")
def update_department(ticket_id: str, payload: DepartmentUpdate):
    """Update grievance department."""
    try:
        col = get_collection("grievances")
    except Exception:
        raise HTTPException(status_code=503, detail="Database unavailable")

    now = datetime.now(timezone.utc).isoformat()
    result = col.update_one(
        {"ticket_id": ticket_id},
        {"$set": {"department": payload.department, "updated_at": now}},
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Complaint not found")
    return {"message": "Department updated", "department": payload.department}
