import logging
from typing import List, Dict, Any
import json
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct, Filter, FieldCondition, MatchValue
import google.generativeai as genai

from app.config import settings
from app.models.transaction import Transaction

logger = logging.getLogger(__name__)

if settings.GEMINI_API_KEY:
    genai.configure(api_key=settings.GEMINI_API_KEY)

class RAGPipeline:
    def __init__(self, db: AsyncSession, qdrant_url: str = settings.QDRANT_URL):
        self.db = db
        self.client = AsyncQdrantClient(url=qdrant_url) if qdrant_url else AsyncQdrantClient(":memory:")
        self.collection_name = "transactions"
        
    async def init_collection(self):
        try:
            await self.client.get_collection(self.collection_name)
        except Exception:
            await self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=VectorParams(size=768, distance=Distance.COSINE),
            )

    async def embed_transactions(self, transactions: List[Transaction]):
        await self.init_collection()
        points = []
        for txn in transactions:
            text = f"{txn.description} {float(txn.amount)} {txn.category or 'Uncategorized'} {txn.date}"
            emb = genai.embed_content(
                model="models/text-embedding-004",
                content=text
            )['embedding']
            
            points.append(
                PointStruct(
                    id=str(txn.id),
                    vector=emb,
                    payload={
                        "user_id": str(txn.user_id),
                        "description": txn.description,
                        "amount": float(txn.amount),
                        "category": txn.category,
                        "date": str(txn.date)
                    }
                )
            )
        
        if points:
            await self.client.upsert(
                collection_name=self.collection_name,
                points=points
            )

    async def search_relevant_transactions(self, query: str, user_id: str, top_k: int = 20) -> List[Dict[str, Any]]:
        await self.init_collection()
        emb = genai.embed_content(
            model="models/text-embedding-004",
            content=query
        )['embedding']
        
        results = await self.client.search(
            collection_name=self.collection_name,
            query_vector=emb,
            query_filter=Filter(
                must=[FieldCondition(key="user_id", match=MatchValue(value=user_id))]
            ),
            limit=top_k
        )
        return [hit.payload for hit in results]

    def build_context_string(self, transactions: List[Dict[str, Any]]) -> str:
        if not transactions:
            return "No recent transactions found."
            
        lines = ["| Date | Description | Amount | Category |"]
        lines.append("|---|---|---|---|")
        for t in transactions:
            lines.append(f"| {t.get('date')} | {t.get('description')} | {t.get('amount')} | {t.get('category')} |")
        
        return "\n".join(lines)
        self.qdrant = AsyncQdrantClient(url=qdrant_url)
        self.collection_name = "transactions"
        self.embed_model = "models/embedding-004"

    async def init_collection(self):
        """Create the collection if it doesn't exist."""
        exists = await self.qdrant.collection_exists(self.collection_name)
        if not exists:
            await self.qdrant.create_collection(
                collection_name=self.collection_name,
                vectors_config=VectorParams(size=768, distance=Distance.COSINE),
            )
            logger.info(f"Qdrant collection '{self.collection_name}' created.")

    async def _embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Get embeddings for a list of texts from Gemini."""
        if not settings.GEMINI_API_KEY:
            logger.warning("No Gemini API key found for embedding generation.")
            return [[0.0] * 768] * len(texts)
        
        response = await genai.embed_content_async(
            model=self.embed_model,
            content=texts,
            task_type="retrieval_document"
        )
        # GenAI SDK returns embeddings list in `.embeddings` or list of floats
        # Usually it returns a dict with 'embedding' key per item
        return [emb["values"] for emb in response['embedding']] if isinstance(response, dict) and 'embedding' in response else [e for e in response.get('embedding', [])]
        # Wait, the v0.8.6 signature is generally: response['embedding'] which is a list of embeddings.
        # Actually `embed_content` returns a dictionary `{'embedding': [[v1,v2...], ...]}`

    async def embed_transactions(self):
        """Embed transactions that haven't been embedded yet."""
        await self.init_collection()

        stmt = select(Transaction).where(Transaction.category != None)
        result = await self.db.execute(stmt)
        transactions = result.scalars().all()

        if not transactions:
            logger.info("No categorizer transactions found to embed.")
            return

        logger.info(f"Embedding {len(transactions)} transactions.")

        # Batch embed
        batch_size = 100
        for i in range(0, len(transactions), batch_size):
            chunk = transactions[i:i + batch_size]
            
            # Format: "{merchant} {amount} {category} {date}"
            texts = [
                f"{tx.merchant_name} {'Debit' if tx.is_debit else 'Credit'} {tx.amount} {tx.category} {tx.date.strftime('%Y-%m-%d')}" 
                for tx in chunk
            ]

            try:
                response = await genai.embed_content_async(
                    model=self.embed_model,
                    content=texts,
                    task_type="retrieval_document"
                )
                
                # google-generativeai API might return a list of lists or dict
                if isinstance(response, dict) and 'embedding' in response:
                    embeddings = response['embedding']
                else:
                    embeddings = response
                
                points = []
                for tx, emb in zip(chunk, embeddings):
                    points.append(
                        PointStruct(
                            id=tx.id,
                            vector=emb,
                            payload={
                                "user_id": tx.user_id,
                                "merchant_name": tx.merchant_name,
                                "amount": tx.amount,
                                "category": tx.category,
                                "date": tx.date.strftime('%Y-%m-%d'),
                                "is_debit": tx.is_debit
                            }
                        )
                    )
                
                # Upsert into Qdrant
                await self.qdrant.upsert(
                    collection_name=self.collection_name,
                    points=points
                )
            except Exception as e:
                logger.error(f"Error embedding transaction chunk: {e}")

    async def search_relevant_transactions(self, query: str, user_id: int, top_k: int = 20) -> List[Dict[str, Any]]:
        """Search transactions relevant to query, filtered by user_id."""
        if not settings.GEMINI_API_KEY:
            return []
            
        try:
            embed_res = await genai.embed_content_async(
                model=self.embed_model,
                content=query,
                task_type="retrieval_query"
            )
            
            if isinstance(embed_res, dict) and 'embedding' in embed_res:
                query_vector = embed_res['embedding']
            else:
                query_vector = embed_res

            # Ensure it's a 1D array
            if isinstance(query_vector, list) and len(query_vector) > 0 and isinstance(query_vector[0], list):
                query_vector = query_vector[0]

            results = await self.qdrant.search(
                collection_name=self.collection_name,
                query_vector=query_vector,
                query_filter=Filter(
                    must=[
                        FieldCondition(
                            key="user_id",
                            match=MatchValue(value=user_id)
                        )
                    ]
                ),
                limit=top_k
            )

            return [res.payload for res in results if res.payload]
        except Exception as e:
            logger.error(f"Failed to search relevant transactions: {e}")
            return []

    def build_context_string(self, transactions: List[Dict[str, Any]]) -> str:
        """Format search results as a markdown table."""
        if not transactions:
            return "No relevant transactions found."
            
        markdown = "| Date | Merchant | Amount | Type | Category |\n"
        markdown += "|------|----------|--------|------|----------|\n"
        
        for tx in transactions:
            type_str = "Debit" if tx.get("is_debit") else "Credit"
            date_str = tx.get("date", "N/A")
            merchant = tx.get("merchant_name", "N/A")
            amount = tx.get("amount", 0.0)
            cat = tx.get("category", "N/A")
            markdown += f"| {date_str} | {merchant} | {amount:.2f} | {type_str} | {cat} |\n"
            
        return markdown
