-- ============================================================
-- OLIST E-COMMERCE — ANALYTICAL QUERIES
-- Senior BI version — optimised for Power BI export
-- Each query is a standalone export. Run > export CSV > load in PBI.
-- ============================================================


-- ============================================================
-- DOMAIN 1: REVENUE & GMV
-- ============================================================

-- 00 Total payments received on delivered orders
-- PBI use: KPI card — "Total revenue collected"
SELECT
    opd.order_id,
    ROUND(SUM(opd.payment_value), 2)    AS total_paid,
    od.order_status
FROM olist_order_payments_dataset opd
INNER JOIN olist_orders_dataset od ON opd.order_id = od.order_id
WHERE od.order_status = 'delivered'
GROUP BY opd.order_id, od.order_status
ORDER BY total_paid DESC;


-- 01 Total item revenue (GMV — price only, excludes freight)
-- PBI use: KPI card — "Total GMV"
SELECT
    ROUND(SUM(oid.price), 2)            AS total_gmv
FROM olist_order_items_dataset oid
INNER JOIN olist_orders_dataset od ON oid.order_id = od.order_id
WHERE od.order_status = 'delivered';


-- 02 Monthly revenue trend
-- PBI use: Line chart — month on X axis, revenue on Y axis
SELECT
    DATE_FORMAT(od.order_purchase_timestamp, '%Y-%m')   AS order_month,
    ROUND(SUM(oid.price), 2)                            AS revenue,
    ROUND(SUM(oid.freight_value), 2)                    AS freight_collected,
    ROUND(SUM(oid.price + oid.freight_value), 2)        AS total_collected
FROM olist_order_items_dataset oid
INNER JOIN olist_orders_dataset od ON oid.order_id = od.order_id
WHERE od.order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;


-- 03 Average order value (AOV)
-- PBI use: KPI card — "AOV"
-- Note: avg(price) = avg item price, not avg order value. 
-- True AOV = total revenue / distinct orders.
SELECT
    ROUND(SUM(oid.price) / COUNT(DISTINCT od.order_id), 2)              AS aov,
    ROUND(SUM(oid.price + oid.freight_value) / COUNT(DISTINCT od.order_id), 2) AS aov_incl_freight,
    COUNT(DISTINCT od.order_id)                                         AS total_orders,
    ROUND(SUM(oid.price), 2)                                            AS total_gmv
FROM olist_order_items_dataset oid
INNER JOIN olist_orders_dataset od ON oid.order_id = od.order_id
WHERE od.order_status = 'delivered';


-- 04 Revenue by product category
-- PBI use: Bar chart — category on Y, revenue on X. Add freight_pct for tooltip.
SELECT
    pcnt.product_category_name_english                                  AS category,
    ROUND(SUM(oid.price), 2)                                            AS revenue,
    ROUND(SUM(oid.freight_value), 2)                                    AS freight,
    COUNT(DISTINCT oid.order_id)                                        AS total_orders,
    ROUND(SUM(oid.price) * 100.0 / SUM(SUM(oid.price)) OVER(), 2)      AS pct_of_total_revenue
FROM olist_order_items_dataset oid
INNER JOIN olist_products_dataset pd ON oid.product_id = pd.product_id
INNER JOIN product_category_name_translation pcnt
    ON pd.product_category_name = pcnt.product_category_name
GROUP BY pcnt.product_category_name_english
ORDER BY revenue DESC;


-- 05 Revenue by customer state
-- PBI use: Map visual or bar chart — state on Y, revenue on X
SELECT
    cd.customer_state                                                   AS state,
    ROUND(SUM(opd.payment_value), 2)                                    AS total_revenue,
    COUNT(DISTINCT od.order_id)                                         AS total_orders,
    ROUND(SUM(opd.payment_value) / COUNT(DISTINCT od.order_id), 2)      AS aov_per_state
FROM olist_orders_dataset od
INNER JOIN olist_order_payments_dataset opd ON opd.order_id = od.order_id
INNER JOIN olist_customers_dataset cd ON cd.customer_id = od.customer_id
WHERE od.order_status = 'delivered'
GROUP BY cd.customer_state
ORDER BY total_revenue DESC;


-- 06 Revenue by seller (top 20)
-- PBI use: Bar chart — seller on Y, revenue on X
SELECT
    oid.seller_id,
    sd.seller_state,
    sd.seller_city,
    ROUND(SUM(oid.price), 2)                AS revenue,
    ROUND(SUM(oid.freight_value), 2)        AS freight_charged,
    COUNT(DISTINCT oid.order_id)            AS total_orders,
    ROUND(AVG(oid.price), 2)               AS avg_item_price
FROM olist_order_items_dataset oid
INNER JOIN olist_sellers_dataset sd ON sd.seller_id = oid.seller_id
GROUP BY oid.seller_id, sd.seller_state, sd.seller_city
ORDER BY revenue DESC
LIMIT 20;


-- 07 Revenue by day of week
-- PBI use: Bar chart sorted Mon–Sun
SELECT
    DAYNAME(od.order_purchase_timestamp)                AS day_name,
    DAYOFWEEK(od.order_purchase_timestamp)              AS day_sort,
    COUNT(DISTINCT od.order_id)                         AS total_orders,
    ROUND(SUM(oid.price), 2)                            AS revenue
FROM olist_order_items_dataset oid
INNER JOIN olist_orders_dataset od ON oid.order_id = od.order_id
WHERE od.order_status = 'delivered'
GROUP BY day_name, day_sort
ORDER BY day_sort;


-- 08 Month-over-month revenue growth
-- PBI use: Line chart with pct_change as secondary axis
WITH MonthlyRevenue AS (
    SELECT
        DATE_FORMAT(od.order_purchase_timestamp, '%Y-%m')   AS order_month,
        ROUND(SUM(oid.price), 2)                            AS revenue
    FROM olist_orders_dataset od
    INNER JOIN olist_order_items_dataset oid ON od.order_id = oid.order_id
    WHERE od.order_status = 'delivered'
    GROUP BY order_month
)
SELECT
    order_month,
    revenue,
    LAG(revenue) OVER (ORDER BY order_month)                            AS prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY order_month), 2)        AS abs_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0) * 100
    , 2)                                                                AS pct_change
FROM MonthlyRevenue
ORDER BY order_month;


-- ============================================================
-- DOMAIN 2: FREIGHT & COST
-- ============================================================

-- 09 Total freight cost summary
-- PBI use: KPI card — "Total freight" and "Freight % of GMV"
SELECT
    ROUND(SUM(oid.price), 2)                                            AS total_gmv,
    ROUND(SUM(oid.freight_value), 2)                                    AS total_freight,
    ROUND(SUM(oid.freight_value) / SUM(oid.price) * 100, 2)            AS freight_pct_of_gmv
FROM olist_order_items_dataset oid
INNER JOIN olist_orders_dataset od ON oid.order_id = od.order_id
WHERE od.order_status = 'delivered';


-- 10 Freight vs revenue summary
-- PBI use: Stacked bar — revenue vs freight side by side
SELECT
    ROUND(SUM(oid.price), 2)                                            AS revenue,
    ROUND(SUM(oid.freight_value), 2)                                    AS shipping_costs,
    ROUND(SUM(oid.freight_value) / SUM(oid.price) * 100, 2)            AS shipping_pct
FROM olist_order_items_dataset oid
INNER JOIN olist_orders_dataset od ON oid.order_id = od.order_id
WHERE od.order_status = 'delivered';


-- 11 Freight % by category
-- PBI use: Bar chart sorted by shipping_pct — highlights margin killers
SELECT
    pcnt.product_category_name_english                                  AS category,
    ROUND(SUM(oid.price), 2)                                            AS revenue,
    ROUND(SUM(oid.freight_value), 2)                                    AS freight,
    ROUND(SUM(oid.freight_value) / NULLIF(SUM(oid.price), 0) * 100, 2) AS freight_pct,
    COUNT(DISTINCT oid.order_id)                                        AS total_orders
FROM olist_order_items_dataset oid
INNER JOIN olist_products_dataset pd ON pd.product_id = oid.product_id
INNER JOIN product_category_name_translation pcnt
    ON pcnt.product_category_name = pd.product_category_name
GROUP BY pcnt.product_category_name_english
ORDER BY freight_pct DESC;


-- 12 Freight % by customer state
-- PBI use: Map or bar chart — shows geographic freight burden
SELECT
    cd.customer_state                                                   AS state,
    ROUND(SUM(oid.price), 2)                                            AS revenue,
    ROUND(SUM(oid.freight_value), 2)                                    AS freight,
    ROUND(SUM(oid.freight_value) / NULLIF(SUM(oid.price), 0) * 100, 2) AS freight_pct,
    COUNT(DISTINCT od.order_id)                                         AS total_orders
FROM olist_order_items_dataset oid
INNER JOIN olist_orders_dataset od ON oid.order_id = od.order_id
INNER JOIN olist_customers_dataset cd ON od.customer_id = cd.customer_id
WHERE od.order_status = 'delivered'
GROUP BY cd.customer_state
ORDER BY freight_pct DESC;


-- 13 Freight cost per order
-- PBI use: Distribution histogram or detailed table
SELECT
    oid.order_id,
    ROUND(SUM(oid.price), 2)                                            AS revenue,
    ROUND(SUM(oid.freight_value), 2)                                    AS freight,
    ROUND(SUM(oid.freight_value) / NULLIF(SUM(oid.price), 0) * 100, 2) AS freight_pct
FROM olist_order_items_dataset oid
GROUP BY oid.order_id
ORDER BY freight_pct DESC;


-- 14 Loss-making categories (freight > 30% of revenue)
-- PBI use: Highlight table or red-flagged bar chart
WITH CategoryFreight AS (
    SELECT
        pcnt.product_category_name_english                              AS category,
        ROUND(SUM(oid.price), 2)                                        AS revenue,
        ROUND(SUM(oid.freight_value), 2)                                AS freight,
        ROUND(SUM(oid.freight_value) / NULLIF(SUM(oid.price), 0) * 100, 2) AS freight_pct
    FROM olist_order_items_dataset oid
    INNER JOIN olist_products_dataset pd ON pd.product_id = oid.product_id
    INNER JOIN product_category_name_translation pcnt
        ON pcnt.product_category_name = pd.product_category_name
    GROUP BY pcnt.product_category_name_english
)
SELECT
    category,
    revenue,
    freight,
    freight_pct,
    CASE
        WHEN freight_pct >= 40 THEN 'critical'
        WHEN freight_pct >= 30 THEN 'at risk'
        ELSE 'acceptable'
    END AS risk_level
FROM CategoryFreight
WHERE freight_pct > 30
ORDER BY freight_pct DESC;


-- ============================================================
-- DOMAIN 3: DELIVERY & OPERATIONS
-- ============================================================

-- 15 & 16 On-time vs late delivery rate
-- PBI use: Donut chart — on_time vs late
SELECT
    delivery_status,
    COUNT(*)                                                            AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)                  AS pct_of_delivered
FROM (
    SELECT
        order_id,
        CASE
            WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'on_time'
            ELSE 'late'
        END AS delivery_status
    FROM olist_orders_dataset
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
) AS delivery_flags
GROUP BY delivery_status;


-- 17 Delivery time per order + summary
-- PBI use: Export both. Summary as KPI, detail as table for drill-through.

-- Detail level:
SELECT
    order_id,
    order_purchase_timestamp,
    order_estimated_delivery_date,
    order_delivered_customer_date,
    ROUND(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date), 0) AS days_to_deliver
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
ORDER BY days_to_deliver DESC;

-- Summary level:
SELECT
    ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)), 1) AS avg_days_to_deliver,
    MIN(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date))           AS min_days,
    MAX(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date))           AS max_days
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;


-- 18 Average delivery time by state
-- PBI use: Horizontal bar chart or map — sorted slowest to fastest
SELECT
    cd.customer_state                                                               AS state,
    COUNT(DISTINCT od.order_id)                                                     AS total_orders,
    ROUND(AVG(TIMESTAMPDIFF(DAY, od.order_purchase_timestamp,
        od.order_delivered_customer_date)), 1)                                      AS avg_days_to_deliver
FROM olist_orders_dataset od
INNER JOIN olist_customers_dataset cd ON od.customer_id = cd.customer_id
WHERE od.order_status = 'delivered'
  AND od.order_delivered_customer_date IS NOT NULL
GROUP BY cd.customer_state
ORDER BY avg_days_to_deliver DESC;


-- 19 Average days early vs late (signed)
-- PBI use: Two KPI cards side by side
SELECT
    ROUND(AVG(CASE
        WHEN order_delivered_customer_date < order_estimated_delivery_date
        THEN TIMESTAMPDIFF(DAY, order_delivered_customer_date, order_estimated_delivery_date)
    END), 1)                                                            AS avg_days_early,
    ROUND(AVG(CASE
        WHEN order_delivered_customer_date > order_estimated_delivery_date
        THEN TIMESTAMPDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date)
    END), 1)                                                            AS avg_days_late,
    COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 END) AS on_time_count,
    COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END)  AS late_count
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- 20 & 21 Delivery accuracy and dispatch time by seller
-- PBI use: Scatter plot — dispatch_days on X, late_rate on Y, bubble size = orders
SELECT
    oid.seller_id,
    COUNT(DISTINCT od.order_id)                                                     AS total_orders,
    ROUND(AVG(TIMESTAMPDIFF(DAY, od.order_purchase_timestamp,
        od.order_delivered_carrier_date)), 1)                                       AS avg_dispatch_days,
    ROUND(AVG(TIMESTAMPDIFF(DAY, od.order_purchase_timestamp,
        od.order_delivered_customer_date)), 1)                                      AS avg_delivery_days,
    ROUND(AVG(TIMESTAMPDIFF(DAY, od.order_estimated_delivery_date,
        od.order_delivered_customer_date)), 1)                                      AS avg_days_vs_estimate,
    ROUND(SUM(CASE WHEN od.order_delivered_customer_date > od.order_estimated_delivery_date
        THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT od.order_id), 1)               AS late_rate_pct
FROM olist_order_items_dataset oid
INNER JOIN olist_orders_dataset od ON od.order_id = oid.order_id
WHERE od.order_status = 'delivered'
  AND od.order_delivered_customer_date IS NOT NULL
GROUP BY oid.seller_id
ORDER BY late_rate_pct DESC;


-- 22 Orders by status breakdown
-- PBI use: Donut or bar chart
SELECT
    order_status,
    COUNT(order_id)                                                     AS total_orders,
    ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER(), 2)    AS pct_of_total
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY total_orders DESC;


-- ============================================================
-- DOMAIN 4: REVIEWS & SATISFACTION
-- ============================================================

-- 23 Overall average review score
-- PBI use: KPI card — "Avg customer rating"
SELECT
    ROUND(AVG(review_score), 2)                                         AS avg_review_score,
    COUNT(review_id)                                                    AS total_reviews,
    COUNT(CASE WHEN review_score = 5 THEN 1 END)                        AS five_star,
    COUNT(CASE WHEN review_score = 1 THEN 1 END)                        AS one_star
FROM olist_order_reviews_dataset;


-- 24 Review score distribution
-- PBI use: Bar chart — score on X, count/% on Y
SELECT
    review_score,
    COUNT(*)                                                            AS total_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)                  AS pct_of_total
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;


-- 25 Review score: on-time vs late delivery
-- PBI use: Grouped bar or KPI pair — clearest impact story in the whole dataset
SELECT
    delivery_status,
    COUNT(*)                                                            AS total_orders,
    ROUND(AVG(review_score), 2)                                         AS avg_review_score
FROM (
    SELECT
        rd.review_score,
        CASE
            WHEN od.order_delivered_customer_date <= od.order_estimated_delivery_date THEN 'on_time'
            ELSE 'late'
        END AS delivery_status
    FROM olist_order_reviews_dataset rd
    INNER JOIN olist_orders_dataset od ON od.order_id = rd.order_id
    WHERE od.order_status = 'delivered'
      AND od.order_delivered_customer_date IS NOT NULL
      AND od.order_estimated_delivery_date IS NOT NULL
) AS delivery_reviews
GROUP BY delivery_status;


-- 26 1-star reviews by category
-- PBI use: Bar chart — categories most in need of product/quality improvement
SELECT
    COALESCE(pcnt.product_category_name_english, 'uncategorised')       AS category,
    COUNT(rd.review_id)                                                 AS one_star_reviews
FROM olist_order_reviews_dataset rd
INNER JOIN olist_order_items_dataset oid ON rd.order_id = oid.order_id
INNER JOIN olist_products_dataset pd ON pd.product_id = oid.product_id
LEFT JOIN product_category_name_translation pcnt
    ON pcnt.product_category_name = pd.product_category_name
WHERE rd.review_score = 1
GROUP BY pcnt.product_category_name_english
ORDER BY one_star_reviews DESC;


-- 27 Average review score by seller
-- PBI use: Scatter plot — avg_score on X, revenue on Y
SELECT
    oid.seller_id,
    ROUND(AVG(rd.review_score), 2)                                      AS avg_review_score,
    COUNT(DISTINCT oid.order_id)                                        AS total_orders,
    ROUND(SUM(oid.price), 2)                                            AS revenue
FROM olist_order_items_dataset oid
LEFT JOIN olist_order_reviews_dataset rd ON rd.order_id = oid.order_id
GROUP BY oid.seller_id
ORDER BY avg_review_score DESC;


-- 28 Average review score by state
-- PBI use: Map or bar chart — regional satisfaction comparison
SELECT
    cd.customer_state                                                   AS state,
    ROUND(AVG(rd.review_score), 2)                                      AS avg_review_score,
    COUNT(rd.review_id)                                                 AS total_reviews
FROM olist_order_reviews_dataset rd
INNER JOIN olist_orders_dataset od ON rd.order_id = od.order_id
INNER JOIN olist_customers_dataset cd ON od.customer_id = cd.customer_id
GROUP BY cd.customer_state
ORDER BY avg_review_score ASC;


-- 29 High revenue, low-rated sellers (risk register)
-- PBI use: Highlight table with conditional formatting
SELECT
    oid.seller_id,
    ROUND(SUM(oid.price), 2)                                            AS revenue,
    ROUND(AVG(rd.review_score), 2)                                      AS avg_review_score,
    COUNT(DISTINCT oid.order_id)                                        AS total_orders
FROM olist_order_items_dataset oid
LEFT JOIN olist_order_reviews_dataset rd ON rd.order_id = oid.order_id
GROUP BY oid.seller_id
HAVING revenue > 15000
   AND avg_review_score < 3.0
ORDER BY revenue DESC;


-- 30 Review score trend over time
-- PBI use: Line chart — is satisfaction improving or declining?
SELECT
    DATE_FORMAT(od.order_purchase_timestamp, '%Y-%m')                   AS order_month,
    ROUND(AVG(rd.review_score), 2)                                      AS avg_review_score,
    COUNT(rd.review_id)                                                 AS total_reviews
FROM olist_order_reviews_dataset rd
INNER JOIN olist_orders_dataset od ON rd.order_id = od.order_id
WHERE od.order_purchase_timestamp IS NOT NULL
GROUP BY order_month
ORDER BY order_month;


-- ============================================================
-- DOMAIN 5: CUSTOMER BEHAVIOUR & RETENTION
-- ============================================================

-- 31 Repeat vs one-time buyer rate
-- PBI use: Donut chart — one-time vs repeat
WITH CustomerOrders AS (
    SELECT
        cd.customer_unique_id,
        COUNT(od.order_id)                                              AS total_orders
    FROM olist_customers_dataset cd
    LEFT JOIN olist_orders_dataset od ON od.customer_id = cd.customer_id
    GROUP BY cd.customer_unique_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'one_time_buyer'
        WHEN total_orders > 1 THEN 'repeat_buyer'
    END                                                                 AS customer_type,
    COUNT(*)                                                            AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)                  AS pct_of_total
FROM CustomerOrders
GROUP BY customer_type
ORDER BY customers DESC;


-- 32 Customer lifetime value (CLV)
-- PBI use: Top N table — highest value customers
SELECT
    cd.customer_unique_id,
    COUNT(DISTINCT od.order_id)                                         AS total_orders,
    ROUND(SUM(oid.price), 2)                                            AS item_revenue,
    ROUND(SUM(oid.freight_value), 2)                                    AS freight_paid,
    ROUND(SUM(oid.price + oid.freight_value), 2)                        AS total_clv,
    ROUND(SUM(oid.price + oid.freight_value)
        / NULLIF(COUNT(DISTINCT od.order_id), 0), 2)                   AS avg_order_value
FROM olist_customers_dataset cd
LEFT JOIN olist_orders_dataset od ON cd.customer_id = od.customer_id
LEFT JOIN olist_order_items_dataset oid ON od.order_id = oid.order_id
GROUP BY cd.customer_unique_id
ORDER BY total_clv DESC;


-- 33 Days between first and second order
-- PBI use: KPI card — "Avg repurchase window"
WITH OrderSequence AS (
    SELECT
        cd.customer_unique_id,
        od.order_purchase_timestamp,
        LEAD(od.order_purchase_timestamp) OVER (
            PARTITION BY cd.customer_unique_id
            ORDER BY od.order_purchase_timestamp
        )                                                               AS next_order_date,
        ROW_NUMBER() OVER (
            PARTITION BY cd.customer_unique_id
            ORDER BY od.order_purchase_timestamp
        )                                                               AS order_num
    FROM olist_orders_dataset od
    INNER JOIN olist_customers_dataset cd ON od.customer_id = cd.customer_id
    WHERE od.order_status = 'delivered'
)
SELECT
    ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, next_order_date)), 0) AS avg_days_to_repurchase,
    COUNT(*)                                                            AS repeat_customers_sampled
FROM OrderSequence
WHERE order_num = 1
  AND next_order_date IS NOT NULL;


-- 34 New customers per month (acquisition trend)
-- PBI use: Bar chart — monthly new customer volume
WITH FirstOrder AS (
    SELECT
        cd.customer_unique_id,
        MIN(od.order_purchase_timestamp)                                AS first_order_date
    FROM olist_customers_dataset cd
    INNER JOIN olist_orders_dataset od ON cd.customer_id = od.customer_id
    GROUP BY cd.customer_unique_id
)
SELECT
    DATE_FORMAT(first_order_date, '%Y-%m')                              AS cohort_month,
    COUNT(customer_unique_id)                                           AS new_customers
FROM FirstOrder
GROUP BY cohort_month
ORDER BY cohort_month;


-- 35 Top customers by total spend
-- PBI use: Top N bar chart or table
SELECT
    cd.customer_unique_id,
    cd.customer_state,
    COUNT(DISTINCT od.order_id)                                         AS total_orders,
    ROUND(SUM(oid.price + oid.freight_value), 2)                        AS total_spend
FROM olist_order_items_dataset oid
INNER JOIN olist_orders_dataset od ON oid.order_id = od.order_id
INNER JOIN olist_customers_dataset cd ON cd.customer_id = od.customer_id
GROUP BY cd.customer_unique_id, cd.customer_state
ORDER BY total_spend DESC
LIMIT 50;


-- 36 Customer distribution by state
-- PBI use: Map or bar chart — geographic customer spread
SELECT
    customer_state                                                      AS state,
    COUNT(DISTINCT customer_unique_id)                                  AS unique_customers
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY unique_customers DESC;


-- 37 Customers whose entire order history is 1-star
-- PBI use: KPI card — "At-risk churned customers"
WITH CustomerScores AS (
    SELECT
        cd.customer_unique_id,
        AVG(rd.review_score)                                            AS avg_score,
        MAX(rd.review_score)                                            AS max_score,
        COUNT(rd.review_id)                                             AS review_count
    FROM olist_customers_dataset cd
    INNER JOIN olist_orders_dataset od ON cd.customer_id = od.customer_id
    INNER JOIN olist_order_reviews_dataset rd ON od.order_id = rd.order_id
    GROUP BY cd.customer_unique_id
)
SELECT
    COUNT(*)                                                            AS customers_all_1star,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_unique_id)
        FROM olist_customers_dataset), 2)                              AS pct_of_total_customers
FROM CustomerScores
WHERE max_score = 1;


-- 38 Monthly cohort retention
-- PBI use: Cohort retention matrix table
WITH CustomerCohorts AS (
    SELECT
        cd.customer_unique_id,
        DATE_FORMAT(MIN(od.order_purchase_timestamp), '%Y-%m-01')       AS cohort_month
    FROM olist_customers_dataset cd
    INNER JOIN olist_orders_dataset od ON cd.customer_id = od.customer_id
    GROUP BY cd.customer_unique_id
),
CustomerActivity AS (
    SELECT DISTINCT
        cd.customer_unique_id,
        DATE_FORMAT(od.order_purchase_timestamp, '%Y-%m-01')            AS activity_month
    FROM olist_customers_dataset cd
    INNER JOIN olist_orders_dataset od ON cd.customer_id = od.customer_id
)
SELECT
    c.cohort_month,
    COUNT(DISTINCT c.customer_unique_id)                                AS new_customers,
    COUNT(DISTINCT a.customer_unique_id)                                AS returned_next_month,
    ROUND(COUNT(DISTINCT a.customer_unique_id) * 100.0
        / NULLIF(COUNT(DISTINCT c.customer_unique_id), 0), 2)          AS retention_rate_pct
FROM CustomerCohorts c
LEFT JOIN CustomerActivity a
    ON c.customer_unique_id = a.customer_unique_id
    AND a.activity_month = c.cohort_month + INTERVAL 1 MONTH
GROUP BY c.cohort_month
ORDER BY c.cohort_month;


-- ============================================================
-- DOMAIN 6: SELLER PERFORMANCE
-- ============================================================

-- 39 Top sellers by total revenue
-- PBI use: Bar chart — seller on Y, revenue on X
SELECT
    oid.seller_id,
    sd.seller_state,
    ROUND(SUM(oid.price), 2)                                            AS revenue,
    ROUND(SUM(oid.freight_value), 2)                                    AS freight_charged,
    COUNT(DISTINCT oid.order_id)                                        AS total_orders
FROM olist_order_items_dataset oid
INNER JOIN olist_sellers_dataset sd ON sd.seller_id = oid.seller_id
GROUP BY oid.seller_id, sd.seller_state
ORDER BY revenue DESC;


-- 40 Seller order volume
-- PBI use: Histogram — distribution of seller sizes
SELECT
    seller_id,
    COUNT(DISTINCT order_id)                                            AS total_orders
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY total_orders DESC;


-- 41 Seller cancellation rate
-- PBI use: Bar chart — sellers with highest cancellation %
WITH CanceledOrders AS (
    SELECT
        oid.seller_id,
        COUNT(DISTINCT CASE WHEN od.order_status = 'canceled' THEN od.order_id END) AS canceled_orders,
        COUNT(DISTINCT od.order_id)                                     AS total_orders
    FROM olist_order_items_dataset oid
    INNER JOIN olist_orders_dataset od ON oid.order_id = od.order_id
    GROUP BY oid.seller_id
)
SELECT
    seller_id,
    total_orders,
    canceled_orders,
    ROUND(canceled_orders * 100.0 / NULLIF(total_orders, 0), 2)        AS cancellation_rate_pct
FROM CanceledOrders
WHERE total_orders >= 10
ORDER BY cancellation_rate_pct DESC;


-- 42 Seller concentration by state
-- PBI use: Map or bar chart — supply-side geography
SELECT
    seller_state                                                        AS state,
    COUNT(DISTINCT seller_id)                                           AS total_sellers
FROM olist_sellers_dataset
GROUP BY seller_state
ORDER BY total_sellers DESC;


-- 43 Seller performance quadrant (score × revenue)
-- PBI use: Scatter plot — revenue on X, avg_score on Y, colour by quadrant
WITH SellerStats AS (
    SELECT
        oid.seller_id,
        ROUND(SUM(oid.price + oid.freight_value), 2)                    AS revenue,
        ROUND(AVG(rd.review_score), 2)                                  AS avg_score,
        COUNT(DISTINCT oid.order_id)                                    AS total_orders
    FROM olist_order_items_dataset oid
    LEFT JOIN olist_order_reviews_dataset rd ON rd.order_id = oid.order_id
    GROUP BY oid.seller_id
)
SELECT
    seller_id,
    revenue,
    avg_score,
    total_orders,
    CASE
        WHEN avg_score >= 4   AND revenue >= 5000 THEN 'star — high revenue, high rating'
        WHEN avg_score >= 4   AND revenue <  5000 THEN 'potential — low revenue, high rating'
        WHEN avg_score <  3   AND revenue >= 5000 THEN 'risk — high revenue, low rating'
        ELSE                                           'underperformer — low revenue, low rating'
    END                                                                 AS quadrant
FROM SellerStats
ORDER BY revenue DESC;


-- 44 Multi-category sellers (more than 3 categories)
-- PBI use: Table — identifies diversified sellers
SELECT
    oid.seller_id,
    COUNT(DISTINCT pcnt.product_category_name_english)                  AS total_categories
FROM olist_order_items_dataset oid
INNER JOIN olist_products_dataset pd ON pd.product_id = oid.product_id
LEFT JOIN product_category_name_translation pcnt
    ON pcnt.product_category_name = pd.product_category_name
GROUP BY oid.seller_id
HAVING total_categories > 3
ORDER BY total_categories DESC;


-- ============================================================
-- DOMAIN 7: PAYMENTS & FINANCE
-- ============================================================

-- 45 Payment method split
-- PBI use: Donut chart — payment type share
SELECT
    payment_type,
    COUNT(DISTINCT order_id)                                            AS total_orders,
    ROUND(COUNT(DISTINCT order_id) * 100.0
        / SUM(COUNT(DISTINCT order_id)) OVER(), 2)                     AS pct_of_orders
FROM olist_order_payments_dataset
WHERE payment_type != 'not_defined'
GROUP BY payment_type
ORDER BY total_orders DESC;


-- 46 Average installment count (credit card)
-- PBI use: KPI card — "Avg installments per credit card order"
SELECT
    payment_type,
    COUNT(DISTINCT order_id)                                            AS total_orders,
    ROUND(AVG(payment_installments), 1)                                 AS avg_installments,
    MAX(payment_installments)                                           AS max_installments
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card'
GROUP BY payment_type;


-- 47 High-installment orders (10+) — deferred revenue risk
-- PBI use: KPI card + distribution bar
SELECT
    payment_installments,
    COUNT(order_id)                                                     AS total_orders,
    ROUND(SUM(payment_value), 2)                                        AS total_value,
    ROUND(AVG(payment_value), 2)                                        AS avg_order_value
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card'
  AND payment_installments >= 10
GROUP BY payment_installments
ORDER BY payment_installments;


-- 48 Payment value vs order value (discount/voucher detection)
-- PBI use: Table with conditional formatting — flag "not_fully_paid" rows
WITH OrderItems AS (
    SELECT
        order_id,
        ROUND(SUM(price + freight_value), 2)                            AS total_order_value
    FROM olist_order_items_dataset
    GROUP BY order_id
),
OrderPayments AS (
    SELECT
        order_id,
        ROUND(SUM(payment_value), 2)                                    AS total_paid_value
    FROM olist_order_payments_dataset
    GROUP BY order_id
)
SELECT
    i.order_id,
    i.total_order_value,
    p.total_paid_value,
    ROUND(i.total_order_value - p.total_paid_value, 2)                  AS difference,
    CASE
        WHEN ABS(i.total_order_value - p.total_paid_value) < 0.01 THEN 'fully_paid'
        WHEN p.total_paid_value < i.total_order_value                THEN 'discount_or_voucher'
        ELSE 'overpaid'
    END                                                                 AS payment_status
FROM OrderItems i
LEFT JOIN OrderPayments p ON i.order_id = p.order_id
ORDER BY difference DESC;


-- 49 Voucher usage rate
-- PBI use: KPI card — "Voucher usage %"
SELECT
    COUNT(CASE WHEN payment_type = 'voucher' THEN order_id END)         AS voucher_orders,
    COUNT(DISTINCT order_id)                                            AS total_orders,
    ROUND(
        COUNT(CASE WHEN payment_type = 'voucher' THEN order_id END)
        * 100.0 / NULLIF(COUNT(DISTINCT order_id), 0)
    , 1)                                                                AS voucher_pct
FROM olist_order_payments_dataset;


-- 50 AOV by payment method
-- PBI use: Bar chart — payment method on Y, avg_order_value on X
SELECT
    payment_type,
    COUNT(DISTINCT order_id)                                            AS total_orders,
    ROUND(SUM(payment_value), 2)                                        AS total_revenue,
    ROUND(AVG(payment_value), 2)                                        AS avg_order_value
FROM olist_order_payments_dataset
WHERE payment_type != 'not_defined'
GROUP BY payment_type
ORDER BY avg_order_value DESC;
