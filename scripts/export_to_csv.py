"""
scripts/export_to_csv.py
------------------------
Export the sales_cleaned view to data/sales_cleaned.csv.

Run once locally after importing the dump into MySQL:
    python scripts/export_to_csv.py

The resulting CSV is committed to the repo so the Streamlit dashboard
can fall back to it if the Railway free tier pauses or the DB is unreachable.
"""

import sys
import os
from pathlib import Path

# Resolve project root so dashboard.db imports correctly
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from dashboard.db import query

OUTPUT = ROOT / 'data' / 'sales_cleaned.csv'


def main() -> None:
    print("Connecting to MySQL and reading sales_cleaned…")
    df = query("SELECT * FROM sales_cleaned")
    print(f"  {len(df):,} rows fetched.")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUTPUT, index=False)
    print(f"  Saved → {OUTPUT}")
    print("Done.")


if __name__ == '__main__':
    main()
