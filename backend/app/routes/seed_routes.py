from fastapi import APIRouter, Depends
from typing import Dict
from datetime import datetime, timezone
import random

from app.database.connection import get_db

router = APIRouter(prefix="/seed", tags=["seed"])

@router.post("")
def seed_data(db=Depends(get_db)):
    collection = db["grievances"]
    
    # Check if there is already data to prevent duplicate seeding
    if collection.find_one():
        return {"message": "Data already seeded"}
        
    now = datetime.now(timezone.utc).isoformat()
    dummy_grievances = [
        {
            "ticket_id": f"GRV-2026-{random.randint(1000, 9999)}",
            "title": "Pothole on Main Street",
            "description": "There is a large pothole near the central park entrance causing traffic issues.",
            "category": "Road & Infrastructure",
            "issue_type": "Pothole",
            "priority": "High",
            "department": "Municipal Corporation",
            "summary": "Large pothole causing traffic issues.",
            "status": "Submitted",
            "location": "Main Street, near Central Park",
            "image": None,
            "created_at": now,
            "updated_at": now
        },
        {
            "ticket_id": f"GRV-2026-{random.randint(1000, 9999)}",
            "title": "Water Supply Issue",
            "description": "No water supply for the last 2 days in Sector 4.",
            "category": "Water Supply",
            "issue_type": "No Water",
            "priority": "Critical",
            "department": "Water Department",
            "summary": "No water in Sector 4 for 2 days.",
            "status": "In Progress",
            "location": "Sector 4",
            "image": None,
            "created_at": now,
            "updated_at": now
        },
        {
            "ticket_id": f"GRV-2026-{random.randint(1000, 9999)}",
            "title": "Street Light Not Working",
            "description": "Street light pole no. 45 is broken and street is very dark at night.",
            "category": "Electricity",
            "issue_type": "Broken Light",
            "priority": "Low",
            "department": "Electricity Department",
            "summary": "Broken street light pole 45.",
            "status": "Resolved",
            "location": "Oak Avenue",
            "image": None,
            "created_at": now,
            "updated_at": now
        },
        {
            "ticket_id": f"GRV-2026-{random.randint(1000, 9999)}",
            "title": "Garbage Accumulation",
            "description": "Garbage has not been collected for a week outside the market.",
            "category": "Waste Management",
            "issue_type": "No Collection",
            "priority": "Medium",
            "department": "Sanitation Department",
            "summary": "Garbage uncollected for a week.",
            "status": "Assigned",
            "location": "City Market",
            "image": None,
            "created_at": now,
            "updated_at": now
        }
    ]
    
    collection.insert_many(dummy_grievances)
        
    return {"message": "Seed data created successfully"}

