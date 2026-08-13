"""
Statement upload endpoint – JWT-secured.

Uploads a CSV/PDF bank statement, parses it synchronously
(Celery fallback when Redis is unavailable), categorises transactions,
and inserts them into the DB for the authenticated user.
"""

import os
import uuid
from datetime import date as date_type

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.transaction import Transaction
from app.services.parser import parse_statement

router = APIRouter()


class UploadResponse(BaseModel):
    task_id: str
    transactions_parsed: int
    message: str


@router.post("/statement", response_model=UploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_statement(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Upload a bank statement (CSV or PDF).
    Parses it and inserts transactions for the authenticated user.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")

    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in (".csv", ".pdf"):
        raise HTTPException(status_code=400, detail="Only .csv and .pdf files are supported")

    # Save uploaded file
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    save_name = f"{uuid.uuid4()}{ext}"
    save_path = os.path.join(settings.UPLOAD_DIR, save_name)
    file_bytes = await file.read()
    with open(save_path, "wb") as f:
        f.write(file_bytes)

    # Try Celery first, fall back to synchronous parsing
    try:
        from app.tasks.celery_app import parse_statement_task
        async_result = parse_statement_task.delay(save_path, file.filename, current_user.id)
        task_id = str(async_result.id)
        return UploadResponse(
            task_id=task_id,
            transactions_parsed=0,
            message=f"Enqueued parsing task {task_id} for {file.filename}",
        )
    except Exception:
        # Synchronous fallback
        try:
            parsed = parse_statement(file_bytes, file.filename)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

        for tx in parsed:
            db_tx = Transaction(
                user_id=current_user.id,
                merchant_name=tx["merchant_name"],
                amount=tx["amount"],
                date=date_type.fromisoformat(tx["date"]),
                raw_description=tx.get("merchant_name"),
                is_debit=tx["is_debit"],
            )
            db.add(db_tx)

        task_id = str(uuid.uuid4())

        return UploadResponse(
            task_id=task_id,
            transactions_parsed=len(parsed),
            message=f"Parsed {len(parsed)} transactions from {file.filename}",
        )
