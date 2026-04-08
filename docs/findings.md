# Sales Insights — Key Findings

Use the live dashboard and the analysis notebook to answer each question below.
These are your interview talking points — answer them in your own words.

---

## 1. Revenue Trend

**Question:** Is overall revenue growing or declining across the years in the dataset?

> Your answer: ___

**Follow-up to expect in an interview:**
*"What would you do to investigate the root cause of a revenue decline?"*
→ Think: drill down by market, then by customer, then by product. Check if it's concentration (one customer left) or broad-based.

---

## 2. Year-over-Year Growth

**Question:** Which year had the sharpest YoY decline, and what was the approximate percentage?

> Revenue grew +377% from 2017→2018 (likely a partial-year baseline in 2017), then declined -14.9% in 2018→2019, and fell a further -57.4% in 2019→2020. The 2019→2020 drop is the sharpest and most significant.

**Hypothesis on the 2020 decline:** The -57.4% drop in 2020 aligns with the global disruption caused by COVID-19 — hardware supply chains, retail closures, and B2B procurement freezes all affected companies like AtliQ in this period. However, this dataset contains no external context to confirm causation. Other possibilities include loss of a major customer, a product line change, or incomplete 2020 data in the dump. In an interview, frame this correctly: *"The timing is consistent with COVID-19 impact, but I'd want to cross-reference with customer churn data and order-fulfilment records before drawing a firm conclusion."*

**Follow-up:**
*"How did you calculate YoY growth in SQL?"*
→ `LAG(revenue) OVER (ORDER BY year)` — explain that window functions let you reference a prior row without a self-join.

---

## 3. Top Market

**Question:** Which single city generates the most revenue, and what percentage of total revenue does it represent?

> Your answer: ___

**Follow-up:**
*"Is that concentration a business risk?"*
→ Yes — if one city drives >30% of revenue, losing a key customer there has outsized impact (link to Pareto analysis).

---

## 4. Regional Split

**Question:** Which zone (North / South / Central / International) leads by revenue share?

> Your answer: ___

**Follow-up:**
*"Were there any markets you excluded from regional analysis and why?"*
→ Mark097 (New York) and Mark999 (Paris) had empty zone values and USD currency. You coalesced them to 'International' rather than dropping them, to preserve their revenue in global totals.

---

## 5. Top Customer

**Question:** Who is the single largest customer by revenue, and what share of total revenue do they represent?

> Your answer: ___

**Follow-up:**
*"How concentrated is the customer base?"*
→ Look at the Pareto chart in the notebook — how many customers make up 80% of revenue? If it's fewer than 10, that's a risk worth flagging.

---

## 6. Channel Mix

**Question:** Is the E-Commerce share of revenue growing, shrinking, or stable year over year?

> Your answer: ___

**Follow-up:**
*"What business implication does that trend have?"*
→ Growing e-commerce = shift in distribution strategy. AtliQ may need to invest in digital channels / direct-to-consumer rather than brick-and-mortar partnerships.

---

## 7. Seasonality

**Question:** Looking at the monthly revenue chart — is there a consistent seasonal peak (e.g. a month that is always the highest)?

> Your answer: ___

**Follow-up:**
*"How would you use this insight operationally?"*
→ Inventory planning, marketing spend timing, sales team quota setting by quarter.

---

## 8. Top Product

**Question:** Which product code generates the most revenue, and is it Own Brand or Distribution?

> Your answer: ___

**Follow-up:**
*"Why does product type matter strategically?"*
→ Own Brand products have higher margins. If top revenue products are Distribution, AtliQ's profitability story is different from its revenue story.

---

## 9. Data Quality Impact

**Question:** How many rows were excluded by the `WHERE sales_amount > 0` filter, and what fraction of total rows does that represent?

> Your answer: ___ rows excluded, ___% of total

**Follow-up:**
*"How did you decide it was safe to exclude those rows?"*
→ Ran `02_data_quality.sql` first to quantify the impact. The -1 rows appear to be a sentinel value (no meaningful quantity or amount), not real returns, so excluding them doesn't distort the KPIs.

---

## 10. USD Conversion Assumption

**Question:** How much revenue came from USD transactions, and how sensitive are the KPIs to the ₹83/$ assumption?

> Your answer: ___

**Follow-up:**
*"What would you do if the exchange rate assumption mattered a lot?"*
→ Pull historical daily rates from an API (e.g. Open Exchange Rates), join on `order_date`, and convert row-by-row instead of using a fixed rate. Flag this as a known limitation in any executive report.

---

## Summary Table

Fill this in after exploring the dashboard:

| Metric | Value |
|--------|-------|
| Total revenue (INR Cr) | |
| Date range | |
| Peak revenue year | |
| Worst YoY decline | |
| Top market | |
| Top market revenue share | |
| Top customer | |
| Top customer revenue share | |
| Customers = 80% of revenue (Pareto) | |
| E-Commerce share trend | |
| Rows excluded (sales_amount ≤ 0) | |
