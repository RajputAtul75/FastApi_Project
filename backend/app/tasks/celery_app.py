from __future__ import annotations

import asyncio
import os
from celery import Celery

from app.config import settings
from app.services.parser import parse_statement
from app.models.transaction import Transaction
from app.core.database import async_session


celery = Celery("fincopilot", broker=settings.REDIS_URL)


@celery.task(bind=True)
def parse_statement_task(self, file_path: str, filename: str, user_id: int):
    """Celery task: parse a saved statement file and insert transactions into DB."""
    if not os.path.exists(file_path):
        return {"error": "file not found"}

    with open(file_path, "rb") as f:
        file_bytes = f.read()

    parsed = parse_statement(file_bytes, filename)

    async def _insert():
        async with async_session() as db:
            for tx in parsed:
                db_tx = Transaction(
                    user_id=user_id,
                    merchant_name=tx["merchant_name"],
                    amount=tx["amount"],
                    date=__import__("datetime").date.fromisoformat(tx["date"]),
                    raw_description=tx.get("merchant_name"),
                    is_debit=tx["is_debit"],
                )
                db.add(db_tx)
            await db.commit()

    # Run the async insertion in an event loop
    asyncio.run(_insert())

    return {"parsed": len(parsed)}
