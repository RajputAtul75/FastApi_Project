from fastapi import APIRouter, Depends
from app.database.connection import get_db

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

@router.get("/stats")
def get_dashboard_stats(db=Depends(get_db)):
    collection = db["grievances"]
    
    total = collection.count_documents({})
    pending = collection.count_documents({"status": "Submitted"})
    in_progress = collection.count_documents({"status": "In Progress"})
    resolved = collection.count_documents({"status": "Resolved"})
    
    # Example for charts (fl_chart) - group by category
    category_pipeline = [{"$group": {"_id": "$category", "count": {"$sum": 1}}}]
    category_counts = list(collection.aggregate(category_pipeline))
    categories = {item["_id"]: item["count"] for item in category_counts if item["_id"]}

    department_pipeline = [{"$group": {"_id": "$department", "count": {"$sum": 1}}}]
    dept_counts = list(collection.aggregate(department_pipeline))
    departments = {item["_id"]: item["count"] for item in dept_counts if item["_id"]}

    priority_pipeline = [{"$group": {"_id": "$priority", "count": {"$sum": 1}}}]
    priority_counts = list(collection.aggregate(priority_pipeline))
    priorities = {item["_id"]: item["count"] for item in priority_counts if item["_id"]}
    
    return {
        "total": total,
        "pending": pending,
        "in_progress": in_progress,
        "resolved": resolved,
        "by_category": categories,
        "by_department": departments,
        "by_priority": priorities
    }

