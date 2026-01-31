/*	=== Silver Layer ===	*/

-- Remove Duplicates
SELECT *
INTO silver.clean_user_transactions
FROM bronze.user_transactions
WHERE is_duplicated = 0;

-- Remove Nulls
UPDATE silver.clean_user_transactions
SET refund_amount = 0
WHERE refund_amount IS NULL;

-- create users table
SELECT DISTINCT
    user_id,
    age,
    sex,
    phone_number,
    country,
    joined_date
INTO silver.users
FROM bronze.user_transactions;

-- create orders table
SELECT
    order_id,
    user_id,
    product_category,
    purchase_medium,
    purchased_date,
    total_purchase,
    total_discount,
    total_purchase_after_discount,
    return_status,
    refund_amount
INTO silver.orders
FROM bronze.user_transactions;

-- create payments table
SELECT
    transaction_id,
    order_id,
    payment_method,
    payment_status,
    payment_date
INTO silver.payments
FROM bronze.user_transactions;

-- create shipping table
SELECT
    order_id,
    shipping_method,
    shipping_cost,
    total_delivery_days,
    estimated_vs_actual
INTO silver.shipping
FROM bronze.user_transactions;

-- create loyalty table
SELECT
    user_id,
    loyalty_program_member,
    loyalty_tier,
    loyalty_points_redeemed,
    total_discount_percentage
INTO silver.loyalty
FROM bronze.user_transactions;
