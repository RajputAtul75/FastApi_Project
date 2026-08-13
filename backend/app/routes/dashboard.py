"""Dashboard stats and health routes."""
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException
from app.database.connection import get_collection, check_connection

router = APIRouter(prefix="/api", tags=["dashboard"])


@router.get("/health")
def health():
    """Health check endpoint."""
    db_ok = check_connection()
    return {
        "status": "ok" if db_ok else "degraded",
        "database": "connected" if db_ok else "unavailable",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/dashboard/stats")
def dashboard_stats():
    """Get dashboard statistics."""
    try:
        col = get_collection("grievances")
    except Exception:
        raise HTTPException(status_code=503, detail="Database unavailable")

    total = col.count_documents({})

    def _count_by(field: str) -> dict:
        pipeline = [
            {"$group": {"_id": f"${field}", "count": {"$sum": 1}}},
            {"$sort": {"count": -1}},
        ]
        return {doc["_id"]: doc["count"] for doc in col.aggregate(pipeline) if doc["_id"]}

    return {
        "total": total,
        "by_status": _count_by("status"),
        "by_priority": _count_by("priority"),
        "by_category": _count_by("category"),
        "by_department": _count_by("department"),
    }
