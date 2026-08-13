from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.core.database import init_db

# Import models so Base.metadata knows about them
import app.models  # noqa: F401

from app.routers import auth, transactions, upload, chat, goals, dashboard, budgets


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create DB tables on startup (dev convenience)."""
    await init_db()
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

# CORS — allow the Flutter web frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(transactions.router, prefix="/api/v1/transactions", tags=["transactions"])
app.include_router(upload.router, prefix="/api/v1/upload", tags=["upload"])
app.include_router(chat.router, prefix="/api/v1/chat", tags=["chat"])
app.include_router(goals.router, prefix="/api/v1/goals", tags=["goals"])
app.include_router(dashboard.router, prefix="/api/v1/dashboard", tags=["dashboard"])
app.include_router(budgets.router, prefix="/api/v1/budgets", tags=["budgets"])


@app.get("/")
def root():
    return {"message": "Welcome to FinCopilot API"}
