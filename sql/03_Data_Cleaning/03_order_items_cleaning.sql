
-- Step 1: Establish the baseline data quality profile of the order items table

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT seller_id) AS unique_sellers,

    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS missing_order_item_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS missing_seller_id,
    COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS missing_shipping_date,
    COUNT(*) FILTER (WHERE price IS NULL) AS missing_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS missing_freight_value,

    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price,

    MIN(freight_value) AS minimum_freight,
    MAX(freight_value) AS maximum_freight

FROM olist_order_items_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------


-- Step 2: Check whether the order_id and order_item_id combination is unique

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT (order_id, order_item_id)) AS unique_order_item_combinations,
    COUNT(*) - COUNT(DISTINCT (order_id, order_item_id))
        AS duplicate_key_records
FROM olist_order_items_dataset;


---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 3: Identify repeated product combinations within the same order

SELECT
    order_id,
    product_id,
    COUNT(*) AS item_record_count,
    COUNT(DISTINCT seller_id) AS distinct_sellers,
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price,
    MIN(freight_value) AS minimum_freight,
    MAX(freight_value) AS maximum_freight
FROM olist_order_items_dataset
GROUP BY
    order_id,
    product_id
HAVING COUNT(*) > 1
ORDER BY item_record_count DESC, order_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 4: Summarize repeated order-product combinations by item count

WITH repeated_combinations AS (
    SELECT
        order_id,
        product_id,
        COUNT(*) AS item_record_count
    FROM olist_order_items_dataset
    GROUP BY
        order_id,
        product_id
    HAVING COUNT(*) > 1
)
SELECT
    item_record_count,
    COUNT(*) AS repeated_combinations
FROM repeated_combinations
GROUP BY item_record_count
ORDER BY item_record_count;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 5: Identify repeated order-product combinations with inconsistent values

SELECT
    order_id,
    product_id,
    COUNT(*) AS item_record_count,
    COUNT(DISTINCT seller_id) AS distinct_sellers,
    COUNT(DISTINCT price) AS distinct_prices,
    COUNT(DISTINCT freight_value) AS distinct_freight_values
FROM olist_order_items_dataset
GROUP BY
    order_id,
    product_id
HAVING
    COUNT(*) > 1
    AND (
        COUNT(DISTINCT seller_id) > 1
        OR COUNT(DISTINCT price) > 1
        OR COUNT(DISTINCT freight_value) > 1
    )
ORDER BY item_record_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 6: Examine order-item records with zero freight value

SELECT
    COUNT(*) AS zero_freight_records,
    COUNT(DISTINCT order_id) AS affected_orders,
    COUNT(DISTINCT product_id) AS affected_products,
    COUNT(DISTINCT seller_id) AS affected_sellers,
    MIN(price) AS minimum_product_price,
    MAX(price) AS maximum_product_price
FROM olist_order_items_dataset
WHERE freight_value = 0;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 7: Analyze zero-freight records by seller

SELECT
    seller_id,
    COUNT(*) AS zero_freight_items,
    COUNT(DISTINCT order_id) AS affected_orders,
    COUNT(DISTINCT product_id) AS affected_products,
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price
FROM olist_order_items_dataset
WHERE freight_value = 0
GROUP BY seller_id
ORDER BY zero_freight_items DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 8: Analyze zero-freight records by order status

SELECT
    o.order_status,
    COUNT(*) AS zero_freight_items,
    COUNT(DISTINCT oi.order_id) AS affected_orders,
    COUNT(DISTINCT oi.seller_id) AS affected_sellers,
    COUNT(DISTINCT oi.product_id) AS affected_products
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE oi.freight_value = 0
GROUP BY o.order_status
ORDER BY zero_freight_items DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 9: Compare product price distributions for zero- and non-zero-freight items

SELECT
    CASE
        WHEN freight_value = 0 THEN 'Zero freight'
        ELSE 'Non-zero freight'
    END AS freight_category,
    COUNT(*) AS total_items,
    ROUND(AVG(price)::numeric, 2) AS average_product_price,
    ROUND(MIN(price)::numeric, 2) AS minimum_product_price,
    ROUND(MAX(price)::numeric, 2) AS maximum_product_price,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::numeric, 2)
        AS median_product_price
FROM olist_order_items_dataset
GROUP BY
    CASE
        WHEN freight_value = 0 THEN 'Zero freight'
        ELSE 'Non-zero freight'
    END
ORDER BY freight_category;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 10: Analyze zero-freight item records by order purchase month

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS purchase_month,
    COUNT(*) AS zero_freight_items,
    COUNT(DISTINCT oi.order_id) AS affected_orders,
    COUNT(DISTINCT oi.seller_id) AS affected_sellers,
    COUNT(DISTINCT oi.product_id) AS affected_products
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE oi.freight_value = 0
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY purchase_month;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 11: Analyze zero-freight records by seller and purchase month

SELECT
    oi.seller_id,
    DATE_TRUNC('month', o.order_purchase_timestamp) AS purchase_month,
    COUNT(*) AS zero_freight_items,
    COUNT(DISTINCT oi.order_id) AS affected_orders,
    COUNT(DISTINCT oi.product_id) AS affected_products
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE oi.freight_value = 0
GROUP BY
    oi.seller_id,
    DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY
    purchase_month,
    zero_freight_items DESC;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 12: Compare freight values for products with zero-freight records across all orders

WITH zero_freight_products AS (
    SELECT DISTINCT product_id
    FROM olist_order_items_dataset
    WHERE freight_value = 0
)
SELECT
    oi.product_id,
    COUNT(*) AS total_item_records,
    COUNT(*) FILTER (WHERE oi.freight_value = 0) AS zero_freight_records,
    COUNT(*) FILTER (WHERE oi.freight_value > 0) AS non_zero_freight_records,
    COUNT(DISTINCT oi.seller_id) AS distinct_sellers,
    MIN(oi.freight_value) AS minimum_freight,
    MAX(oi.freight_value) AS maximum_freight
FROM olist_order_items_dataset oi
JOIN zero_freight_products zfp
    ON oi.product_id = zfp.product_id
GROUP BY oi.product_id
ORDER BY zero_freight_records DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 13: Compare freight values by product and seller for zero-freight products

SELECT
    product_id,
    seller_id,
    COUNT(*) AS total_item_records,
    COUNT(*) FILTER (WHERE freight_value = 0) AS zero_freight_records,
    COUNT(*) FILTER (WHERE freight_value > 0) AS non_zero_freight_records,
    MIN(freight_value) AS minimum_freight,
    MAX(freight_value) AS maximum_freight
FROM olist_order_items_dataset
WHERE product_id IN (
    SELECT DISTINCT product_id
    FROM olist_order_items_dataset
    WHERE freight_value = 0
)
GROUP BY product_id, seller_id
ORDER BY product_id, seller_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 14: Identify order items with shipping-limit dates before purchase dates

SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    o.order_purchase_timestamp,
    oi.shipping_limit_date,
    oi.shipping_limit_date - o.order_purchase_timestamp
        AS time_difference
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE oi.shipping_limit_date < o.order_purchase_timestamp
ORDER BY time_difference;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 15: Identify repeated order-product combinations with different shipping-limit dates

SELECT
    order_id,
    product_id,
    COUNT(*) AS item_record_count,
    COUNT(DISTINCT shipping_limit_date) AS distinct_shipping_dates,
    MIN(shipping_limit_date) AS earliest_shipping_limit,
    MAX(shipping_limit_date) AS latest_shipping_limit
FROM olist_order_items_dataset
GROUP BY order_id, product_id
HAVING
    COUNT(*) > 1
    AND COUNT(DISTINCT shipping_limit_date) > 1
ORDER BY item_record_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 16: Identify orders with missing or discontinuous order-item sequences

WITH item_sequence AS (
    SELECT
        order_id,
        COUNT(*) AS total_items,
        MIN(order_item_id) AS minimum_item_id,
        MAX(order_item_id) AS maximum_item_id,
        COUNT(DISTINCT order_item_id) AS distinct_item_ids
    FROM olist_order_items_dataset
    GROUP BY order_id
)
SELECT
    order_id,
    total_items,
    minimum_item_id,
    maximum_item_id,
    distinct_item_ids
FROM item_sequence
WHERE
    minimum_item_id <> 1
    OR maximum_item_id <> total_items
    OR distinct_item_ids <> total_items
ORDER BY order_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 17: Identify order-item records referencing missing orders

SELECT
    COUNT(*) AS orphaned_item_records,
    COUNT(DISTINCT oi.order_id) AS affected_orders
FROM olist_order_items_dataset oi
LEFT JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 18: Identify order-item records referencing missing products

SELECT
    COUNT(*) AS orphaned_item_records,
    COUNT(DISTINCT oi.product_id) AS missing_products
FROM olist_order_items_dataset oi
LEFT JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 19: Identify order-item records referencing missing sellers

SELECT
    COUNT(*) AS orphaned_item_records,
    COUNT(DISTINCT oi.seller_id) AS missing_sellers
FROM olist_order_items_dataset oi
LEFT JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 20: Create a cleaned view of the order-items table

CREATE OR REPLACE VIEW public.olist_order_items_cleaned AS
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM public.olist_order_items_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 21: Compare source and cleaned-view record counts

SELECT
    (SELECT COUNT(*)
     FROM public.olist_order_items_dataset) AS source_records,

    (SELECT COUNT(*)
     FROM public.olist_order_items_cleaned) AS cleaned_view_records,

    (SELECT COUNT(*)
     FROM public.olist_order_items_dataset)
    -
    (SELECT COUNT(*)
     FROM public.olist_order_items_cleaned) AS record_count_difference;
	 
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 22: Compare source and cleaned-view records across all columns

SELECT
    COUNT(*) AS mismatched_records
FROM public.olist_order_items_dataset s
JOIN public.olist_order_items_cleaned c
    ON s.order_id = c.order_id
    AND s.order_item_id = c.order_item_id
WHERE
    s.product_id IS DISTINCT FROM c.product_id
    OR s.seller_id IS DISTINCT FROM c.seller_id
    OR s.shipping_limit_date IS DISTINCT FROM c.shipping_limit_date
    OR s.price IS DISTINCT FROM c.price
    OR s.freight_value IS DISTINCT FROM c.freight_value;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
