"""NyayaAI Backend - Database connection module."""
import os
from pymongo import MongoClient, ASCENDING, DESCENDING
from pymongo.errors import ConnectionFailure


_client = None
_db = None


def get_database():
    """Get the MongoDB database instance, creating connection if needed."""
    global _client, _db
    if _db is not None:
        return _db

    uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    db_name = os.getenv("MONGODB_DATABASE", "nyayaai")

    _client = MongoClient(uri, serverSelectionTimeoutMS=5000)
    _db = _client[db_name]
    return _db


def get_collection(name: str = "grievances"):
    """Get a MongoDB collection by name."""
    db = get_database()
    return db[name]


def check_connection() -> bool:
    """Check if MongoDB is reachable."""
    try:
        db = get_database()
        db.command("ping")
        return True
    except Exception:
        return False


def ensure_indexes():
    """Create required indexes on the grievances collection."""
    try:
        col = get_collection("grievances")
        col.create_index([("ticket_id", ASCENDING)], unique=True)
        col.create_index([("status", ASCENDING)])
        col.create_index([("department", ASCENDING)])
        col.create_index([("category", ASCENDING)])
        col.create_index([("created_at", DESCENDING)])
        print("[+] MongoDB indexes ensured.")
    except Exception as e:
        print(f"[!] Could not create indexes: {e}")
