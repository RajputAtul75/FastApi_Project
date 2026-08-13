from fastapi import APIRouter, Depends
from app.database.connection import get_db

router = APIRouter()

@router.get("/health")
def health_check(db=Depends(get_db)):
    try:
        # Check connection
        db.command("ping")
        return {"status": "ok", "db": "connected"}
    except Exception as e:
        return {"status": "error", "db": "disconnected", "detail": str(e)}
