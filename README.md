# Sales Insights Dashboard — AtliQ Hardware

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Streamlit-FF4B4B?logo=streamlit&logoColor=white)](https://sales-insights-dashboard.streamlit.app)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://python.org)
[![Pandas](https://img.shields.io/badge/Pandas-2.x-150458?logo=pandas&logoColor=white)](https://pandas.pydata.org/)
[![Plotly](https://img.shields.io/badge/Plotly-5.x-3F4F75?logo=plotly&logoColor=white)](https://plotly.com/)

An end-to-end sales analytics project on AtliQ Hardware's transactional data.
Covers the full data pipeline: raw SQL exploration → data quality audit → cleaned view → KPI queries → Python ETL → interactive Streamlit dashboard.

**[View live dashboard →](https://sales-insights-dashboard.streamlit.app)**

---

## Screenshot

![Dashboard screenshot](dashboard/screenshots/dashboard.png)

---

## Project Structure

```
sales-insights-dashboard/
├── sql/
│   ├── 01_exploration.sql       # Schema audit, row counts, FK orphan checks
│   ├── 02_data_quality.sql      # 7 data quality issues quantified
│   ├── 03_cleaned_view.sql      # sales_cleaned view: USD→INR, joins, filters
│   └── 04_kpi_queries.sql       # 10 KPI queries with window functions
├── notebooks/
│   └── analysis.ipynb           # 11-section EDA narrative + Plotly charts
├── dashboard/
│   ├── db.py                    # SQLAlchemy singleton, URL-safe credentials
│   ├── app.py                   # Streamlit dashboard (MySQL + CSV fallback)
│   └── screenshots/             # Drop dashboard.png here
├── scripts/
│   └── export_to_csv.py         # Exports sales_cleaned → data/sales_cleaned.csv
├── docs/
│   └── findings.md              # Key business insights & interview talking points
├── data/
│   ├── db_dump.sql              # Raw dump — gitignored
│   └── sales_cleaned.csv        # Pre-exported fallback (94,073 rows)
├── .env.example
├── requirements.txt
└── README.md
```

---

## Data Quality Issues Found

The raw dump contained 7 issues identified in `sql/02_data_quality.sql`:

| # | Issue | Fix applied in `sales_cleaned` view |
|---|-------|--------------------------------------|
| 1 | `custmer_name` — typo in column name | Aliased as `customer_name` |
| 2 | `currency` values like `'INR\r'` (Windows carriage return) | `TRIM(BOTH '\r' FROM currency)` |
| 3 | `sales_amount = -1` — sentinel rows with no valid sale | Excluded: `WHERE sales_amount > 0` |
| 4 | `sales_amount = 0` — zero-revenue rows | Excluded: `WHERE sales_amount > 0` |
| 5 | USD transactions mixed with INR | Converted at ₹83/$ in `sales_amount_inr` |
| 6 | Mark097 (New York) & Mark999 (Paris) — empty `zone` | Coalesced to `'International'` |
| 7 | Exact duplicate rows (no surrogate key) | Documented; not filtered (business rows, not errors) |

---

## Key Findings

> Run `notebooks/analysis.ipynb` or click through the live dashboard to fill these in.

- **Total clean rows:** 94,073 transactions across 4 years
- **Peak revenue year:** —
- **Top customer:** —
- **Top market:** —
- **Notable trend:** —

---

## Setup — Option A: Local MySQL

```bash
git clone https://github.com/akallam04/sales-insights-dashboard.git
cd sales-insights-dashboard
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # fill in DB credentials
mysql -u root -p < data/db_dump.sql
mysql -u root -p sales < sql/03_cleaned_view.sql
streamlit run dashboard/app.py
```

## Setup — Option B: CSV mode (no database needed)

The repo includes a pre-exported `data/sales_cleaned.csv` (94,073 rows).
Set `USE_CSV=1` and the dashboard reads directly from that file:

```bash
git clone https://github.com/akallam04/sales-insights-dashboard.git
cd sales-insights-dashboard
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
USE_CSV=1 streamlit run dashboard/app.py
```

---

## Deploying to Streamlit Community Cloud

1. Fork / push repo to GitHub.
2. Go to [share.streamlit.io](https://share.streamlit.io) → **New app** → point at `dashboard/app.py`.
3. Under **Advanced settings → Secrets**, add your DB credentials:
   ```toml
   DB_HOST     = "your-host"
   DB_PORT     = "your-port"
   DB_USER     = "root"
   DB_PASSWORD = "your-password"
   DB_NAME     = "sales"
   ```
4. If Railway free tier pauses, add `USE_CSV = "1"` to secrets — the app falls back to the committed CSV automatically.

---

## Interview Talking Points

- **Why this dataset?** AtliQ Hardware mirrors real B2B complexity — multi-currency transactions, no surrogate keys, mix of Indian and international markets.
- **Biggest data quality issue:** `'INR\r'` — Windows carriage returns embedded in the currency column, invisible in most editors, caught via `LENGTH(currency) = 4` in the quality audit.
- **SQL design decision:** All cleaning lives in one `sales_cleaned` view. KPI queries stay simple and any fix propagates everywhere automatically.
- **Window functions used:** `LAG()` for YoY growth, `SUM() OVER (PARTITION BY year)` for channel share, `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` for cumulative YTD revenue.
- **Resilience decision:** CSV fallback means the live demo never goes down even if the free-tier DB pauses — important for a portfolio project that gets viewed asynchronously.
- **What I'd add with more time:** Prophet forecasting for the monthly trend, customer churn model using RFM segmentation, dbt for the transformation layer.
