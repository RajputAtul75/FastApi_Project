import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

from app.database.connection import init_db
from app.routes import health, grievance_routes, upload_routes, dashboard_routes, seed_routes

# Initialize DB (indexes)
init_db()

app = FastAPI(title="NyayaAI Backend API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router, prefix="/api")
app.include_router(grievance_routes.router, prefix="/api")
app.include_router(upload_routes.router, prefix="/api")
app.include_router(dashboard_routes.router, prefix="/api")
app.include_router(seed_routes.router, prefix="/api")
