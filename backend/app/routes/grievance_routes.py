from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from datetime import datetime, timezone
import random

from app.database.connection import get_db
from app.schemas.grievance import (
    GrievanceCreate, 
    GrievanceResponse, 
    StatusUpdate, 
    DepartmentUpdate
)
from app.services.ai_service import analyze_grievance

router = APIRouter(prefix="/grievances", tags=["grievances"])

def generate_ticket_id(db):
    # Generates a simple ticket ID: GRV-2026-XXXX
    # In a real app, use an atomic counter. For MVP, random 4 digits is okay, but let's make it robust by checking existence.
    while True:
        num = random.randint(1000, 9999)
        ticket_id = f"GRV-2026-{num}"
        if not db["grievances"].find_one({"ticket_id": ticket_id}):
            return ticket_id

@router.post("", response_model=GrievanceResponse)
def create_grievance(grievance: GrievanceCreate, db=Depends(get_db)):
    collection = db["grievances"]
    
    # 1. Analyze with AI
    ai_result = analyze_grievance(grievance.description)
    
    # 2. Generate Ticket ID
    ticket_id = generate_ticket_id(db)
    
    # 3. Construct Document
    now = datetime.now(timezone.utc).isoformat()
    doc = {
        "ticket_id": ticket_id,
        "title": grievance.title,
        "description": grievance.description,
        "category": ai_result.get("category", grievance.category or "Other"),
        "issue_type": ai_result.get("issue_type", "General"),
        "priority": ai_result.get("priority", "Medium"),
        "department": ai_result.get("department", "Unassigned"),
        "summary": ai_result.get("summary", ""),
        "status": "Submitted",
        "location": grievance.location,
        "image": grievance.image,
        "created_at": now,
        "updated_at": now
    }
    
    # 4. Insert
    collection.insert_one(doc)
    
    # Return doc (excluding MongoDB _id)
    doc.pop("_id", None)
    return doc

@router.get("", response_model=List[GrievanceResponse])
def get_grievances(
    skip: int = 0, 
    limit: int = 50, 
    status: Optional[str] = None,
    department: Optional[str] = None,
    category: Optional[str] = None,
    priority: Optional[str] = None,
    db=Depends(get_db)
):
    collection = db["grievances"]
    query = {}
    if status:
        query["status"] = status
    if department:
        query["department"] = department
    if category:
        query["category"] = category
    if priority:
        query["priority"] = priority
        
    cursor = collection.find(query, {"_id": 0}).skip(skip).limit(limit).sort("created_at", -1)
    return list(cursor)

@router.get("/{ticket_id}", response_model=GrievanceResponse)
def get_grievance(ticket_id: str, db=Depends(get_db)):
    doc = db["grievances"].find_one({"ticket_id": ticket_id}, {"_id": 0})
    if not doc:
        raise HTTPException(status_code=404, detail="Grievance not found")
    return doc

@router.put("/{ticket_id}/status", response_model=GrievanceResponse)
def update_status(ticket_id: str, status_update: StatusUpdate, db=Depends(get_db)):
    collection = db["grievances"]
    now = datetime.now(timezone.utc).isoformat()
    
    result = collection.find_one_and_update(
        {"ticket_id": ticket_id},
        {"$set": {"status": status_update.status, "updated_at": now}},
        projection={"_id": 0},
        return_document=True
    )
    if not result:
        raise HTTPException(status_code=404, detail="Grievance not found")
    return result

@router.put("/{ticket_id}/department", response_model=GrievanceResponse)
def update_department(ticket_id: str, dept_update: DepartmentUpdate, db=Depends(get_db)):
    collection = db["grievances"]
    now = datetime.now(timezone.utc).isoformat()
    
    result = collection.find_one_and_update(
        {"ticket_id": ticket_id},
        {"$set": {"department": dept_update.department, "updated_at": now}},
        projection={"_id": 0},
        return_document=True
    )
    if not result:
        raise HTTPException(status_code=404, detail="Grievance not found")
    return result
