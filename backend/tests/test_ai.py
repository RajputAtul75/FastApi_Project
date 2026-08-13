import asyncio
import os
import sys
from dotenv import load_dotenv
load_dotenv()

from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import async_session
from app.services.categorizer import TransactionCategorizer
from app.services.rag import RAGPipeline

async def test_categorizer():
    print("Testing Categorizer...")
    async with async_session() as session:
        categorizer = TransactionCategorizer(session)
        await categorizer.run()
        print("Categorizer finished running.")

async def test_rag():
    print("Testing RAG Embedding...")
    async with async_session() as session:
        rag = RAGPipeline(session)
        await rag.embed_transactions()
        print("RAG embedding finished.")
        
        print("Testing RAG Search...")
        # Assume user_id = 1 for test
        results = await rag.search_relevant_transactions("food", user_id=1, top_k=5)
        print(f"RAG Search Results: {results}")

async def main():
    if not os.getenv("GEMINI_API_KEY") or os.getenv("GEMINI_API_KEY") == "YOUR_GEMINI_KEY":
        print("WARNING: Valid GEMINI_API_KEY is required to actually call Gemini.")
        
    await test_categorizer()
    await test_rag()

if __name__ == "__main__":
    asyncio.run(main())