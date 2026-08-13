"""Utility functions for NyayaAI backend."""
from datetime import datetime
from app.database.connection import get_collection


def generate_ticket_id() -> str:
    """Generate a unique ticket ID in format GRV-YYYY-XXXX."""
    year = datetime.now().year
    col = get_collection("counters")

    result = col.find_one_and_update(
        {"_id": f"ticket_{year}"},
        {"$inc": {"seq": 1}},
        upsert=True,
        return_document=True,
    )
    seq = result["seq"]
    return f"GRV-{year}-{seq:04d}"
