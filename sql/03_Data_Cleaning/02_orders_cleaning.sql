
-- Step 1: Identify missing order timestamps across different order statuses

SELECT
    order_status,
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval_timestamp,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_timestamp,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_customer_delivery_timestamp

FROM olist_orders_dataset

GROUP BY order_status

ORDER BY total_orders DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 2: Retrieve delivered orders with one or more missing lifecycle timestamps

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date

FROM olist_orders_dataset

WHERE order_status = 'delivered'
  AND (
      order_approved_at IS NULL
      OR order_delivered_carrier_date IS NULL
      OR order_delivered_customer_date IS NULL
  )

ORDER BY order_purchase_timestamp;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 3: Identify orders with chronological inconsistencies between available lifecycle timestamps

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,

    CASE
        WHEN order_approved_at::timestamp < order_purchase_timestamp
            THEN 'Approval before purchase'

        WHEN order_delivered_carrier_date < order_approved_at::timestamp
            THEN 'Carrier handover before approval'

        WHEN order_delivered_customer_date < order_delivered_carrier_date
            THEN 'Customer delivery before carrier handover'
    END AS timestamp_issue

FROM olist_orders_dataset

WHERE
       order_approved_at::timestamp < order_purchase_timestamp
    OR order_delivered_carrier_date < order_approved_at::timestamp
    OR order_delivered_customer_date < order_delivered_carrier_date

ORDER BY order_purchase_timestamp;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 4: Count each type of chronological inconsistency independently

SELECT
    COUNT(*) AS total_orders_with_timestamp_issues,

    COUNT(*) FILTER (
        WHERE order_approved_at::timestamp < order_purchase_timestamp
    ) AS approval_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_approved_at::timestamp
    ) AS carrier_before_approval,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_delivered_carrier_date
    ) AS customer_delivery_before_carrier

FROM olist_orders_dataset

WHERE
       order_approved_at::timestamp < order_purchase_timestamp
    OR order_delivered_carrier_date < order_approved_at::timestamp
    OR order_delivered_customer_date < order_delivered_carrier_date;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 5: Examine the monthly distribution of carrier handover timestamps occurring before approval

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS purchase_month,
    COUNT(*) AS affected_orders

FROM olist_orders_dataset

WHERE order_delivered_carrier_date < order_approved_at::timestamp

GROUP BY DATE_TRUNC('month', order_purchase_timestamp)

ORDER BY purchase_month;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 6: Calculate the monthly percentage of orders with carrier handover before approval

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS purchase_month,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_approved_at::timestamp
    ) AS affected_orders,
    ROUND(
        COUNT(*) FILTER (
            WHERE order_delivered_carrier_date < order_approved_at::timestamp
        ) * 100.0 / COUNT(*),
        2
    ) AS affected_percentage
FROM olist_orders_dataset
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
HAVING COUNT(*) FILTER (
    WHERE order_delivered_carrier_date < order_approved_at::timestamp
) > 0
ORDER BY purchase_month;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 7: Examine carrier-before-approval inconsistencies by order status

SELECT
    order_status,
    COUNT(*) AS affected_orders
FROM olist_orders_dataset
WHERE order_delivered_carrier_date < order_approved_at::timestamp
GROUP BY order_status
ORDER BY affected_orders DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 8: Calculate the time difference between approval and carrier handover

SELECT
    order_id,
    order_status,
    order_approved_at::timestamp AS approval_timestamp,
    order_delivered_carrier_date AS carrier_timestamp,
    ROUND(
        EXTRACT(
            EPOCH FROM (
                order_approved_at::timestamp - order_delivered_carrier_date
            )
        ) / 3600,
        2
    ) AS hours_carrier_before_approval
FROM olist_orders_dataset
WHERE order_delivered_carrier_date < order_approved_at::timestamp
ORDER BY hours_carrier_before_approval DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 9: Summarize the time-gap distribution for carrier-before-approval cases

WITH time_gaps AS (
    SELECT
        EXTRACT(
            EPOCH FROM (
                order_approved_at::timestamp - order_delivered_carrier_date
            )
        ) / 3600 AS gap_hours
    FROM olist_orders_dataset
    WHERE order_delivered_carrier_date < order_approved_at::timestamp
)
SELECT
    COUNT(*) AS affected_orders,
    ROUND(AVG(gap_hours)::numeric, 2) AS average_gap_hours,
    ROUND(MIN(gap_hours)::numeric, 2) AS minimum_gap_hours,
    ROUND(MAX(gap_hours)::numeric, 2) AS maximum_gap_hours,
    ROUND(
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY gap_hours)::numeric,
        2
    ) AS median_gap_hours
FROM time_gaps;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 10: Classify carrier-before-approval cases by the size of their time gap

WITH time_gaps AS (
    SELECT
        EXTRACT(
            EPOCH FROM (
                order_approved_at::timestamp - order_delivered_carrier_date
            )
        ) / 3600 AS gap_hours
    FROM olist_orders_dataset
    WHERE order_delivered_carrier_date < order_approved_at::timestamp
),
categorized AS (
    SELECT
        CASE
            WHEN gap_hours <= 1 THEN 'Up to 1 hour'
            WHEN gap_hours <= 6 THEN 'Above 1 to 6 hours'
            WHEN gap_hours <= 24 THEN 'Above 6 to 24 hours'
            WHEN gap_hours <= 72 THEN 'Above 24 to 72 hours'
            WHEN gap_hours <= 168 THEN 'Above 3 to 7 days'
            ELSE 'Above 7 days'
        END AS gap_category,
        CASE
            WHEN gap_hours <= 1 THEN 1
            WHEN gap_hours <= 6 THEN 2
            WHEN gap_hours <= 24 THEN 3
            WHEN gap_hours <= 72 THEN 4
            WHEN gap_hours <= 168 THEN 5
            ELSE 6
        END AS sort_order
    FROM time_gaps
)
SELECT
    gap_category,
    COUNT(*) AS affected_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS affected_percentage
FROM categorized
GROUP BY gap_category, sort_order
ORDER BY sort_order;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 11: Retrieve orders with carrier handover more than 7 days before approval

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at::timestamp AS approval_timestamp,
    order_delivered_carrier_date AS carrier_timestamp,
    ROUND(
        EXTRACT(
            EPOCH FROM (
                order_approved_at::timestamp - order_delivered_carrier_date
            )
        ) / 3600,
        2
    ) AS hours_carrier_before_approval
FROM olist_orders_dataset
WHERE order_delivered_carrier_date < order_approved_at::timestamp
  AND order_approved_at::timestamp - order_delivered_carrier_date > INTERVAL '7 days'
ORDER BY hours_carrier_before_approval DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 12: Identify orders where carrier handover occurred before purchase

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at::timestamp AS approval_timestamp,
    order_delivered_carrier_date AS carrier_timestamp
FROM olist_orders_dataset
WHERE order_delivered_carrier_date < order_purchase_timestamp
ORDER BY order_purchase_timestamp;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 13: Calculate the time difference between carrier handover and purchase

SELECT
    COUNT(*) AS affected_orders,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (
            order_purchase_timestamp - order_delivered_carrier_date
        )) / 60)::numeric,
        2
    ) AS average_gap_minutes,
    ROUND(
        MIN(EXTRACT(EPOCH FROM (
            order_purchase_timestamp - order_delivered_carrier_date
        )) / 60)::numeric,
        2
    ) AS minimum_gap_minutes,
    ROUND(
        MAX(EXTRACT(EPOCH FROM (
            order_purchase_timestamp - order_delivered_carrier_date
        )) / 60)::numeric,
        2
    ) AS maximum_gap_minutes,
    ROUND(
        PERCENTILE_CONT(0.50) WITHIN GROUP (
            ORDER BY EXTRACT(EPOCH FROM (
                order_purchase_timestamp - order_delivered_carrier_date
            )) / 60
        )::numeric,
        2
    ) AS median_gap_minutes
FROM olist_orders_dataset
WHERE order_delivered_carrier_date < order_purchase_timestamp;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 14: Categorize orders where carrier handover occurred before purchase

WITH time_gaps AS (
    SELECT
        EXTRACT(
            EPOCH FROM (
                order_purchase_timestamp - order_delivered_carrier_date
            )
        ) / 3600 AS gap_hours
    FROM olist_orders_dataset
    WHERE order_delivered_carrier_date < order_purchase_timestamp
),
categorized AS (
    SELECT
        CASE
            WHEN gap_hours <= 1 THEN 'Up to 1 hour'
            WHEN gap_hours <= 6 THEN 'Above 1 to 6 hours'
            WHEN gap_hours <= 24 THEN 'Above 6 to 24 hours'
            WHEN gap_hours <= 72 THEN 'Above 24 to 72 hours'
            WHEN gap_hours <= 168 THEN 'Above 3 to 7 days'
            ELSE 'Above 7 days'
        END AS gap_category,
        CASE
            WHEN gap_hours <= 1 THEN 1
            WHEN gap_hours <= 6 THEN 2
            WHEN gap_hours <= 24 THEN 3
            WHEN gap_hours <= 72 THEN 4
            WHEN gap_hours <= 168 THEN 5
            ELSE 6
        END AS sort_order
    FROM time_gaps
)
SELECT
    gap_category,
    COUNT(*) AS affected_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS affected_percentage
FROM categorized
GROUP BY gap_category, sort_order
ORDER BY sort_order;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 15: Retrieve orders where carrier handover occurred more than 3 days before purchase

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at::timestamp AS approval_timestamp,
    order_delivered_carrier_date AS carrier_timestamp,
    ROUND(
        EXTRACT(
            EPOCH FROM (
                order_purchase_timestamp - order_delivered_carrier_date
            )
        ) / 3600,
        2
    ) AS hours_carrier_before_purchase
FROM olist_orders_dataset
WHERE order_delivered_carrier_date < order_purchase_timestamp
  AND order_purchase_timestamp - order_delivered_carrier_date > INTERVAL '3 days'
ORDER BY hours_carrier_before_purchase DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 16: Count distinct orders with any chronological timestamp inconsistency

SELECT
    COUNT(DISTINCT order_id) AS total_orders_with_chronological_issues
FROM olist_orders_dataset
WHERE
       order_approved_at::timestamp < order_purchase_timestamp
    OR order_delivered_carrier_date < order_purchase_timestamp
    OR order_delivered_carrier_date < order_approved_at::timestamp
    OR order_delivered_customer_date < order_delivered_carrier_date;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
