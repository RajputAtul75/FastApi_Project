import json
import logging
import time
import google.generativeai as genai
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any

from app.models.transaction import Transaction
from app.config import settings

logger = logging.getLogger(__name__)

# Initialize GenAI
if settings.GEMINI_API_KEY:
    genai.configure(api_key=settings.GEMINI_API_KEY)

# Rule Engine basics
RULE_ENGINE_CATEGORIES = {
    "swiggy": "Food", 
    "zomato": "Food", 
    "uber": "Travel", 
    "ola": "Travel", 
    "netflix": "Entertainment", 
    "amazon": "Shopping", 
    "hdfc emi": "EMI", 
    "electricity": "Utilities", 
    "pharmacy": "Health"
}

from google.generativeai.types import HarmCategory, HarmBlockThreshold

async def categorize_transactions(db: AsyncSession):
    # Rule engine first
    uncategorized = await db.execute(select(Transaction).where(Transaction.category == None).limit(50))
    transactions = uncategorized.scalars().all()
    
    if not transactions:
        return 0

    to_llm = []
    updated_count = 0
    
    for txn in transactions:
        desc_lower = (txn.description or "").lower()
        matched = False
        for key, category in RULE_ENGINE_CATEGORIES.items():
            if key in desc_lower:
                txn.category = category
                updated_count += 1
                matched = True
                break
        if not matched:
            to_llm.append({"id": str(txn.id), "description": txn.description, "amount": float(txn.amount)})

    if to_llm and settings.GEMINI_API_KEY:
        try:
            model = genai.GenerativeModel('gemini-1.5-pro')
            prompt = (
                "Categorize into: Food/Travel/Shopping/EMI/Utilities/Entertainment/Health/Investment/Other. "
                "Return exactly a JSON array block like: [{\"id\": \"uuid\", \"category\": \"Category\"}]\n\n"
                f"Transactions: {json.dumps(to_llm)}"
            )
            response = model.generate_content(prompt)
            raw_text = response.text
            # Extract JSON from potential markdown block
            if "```" in raw_text:
                json_str = raw_text.split("```")[1]
                if json_str.startswith("json"):
                    json_str = json_str[4:]
            else:
                json_str = raw_text
            
            cats = json.loads(json_str.strip())
            
            cat_map = {item['id']: item['category'] for item in cats}
            
            for txn in transactions:
                if str(txn.id) in cat_map:
                    txn.category = cat_map[str(txn.id)]
                    updated_count += 1
        except Exception as e:
            logger.error(f"LLM Categorization failed: {e}")
            
    await db.commit()
    return updated_count
    "uber": "Travel",
    "ola": "Travel",
    "netflix": "Entertainment",
    "amazon": "Shopping",
    "hdfc emi": "EMI",
    "electricity": "Utilities",
    "pharmacy": "Health"
}

ALLOWED_CATEGORIES = [
    "Food", "Travel", "Shopping", "EMI", "Utilities", 
    "Entertainment", "Health", "Investment", "Other"
]

class TransactionCategorizer:
    def __init__(self, db: AsyncSession):
        self.db = db
        # We will use gemini-1.5-pro, typical general text model
        self.model = genai.GenerativeModel("gemini-1.5-pro")

    async def run(self):
        """
        Fetches uncategorized transactions, categorizes via Rule Engine first,
        then batches the rest to LLM, and updates the database.
        """
        # Fetch uncategorized transactions
        stmt = select(Transaction).where(
            (Transaction.category == None) | (Transaction.category == "")
        )
        result = await self.db.execute(stmt)
        transactions = result.scalars().all()

        if not transactions:
            logger.info("No uncategorized transactions found.")
            return

        logger.info(f"Found {len(transactions)} uncategorized transactions.")

        llm_batch = []
        updates: list[dict[str, Any]] = []

        # 1. Rule Engine Pass
        for tx in transactions:
            merchant_lower = tx.merchant_name.lower()
            matched = False
            for keyword, category in RULE_ENGINE_CATEGORIES.items():
                if keyword in merchant_lower:
                    updates.append({"id": tx.id, "category": category})
                    matched = True
                    break
            
            if not matched:
                llm_batch.append(tx)

        # Apply Rule Engine updates
        if updates:
            await self._bulk_update_categories(updates)

        # 2. LLM Batch Pass
        if llm_batch and settings.GEMINI_API_KEY:
            # Batch in chunks of 50
            batch_size = 50
            for i in range(0, len(llm_batch), batch_size):
                chunk = llm_batch[i:i + batch_size]
                await self._categorize_with_llm(chunk)
                
    async def _categorize_with_llm(self, tx_list: list[Transaction]):
        tx_data = [{"id": tx.id, "merchant": tx.merchant_name, "amount": tx.amount, "is_debit": tx.is_debit} for tx in tx_list]
        
        prompt = f"""
        Categorize the following bank transactions into exactly one of these categories:
        {", ".join(ALLOWED_CATEGORIES)}

        Respond with valid JSON only. The JSON must be an array of objects, where each object has:
        - "id": The integer ID of the transaction.
        - "category": The assigned category string.

        Transactions:
        {json.dumps(tx_data, indent=2)}
        """

        try:
            response = await self.model.generate_content_async(
                prompt,
                generation_config=genai.types.GenerationConfig(response_mime_type="application/json")
            )
            data = json.loads(response.text)
            
            updates = []
            for item in data:
                cat = item.get("category", "Other")
                if cat not in ALLOWED_CATEGORIES:
                    cat = "Other"
                updates.append({"id": item.get("id"), "category": cat})

            if updates:
                await self._bulk_update_categories(updates)
                
        except Exception as e:
            logger.error(f"Error calling LLM categorization: {e}")

    async def _bulk_update_categories(self, updates: list[dict[str, Any]]):
        """Execute a bulk update using bulk-save mapping."""
        # Simple loops for local iteration update since SQLite doesn't strictly need advanced bulk updates for small lists.
        # But we could do an executemany update.
        for u in updates:
            stmt = select(Transaction).where(Transaction.id == u["id"])
            res = await self.db.execute(stmt)
            tx = res.scalar_one_or_none()
            if tx:
                tx.category = u["category"]
        await self.db.commit()
