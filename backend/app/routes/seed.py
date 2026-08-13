"""Seed data route for demo purposes."""
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter
from app.database.connection import get_collection
from app.utils.helpers import generate_ticket_id

router = APIRouter(prefix="/api", tags=["seed"])

SEED_DATA = [
    {
        "title": "Large pothole near college entrance",
        "description": "There is a large pothole near the college main gate that is dangerous for vehicles and has caused multiple accidents. Immediate repair needed.",
        "category": "Road & Infrastructure",
        "issue_type": "Pothole",
        "priority": "High",
        "department": "Municipal Corporation",
        "summary": "Dangerous pothole near college entrance causing accidents",
        "status": "Submitted",
        "location": "College Main Gate, Sector 15",
    },
    {
        "title": "Streetlight failure on MG Road",
        "description": "Multiple streetlights have been non-functional on MG Road for the past two weeks. The area becomes very dark at night, creating safety concerns for pedestrians.",
        "category": "Electricity",
        "issue_type": "Streetlight Failure",
        "priority": "Medium",
        "department": "Electricity Department",
        "summary": "Multiple streetlights not working on MG Road for 2 weeks",
        "status": "Assigned",
        "location": "MG Road, Block A-C",
    },
    {
        "title": "Garbage accumulation in residential area",
        "description": "Garbage has been piling up at the corner of Green Park Colony for over a week. The waste collection truck has not visited. It is attracting stray animals and causing bad odor.",
        "category": "Waste Management",
        "issue_type": "Garbage Accumulation",
        "priority": "High",
        "department": "Sanitation Department",
        "summary": "Week-long garbage pile-up in Green Park Colony",
        "status": "In Progress",
        "location": "Green Park Colony, Corner Plot",
    },
    {
        "title": "Water pipeline leakage near market",
        "description": "A major water pipeline is leaking near the central market area. Water is flowing on the road and causing waterlogging. This has been going on for 3 days.",
        "category": "Water Supply",
        "issue_type": "Water Leakage",
        "priority": "Critical",
        "department": "Water Department",
        "summary": "Major water pipeline leak near central market for 3 days",
        "status": "Submitted",
        "location": "Central Market, Main Road",
    },
    {
        "title": "Drainage blockage causing flooding",
        "description": "The main drainage channel near Laxmi Nagar is completely blocked. During recent rains, the entire area was flooded. Residents are unable to commute.",
        "category": "Road & Infrastructure",
        "issue_type": "Drainage Blockage",
        "priority": "Critical",
        "department": "Municipal Corporation",
        "summary": "Blocked drainage causing flooding in Laxmi Nagar during rains",
        "status": "Assigned",
        "location": "Laxmi Nagar, Main Drain",
    },
    {
        "title": "Electricity outage in Ward 12",
        "description": "Ward 12 has been experiencing frequent power outages lasting 4-6 hours daily. The transformer appears to be overloaded. Residents and small businesses are severely affected.",
        "category": "Electricity",
        "issue_type": "Power Outage",
        "priority": "High",
        "department": "Electricity Department",
        "summary": "Frequent 4-6 hour power outages in Ward 12 due to overloaded transformer",
        "status": "In Progress",
        "location": "Ward 12, Transformer Station",
    },
    {
        "title": "Damaged road surface on NH-48",
        "description": "A 200-meter stretch of NH-48 near the toll plaza has severely damaged road surface with deep cracks and potholes. Heavy vehicles are at risk of accidents.",
        "category": "Road & Infrastructure",
        "issue_type": "Damaged Road",
        "priority": "High",
        "department": "Municipal Corporation",
        "summary": "200m stretch of severely damaged road on NH-48 near toll plaza",
        "status": "Resolved",
        "location": "NH-48, Near Toll Plaza",
    },
    {
        "title": "Public toilet in unhygienic condition",
        "description": "The public toilet facility near the bus stand is in extremely unhygienic condition. No water supply, broken doors, and no cleaning has been done for weeks.",
        "category": "Sanitation",
        "issue_type": "Public Sanitation",
        "priority": "Medium",
        "department": "Sanitation Department",
        "summary": "Unhygienic public toilet near bus stand with no water and broken doors",
        "status": "Submitted",
        "location": "Central Bus Stand",
    },
]


@router.post("/seed")
def seed_data():
    """Insert demo grievances for testing. Safe to call multiple times."""
    col = get_collection("grievances")
    inserted = []
    now = datetime.now(timezone.utc)

    for i, item in enumerate(SEED_DATA):
        ticket_id = generate_ticket_id()
        created = (now - timedelta(days=len(SEED_DATA) - i, hours=i * 3)).isoformat()

        doc = {
            "ticket_id": ticket_id,
            **item,
            "image": None,
            "created_at": created,
            "updated_at": created,
            "ai_status": "seed",
        }
        col.insert_one(doc)
        inserted.append(ticket_id)

    return {
        "message": f"Seeded {len(inserted)} demo grievances",
        "ticket_ids": inserted,
    }
