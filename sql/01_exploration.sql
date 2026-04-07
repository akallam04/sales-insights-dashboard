-- =============================================================================
-- 01_exploration.sql
-- Purpose : Understand the raw shape of every table before touching anything.
--           Run these queries top-to-bottom the first time you load the dump.
-- Database: sales
-- =============================================================================

USE sales;

-- ---------------------------------------------------------------------------
-- 1. ROW COUNTS — how large is each table?
-- ---------------------------------------------------------------------------
SELECT 'customers'   AS tbl, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'date',                COUNT(*)              FROM date
UNION ALL
SELECT 'markets',             COUNT(*)              FROM markets
UNION ALL
SELECT 'products',            COUNT(*)              FROM products
UNION ALL
SELECT 'transactions',        COUNT(*)              FROM transactions;


-- ---------------------------------------------------------------------------
-- 2. SCHEMA PEEK — column names, types, and nullability for every table
--    (information_schema is always safe to query)
-- ---------------------------------------------------------------------------
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION AS col_order,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'sales'
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- ---------------------------------------------------------------------------
-- 3. CUSTOMERS — distinct types, sample rows
-- ---------------------------------------------------------------------------
-- Note: column is intentionally misspelled as custmer_name in the source dump
SELECT DISTINCT customer_type FROM customers;

SELECT * FROM customers LIMIT 10;


-- ---------------------------------------------------------------------------
-- 4. MARKETS — which zones exist? any markets without a zone?
-- ---------------------------------------------------------------------------
SELECT DISTINCT zone FROM markets ORDER BY zone;

SELECT * FROM markets ORDER BY markets_code;


-- ---------------------------------------------------------------------------
-- 5. PRODUCTS — distinct product types
-- ---------------------------------------------------------------------------
SELECT DISTINCT product_type FROM products;

SELECT * FROM products LIMIT 10;


-- ---------------------------------------------------------------------------
-- 6. DATE DIMENSION — date range and grain
-- ---------------------------------------------------------------------------
SELECT
    MIN(`date`)      AS earliest_date,
    MAX(`date`)      AS latest_date,
    COUNT(*)         AS total_days,
    COUNT(DISTINCT year)       AS distinct_years,
    COUNT(DISTINCT month_name) AS distinct_months
FROM date;

-- What years are covered?
SELECT DISTINCT year FROM date ORDER BY year;


-- ---------------------------------------------------------------------------
-- 7. TRANSACTIONS — date range, currency values, amount distribution
-- ---------------------------------------------------------------------------
SELECT
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    COUNT(*)        AS total_transactions
FROM transactions;

-- What currency codes actually appear?
SELECT currency, COUNT(*) AS cnt
FROM transactions
GROUP BY currency
ORDER BY cnt DESC;

-- sales_amount distribution (quick sanity check)
SELECT
    MIN(sales_amount)  AS min_amt,
    MAX(sales_amount)  AS max_amt,
    AVG(sales_amount)  AS avg_amt,
    SUM(sales_amount)  AS total_amt,
    COUNT(*)           AS total_rows,
    SUM(sales_amount <= 0) AS non_positive_rows
FROM transactions;

-- sales_qty distribution
SELECT
    MIN(sales_qty)  AS min_qty,
    MAX(sales_qty)  AS max_qty,
    AVG(sales_qty)  AS avg_qty
FROM transactions;


-- ---------------------------------------------------------------------------
-- 8. FOREIGN KEY SANITY — do all FK values exist in their dimension tables?
-- ---------------------------------------------------------------------------

-- Transactions → customers
SELECT COUNT(*) AS orphan_customer_codes
FROM transactions t
LEFT JOIN customers c ON t.customer_code = c.customer_code
WHERE c.customer_code IS NULL;

-- Transactions → markets
SELECT COUNT(*) AS orphan_market_codes
FROM transactions t
LEFT JOIN markets m ON t.market_code = m.markets_code
WHERE m.markets_code IS NULL;

-- Transactions → products
SELECT COUNT(*) AS orphan_product_codes
FROM transactions t
LEFT JOIN products p ON t.product_code = p.product_code
WHERE p.product_code IS NULL;

-- Transactions → date
SELECT COUNT(*) AS orphan_order_dates
FROM transactions t
LEFT JOIN date d ON t.order_date = d.date
WHERE d.date IS NULL;
