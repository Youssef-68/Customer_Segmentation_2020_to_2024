/*	=== Bronze Layer ===	*/

-- Load Data as a bronze layer
SELECT *
INTO bronze.user_transactions
FROM dbo.Customer_Segmentation_Cleaned;

-- Add Metadata
ALTER TABLE bronze.user_transactions
ADD
    ingestion_time DATETIME DEFAULT GETDATE(),
    has_nulls BIT,
    is_duplicated BIT;

-- Find Nulls
UPDATE bronze.user_transactions
SET has_nulls =
    CASE
        WHEN user_id IS NULL
          OR order_id IS NULL
          OR purchased_date IS NULL
        THEN 1
        ELSE 0
    END;

-- Find Duplicates
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id, order_id
               ORDER BY ingestion_time
           ) AS rn
    FROM bronze.user_transactions
)
UPDATE cte
SET is_duplicated = CASE WHEN rn > 1 THEN 1 ELSE 0 END;
