"""NyayaAI Backend - FastAPI application entry point."""
import os
from dotenv import load_dotenv

# Load .env before anything else
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database.connection import ensure_indexes
from app.routes import grievances, dashboard, upload, seed

app = FastAPI(
    title="NyayaAI API",
    description="AI-powered citizen grievance management platform",
    version="1.0.0",
)

# CORS - permissive for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(grievances.router)
app.include_router(dashboard.router)
app.include_router(upload.router)
app.include_router(seed.router)


@app.on_event("startup")
def startup():
    """Run on application startup."""
    print("[*] NyayaAI Backend starting...")
    ensure_indexes()
    print("[+] NyayaAI Backend ready!")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
