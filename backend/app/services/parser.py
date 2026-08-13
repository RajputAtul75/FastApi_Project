"""
CSV / PDF bank-statement parser.

Supports auto-detection of columns for HDFC, SBI, Axis, ICICI CSV formats.
For PDFs it uses pdfplumber + regex to extract transaction rows.

Every format is normalised to:
    {date: str, merchant_name: str, amount: float, is_debit: bool}
"""

from __future__ import annotations

import io
import re
from datetime import datetime
from pathlib import Path
from typing import Any

import pandas as pd

# Column-name variations across Indian banks
DATE_COLS = ["date", "txn date", "transaction date", "value date", "posting date"]
DESC_COLS = [
    "description",
    "narration",
    "details",
    "particulars",
    "transaction details",
    "remarks",
]
DEBIT_COLS = ["debit", "withdrawal", "withdrawal amt", "debit amount", "dr"]
CREDIT_COLS = ["credit", "deposit", "deposit amt", "credit amount", "cr"]
AMOUNT_COLS = ["amount", "transaction amount", "txn amount"]


def _find_col(df: pd.DataFrame, candidates: list[str]) -> str | None:
    """Return the first column in *df* that matches one of *candidates* (case-insensitive)."""
    lower_map = {c.lower().strip(): c for c in df.columns}
    for candidate in candidates:
        if candidate in lower_map:
            return lower_map[candidate]
    return None


def _parse_date(val: Any) -> str:
    """Best-effort date parsing → ISO string."""
    if pd.isna(val):
        return datetime.today().strftime("%Y-%m-%d")
    for fmt in ("%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d", "%d/%m/%y", "%m/%d/%Y", "%d-%b-%Y", "%d %b %Y"):
        try:
            return datetime.strptime(str(val).strip(), fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    # Last resort – let pandas try
    try:
        return pd.to_datetime(str(val), dayfirst=True).strftime("%Y-%m-%d")
    except Exception:
        return datetime.today().strftime("%Y-%m-%d")


def parse_csv(file_bytes: bytes, filename: str = "") -> list[dict]:
    """Parse a bank CSV and return normalised transaction dicts."""
    # Try to read with common delimiters
    for sep in [",", "\t", "|"]:
        try:
            df = pd.read_csv(io.BytesIO(file_bytes), sep=sep, engine="python", on_bad_lines="skip")
            if len(df.columns) >= 3:
                break
        except Exception:
            continue
    else:
        return []

    # Strip whitespace from column names
    df.columns = [c.strip() for c in df.columns]

    date_col = _find_col(df, DATE_COLS)
    desc_col = _find_col(df, DESC_COLS)
    debit_col = _find_col(df, DEBIT_COLS)
    credit_col = _find_col(df, CREDIT_COLS)
    amount_col = _find_col(df, AMOUNT_COLS)

    transactions: list[dict] = []
    for _, row in df.iterrows():
        # Date
        raw_date = row[date_col] if date_col else None
        tx_date = _parse_date(raw_date)

        # Description / merchant
        merchant = str(row[desc_col]).strip() if desc_col and pd.notna(row[desc_col]) else "Unknown"

        # Amount & direction
        is_debit = True
        amount = 0.0
        if debit_col and credit_col:
            debit_val = row.get(debit_col)
            credit_val = row.get(credit_col)
            if pd.notna(debit_val) and _to_float(debit_val) > 0:
                amount = _to_float(debit_val)
                is_debit = True
            elif pd.notna(credit_val) and _to_float(credit_val) > 0:
                amount = _to_float(credit_val)
                is_debit = False
        elif amount_col:
            amount = _to_float(row[amount_col])
            is_debit = amount >= 0
            amount = abs(amount)

        if amount == 0:
            continue

        transactions.append(
            {
                "date": tx_date,
                "merchant_name": merchant[:500],
                "amount": round(amount, 2),
                "is_debit": is_debit,
            }
        )

    return transactions


def _to_float(val: Any) -> float:
    """Convert a value to float, stripping commas and currency symbols."""
    if isinstance(val, (int, float)):
        return float(val)
    try:
        cleaned = re.sub(r"[^\d.\-]", "", str(val))
        return float(cleaned) if cleaned else 0.0
    except (ValueError, TypeError):
        return 0.0


def parse_pdf(file_bytes: bytes, filename: str = "") -> list[dict]:
    """Extract transactions from a PDF bank statement using pdfplumber."""
    try:
        import pdfplumber
    except ImportError:
        return []

    transactions: list[dict] = []
    # Regex: date  description  debit/credit  amount
    # Matches patterns like: 01/04/2024  NEFT-SALARY  10,000.00
    row_pattern = re.compile(
        r"(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})\s+"  # date
        r"(.+?)\s+"  # description (non-greedy)
        r"([\d,]+\.\d{2})\s*"  # amount
        r"(Cr|Dr|CR|DR)?"  # optional Cr/Dr suffix
    )

    with pdfplumber.open(io.BytesIO(file_bytes)) as pdf:
        for page in pdf.pages:
            text = page.extract_text() or ""
            for line in text.split("\n"):
                m = row_pattern.search(line)
                if m:
                    tx_date = _parse_date(m.group(1))
                    merchant = m.group(2).strip()[:500]
                    amount = _to_float(m.group(3))
                    suffix = (m.group(4) or "").upper()
                    is_debit = suffix != "CR"

                    if amount > 0:
                        transactions.append(
                            {
                                "date": tx_date,
                                "merchant_name": merchant,
                                "amount": round(amount, 2),
                                "is_debit": is_debit,
                            }
                        )

    return transactions


def parse_statement(file_bytes: bytes, filename: str) -> list[dict]:
    """Auto-detect file type and parse."""
    ext = Path(filename).suffix.lower()
    if ext == ".csv":
        return parse_csv(file_bytes, filename)
    elif ext == ".pdf":
        return parse_pdf(file_bytes, filename)
    else:
        raise ValueError(f"Unsupported file type: {ext}")
