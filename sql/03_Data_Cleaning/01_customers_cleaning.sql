
/*
============================================================
PROJECT: Olist E-commerce SQL Project
FILE: 01_customers_cleaning.sql
TABLE: olist_customers_dataset

OBJECTIVE:
Investigate customer data quality and create a cleaned
representation without modifying the original raw table.

CLEANING POLICY:
- Preserve all original records and values.
- Retain repeated customer identities.
- Retain location variations for further review.
- Standardize ZIP-code prefixes in a separate view.
============================================================
*/

-- STEP 1: Establish baseline data quality profile

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customer_unique_ids,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS missing_customer_unique_id,
    COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS missing_zip_code,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS missing_city,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS missing_state
FROM olist_customers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 2: Identify repeated customer identities

SELECT
    customer_unique_id,
    COUNT(*) AS customer_record_count
FROM olist_customers_dataset
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY customer_record_count DESC, customer_unique_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 3: Quantify repeated identity records

WITH repeated_customers AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS customer_record_count
    FROM olist_customers_dataset
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS repeated_customer_identities,
    SUM(customer_record_count) AS records_belonging_to_repeated_identities,
    SUM(customer_record_count - 1) AS additional_customer_records,
    MAX(customer_record_count) AS maximum_records_per_identity
FROM repeated_customers;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 4: Identify customer identities associated with multiple locations

SELECT
    customer_unique_id,
    COUNT(*) AS customer_record_count,
    COUNT(DISTINCT customer_zip_code_prefix) AS distinct_zip_codes,
    COUNT(DISTINCT customer_city) AS distinct_cities,
    COUNT(DISTINCT customer_state) AS distinct_states
FROM olist_customers_dataset
GROUP BY customer_unique_id
HAVING
       COUNT(DISTINCT customer_zip_code_prefix) > 1
    OR COUNT(DISTINCT customer_city) > 1
    OR COUNT(DISTINCT customer_state) > 1
ORDER BY customer_record_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 5: Identify different customer locations within 60 minutes

WITH location_variations AS (
    SELECT customer_unique_id
    FROM olist_customers_dataset
    GROUP BY customer_unique_id
    HAVING
           COUNT(DISTINCT customer_zip_code_prefix) > 1
        OR COUNT(DISTINCT customer_city) > 1
        OR COUNT(DISTINCT customer_state) > 1
)
SELECT
    c1.customer_unique_id,
    o1.order_id AS order_id_1,
    c1.customer_zip_code_prefix AS zip_code_1,
    c1.customer_city AS city_1,
    c1.customer_state AS state_1,
    o1.order_purchase_timestamp AS purchase_timestamp_1,
    o2.order_id AS order_id_2,
    c2.customer_zip_code_prefix AS zip_code_2,
    c2.customer_city AS city_2,
    c2.customer_state AS state_2,
    o2.order_purchase_timestamp AS purchase_timestamp_2,
    ROUND(
        ABS(EXTRACT(EPOCH FROM (
            o1.order_purchase_timestamp - o2.order_purchase_timestamp
        ))) / 60,
        2
    ) AS time_difference_minutes
FROM olist_customers_dataset c1
JOIN olist_customers_dataset c2
    ON c1.customer_unique_id = c2.customer_unique_id
   AND c1.customer_id < c2.customer_id
JOIN olist_orders_dataset o1
    ON c1.customer_id = o1.customer_id
JOIN olist_orders_dataset o2
    ON c2.customer_id = o2.customer_id
JOIN location_variations lv
    ON c1.customer_unique_id = lv.customer_unique_id
WHERE
    (
        c1.customer_zip_code_prefix <> c2.customer_zip_code_prefix
        OR c1.customer_city <> c2.customer_city
        OR c1.customer_state <> c2.customer_state
    )
    AND ABS(EXTRACT(EPOCH FROM (
        o1.order_purchase_timestamp - o2.order_purchase_timestamp
    ))) <= 3600
ORDER BY c1.customer_unique_id, time_difference_minutes;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 6: Identify ZIP prefixes associated with multiple cities or states

SELECT
    customer_zip_code_prefix,
    COUNT(*) AS customer_record_count,
    COUNT(DISTINCT customer_city) AS distinct_cities,
    COUNT(DISTINCT customer_state) AS distinct_states,
    STRING_AGG(DISTINCT customer_city, ', ') AS cities,
    STRING_AGG(DISTINCT customer_state, ', ') AS states
FROM olist_customers_dataset
GROUP BY customer_zip_code_prefix
HAVING
       COUNT(DISTINCT customer_city) > 1
    OR COUNT(DISTINCT customer_state) > 1
ORDER BY distinct_states DESC, distinct_cities DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 7: Identify city names associated with multiple states

SELECT
    customer_city,
    COUNT(*) AS customer_record_count,
    COUNT(DISTINCT customer_state) AS distinct_states,
    STRING_AGG(DISTINCT customer_state, ', ') AS states
FROM olist_customers_dataset
GROUP BY customer_city
HAVING COUNT(DISTINCT customer_state) > 1
ORDER BY distinct_states DESC, customer_record_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 8: Check ZIP-code prefix length distribution

SELECT
    LENGTH(customer_zip_code_prefix::text) AS zip_code_length,
    COUNT(*) AS record_count,
    COUNT(DISTINCT customer_zip_code_prefix) AS distinct_zip_codes
FROM olist_customers_dataset
GROUP BY LENGTH(customer_zip_code_prefix::text)
ORDER BY zip_code_length;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 9: Retrieve sample records with four-digit ZIP prefixes

SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM olist_customers_dataset
WHERE LENGTH(customer_zip_code_prefix::text) = 4
ORDER BY customer_zip_code_prefix
LIMIT 30;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 10: Validate five-character ZIP-code formatting

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE LENGTH(LPAD(customer_zip_code_prefix::text, 5, '0')) = 5
    ) AS records_with_five_digit_format,
    COUNT(*) FILTER (
        WHERE LENGTH(customer_zip_code_prefix::text) = 4
    ) AS records_requiring_leading_zero,
    COUNT(*) FILTER (
        WHERE LENGTH(customer_zip_code_prefix::text) NOT IN (4, 5)
    ) AS records_with_unexpected_length
FROM olist_customers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 11: Identify exact duplicate customer records

SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    COUNT(*) AS duplicate_count
FROM olist_customers_dataset
GROUP BY
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 12: Create a separate cleaned customer view
-- Run only once. The view has already been created.

CREATE VIEW public.olist_customers_cleaned AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    LPAD(customer_zip_code_prefix::text, 5, '0')
        AS customer_zip_code_prefix_cleaned,
    customer_city,
    customer_state
FROM olist_customers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 13: Inspect the cleaned customer view

SELECT *
FROM public.olist_customers_cleaned
LIMIT 10;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 14: Validate the cleaned customer view

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(*) FILTER (
        WHERE LENGTH(customer_zip_code_prefix_cleaned) <> 5
    ) AS invalid_cleaned_zip_codes,
    COUNT(*) FILTER (
        WHERE customer_zip_code_prefix::text <>
              customer_zip_code_prefix_cleaned
    ) AS records_with_formatting_changes
FROM public.olist_customers_cleaned;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- STEP 15: Verify the original customer table remains unchanged

SELECT
    COUNT(*) AS raw_total_records,
    COUNT(*) FILTER (
        WHERE LENGTH(customer_zip_code_prefix::text) = 4
    ) AS original_four_digit_zip_codes
FROM olist_customers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------


