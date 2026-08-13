import sqlite3
from pathlib import Path

db_path = Path(__file__).resolve().parents[1] / "fincopilot.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()
cur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
tables = cur.fetchall()
print(tables)
