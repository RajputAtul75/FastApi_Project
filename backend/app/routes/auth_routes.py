from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os

router = APIRouter(prefix="/auth", tags=["auth"])

class LoginRequest(BaseModel):
    username: str
    password: str

@router.post("/login")
def admin_login(credentials: LoginRequest):
    """Validate admin credentials against environment variables."""
    admin_user = os.getenv("ADMIN_USERNAME", "admin")
    admin_pass = os.getenv("ADMIN_PASSWORD", "admin123")

    if credentials.username == admin_user and credentials.password == admin_pass:
        return {"success": True, "message": "Login successful", "role": "admin"}
    
    raise HTTPException(status_code=401, detail="Invalid username or password")
