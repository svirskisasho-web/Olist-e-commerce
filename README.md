# Olist E-Commerce — SQL Analytics Project

![SQL](https://img.shields.io/badge/SQL-MySQL-4479A1?style=flat&logo=mysql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-22C55E?style=flat)
![Queries](https://img.shields.io/badge/Queries-50-0D9488?style=flat)
![Tables](https://img.shields.io/badge/Tables-9-6366F1?style=flat)

A end-to-end SQL analytics project on the Olist Brazilian e-commerce dataset. The project covers 50 analytical queries across 7 business domains, producing executive-ready insights on revenue, freight margins, delivery performance, customer retention, seller behaviour and payments.

---

## Business Context

Olist is a Brazilian e-commerce marketplace that connects small and medium sellers to major retail platforms. The dataset covers **September 2016 to August 2018** and contains the full order lifecycle — from purchase through payment, delivery and customer review.

This project approaches the data from the perspective of a senior BI analyst presenting to two executive stakeholders:

- **CFO** — revenue growth, freight cost as a margin risk, payment structure and deferred revenue
- **Product Chief** — delivery performance, customer satisfaction, seller quality and retention gaps

---

## Dataset

| Table | Description | Rows |
|---|---|---|
| `olist_orders_dataset` | Order lifecycle — status, timestamps, delivery dates | 99,441 |
| `olist_order_items_dataset` | Items per order — price, freight, seller, product | 112,650 |
| `olist_order_payments_dataset` | Payment method, value, installments | 103,886 |
| `olist_order_reviews_dataset` | Customer review scores and comments | 99,224 |
| `olist_customers_dataset` | Customer location and unique ID | 99,441 |
| `olist_sellers_dataset` | Seller location | 3,095 |
| `olist_products_dataset` | Product attributes and category | 32,951 |
| `product_category_name_translation` | Portuguese to English category names | 71 |

Source: [Kaggle — Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

## Schema

```
olist_orders_dataset
    ├── order_id (PK)
    ├── customer_id → olist_customers_dataset
    ├── order_status
    ├── order_purchase_timestamp
    ├── order_delivered_customer_date
    └── order_estimated_delivery_date

olist_order_items_dataset
    ├── order_id → olist_orders_dataset
    ├── seller_id → olist_sellers_dataset
    ├── product_id → olist_products_dataset
    ├── price
    └── freight_value

olist_order_payments_dataset
    ├── order_id → olist_orders_dataset
    ├── payment_type
    ├── payment_installments
    └── payment_value

olist_order_reviews_dataset
    ├── order_id → olist_orders_dataset
    └── review_score (1–5)

olist_products_dataset
    ├── product_id (PK)
    └── product_category_name → product_category_name_translation
```

---

## Key Findings

### Revenue & Growth
- Total GMV of **R$13.2M** across 99,441 delivered orders over 2 years
- Revenue grew **+2,394%** from Sep 2016 to Aug 2018
- Peak month: **November 2017 at R$1.01M** — likely driven by Black Friday
- Average order value: **R$137.05** (items only) / **R$159.83** including freight

### Freight — The Margin Problem
- Freight costs total **R$2.19M — 16.6% of GMV**, well above the ~10% industry benchmark
- Five categories have freight ratios exceeding 30% of their own revenue, making them likely unprofitable:

| Category | Freight % of Revenue |
|---|---|
| Flowers | 44.0% |
| Furniture (Mattress) | 37.3% |
| Christmas Supplies | 36.7% |
| Diapers & Hygiene | 36.6% |
| Food & Drink | 29.7% |

### Delivery — The Satisfaction Driver
- **91.9% of orders delivered on time** — but 8.1% (7,826 orders) arrive late
- Average delivery time: **12.1 days** from purchase to door
- Late deliveries cause a **40% collapse in review score**: 4.29 average when on time vs 2.57 when late
- Northern states (RR, AM, AP, PA) average **27–29 days** delivery with freight ratios above 40% — a combined margin and satisfaction problem

### Customer Retention — The Critical Gap
- **96.9% of customers never placed a second order** — 93,099 out of 96,096 unique customers
- Only **3,097 repeat buyers** in the entire 2-year period
- Average gap between first and second order among returning customers: **62 days**
- The business is effectively an acquisition machine with no retention engine

### Seller Performance
- Top seller generated **R$241K** in revenue but holds a **3.3 average review score** — the highest-earning, worst-rated seller in the dataset
- Sellers in the "risk" quadrant (high revenue, low rating) represent a hidden churn engine
- **73.9% of orders paid by credit card**, averaging **3.5 installments** — creating deferred cash flow across the entire seller base

---

## Queries — 50 Metrics across 7 Domains

| # | Domain | Metric | Difficulty |
|---|---|---|---|
| 01–08 | Revenue & GMV | Total GMV, monthly trend, AOV, revenue by category / state / seller / day, MoM growth |
| 09–14 | Freight & Cost | Total freight, freight % of GMV, by category, by state, loss-making categories |
| 15–22 | Delivery & Operations | On-time rate, avg delivery days, by state, signed days early/late, seller accuracy, dispatch time |
| 23–30 | Reviews & Satisfaction | Score distribution, on-time vs late gap, 1-star by category, by seller, by state, trend over time |
| 31–38 | Customer Behaviour | Repeat vs one-time buyers, CLV, repurchase gap, acquisition trend, cohort retention |
| 39–44 | Seller Performance | Revenue ranking, order volume, cancellation rate, geography, quadrant analysis, multi-category |
| 45–50 | Payments & Finance | Payment split, installment count, deferred revenue risk, voucher usage, AOV by method |

---

## SQL Techniques Used

- Multi-table `INNER JOIN` across 5+ tables in a single query
- `LEFT JOIN` with `NULLIF` for division-by-zero protection
- Common Table Expressions (`WITH` / CTE) for readable multi-step logic
- Window functions: `LAG()`, `LEAD()`, `ROW_NUMBER()`, `RANK()`, `SUM() OVER()`, `COUNT() OVER()`
- `CASE WHEN` for conditional classification (delivery status, risk levels, customer segments, seller quadrants)
- `TIMESTAMPDIFF()` and `DATE_FORMAT()` for date arithmetic and time series grouping
- `HAVING` for post-aggregation filtering
- Subqueries and derived tables
- `COALESCE()` and `NULLIF()` for NULL handling

---

## Recommendations

**01 — Renegotiate freight on high-ratio categories**
Flowers (44%), mattresses (37%) and Christmas supplies (37%) have freight ratios that likely make them unprofitable. Renegotiate carrier rates, introduce minimum order values, or exit these categories.

**02 — Fix delivery reliability in northern states**
RR, AM, AP and PA average 27–29 days to deliver with freight ratios above 40%. These are simultaneously a margin problem and a satisfaction problem — together they explain the low review scores in these regions.

**03 — Launch a loyalty or re-engagement programme**
A 96.9% single-purchase rate means acquisition spend is not compounding. Even converting 5% of one-time buyers to repeat customers would add significant GMV without incremental acquisition cost.

**04 — Put high-revenue, low-rating sellers on notice**
Sellers generating over R$15K with average ratings below 3.5 are a hidden churn engine. Implement seller SLAs: maintain a 3.5+ rating or face listing restrictions.

---

## Project Structure

```
olist-ecommerce-sql/
│
├── data/
│   ├── olist_orders_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_customers_dataset.csv
│   ├── olist_sellers_dataset.csv
│   ├── olist_products_dataset.csv
│   └── product_category_name_translation.csv
│
├── queries/
│   └── analytical_queries.sql        -- All 50 queries with comments and PBI export notes
│
├── presentation/
│   └── olist_executive_presentation.pptx   -- 21-slide executive deck
│
└── README.md
```

---

## Tools & Environment

| Tool | Purpose |
|---|---|
| MySQL 8.0 | Query execution and data analysis |
| MySQL Workbench | Query editor and schema visualisation |
| Microsoft PowerPoint | Executive presentation |

---

## What I Learned

This project was built as part of a career transition from Financial Analysis to Business / BI Analysis. It represents a step up from single-table analysis to working with a fully normalised relational schema across 9 tables.

The key progression from my previous project:

- From `SELECT` and `GROUP BY` → to CTEs, window functions and multi-table JOINs
- From flat CSV analysis → to relational schema design and foreign key reasoning
- From running queries → to framing business questions and communicating findings to non-technical stakeholders

The most technically challenging queries were the cohort retention analysis (metric 38) using self-joining CTEs, the MoM growth rate using `LAG()` (metric 08), and the seller performance quadrant (metric 43) combining revenue and satisfaction into a single classification framework.

---

## Author

**Sasho Svirski**
Career transition: Financial Analysis → Business / BI Analysis
[LinkedIn](https://www.linkedin.com/in/sasho-s-a0a61658/) · [GitHub](https://github.com/svirskisasho-web)
