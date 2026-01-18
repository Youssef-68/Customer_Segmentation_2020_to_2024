-- Demographics Analysis
SELECT
    c.age_group,
    c.gender,
    c.country,
    COUNT(DISTINCT f.user_id) AS customers_count
FROM [gold].[fact_sales] f
JOIN [gold].[dim_customer] c ON f.user_id = c.user_id
GROUP BY c.age_group, c.gender, c.country;

-- Loyalty Program Analysis
SELECT
    c.loyalty_tier,
    COUNT(DISTINCT f.user_id) AS users_count,
    SUM(f.revenue) AS total_revenue
FROM [gold].[fact_sales] f
JOIN [gold].[dim_customer] c ON f.user_id = c.user_id
WHERE c.loyalty_member = 'Yes'
GROUP BY c.loyalty_tier;

-- Behavior Analysis
SELECT
    p.product_category,
    p.purchase_medium,
    COUNT(*) AS transactions,
    SUM(f.revenue) AS revenue
FROM [gold].[fact_sales] f
JOIN [gold].[dim_product] p ON f.product_category = p.product_category
GROUP BY p.product_category, p.purchase_medium;

-- Logistics & Delivery Analysis
SELECT
    s.shipping_method,
    AVG(CAST(s.delivery_days AS BIGINT)) AS avg_delivery_days,
    AVG(CAST(s.shipping_cost AS DECIMAL(18,2))) AS avg_shipping_cost
FROM [gold].[fact_sales] f
JOIN [gold].[dim_shipping] s ON f.shipping_method = s.shipping_method
GROUP BY s.shipping_method;


-- Payment Performance by Date
SELECT
    d.year,
    d.quarter,
    d.month_name,
    p.payment_method,
    COUNT(DISTINCT f.transaction_id) AS transaction_count,
    SUM(f.revenue) AS net_sales,
    AVG(f.total_purchase) AS avg_transaction_value
FROM [gold].[fact_sales] f
JOIN [gold].[dim_payment] p ON f.payment_method = p.payment_method
JOIN [gold].[dim_date] d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter, d.month_name, p.payment_method
ORDER BY d.year DESC, d.quarter DESC, net_sales DESC;

-- Payment Success/Failure Analysis
SELECT
    d.year,
    d.quarter,
    p.payment_method,
    p.payment_status,
    COUNT(DISTINCT f.transaction_id) AS transaction_count,
    COUNT(DISTINCT f.order_id) AS order_count,
    SUM(f.total_purchase) AS gross_sales,
    SUM(f.revenue) AS net_sales,
    ROUND(SUM(CASE WHEN f.is_successful = 1 THEN 1 ELSE 0 END) * 100.0 / 
          COUNT(*), 2) AS payment_success_rate_percent
FROM [gold].[fact_sales] f
JOIN [gold].[dim_payment] p ON f.payment_method = p.payment_method
JOIN [gold].[dim_date] d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter, p.payment_method, p.payment_status
ORDER BY d.year DESC, d.quarter DESC, transaction_count DESC;

-- Business Performance Metrics
SELECT
    d.year,
    d.month_name,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(DISTINCT f.user_id) AS unique_customers,
    SUM(f.revenue) AS total_revenue,
    SUM(f.total_purchase) AS gross_sales,
    ROUND(AVG(f.revenue), 2) AS avg_order_value
FROM [gold].[fact_sales] f
JOIN [gold].[dim_date] d ON f.date_id = d.date_id
GROUP BY d.year, d.month_name
ORDER BY d.year DESC, d.month_name;

-- Quarterly Business KPIs
SELECT
    d.year,
    d.quarter,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(DISTINCT f.user_id) AS unique_customers,
    SUM(f.revenue) AS total_revenue,
    SUM(f.total_discount) AS total_discounts,
    SUM(f.refund_amount) AS total_refunds,
    ROUND(SUM(f.revenue) / NULLIF(COUNT(DISTINCT f.user_id), 0), 2) AS revenue_per_customer,
    ROUND(SUM(f.total_discount) * 100.0 / NULLIF(SUM(f.total_purchase), 0), 2) AS discount_rate_percent,
    ROUND(SUM(f.refund_amount) * 100.0 / NULLIF(SUM(f.total_purchase), 0), 2) AS refund_rate_percent
FROM [gold].[fact_sales] f
JOIN [gold].[dim_date] d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter
ORDER BY d.year DESC, d.quarter DESC;

-- Transaction Success Rate Analysis
SELECT
    d.year,
    d.quarter,
    d.month_name,
    SUM(CASE WHEN f.is_successful = 1 THEN 1 ELSE 0 END) AS successful_transactions,
    SUM(CASE WHEN f.is_successful = 0 THEN 1 ELSE 0 END) AS failed_transactions,
    COUNT(*) AS total_transactions,
    ROUND(SUM(CASE WHEN f.is_successful = 1 THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(COUNT(*), 0), 2) AS success_rate_percent
FROM [gold].[fact_sales] f
JOIN [gold].[dim_date] d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter, d.month_name
ORDER BY d.year DESC, d.quarter DESC, success_rate_percent DESC;

-- Monthly Revenue Growth Analysis
WITH monthly_revenue AS (
    SELECT
        d.year,
        d.month_name,
        SUM(f.revenue) AS monthly_revenue,
        LAG(SUM(f.revenue)) OVER (ORDER BY d.year, MIN(d.date_id)) AS previous_month_revenue
    FROM [gold].[fact_sales] f
    JOIN [gold].[dim_date] d ON f.date_id = d.date_id
    GROUP BY d.year, d.month_name
)
SELECT
    year,
    month_name,
    monthly_revenue,
    previous_month_revenue,
    monthly_revenue - previous_month_revenue AS revenue_change,
    ROUND((monthly_revenue - previous_month_revenue) * 100.0 / 
          NULLIF(previous_month_revenue, 0), 2) AS growth_rate_percent
FROM monthly_revenue
ORDER BY year DESC, month_name;

-- Customer Activity and Engagement
SELECT
    d.year,
    d.quarter,
    COUNT(DISTINCT f.user_id) AS active_customers,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(COUNT(DISTINCT f.order_id) * 1.0 / 
          NULLIF(COUNT(DISTINCT f.user_id), 0), 2) AS avg_orders_per_customer,
    SUM(f.revenue) AS total_revenue,
    ROUND(SUM(f.revenue) / NULLIF(COUNT(DISTINCT f.user_id), 0), 2) AS avg_revenue_per_customer
FROM [gold].[fact_sales] f
JOIN [gold].[dim_date] d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter
ORDER BY d.year DESC, d.quarter DESC;

-- Payment Method Trends Over Time
SELECT
    d.year,
    d.quarter,
    p.payment_method,
    COUNT(DISTINCT f.transaction_id) AS transaction_count,
    SUM(f.revenue) AS total_revenue,
    ROUND(SUM(f.revenue) * 100.0 / 
          SUM(SUM(f.revenue)) OVER (PARTITION BY d.year, d.quarter), 2) AS revenue_share_percent
FROM [gold].[fact_sales] f
JOIN [gold].[dim_payment] p ON f.payment_method = p.payment_method
JOIN [gold].[dim_date] d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter, p.payment_method
ORDER BY d.year DESC, d.quarter DESC, total_revenue DESC;