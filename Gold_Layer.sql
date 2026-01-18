/*	=== Golden Layer ===	*/

/* 1) DIMENSIONS */

-- dim_customer
SELECT DISTINCT
    u.user_id,

    CASE
        WHEN u.age < 18 THEN 'Under 18'
        WHEN u.age BETWEEN 18 AND 25 THEN '18-25'
        WHEN u.age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_group,

    u.sex AS gender,
    u.country,

    CASE 
        WHEN l.loyalty_program_member = 1 THEN 'Yes'
        ELSE 'No'
    END AS loyalty_member,

    l.loyalty_tier
INTO gold.dim_customer
FROM silver.users u
LEFT JOIN silver.loyalty l
    ON u.user_id = l.user_id;

-- dim_date
SELECT DISTINCT
    CAST(p.payment_date AS DATE) AS date_id,
    YEAR(p.payment_date) AS year,
    MONTH(p.payment_date) AS month,
    DATENAME(MONTH, p.payment_date) AS month_name,
    DAY(p.payment_date) AS day,
    DATEPART(QUARTER, p.payment_date) AS quarter
INTO gold.dim_date
FROM silver.payments p;

-- dim_product
SELECT DISTINCT
    o.product_category,
    o.purchase_medium
INTO gold.dim_product
FROM silver.orders o;

-- dim_payment
SELECT DISTINCT
    p.payment_method,
    p.payment_status
INTO gold.dim_payment
FROM silver.payments p;

-- dim_shipping
SELECT DISTINCT
    s.shipping_method,
    s.shipping_cost,
    s.total_delivery_days AS delivery_days,
    s.estimated_vs_actual
INTO gold.dim_shipping
FROM silver.shipping s;


/* 2) FACT TABLE */

-- fact_sales
SELECT
    p.transaction_id,
    o.order_id,
    o.user_id,
    CAST(p.payment_date AS DATE) AS date_id,

    o.product_category,
    p.payment_method,
    s.shipping_method,

    o.total_purchase,
    o.total_discount,
    o.total_purchase_after_discount AS revenue,
    o.refund_amount,

    CASE 
        WHEN p.payment_status = 'Success' THEN 1
        ELSE 0
    END AS is_successful
INTO gold.fact_sales
FROM silver.orders o
JOIN silver.payments p ON o.order_id = p.order_id
LEFT JOIN silver.shipping s ON o.order_id = s.order_id;


/* 3) AGGREGATED TABLES */

-- agg_monthly_sales
SELECT
    d.year,
    d.month,
    SUM(f.revenue) AS total_revenue,
    COUNT(f.transaction_id) AS orders
INTO gold.agg_monthly_sales
FROM gold.fact_sales f
JOIN gold.dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month;

-- agg_customer_metrics
SELECT
    f.user_id,
    COUNT(f.transaction_id) AS total_orders,
    SUM(f.revenue) AS lifetime_value,
    AVG(f.revenue) AS avg_order_value
INTO gold.agg_customer_metrics
FROM gold.fact_sales f
GROUP BY f.user_id;