-- =============================================================================
-- 03_cleaned_view.sql
-- Purpose : Create the `sales_cleaned` view — the single source of truth for
--           all KPI queries and the Python/notebook layer.
--
-- Cleaning decisions (each justified by 02_data_quality.sql findings):
--   1. Alias custmer_name → customer_name  (column typo)
--   2. TRIM carriage returns from currency  ('INR\r' → 'INR')
--   3. Exclude rows where sales_amount <= 0 (sentinel -1 and zero rows)
--   4. Convert USD → INR at a fixed rate of 83 for comparable revenue figures
--      (rate chosen as a representative ~2020 average; document this assumption)
--   5. All dimension tables joined so downstream queries need only this view
--   6. Non-Indian markets (Mark097, Mark999) are included but zone is coalesced
--      to 'International' for grouping
-- =============================================================================

USE sales;

DROP VIEW IF EXISTS sales_cleaned;

CREATE VIEW sales_cleaned AS
SELECT
    -- -----------------------------------------------------------------------
    -- Transaction facts
    -- -----------------------------------------------------------------------
    t.order_date,
    t.sales_qty,

    -- Normalise currency to INR; preserve original for auditability
    TRIM(BOTH '\r' FROM t.currency)                         AS currency,
    t.sales_amount                                          AS sales_amount_raw,
    CASE
        WHEN TRIM(BOTH '\r' FROM t.currency) = 'USD'
            THEN t.sales_amount * 83          -- USD → INR conversion
        ELSE t.sales_amount
    END                                                     AS sales_amount_inr,

    -- -----------------------------------------------------------------------
    -- Date dimension (flattened for convenience)
    -- -----------------------------------------------------------------------
    d.year,
    d.month_name,
    d.date_yy_mmm,                          -- e.g. '18-Jan' — useful for charts

    -- -----------------------------------------------------------------------
    -- Customer dimension
    -- -----------------------------------------------------------------------
    c.customer_code,
    c.custmer_name  AS customer_name,        -- fix typo via alias
    c.customer_type,                         -- 'Brick & Mortar' | 'E-Commerce'

    -- -----------------------------------------------------------------------
    -- Market / geography dimension
    -- -----------------------------------------------------------------------
    m.markets_code,
    m.markets_name,
    CASE
        WHEN m.zone = '' OR m.zone IS NULL THEN 'International'
        ELSE m.zone
    END                                                     AS zone,

    -- -----------------------------------------------------------------------
    -- Product dimension
    -- -----------------------------------------------------------------------
    p.product_code,
    p.product_type

FROM transactions t

-- Join dimension tables
INNER JOIN date     d ON t.order_date    = d.date
INNER JOIN customers c ON t.customer_code = c.customer_code
INNER JOIN markets   m ON t.market_code   = m.markets_code
INNER JOIN products  p ON t.product_code  = p.product_code

-- -----------------------------------------------------------------------
-- FILTERS — rows excluded with documented reasons
-- -----------------------------------------------------------------------

-- Rule 1: Drop invalid amounts (-1 sentinel and zero-revenue rows)
WHERE t.sales_amount > 0

-- Rule 2: Keep only rows with a recognised currency (after stripping \r)
  AND TRIM(BOTH '\r' FROM t.currency) IN ('INR', 'USD');


-- ---------------------------------------------------------------------------
-- Quick validation — run after creating the view
-- ---------------------------------------------------------------------------

-- Row count before vs after cleaning
-- SELECT COUNT(*) FROM transactions;          -- raw
-- SELECT COUNT(*) FROM sales_cleaned;         -- cleaned

-- Confirm no bad currency values remain
-- SELECT DISTINCT currency FROM sales_cleaned;

-- Confirm no non-positive amounts remain
-- SELECT MIN(sales_amount_inr) FROM sales_cleaned;

-- Check all zones are populated
-- SELECT DISTINCT zone FROM sales_cleaned ORDER BY zone;
