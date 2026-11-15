
-- Step 1: Profile payment records and identify missing or invalid field values.

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS null_order_id,

    COUNT(*) FILTER (
        WHERE payment_sequential IS NULL
    ) AS null_payment_sequential,

    COUNT(*) FILTER (
        WHERE payment_type IS NULL
    ) AS null_payment_type,

    COUNT(*) FILTER (
        WHERE payment_type IS NOT NULL
          AND TRIM(payment_type) = ''
    ) AS blank_payment_type,

    COUNT(*) FILTER (
        WHERE payment_installments IS NULL
    ) AS null_payment_installments,

    COUNT(*) FILTER (
        WHERE payment_value IS NULL
    ) AS null_payment_value,

    COUNT(*) FILTER (
        WHERE payment_value = 0
    ) AS zero_payment_value,

    COUNT(*
	) FILTER (
        WHERE payment_value < 0
    ) AS negative_payment_value,

    COUNT(*) FILTER (
        WHERE payment_sequential <= 0
    ) AS invalid_payment_sequential,

    COUNT(*) FILTER (
        WHERE payment_installments <= 0
    ) AS invalid_payment_installments,

    MIN(payment_value) AS minimum_payment_value,
    MAX(payment_value) AS maximum_payment_value

FROM public.olist_order_payments_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 2: Examine zero-value payment records and their associated order details.

SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    o.order_status,
    o.order_purchase_timestamp
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE p.payment_value = 0
ORDER BY
    o.order_status,
    p.order_id,
    p.payment_sequential;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 3: Examine all payment entries belonging to orders with zero-value payments.

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM olist_order_payments_dataset
WHERE order_id IN (
    SELECT DISTINCT order_id
    FROM olist_order_payments_dataset
    WHERE payment_value = 0
)
ORDER BY
    order_id,
    payment_sequential;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 4: Identify payment records with invalid installment values.

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM olist_order_payments_dataset
WHERE payment_installments <= 0
ORDER BY
    order_id,
    payment_sequential;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 5: Examine all payment entries for orders with zero credit-card installments.

SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    o.order_status
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE p.order_id IN (
    '1a57108394169c0b47d8f876acc9ba2d',
    '744bade1fcf9ff3f31d860ace076d422'
)
ORDER BY
    p.order_id,
    p.payment_sequential;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 6: Identify orders with gaps or duplicate payment sequence numbers.

WITH sequence_check AS (
    SELECT
        order_id,
        COUNT(*) AS payment_records,
        COUNT(DISTINCT payment_sequential) AS unique_sequences,
        MIN(payment_sequential) AS minimum_sequence,
        MAX(payment_sequential) AS maximum_sequence
    FROM olist_order_payments_dataset
    GROUP BY order_id
)
SELECT
    order_id,
    payment_records,
    unique_sequences,
    minimum_sequence,
    maximum_sequence,
    maximum_sequence - minimum_sequence + 1 AS expected_sequences
FROM sequence_check
WHERE payment_records <> unique_sequences
   OR payment_records <> maximum_sequence - minimum_sequence + 1
ORDER BY payment_records DESC, order_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 7: Summarize payment records and payment values by payment type.

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS distinct_orders,
    SUM(payment_value) AS total_payment_value,
    ROUND(AVG(payment_value)::numeric, 2) AS average_payment_value,
    MIN(payment_value) AS minimum_payment_value,
    MAX(payment_value) AS maximum_payment_value
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY payment_records DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 8: Inspect the 20 highest individual payment values and their order details.

SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    o.order_status,
    o.order_purchase_timestamp
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
ORDER BY
    p.payment_value DESC
LIMIT 20;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 9: Count high-value payment records by purchase month and payment type.

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS purchase_month,
    p.payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT p.order_id) AS distinct_orders,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_payment_value,
    ROUND(AVG(p.payment_value)::numeric, 2) AS average_payment_value,
    MAX(p.payment_value) AS maximum_payment_value
FROM olist_order_payments_dataset AS p
JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE p.payment_value >= 3000
GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp)::date,
    p.payment_type
ORDER BY
    purchase_month,
    payment_records DESC;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 10: Inspect all payment records for the order with the highest individual payment.

SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    o.order_status,
    o.order_purchase_timestamp
FROM olist_order_payments_dataset AS p
JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE p.order_id = '03caa2c082116e1d31e67e9ae3700499'
ORDER BY p.payment_sequential;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 11: Analyze the number of payment records associated with each order.

WITH order_payment_counts AS (
    SELECT
        order_id,
        COUNT(*) AS payment_record_count,
        COUNT(DISTINCT payment_type) AS distinct_payment_types,
        SUM(payment_value) AS total_payment_value
    FROM olist_order_payments_dataset
    GROUP BY order_id
)
SELECT
    payment_record_count,
    COUNT(*) AS order_count,
    MIN(total_payment_value) AS minimum_order_payment,
    MAX(total_payment_value) AS maximum_order_payment
FROM order_payment_counts
GROUP BY payment_record_count
ORDER BY payment_record_count;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 12: Profile orders with 10 or more payment records.

SELECT
    p.order_id,
    o.order_status,
    COUNT(*) AS payment_record_count,
    COUNT(DISTINCT p.payment_type) AS distinct_payment_types,
    STRING_AGG(DISTINCT p.payment_type, ', ' ORDER BY p.payment_type) AS payment_types,
    COUNT(*) FILTER (WHERE p.payment_value = 0) AS zero_value_records,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_payment_value,
    MIN(p.payment_sequential) AS minimum_sequence,
    MAX(p.payment_sequential) AS maximum_sequence
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
GROUP BY
    p.order_id,
    o.order_status
HAVING COUNT(*) >= 10
ORDER BY
    payment_record_count DESC,
    p.order_id;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 13: Identify exact duplicate payment records across all payment columns.

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    COUNT(*) AS duplicate_count
FROM olist_order_payments_dataset
GROUP BY
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, order_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 14: Identify payment sequence values that are zero, negative, or non-integer.

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_value
FROM olist_order_payments_dataset
WHERE payment_sequential <= 0
   OR payment_sequential::numeric <> TRUNC(payment_sequential::numeric)
ORDER BY order_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 15: Analyze installment value distribution by payment type.

SELECT
    payment_type,
    payment_installments,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS distinct_orders,
    ROUND(SUM(payment_value)::numeric, 2) AS total_payment_value
FROM olist_order_payments_dataset
GROUP BY
    payment_type,
    payment_installments
ORDER BY
    payment_type,
    payment_installments;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 16: Examine credit-card transactions with more than 12 installments.

SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_installments,
    p.payment_value,
    o.order_status,
    o.order_purchase_timestamp
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE p.payment_type = 'credit_card'
  AND p.payment_installments > 12
ORDER BY
    p.payment_installments DESC,
    p.payment_value DESC;
	
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 17: Analyze monthly distribution of credit-card payments with more than 12 installments.

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS purchase_month,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT p.order_id) AS distinct_orders,
    MIN(p.payment_installments) AS minimum_installments,
    MAX(p.payment_installments) AS maximum_installments,
    ROUND(AVG(p.payment_value)::numeric, 2) AS average_payment_value
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE p.payment_type = 'credit_card'
  AND p.payment_installments > 12
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY purchase_month;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 18: Identify payment values containing more than two decimal places.

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_value
FROM olist_order_payments_dataset
WHERE payment_value::numeric <> ROUND(payment_value::numeric, 2)
ORDER BY payment_value;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 19: Inspect distinct payment types and their record counts.

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY payment_records DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 20: Examine payment-value distribution and quartiles by payment type.

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    MIN(payment_value) AS minimum_value,
    ROUND(AVG(payment_value)::numeric, 2) AS average_value,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY payment_value) AS first_quartile,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY payment_value) AS median_value,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY payment_value) AS third_quartile,
    MAX(payment_value) AS maximum_value
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY payment_type;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 21: Inspect positive payment values below R$1.

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS distinct_orders,
    MIN(payment_value) AS minimum_value,
    MAX(payment_value) AS maximum_value,
    ROUND(AVG(payment_value)::numeric, 4) AS average_value
FROM olist_order_payments_dataset
WHERE payment_value > 0
  AND payment_value < 1
GROUP BY payment_type
ORDER BY payment_records DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 22: Classify orders by the number of distinct payment methods used.

SELECT
    payment_method_count,
    COUNT(*) AS order_count
FROM (
    SELECT
        order_id,
        COUNT(DISTINCT payment_type) AS payment_method_count
    FROM olist_order_payments_dataset
    GROUP BY order_id
) AS payment_methods
GROUP BY payment_method_count
ORDER BY payment_method_count;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 23: Count orders by their distinct payment-method combination.

SELECT
    payment_method_combination,
    COUNT(*) AS order_count
FROM (
    SELECT
        order_id,
        STRING_AGG(DISTINCT payment_type, ' + ' ORDER BY payment_type) AS payment_method_combination
    FROM olist_order_payments_dataset
    GROUP BY order_id
) AS order_combinations
GROUP BY payment_method_combination
ORDER BY order_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 24: Inspect the order using both credit card and debit card.

SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    o.order_status,
    o.order_purchase_timestamp
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE p.order_id IN (
    SELECT order_id
    FROM olist_order_payments_dataset
    GROUP BY order_id
    HAVING COUNT(DISTINCT payment_type) > 1
       AND COUNT(DISTINCT payment_type) FILTER (
           WHERE payment_type IN ('credit_card', 'debit_card')
       ) = 2
)
ORDER BY p.order_id, p.payment_sequential;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 25: Identify payment records without a matching order.

SELECT
    p.order_id,
    COUNT(*) AS payment_records,
    SUM(p.payment_value) AS total_payment_value
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL
GROUP BY p.order_id
ORDER BY payment_records DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 26: Identify NULL, empty, or whitespace-only order IDs.

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_ids,
    COUNT(*) FILTER (
        WHERE BTRIM(order_id) = ''
    ) AS blank_order_ids,
    COUNT(*) FILTER (
        WHERE order_id IS NOT NULL
          AND order_id <> BTRIM(order_id)
    ) AS order_ids_with_surrounding_spaces
FROM olist_order_payments_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 27: Create a cleaned view while preserving all original payment records and values.

CREATE OR REPLACE VIEW public.olist_order_payments_cleaned AS
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM public.olist_order_payments_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 28: Compare source and cleaned-view record counts.

SELECT
    (SELECT COUNT(*)
     FROM public.olist_order_payments_dataset) AS source_records,

    (SELECT COUNT(*)
     FROM public.olist_order_payments_cleaned) AS cleaned_records,

    (SELECT COUNT(*)
     FROM public.olist_order_payments_dataset)
    -
    (SELECT COUNT(*)
     FROM public.olist_order_payments_cleaned) AS record_difference;
	 
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 29: Compare source and cleaned-view records in both directions.

SELECT
    COUNT(*) AS mismatched_records
FROM (
    (
        SELECT * FROM public.olist_order_payments_dataset
        EXCEPT ALL
        SELECT * FROM public.olist_order_payments_cleaned
    )

    UNION ALL

    (
        SELECT * FROM public.olist_order_payments_cleaned
        EXCEPT ALL
        SELECT * FROM public.olist_order_payments_dataset
    )
) AS differences;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
