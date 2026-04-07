# Sales Insights Dashboard — AtliQ Hardware

A production-quality business analytics project built on AtliQ Hardware's sales data.
Demonstrates end-to-end data work: SQL analysis, Python ETL, and an interactive Streamlit dashboard.

---

## Project Overview

AtliQ Hardware is a fictional computer hardware supplier. This project analyzes ~150k transactions
across multiple markets and years to surface revenue trends, top customers, and product performance.

**Tech stack:** MySQL · Python (Pandas, SQLAlchemy) · Plotly · Streamlit · Jupyter

---

## Project Structure

```
sales-insights-dashboard/
├── sql/
│   ├── 01_exploration.sql       # Schema inspection & row counts
│   ├── 02_data_quality.sql      # Nulls, negatives, currency issues
│   ├── 03_cleaned_view.sql      # sales_cleaned view (USD→INR, joins)
│   └── 04_kpi_queries.sql       # Revenue KPIs, YoY growth, top-N
├── notebooks/
│   └── analysis.ipynb           # EDA narrative + Plotly charts
├── dashboard/
│   ├── db.py                    # SQLAlchemy connection helper
│   └── app.py                   # Streamlit multi-chart dashboard
├── docs/
│   └── findings.md              # Key insights (fill in after analysis)
├── data/
│   └── db_dump.sql              # Raw dump — gitignored, not committed
├── .env.example                 # Connection variable template
├── requirements.txt
└── README.md
```

---

## Setup Instructions

### 1. Clone & install dependencies

```bash
git clone https://github.com/akallam04/sales-insights-dashboard.git
cd sales-insights-dashboard
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure environment variables

```bash
cp .env.example .env
# Open .env and fill in your MySQL password
```

### 3. Import the database

> **Note:** You need MySQL running locally. With Homebrew: `brew services start mysql`

```bash
mysql -u root -p < data/db_dump.sql
```

This creates a `sales` database with tables: `customers`, `products`, `markets`, `transactions`, `date`.

### 4. Create the cleaned view

```bash
mysql -u root -p sales < sql/03_cleaned_view.sql
```

### 5. Run the Jupyter notebook

```bash
jupyter notebook notebooks/analysis.ipynb
```

### 6. Run the Streamlit dashboard locally

```bash
streamlit run dashboard/app.py
```

---

## Deploying to Streamlit Community Cloud

1. Push this repo to GitHub (see commands below).
2. Go to [share.streamlit.io](https://share.streamlit.io) and connect your GitHub account.
3. Select this repo, set the main file to `dashboard/app.py`.
4. Add your DB credentials under **Settings → Secrets** using the same keys as `.env.example`.
   (Streamlit Cloud reads from `st.secrets`; `db.py` handles both local `.env` and cloud secrets.)

---

## Publishing to GitHub (first time)

```bash
git remote add origin https://github.com/akallam04/sales-insights-dashboard.git
git branch -M main
git push -u origin main
```

---

## Key Findings

> _Fill in after running the analysis notebook._

- **Total revenue (INR):** —
- **Peak year:** —
- **Top customer:** —
- **Top market:** —
- **Notable trend:** —

---

## Screenshots

> _Add dashboard screenshots here after deployment._

---

## Interview Talking Points

> _Fill in with your own language after completing the project._

- **Why this dataset?** AtliQ Hardware mirrors real B2B sales complexity: multi-currency, sparse nulls, market-level aggregation.
- **Biggest data quality issue found:** (e.g., negative sales amounts, USD/INR mix)
- **SQL technique highlighted:** Window functions for YoY growth (`LAG()` over yearly partitions)
- **Dashboard design decision:** (e.g., why year + market filters instead of date range pickers)
- **What I'd do with more time:** (e.g., forecasting with Prophet, customer churn model)
