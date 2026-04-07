-- =============================================================================
-- 04_kpi_queries.sql
-- Purpose : Business KPIs built entirely on the `sales_cleaned` view.
--           All amounts are in INR. Run 03_cleaned_view.sql first.
-- Database: sales
-- =============================================================================

USE sales;

-- ---------------------------------------------------------------------------
-- KPI 1 — Revenue and Volume by Year
-- Answers: Is the business growing or declining year-over-year?
-- ---------------------------------------------------------------------------
SELECT
    year,
    COUNT(*)                        AS transactions,
    SUM(sales_qty)                  AS units_sold,
    ROUND(SUM(sales_amount_inr), 2) AS revenue_inr
FROM sales_cleaned
GROUP BY year
ORDER BY year;


-- ---------------------------------------------------------------------------
-- KPI 2 — Monthly Revenue Trend (all years combined)
-- Answers: Are there seasonal patterns?
-- Note: month_name ordering uses FIELD() to get calendar order, not alpha.
-- ---------------------------------------------------------------------------
SELECT
    year,
    month_name,
    date_yy_mmm,
    ROUND(SUM(sales_amount_inr), 2) AS revenue_inr,
    SUM(sales_qty)                  AS units_sold
FROM sales_cleaned
GROUP BY year, month_name, date_yy_mmm
ORDER BY year, FIELD(month_name,
    'January','February','March','April','May','June',
    'July','August','September','October','November','December');


-- ---------------------------------------------------------------------------
-- KPI 3 — Year-over-Year Revenue Growth (window function)
-- Answers: What is the YoY growth rate for each year?
-- ---------------------------------------------------------------------------
WITH yearly_revenue AS (
    SELECT
        year,
        ROUND(SUM(sales_amount_inr), 2) AS revenue_inr
    FROM sales_cleaned
    GROUP BY year
)
SELECT
    year,
    revenue_inr,
    LAG(revenue_inr) OVER (ORDER BY year)  AS prev_year_revenue,
    ROUND(
        100.0 * (revenue_inr - LAG(revenue_inr) OVER (ORDER BY year))
              / LAG(revenue_inr) OVER (ORDER BY year),
        2
    )                                       AS yoy_growth_pct
FROM yearly_revenue
ORDER BY year;


-- ---------------------------------------------------------------------------
-- KPI 4 — Top 5 Customers by Revenue
-- Answers: Who drives the most revenue? Are we over-concentrated?
-- ---------------------------------------------------------------------------
SELECT
    customer_code,
    customer_name,
    customer_type,
    ROUND(SUM(sales_amount_inr), 2) AS revenue_inr,
    SUM(sales_qty)                  AS units_sold,
    COUNT(*)                        AS transactions,
    ROUND(
        100.0 * SUM(sales_amount_inr)
              / SUM(SUM(sales_amount_inr)) OVER (),
        2
    )                               AS revenue_share_pct
FROM sales_cleaned
GROUP BY customer_code, customer_name, customer_type
ORDER BY revenue_inr DESC
LIMIT 5;


-- ---------------------------------------------------------------------------
-- KPI 5 — Top 5 Products by Revenue
-- Answers: Which products are the biggest revenue drivers?
-- ---------------------------------------------------------------------------
SELECT
    product_code,
    product_type,
    ROUND(SUM(sales_amount_inr), 2) AS revenue_inr,
    SUM(sales_qty)                  AS units_sold,
    COUNT(*)                        AS transactions,
    ROUND(
        100.0 * SUM(sales_amount_inr)
              / SUM(SUM(sales_amount_inr)) OVER (),
        2
    )                               AS revenue_share_pct
FROM sales_cleaned
GROUP BY product_code, product_type
ORDER BY revenue_inr DESC
LIMIT 5;


-- ---------------------------------------------------------------------------
-- KPI 6 — Revenue by Market
-- Answers: Which cities / geographies perform best?
-- ---------------------------------------------------------------------------
SELECT
    markets_code,
    markets_name,
    zone,
    ROUND(SUM(sales_amount_inr), 2)  AS revenue_inr,
    SUM(sales_qty)                   AS units_sold,
    COUNT(*)                         AS transactions,
    ROUND(
        100.0 * SUM(sales_amount_inr)
              / SUM(SUM(sales_amount_inr)) OVER (),
        2
    )                                AS revenue_share_pct
FROM sales_cleaned
GROUP BY markets_code, markets_name, zone
ORDER BY revenue_inr DESC;


-- ---------------------------------------------------------------------------
-- KPI 7 — Revenue by Zone
-- Answers: Which region (North / South / Central / International) leads?
-- ---------------------------------------------------------------------------
SELECT
    zone,
    ROUND(SUM(sales_amount_inr), 2) AS revenue_inr,
    SUM(sales_qty)                  AS units_sold,
    ROUND(
        100.0 * SUM(sales_amount_inr)
              / SUM(SUM(sales_amount_inr)) OVER (),
        2
    )                               AS revenue_share_pct
FROM sales_cleaned
GROUP BY zone
ORDER BY revenue_inr DESC;


-- ---------------------------------------------------------------------------
-- KPI 8 — Customer Type Split (Brick & Mortar vs E-Commerce)
-- Answers: How is the channel mix evolving over time?
-- ---------------------------------------------------------------------------
SELECT
    year,
    customer_type,
    ROUND(SUM(sales_amount_inr), 2) AS revenue_inr,
    ROUND(
        100.0 * SUM(sales_amount_inr)
              / SUM(SUM(sales_amount_inr)) OVER (PARTITION BY year),
        2
    )                               AS channel_share_pct
FROM sales_cleaned
GROUP BY year, customer_type
ORDER BY year, customer_type;


-- ---------------------------------------------------------------------------
-- KPI 9 — Running / Rolling Revenue (cumulative within each year)
-- Answers: Where is the business relative to its annual total at any point?
-- ---------------------------------------------------------------------------
WITH monthly AS (
    SELECT
        year,
        date_yy_mmm,
        FIELD(month_name,
            'January','February','March','April','May','June',
            'July','August','September','October','November','December'
        )                               AS month_num,
        ROUND(SUM(sales_amount_inr), 2) AS monthly_revenue
    FROM sales_cleaned
    GROUP BY year, date_yy_mmm, month_name
)
SELECT
    year,
    date_yy_mmm,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        PARTITION BY year
        ORDER BY month_num
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                   AS cumulative_revenue_ytd
FROM monthly
ORDER BY year, month_num;


-- ---------------------------------------------------------------------------
-- KPI 10 — Market × Year Revenue Matrix
-- Answers: Which markets grew or shrank across years? (pivot-friendly output)
-- ---------------------------------------------------------------------------
SELECT
    markets_name,
    zone,
    SUM(CASE WHEN year = 2017 THEN sales_amount_inr ELSE 0 END) AS rev_2017,
    SUM(CASE WHEN year = 2018 THEN sales_amount_inr ELSE 0 END) AS rev_2018,
    SUM(CASE WHEN year = 2019 THEN sales_amount_inr ELSE 0 END) AS rev_2019,
    SUM(CASE WHEN year = 2020 THEN sales_amount_inr ELSE 0 END) AS rev_2020,
    ROUND(SUM(sales_amount_inr), 2)                             AS total_revenue
FROM sales_cleaned
GROUP BY markets_name, zone
ORDER BY total_revenue DESC;
