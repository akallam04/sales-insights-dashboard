-- =============================================================================
-- 02_data_quality.sql
-- Purpose : Precisely quantify every data quality issue so we can make
--           deliberate, documented decisions before writing the cleaned view.
-- Database: sales
-- =============================================================================

USE sales;

-- ---------------------------------------------------------------------------
-- ISSUE 1 — Negative and zero sales amounts
-- Expected: sales_amount is always a positive number.
-- Found   : -1 values (likely a sentinel for "no sale recorded") and 0s.
-- ---------------------------------------------------------------------------
SELECT
    sales_amount,
    COUNT(*)    AS row_count,
    SUM(sales_qty) AS total_qty
FROM transactions
WHERE sales_amount <= 0
GROUP BY sales_amount
ORDER BY sales_amount;

-- How much revenue would we lose by excluding these rows?
SELECT
    SUM(CASE WHEN sales_amount > 0 THEN sales_amount ELSE 0 END) AS valid_revenue,
    SUM(CASE WHEN sales_amount <= 0 THEN 1 ELSE 0 END)           AS excluded_rows,
    COUNT(*)                                                       AS total_rows
FROM transactions;


-- ---------------------------------------------------------------------------
-- ISSUE 2 — Dirty currency strings (carriage-return suffix)
-- The dump was likely exported on Windows; some rows have 'INR\r' instead
-- of 'INR'. TRIM() alone won't fix this — we need TRIM(BOTH '\r' ...).
-- ---------------------------------------------------------------------------
SELECT
    currency,
    LENGTH(currency) AS byte_len,   -- 'INR' = 3, 'INR\r' = 4
    COUNT(*)         AS row_count
FROM transactions
GROUP BY currency
ORDER BY currency;

-- Rows with any non-standard currency value
SELECT COUNT(*) AS dirty_currency_rows
FROM transactions
WHERE currency NOT IN ('INR', 'USD');


-- ---------------------------------------------------------------------------
-- ISSUE 3 — USD transactions (need conversion to INR for apples-to-apples KPIs)
-- Markets Mark097 (New York) and Mark999 (Paris) appear to be the source.
-- ---------------------------------------------------------------------------
SELECT
    m.markets_name,
    m.zone,
    t.currency,
    COUNT(*)           AS transaction_count,
    SUM(t.sales_amount) AS raw_total_amount
FROM transactions t
JOIN markets m ON t.market_code = m.markets_code
WHERE TRIM(BOTH '\r' FROM t.currency) = 'USD'
GROUP BY m.markets_name, m.zone, t.currency
ORDER BY transaction_count DESC;


-- ---------------------------------------------------------------------------
-- ISSUE 4 — Non-Indian markets (empty zone)
-- Mark097 / Mark999 have no zone value. Strategy: exclude them from regional
-- KPIs but convert their USD revenue and include in global totals.
-- ---------------------------------------------------------------------------
SELECT
    markets_code,
    markets_name,
    zone,
    LENGTH(zone) AS zone_len   -- confirms truly empty vs whitespace
FROM markets
WHERE zone = '' OR zone IS NULL;


-- ---------------------------------------------------------------------------
-- ISSUE 5 — Duplicate transactions
-- There is no surrogate key, so a "duplicate" is an identical combination
-- of all meaningful columns.
-- ---------------------------------------------------------------------------
SELECT
    product_code, customer_code, market_code, order_date,
    sales_qty, sales_amount, currency,
    COUNT(*) AS occurrences
FROM transactions
GROUP BY
    product_code, customer_code, market_code, order_date,
    sales_qty, sales_amount, currency
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

-- Total duplicated rows
SELECT SUM(occurrences - 1) AS excess_duplicate_rows
FROM (
    SELECT COUNT(*) AS occurrences
    FROM transactions
    GROUP BY product_code, customer_code, market_code, order_date,
             sales_qty, sales_amount, currency
    HAVING COUNT(*) > 1
) dupes;


-- ---------------------------------------------------------------------------
-- ISSUE 6 — NULL values across all transaction columns
-- ---------------------------------------------------------------------------
SELECT
    SUM(product_code   IS NULL) AS null_product_code,
    SUM(customer_code  IS NULL) AS null_customer_code,
    SUM(market_code    IS NULL) AS null_market_code,
    SUM(order_date     IS NULL) AS null_order_date,
    SUM(sales_qty      IS NULL) AS null_sales_qty,
    SUM(sales_amount   IS NULL) AS null_sales_amount,
    SUM(currency       IS NULL) AS null_currency
FROM transactions;


-- ---------------------------------------------------------------------------
-- ISSUE 7 — Typo in customers table column name
-- 'custmer_name' is missing the letter 'o'. Not fixable via a view column
-- rename without ALTER TABLE, so we'll alias it in the cleaned view.
-- ---------------------------------------------------------------------------
SELECT custmer_name AS customer_name
FROM customers
LIMIT 5;


-- ---------------------------------------------------------------------------
-- SUMMARY — total rows that will be excluded by the cleaning rules
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                         AS total_rows,
    SUM(sales_amount <= 0)                           AS excluded_invalid_amount,
    SUM(TRIM(BOTH '\r' FROM currency) NOT IN ('INR','USD')) AS excluded_bad_currency,
    COUNT(*) - SUM(sales_amount > 0)
        - SUM(TRIM(BOTH '\r' FROM currency) NOT IN ('INR','USD'))
                                                     AS approx_clean_rows
FROM transactions;
