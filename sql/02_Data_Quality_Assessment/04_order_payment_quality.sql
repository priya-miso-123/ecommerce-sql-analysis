/*
===============================================================================
DATA QUALITY INVESTIGATION
Validation of order-level payment values against item price + freight values

Objective:
Compare the aggregated payment_value in olist_order_payments_dataset with the
aggregated price + freight_value in olist_order_items_dataset for each order_id.

Important:
- Each numbered query is independently executable.
- CTEs are repeated because PostgreSQL CTEs exist only for one statement.
- All column references are qualified with table aliases.
- The initial comparison uses INNER JOIN, so it covers only order IDs present
  in both source tables.
===============================================================================
*/


/*
-------------------------------------------------------------------------------
STEP 1: INITIAL ORDER-LEVEL VALIDATION
Purpose: Aggregate item and payment values by order_id, then count matching
         and mismatching order totals.
Finding: 98,089 matching orders and 576 mismatching orders (98,665 matched IDs).
-------------------------------------------------------------------------------
*/

WITH order_items AS
(
    SELECT
        oi.order_id,
        COUNT(*) AS item_records,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS price_freight
    FROM olist_order_items_dataset AS oi
    GROUP BY oi.order_id
),

order_payments AS
(
    SELECT
        op.order_id,
        COUNT(*) AS payment_records,
        ROUND(SUM(op.payment_value)::numeric, 2) AS total_payment
    FROM olist_order_payments_dataset AS op
    GROUP BY op.order_id
),

payment_price_freight_check AS
(
    SELECT
        oi.order_id,
        oi.item_records,
        op.payment_records,
        oi.price_freight,
        op.total_payment,
        CASE
            WHEN oi.price_freight = op.total_payment THEN 'same'
            ELSE 'not same'
        END AS equal_check
    FROM order_items AS oi
    INNER JOIN order_payments AS op
        ON oi.order_id = op.order_id
)

SELECT
    ppf.equal_check,
    COUNT(ppf.order_id) AS order_count
FROM payment_price_freight_check AS ppf
GROUP BY ppf.equal_check
ORDER BY ppf.equal_check;


/*
-------------------------------------------------------------------------------
STEP 2: CLASSIFY MISMATCHES BY ABSOLUTE DIFFERENCE
Purpose: Separate mismatches with an absolute difference up to 0.50 from those
         with an absolute difference greater than 0.50.
Finding: 321 orders have a difference <= 0.50; 255 orders have a difference
         > 0.50.
-------------------------------------------------------------------------------
*/

WITH order_items AS
(
    SELECT
        oi.order_id,
        COUNT(*) AS item_records,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS price_freight
    FROM olist_order_items_dataset AS oi
    GROUP BY oi.order_id
),

order_payments AS
(
    SELECT
        op.order_id,
        COUNT(*) AS payment_records,
        ROUND(SUM(op.payment_value)::numeric, 2) AS total_payment
    FROM olist_order_payments_dataset AS op
    GROUP BY op.order_id
),

payment_price_freight_check AS
(
    SELECT
        oi.order_id,
        oi.item_records,
        op.payment_records,
        oi.price_freight,
        op.total_payment,
        CASE
            WHEN oi.price_freight = op.total_payment THEN 'same'
            ELSE 'not same'
        END AS equal_check
    FROM order_items AS oi
    INNER JOIN order_payments AS op
        ON oi.order_id = op.order_id
),

not_same_records AS
(
    SELECT
        ppf.order_id,
        ppf.price_freight,
        ppf.total_payment,
        ROUND((ppf.total_payment - ppf.price_freight)::numeric, 2)
            AS difference_payment
    FROM payment_price_freight_check AS ppf
    WHERE ppf.equal_check = 'not same'
)

SELECT
    CASE
        WHEN ABS(nsr.difference_payment) <= 0.50
            THEN 'Difference <= 0.50'
        ELSE 'Difference > 0.50'
    END AS difference_group,
    COUNT(nsr.order_id) AS order_count
FROM not_same_records AS nsr
GROUP BY
    CASE
        WHEN ABS(nsr.difference_payment) <= 0.50
            THEN 'Difference <= 0.50'
        ELSE 'Difference > 0.50'
    END
ORDER BY difference_group;


/*
-------------------------------------------------------------------------------
STEP 3: CLASSIFY MISMATCHES BY DIRECTION
Purpose: Identify whether payment value is greater than or less than the
         combined item price and freight value.
Finding: 367 payment-greater orders and 209 price-plus-freight-greater orders.
-------------------------------------------------------------------------------
*/

WITH order_items AS
(
    SELECT
        oi.order_id,
        COUNT(*) AS item_records,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS price_freight
    FROM olist_order_items_dataset AS oi
    GROUP BY oi.order_id
),

order_payments AS
(
    SELECT
        op.order_id,
        COUNT(*) AS payment_records,
        ROUND(SUM(op.payment_value)::numeric, 2) AS total_payment
    FROM olist_order_payments_dataset AS op
    GROUP BY op.order_id
),

payment_price_freight_check AS
(
    SELECT
        oi.order_id,
        oi.item_records,
        op.payment_records,
        oi.price_freight,
        op.total_payment,
        CASE
            WHEN oi.price_freight = op.total_payment THEN 'same'
            ELSE 'not same'
        END AS equal_check
    FROM order_items AS oi
    INNER JOIN order_payments AS op
        ON oi.order_id = op.order_id
),

not_same_records AS
(
    SELECT
        ppf.order_id,
        ppf.price_freight,
        ppf.total_payment,
        ROUND((ppf.total_payment - ppf.price_freight)::numeric, 2)
            AS difference_payment
    FROM payment_price_freight_check AS ppf
    WHERE ppf.equal_check = 'not same'
)

SELECT
    CASE
        WHEN nsr.difference_payment > 0 THEN 'Payment greater'
        WHEN nsr.difference_payment < 0 THEN 'Price + freight greater'
        ELSE 'No difference'
    END AS difference_type,
    COUNT(nsr.order_id) AS order_count,
    ROUND(AVG(ABS(nsr.difference_payment)), 2) AS avg_absolute_difference,
    ROUND(MAX(ABS(nsr.difference_payment)), 2) AS max_absolute_difference,
    ROUND(MIN(ABS(nsr.difference_payment)), 2) AS min_absolute_difference
FROM not_same_records AS nsr
GROUP BY
    CASE
        WHEN nsr.difference_payment > 0 THEN 'Payment greater'
        WHEN nsr.difference_payment < 0 THEN 'Price + freight greater'
        ELSE 'No difference'
    END
ORDER BY difference_type;


/*
-------------------------------------------------------------------------------
STEP 4: INVESTIGATE ITEM AND PAYMENT RECORD COUNTS
Purpose: Examine the number of item records and payment records associated
         with mismatched orders whose absolute difference exceeds 0.50.
Finding: 222 of the 255 orders have exactly one item record and one payment
         record.
-------------------------------------------------------------------------------
*/

WITH order_items AS
(
    SELECT
        oi.order_id,
        COUNT(*) AS item_records,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS price_freight
    FROM olist_order_items_dataset AS oi
    GROUP BY oi.order_id
),

order_payments AS
(
    SELECT
        op.order_id,
        COUNT(*) AS payment_records,
        ROUND(SUM(op.payment_value)::numeric, 2) AS total_payment
    FROM olist_order_payments_dataset AS op
    GROUP BY op.order_id
),

payment_price_freight_check AS
(
    SELECT
        oi.order_id,
        oi.item_records,
        op.payment_records,
        oi.price_freight,
        op.total_payment,
        CASE
            WHEN oi.price_freight = op.total_payment THEN 'same'
            ELSE 'not same'
        END AS equal_check
    FROM order_items AS oi
    INNER JOIN order_payments AS op
        ON oi.order_id = op.order_id
)

SELECT
    ppf.item_records,
    ppf.payment_records,
    COUNT(ppf.order_id) AS order_count
FROM payment_price_freight_check AS ppf
WHERE ppf.equal_check = 'not same'
  AND ABS(ppf.total_payment - ppf.price_freight) > 0.50
GROUP BY
    ppf.item_records,
    ppf.payment_records
ORDER BY
    ppf.item_records,
    ppf.payment_records;


/*
-------------------------------------------------------------------------------
STEP 5: RECONCILE THE 222 ONE-ITEM, ONE-PAYMENT ORDERS
Purpose: Split the 222 orders into positive and negative differences greater
         than 0.50 in absolute value.
Finding: 208 positive differences and 14 negative differences.
-------------------------------------------------------------------------------
*/

WITH order_items AS
(
    SELECT
        oi.order_id,
        COUNT(*) AS item_records,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS price_freight
    FROM olist_order_items_dataset AS oi
    GROUP BY oi.order_id
),

order_payments AS
(
    SELECT
        op.order_id,
        COUNT(*) AS payment_records,
        ROUND(SUM(op.payment_value)::numeric, 2) AS total_payment
    FROM olist_order_payments_dataset AS op
    GROUP BY op.order_id
),

payment_price_freight_check AS
(
    SELECT
        oi.order_id,
        oi.item_records,
        op.payment_records,
        oi.price_freight,
        op.total_payment,
        CASE
            WHEN oi.price_freight = op.total_payment THEN 'same'
            ELSE 'not same'
        END AS equal_check
    FROM order_items AS oi
    INNER JOIN order_payments AS op
        ON oi.order_id = op.order_id
),

not_same_records AS
(
    SELECT
        ppf.order_id,
        ppf.price_freight,
        ppf.total_payment,
        ROUND((ppf.total_payment - ppf.price_freight)::numeric, 2)
            AS difference_payment
    FROM payment_price_freight_check AS ppf
    WHERE ppf.equal_check = 'not same'
)

SELECT
    COUNT(nsr.order_id) AS total_mismatched_orders,
    COUNT(nsr.order_id) FILTER (
        WHERE ppf.item_records = 1
    ) AS one_item_record,
    COUNT(nsr.order_id) FILTER (
        WHERE ppf.payment_records = 1
    ) AS one_payment_record,
    COUNT(nsr.order_id) FILTER (
        WHERE ppf.item_records = 1
          AND ppf.payment_records = 1
    ) AS one_item_one_payment,
    COUNT(nsr.order_id) FILTER (
        WHERE ppf.item_records = 1
          AND ppf.payment_records = 1
          AND nsr.difference_payment > 0.50
    ) AS positive_difference_above_050,
    COUNT(nsr.order_id) FILTER (
        WHERE ppf.item_records = 1
          AND ppf.payment_records = 1
          AND nsr.difference_payment < -0.50
    ) AS negative_difference_below_minus_050
FROM not_same_records AS nsr
INNER JOIN payment_price_freight_check AS ppf
    ON nsr.order_id = ppf.order_id;


/*
-------------------------------------------------------------------------------
STEP 6: RETRIEVE THE 14 NEGATIVE-DIFFERENCE ORDERS
Purpose: List the one-item, one-payment orders where price plus freight
         exceeds payment value by more than 0.50.
Finding: 14 orders; absolute differences range from 1.00 to 21.80.
-------------------------------------------------------------------------------
*/

WITH order_items AS
(
    SELECT
        oi.order_id,
        COUNT(*) AS item_records,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS price_freight
    FROM olist_order_items_dataset AS oi
    GROUP BY oi.order_id
),

order_payments AS
(
    SELECT
        op.order_id,
        COUNT(*) AS payment_records,
        ROUND(SUM(op.payment_value)::numeric, 2) AS total_payment
    FROM olist_order_payments_dataset AS op
    GROUP BY op.order_id
),

payment_price_freight_check AS
(
    SELECT
        oi.order_id,
        oi.item_records,
        op.payment_records,
        oi.price_freight,
        op.total_payment,
        CASE
            WHEN oi.price_freight = op.total_payment THEN 'same'
            ELSE 'not same'
        END AS equal_check
    FROM order_items AS oi
    INNER JOIN order_payments AS op
        ON oi.order_id = op.order_id
),

not_same_records AS
(
    SELECT
        ppf.order_id,
        ppf.price_freight,
        ppf.total_payment,
        ROUND((ppf.total_payment - ppf.price_freight)::numeric, 2)
            AS difference_payment
    FROM payment_price_freight_check AS ppf
    WHERE ppf.equal_check = 'not same'
)

SELECT
    nsr.order_id,
    ppf.item_records,
    ppf.payment_records,
    nsr.price_freight,
    nsr.total_payment,
    nsr.difference_payment
FROM not_same_records AS nsr
INNER JOIN payment_price_freight_check AS ppf
    ON nsr.order_id = ppf.order_id
WHERE ppf.item_records = 1
  AND ppf.payment_records = 1
  AND nsr.difference_payment < -0.50
ORDER BY nsr.difference_payment;


/*
-------------------------------------------------------------------------------
STEP 6A: VERIFY THE 14 ORDERS AGAINST ORIGINAL SOURCE VALUES
Purpose: Compare the original item price, freight value and payment value
         for the 14 negative-difference orders.
Finding: The source-level values reproduce the discrepancies; aggregation
         did not introduce these differences.
-------------------------------------------------------------------------------
*/

SELECT
    oi.order_id,
    oi.price,
    oi.freight_value,
    ROUND((oi.price + oi.freight_value)::numeric, 2) AS price_freight,
    op.payment_type,
    op.payment_value,
    op.payment_installments,
    ROUND(
        (op.payment_value - (oi.price + oi.freight_value))::numeric,
        2
    ) AS difference_payment
FROM olist_order_items_dataset AS oi
INNER JOIN olist_order_payments_dataset AS op
    ON oi.order_id = op.order_id
WHERE oi.order_id IN
(
    'fd33085945f15975375cd8ec85440511',
    '6e57e23ecac1ae881286657694444267',
    '4154bf1348caac78152fe76e3e9c4af8',
    '6dcf0aeb8b1eb4021c26e1d0e9394979',
    '8092da256aefda13b330290d2ca86521',
    'aa6bd33ba1853d846d3085a88ae37083',
    'c6f6cbb3c845593222d5c594bb69c5fd',
    '051fcda88d997d3ff86012da2a556342',
    'ed4116f3f55e67e9a26b9f1891ba2497',
    'c8bedae351d76a3163c9840172c1285f',
    '6cff0c3dacf64bb7cb2ad584b81b7d0d',
    'e73fe43cdcd166f7f0c6e3c2bf11a917',
    '6fa0c125ee7d870f6602c97e33d87bc5',
    '882634702ad671a4a28319adef8f058b'
)
ORDER BY oi.order_id;


/*
-------------------------------------------------------------------------------
STEP 6B: CHECK ORDER STATUS OF THE 14 NEGATIVE-DIFFERENCE ORDERS
Purpose: Determine whether the 14 orders share a common order status.
Finding: All 14 orders have the status 'delivered'.
-------------------------------------------------------------------------------
*/

SELECT
    o.order_status,
    COUNT(oi.order_id) AS order_count
FROM olist_order_items_dataset AS oi
INNER JOIN olist_order_payments_dataset AS op
    ON oi.order_id = op.order_id
INNER JOIN olist_orders_dataset AS o
    ON oi.order_id = o.order_id
WHERE oi.order_id IN
(
    'fd33085945f15975375cd8ec85440511',
    '6e57e23ecac1ae881286657694444267',
    '4154bf1348caac78152fe76e3e9c4af8',
    '6dcf0aeb8b1eb4021c26e1d0e9394979',
    '8092da256aefda13b330290d2ca86521',
    'aa6bd33ba1853d846d3085a88ae37083',
    'c6f6cbb3c845593222d5c594bb69c5fd',
    '051fcda88d997d3ff86012da2a556342',
    'ed4116f3f55e67e9a26b9f1891ba2497',
    'c8bedae351d76a3163c9840172c1285f',
    '6cff0c3dacf64bb7cb2ad584b81b7d0d',
    'e73fe43cdcd166f7f0c6e3c2bf11a917',
    '6fa0c125ee7d870f6602c97e33d87bc5',
    '882634702ad671a4a28319adef8f058b'
)
GROUP BY o.order_status
ORDER BY o.order_status;


/*
-------------------------------------------------------------------------------
STEP 7: CLASSIFY THE 208 POSITIVE-DIFFERENCE ORDERS BY PERCENTAGE
Purpose: Calculate the payment difference as a percentage of price plus
         freight and group the 208 eligible orders into continuous ranges.
Finding: 54 orders fall between 12.95% and 13.05%.
-------------------------------------------------------------------------------
*/

WITH order_items AS
(
    SELECT
        oi.order_id,
        COUNT(*) AS item_records,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS price_freight
    FROM olist_order_items_dataset AS oi
    GROUP BY oi.order_id
),

order_payments AS
(
    SELECT
        op.order_id,
        COUNT(*) AS payment_records,
        ROUND(SUM(op.payment_value)::numeric, 2) AS total_payment
    FROM olist_order_payments_dataset AS op
    GROUP BY op.order_id
),

payment_price_freight_check AS
(
    SELECT
        oi.order_id,
        oi.item_records,
        op.payment_records,
        oi.price_freight,
        op.total_payment,
        CASE
            WHEN oi.price_freight = op.total_payment THEN 'same'
            ELSE 'not same'
        END AS equal_check
    FROM order_items AS oi
    INNER JOIN order_payments AS op
        ON oi.order_id = op.order_id
),

not_same_records AS
(
    SELECT
        ppf.order_id,
        ppf.price_freight,
        ppf.total_payment,
        ROUND((ppf.total_payment - ppf.price_freight)::numeric, 2)
            AS difference_payment
    FROM payment_price_freight_check AS ppf
    WHERE ppf.equal_check = 'not same'
)

SELECT
    CASE
        WHEN nsr.difference_payment * 100.0 /
             NULLIF(nsr.price_freight, 0) < 5
            THEN 'Below 5%'
        WHEN nsr.difference_payment * 100.0 /
             NULLIF(nsr.price_freight, 0) < 10
            THEN '5% to below 10%'
        WHEN nsr.difference_payment * 100.0 /
             NULLIF(nsr.price_freight, 0) < 12.95
            THEN '10% to below 12.95%'
        WHEN nsr.difference_payment * 100.0 /
             NULLIF(nsr.price_freight, 0) <= 13.05
            THEN 'Around 13%'
        WHEN nsr.difference_payment * 100.0 /
             NULLIF(nsr.price_freight, 0) <= 15
            THEN 'Above 13.05% to 15%'
        ELSE 'Above 15%'
    END AS difference_percentage_group,
    COUNT(nsr.order_id) AS order_count
FROM not_same_records AS nsr
INNER JOIN payment_price_freight_check AS ppf
    ON nsr.order_id = ppf.order_id
WHERE ppf.item_records = 1
  AND ppf.payment_records = 1
  AND nsr.difference_payment > 0.50
GROUP BY 1
ORDER BY 1;


/*
-------------------------------------------------------------------------------
STEP 7A: RETRIEVE THE 54 ORDERS WITH APPROXIMATELY 13% DIFFERENCE
Purpose: Inspect individual order-level values and calculate the precise
         percentage difference for the 54 orders in the 12.95%-13.05% range.
Finding: The observed percentages range from 12.9953% to 13.0428%.
-------------------------------------------------------------------------------
*/

WITH order_items AS
(
    SELECT
        oi.order_id,
        COUNT(*) AS item_records,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS price_freight
    FROM olist_order_items_dataset AS oi
    GROUP BY oi.order_id
),

order_payments AS
(
    SELECT
        op.order_id,
        COUNT(*) AS payment_records,
        ROUND(SUM(op.payment_value)::numeric, 2) AS total_payment
    FROM olist_order_payments_dataset AS op
    GROUP BY op.order_id
),

payment_price_freight_check AS
(
    SELECT
        oi.order_id,
        oi.item_records,
        op.payment_records,
        oi.price_freight,
        op.total_payment,
        CASE
            WHEN oi.price_freight = op.total_payment THEN 'same'
            ELSE 'not same'
        END AS equal_check
    FROM order_items AS oi
    INNER JOIN order_payments AS op
        ON oi.order_id = op.order_id
),

not_same_records AS
(
    SELECT
        ppf.order_id,
        ppf.price_freight,
        ppf.total_payment,
        ROUND((ppf.total_payment - ppf.price_freight)::numeric, 2)
            AS difference_payment
    FROM payment_price_freight_check AS ppf
    WHERE ppf.equal_check = 'not same'
)

SELECT
    nsr.order_id,
    nsr.price_freight,
    nsr.total_payment,
    nsr.difference_payment,
    ROUND(
        (
            nsr.difference_payment * 100.0 /
            NULLIF(nsr.price_freight, 0)
        )::numeric,
        4
    ) AS difference_percentage
FROM not_same_records AS nsr
INNER JOIN payment_price_freight_check AS ppf
    ON nsr.order_id = ppf.order_id
WHERE ppf.item_records = 1
  AND ppf.payment_records = 1
  AND nsr.difference_payment > 0.50
  AND (
      nsr.difference_payment * 100.0 /
      NULLIF(nsr.price_freight, 0)
  ) BETWEEN 12.95 AND 13.05
ORDER BY nsr.order_id;


/*
===============================================================================
INVESTIGATION SUMMARY

- Matched order IDs compared: 98,665
- Matching aggregated values: 98,089
- Mismatching aggregated values: 576
- Mismatches with absolute difference > 0.50: 255
- One-item, one-payment mismatches in that group: 222
- Positive differences > 0.50: 208
- Negative differences < -0.50: 14
- Approximately 13% pattern among positive differences: 54 orders

The underlying business reason for the discrepancies was not established.
The approximately 13% result is a numerical pattern, not a confirmed fee,
tax, interest amount, or surcharge.

Previously identified unmatched order IDs:
- Missing from payment table: 1
- Missing from item table: 775

These unmatched IDs are excluded from the INNER JOIN comparison above.
===============================================================================
*/
