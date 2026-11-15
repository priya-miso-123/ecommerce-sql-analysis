
-- Step 1: Profile record counts, missing values, blank text fields, and review-score validity.

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE review_id IS NULL
    ) AS null_review_id,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS null_order_id,

    COUNT(*) FILTER (
        WHERE review_score IS NULL
    ) AS null_review_score,

    COUNT(*) FILTER (
        WHERE review_comment_title IS NULL
    ) AS null_comment_title,

    COUNT(*) FILTER (
        WHERE review_comment_message IS NULL
    ) AS null_comment_message,

    COUNT(*) FILTER (
        WHERE review_creation_date IS NULL
    ) AS null_creation_date,

    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NULL
    ) AS null_answer_timestamp,

    COUNT(*) FILTER (
        WHERE BTRIM(review_comment_title) = ''
    ) AS blank_comment_titles,

    COUNT(*) FILTER (
        WHERE BTRIM(review_comment_message) = ''
    ) AS blank_comment_messages,

    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
    ) AS invalid_review_scores

FROM public.olist_order_reviews_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 2: Identify review IDs associated with multiple records.

SELECT
    review_id,
    COUNT(*) AS record_count,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM public.olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC, review_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 3: Summarize review ID frequency across the dataset.

SELECT
    record_count,
    COUNT(*) AS review_id_count
FROM (
    SELECT
        review_id,
        COUNT(*) AS record_count
    FROM public.olist_order_reviews_dataset
    GROUP BY review_id
) AS review_frequency
GROUP BY record_count
ORDER BY record_count;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 4: Compare review contents for review IDs that occur multiple times.

SELECT
    review_id,
    COUNT(*) AS record_count,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT review_score) AS distinct_scores,
    COUNT(DISTINCT review_comment_title) AS distinct_titles,
    COUNT(DISTINCT review_comment_message) AS distinct_messages,
    COUNT(DISTINCT review_creation_date) AS distinct_creation_dates,
    COUNT(DISTINCT review_answer_timestamp) AS distinct_answer_timestamps
FROM public.olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC, review_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 5: Inspect individual records associated with repeated review IDs.

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM public.olist_order_reviews_dataset
WHERE review_id IN (
    SELECT review_id
    FROM public.olist_order_reviews_dataset
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
ORDER BY review_id, order_id
LIMIT 30;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 6: Identify orders associated with multiple review records.

SELECT
    order_id,
    COUNT(*) AS review_records,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(DISTINCT review_score) AS distinct_review_scores
FROM public.olist_order_reviews_dataset
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_records DESC, order_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 7: Inspect all review records for orders with multiple reviews.

SELECT
    order_id,
    review_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM public.olist_order_reviews_dataset
WHERE order_id IN (
    SELECT order_id
    FROM public.olist_order_reviews_dataset
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
ORDER BY order_id, review_creation_date, review_answer_timestamp
LIMIT 30;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 8: Identify exact duplicate review records across all columns.

-- Step 8: Identify exact duplicate review records across all columns.

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    COUNT(*) AS duplicate_count
FROM public.olist_order_reviews_dataset
GROUP BY
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 9: Analyze review score distribution and percentage.

SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM public.olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 10: Inspect blank or whitespace-only review titles and messages.

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    LENGTH(review_comment_title) AS title_length,
    LENGTH(review_comment_message) AS message_length
FROM public.olist_order_reviews_dataset
WHERE
    (
        review_comment_title IS NOT NULL
        AND BTRIM(review_comment_title) = ''
    )
    OR
    (
        review_comment_message IS NOT NULL
        AND BTRIM(review_comment_message) = ''
    )
ORDER BY review_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 11: Identify review records with answer timestamps before creation dates.

SELECT
    review_id,
    order_id,
    review_score,
    review_creation_date,
    review_answer_timestamp
FROM public.olist_order_reviews_dataset
WHERE review_answer_timestamp::timestamp < review_creation_date::timestamp
ORDER BY review_creation_date;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 12: Identify review records without a matching order.

SELECT
    r.review_id,
    r.order_id,
    r.review_score
FROM public.olist_order_reviews_dataset AS r
LEFT JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL
ORDER BY r.order_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 13: Identify reviews created before their corresponding order purchase dates.

SELECT
    r.review_id,
    r.order_id,
    o.order_purchase_timestamp,
    r.review_creation_date,
    r.review_answer_timestamp
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
WHERE r.review_creation_date::timestamp < o.order_purchase_timestamp::timestamp
ORDER BY r.review_creation_date;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 14: Quantify reviews created before order purchase, including the time difference.

SELECT
    COUNT(*) AS affected_review_records,
    COUNT(DISTINCT r.order_id) AS affected_orders,
    MIN(o.order_purchase_timestamp - r.review_creation_date::timestamp)
        AS minimum_time_difference,
    MAX(o.order_purchase_timestamp - r.review_creation_date::timestamp)
        AS maximum_time_difference
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
WHERE r.review_creation_date::timestamp < o.order_purchase_timestamp::timestamp;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 15: Separate reviews dated before the purchase calendar date from same-day timestamp differences.

SELECT
    COUNT(*) FILTER (
        WHERE r.review_creation_date::date < o.order_purchase_timestamp::date
    ) AS reviews_before_purchase_date,
    COUNT(*) FILTER (
        WHERE r.review_creation_date::date = o.order_purchase_timestamp::date
    ) AS reviews_on_same_purchase_date,
    COUNT(*) FILTER (
        WHERE r.review_creation_date::date > o.order_purchase_timestamp::date
    ) AS reviews_after_purchase_date
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 16: Check whether reviews dated before purchase are also dated before order delivery.

SELECT
    COUNT(*) AS affected_review_records,
    COUNT(*) FILTER (
        WHERE o.order_delivered_customer_date IS NULL
    ) AS orders_without_delivery_date,
    COUNT(*) FILTER (
        WHERE r.review_creation_date::date < o.order_delivered_customer_date::date
    ) AS reviews_before_delivery_date,
    COUNT(*) FILTER (
        WHERE r.review_creation_date::date = o.order_delivered_customer_date::date
    ) AS reviews_on_delivery_date,
    COUNT(*) FILTER (
        WHERE r.review_creation_date::date > o.order_delivered_customer_date::date
    ) AS reviews_after_delivery_date
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
WHERE r.review_creation_date::date < o.order_purchase_timestamp::date;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 17: Inspect the six reviews dated before both purchase and delivery.

SELECT
    r.review_id,
    r.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
WHERE r.review_creation_date::date < o.order_purchase_timestamp::date
  AND r.review_creation_date::date < o.order_delivered_customer_date::date
ORDER BY r.review_creation_date;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 18: Determine how many reviews dated before purchase also have answer timestamps before purchase.

SELECT
    COUNT(*) AS reviews_before_purchase_date,
    COUNT(*) FILTER (
        WHERE r.review_answer_timestamp::timestamp < o.order_purchase_timestamp::timestamp
    ) AS answers_before_purchase,
    COUNT(*) FILTER (
        WHERE r.review_answer_timestamp::timestamp >= o.order_purchase_timestamp::timestamp
    ) AS answers_on_or_after_purchase,
    COUNT(*) FILTER (
        WHERE r.review_answer_timestamp IS NULL
    ) AS missing_review_answers
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
WHERE r.review_creation_date::date < o.order_purchase_timestamp::date;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 19: Examine the order-status distribution of reviews dated before purchase.

SELECT
    o.order_status,
    COUNT(*) AS affected_review_records
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
WHERE r.review_creation_date::date < o.order_purchase_timestamp::date
GROUP BY o.order_status
ORDER BY affected_review_records DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 20: Inspect reviews associated with canceled orders that have creation dates before purchase.

SELECT
    r.review_id,
    r.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
WHERE r.review_creation_date::date < o.order_purchase_timestamp::date
  AND o.order_status = 'canceled'
ORDER BY r.review_creation_date;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 21: Check whether canceled orders with premature reviews have associated order items.

SELECT
    COUNT(DISTINCT o.order_id) AS affected_canceled_orders,
    COUNT(DISTINCT oi.order_id) AS orders_with_order_items,
    COUNT(DISTINCT o.order_id) FILTER (
        WHERE oi.order_id IS NULL
    ) AS orders_without_order_items,
    COUNT(oi.order_item_id) AS total_order_item_records
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
LEFT JOIN public.olist_order_items_dataset AS oi
    ON o.order_id = oi.order_id
WHERE r.review_creation_date::date < o.order_purchase_timestamp::date
  AND o.order_status = 'canceled';

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 22: Inspect the only canceled order with a premature review and an associated order item.

SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    r.review_id,
    r.review_creation_date,
    r.review_answer_timestamp,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value
FROM public.olist_order_reviews_dataset AS r
JOIN public.olist_orders_dataset AS o
    ON r.order_id = o.order_id
JOIN public.olist_order_items_dataset AS oi
    ON o.order_id = oi.order_id
WHERE r.review_creation_date::date < o.order_purchase_timestamp::date
  AND o.order_status = 'canceled'
ORDER BY o.order_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 23: Check whether review creation dates fall outside the order purchase date range.

SELECT
    (SELECT MIN(order_purchase_timestamp::date)
     FROM public.olist_orders_dataset) AS earliest_purchase_date,
    (SELECT MAX(order_purchase_timestamp::date)
     FROM public.olist_orders_dataset) AS latest_purchase_date,
    MIN(review_creation_date::date) AS earliest_review_date,
    MAX(review_creation_date::date) AS latest_review_date,
    COUNT(*) FILTER (
        WHERE review_creation_date::date < (
            SELECT MIN(order_purchase_timestamp::date)
            FROM public.olist_orders_dataset
        )
    ) AS reviews_before_dataset_period,
    COUNT(*) FILTER (
        WHERE review_creation_date::date > (
            SELECT MAX(order_purchase_timestamp::date)
            FROM public.olist_orders_dataset
        )
    ) AS reviews_after_dataset_period
FROM public.olist_order_reviews_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 24: Create a cleaned view by converting whitespace-only comments to NULL while preserving all other values.

CREATE OR REPLACE VIEW public.olist_order_reviews_cleaned AS
SELECT
    review_id,
    order_id,
    review_score,
    CASE
        WHEN BTRIM(review_comment_title) = '' THEN NULL
        ELSE review_comment_title
    END AS review_comment_title,
    CASE
        WHEN BTRIM(review_comment_message) = '' THEN NULL
        ELSE review_comment_message
    END AS review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM public.olist_order_reviews_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 25: Verify that the cleaned view retains all source review records.

SELECT
    (SELECT COUNT(*)
     FROM public.olist_order_reviews_dataset) AS source_records,
    (SELECT COUNT(*)
     FROM public.olist_order_reviews_cleaned) AS cleaned_records;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 26: Confirm that no whitespace-only comment titles or messages remain in the cleaned view.

SELECT
    COUNT(*) FILTER (
        WHERE BTRIM(review_comment_title) = ''
    ) AS blank_comment_titles,
    COUNT(*) FILTER (
        WHERE BTRIM(review_comment_message) = ''
    ) AS blank_comment_messages
FROM public.olist_order_reviews_cleaned;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 27: Compare the cleaned view against the expected source data in both directions.

(
    SELECT
        review_id,
        order_id,
        review_score,
        CASE
            WHEN BTRIM(review_comment_title) = '' THEN NULL
            ELSE review_comment_title
        END AS review_comment_title,
        CASE
            WHEN BTRIM(review_comment_message) = '' THEN NULL
            ELSE review_comment_message
        END AS review_comment_message,
        review_creation_date,
        review_answer_timestamp
    FROM public.olist_order_reviews_dataset

    EXCEPT ALL

    SELECT *
    FROM public.olist_order_reviews_cleaned
)

UNION ALL

(
    SELECT *
    FROM public.olist_order_reviews_cleaned

    EXCEPT ALL

    SELECT
        review_id,
        order_id,
        review_score,
        CASE
            WHEN BTRIM(review_comment_title) = '' THEN NULL
            ELSE review_comment_title
        END AS review_comment_title,
        CASE
            WHEN BTRIM(review_comment_message) = '' THEN NULL
            ELSE review_comment_message
        END AS review_comment_message,
        review_creation_date,
        review_answer_timestamp
    FROM public.olist_order_reviews_dataset
);

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
