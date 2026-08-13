import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
MONGODB_DATABASE = os.getenv("MONGODB_DATABASE", "nyayaai")

client = MongoClient(MONGODB_URI)
db = client[MONGODB_DATABASE]

# Create indexes on startup
def init_db():
    collection = db["grievances"]
    collection.create_index("ticket_id", unique=True)
    collection.create_index("status")
    collection.create_index("department")
    collection.create_index("category")
    collection.create_index("created_at")

def get_db():
    return db