import json
import logging
from typing import AsyncGenerator

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from pydantic import BaseModel

import google.generativeai as genai

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.transaction import Transaction
from app.models.chat_message import ChatMessage
from app.services.rag import RAGPipeline
from app.config import settings

router = APIRouter()
logger = logging.getLogger(__name__)

class ChatRequest(BaseModel):
    message: str

@router.post("/stream")
async def chat_stream(
    request: ChatRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    rag = RAGPipeline(db)
    
    # 1. Save user message
    user_msg = ChatMessage(user_id=user.id, role="user", content=request.message)
    db.add(user_msg)
    await db.commit()

    async def event_stream() -> AsyncGenerator[str, None]:
        # 2. Get RAG context
        context_txns = await rag.search_relevant_transactions(request.message, str(user.id))
        context_str = rag.build_context_string(context_txns)
        
        # 3. Build prompt
        system_prompt = (
            "You are FinCopilot, an expert AI financial advisor.\n"
            "Use the following transaction history to answer the user's question.\n"
            "Be concise, helpful, and format with markdown.\n\n"
            f"### Relevant Transactions Data:\n{context_str}\n"
        )
        
        full_prompt = f"{system_prompt}\nUser Question: {request.message}"
        
        model = genai.GenerativeModel('gemini-1.5-pro')
        response = model.generate_content(full_prompt, stream=True)
        
        full_response = ""
        for chunk in response:
            if chunk.text:
                full_response += chunk.text
                yield f"data: {json.dumps({'chunk': chunk.text})}\n\n"
                
        # Save assistant message
        ai_msg = ChatMessage(user_id=user.id, role="assistant", content=full_response)
        db.add(ai_msg)
        await db.commit()
        
        yield "data: [DONE]\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")

logger = logging.getLogger(__name__)

router = APIRouter()

class ChatRequest(BaseModel):
    message: str

@router.post("/stream")
async def chat_stream(
    request: ChatRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not settings.GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured.")

    # genai must be initialized
    genai.configure(api_key=settings.GEMINI_API_KEY)

    # Save user message
    user_msg = ChatMessage(user_id=current_user.id, role="user", content=request.message)
    db.add(user_msg)
    await db.commit()

    async def event_generator() -> AsyncGenerator[str, None]:
        # 1. RAG Context
        rag = RAGPipeline(db, settings.QDRANT_URL)
        # 2. Monthly Summary Context
        monthly_summary = await _get_monthly_summary(db, current_user.id)
        
        try:
            results = await rag.search_relevant_transactions(request.message, current_user.id, top_k=20)
            rag_context = rag.build_context_string(results)
        except Exception as e:
            logger.error(f"RAG search failed: {e}")
            rag_context = "No detailed RAG context could be retrieved."

        # 3. Build System Prompt
        system_prompt = f"""
        You are FinCopilot, a helpful financial AI assistant. 
        Use the following information to answer the user's question.

        User's Monthly Summary:
        {monthly_summary}

        Relevant Transactions (RAG output):
        {rag_context}
        """

        model = genai.GenerativeModel('gemini-1.5-pro', system_instruction=system_prompt)
        
        full_response = []
        try:
            response = await model.generate_content_async(request.message, stream=True)
            async for chunk in response:
                token = chunk.text
                if token:
                    full_response.append(token)
                    yield f"data: {token}\\n\\n"
        except Exception as e:
            logger.error(f"Gemini Streaming Error: {e}")
            yield f"data: Error: {str(e)}\\n\\n"

        # After streaming, save to DB
        assistant_msg = ChatMessage(user_id=current_user.id, role="model", content="".join(full_response))
        db.add(assistant_msg)
        await db.commit()

    return StreamingResponse(event_generator(), media_type="text/event-stream")

async def _get_monthly_summary(db: AsyncSession, user_id: int) -> str:
    """Generate a quick string summarising the user's spending."""
    stmt = select(
        Transaction.category,
        func.sum(Transaction.amount).label("total")
    ).where(
        Transaction.user_id == user_id,
        Transaction.is_debit == True,
        Transaction.category != None
    ).group_by(Transaction.category)
    
    result = await db.execute(stmt)
    summary_data = result.all()
    
    if not summary_data:
        return "No spending recorded this month."
        
    summary_lines = [f"- {cat}: {amt:.2f}" for cat, amt in summary_data if cat]
    return "Total Spending by Category:\n" + "\n".join(summary_lines)
