/*
Table Name: 'olist_orders_dataset'
*/
------------------------------------------------------

-- table information

select
    column_name,
    data_type,
    is_nullable
from information_schema.columns
where table_name = 'olist_orders_dataset'
order by ordinal_position;

------------------------------------------------------

-- table size

select COUNT(*)
from olist_orders_dataset;

------------------------------------------------------

-- column inforamtion

select
	'order_id' as column_name,
	count(*) as total_count,
	count(distinct order_id) as unique_count,
	count(*)-count(order_id) as null_count,
	(
		count(order_id) - count(distinct order_id)
	) as duplicate_count
from olist_orders_dataset

UNION ALL

select
	'customer_id' as column_name,
	count(*) as total_count,
	count(distinct customer_id) as unique_count,
	count(*)-count(customer_id) as null_count,
	(
		count(customer_id) - count(distinct customer_id)
	) as duplicate_count
from olist_orders_dataset

UNION ALL

select
	'order_status' as column_name,
	count(*) as total_count,
	count(distinct order_status) as unique_count,
	count(*)-count(order_status) as null_count,
	(
		count(order_status) - count(distinct order_status)
	) as duplicate_count
from olist_orders_dataset

UNION ALL

select
	'order_purchase_timestamp' as column_name,
	count(*) as total_count,
	count(distinct order_purchase_timestamp) as unique_count,
	count(*)-count(order_purchase_timestamp) as null_count,
	(
		count(order_purchase_timestamp) - count(distinct order_purchase_timestamp)
	) as duplicate_count
from olist_orders_dataset

UNION ALL

select
	'order_approved_at' as column_name,
	count(*) as total_count,
	count(distinct order_approved_at) as unique_count,
	count(*)-count(order_approved_at) as null_count,
	(
		count(order_approved_at) - count(distinct order_approved_at)
	) as duplicate_count
from olist_orders_dataset

UNION ALL

select
	'order_delivered_carrier_date' as column_name,
	count(*) as total_count,
	count(distinct order_delivered_carrier_date) as unique_count,
	count(*)-count(order_delivered_carrier_date) as null_count,
	(
		count(order_delivered_carrier_date) - count(distinct order_delivered_carrier_date)
	) as duplicate_count
from olist_orders_dataset

UNION ALL

select
	'order_delivered_customer_date' as column_name,
	count(*) as total_count,
	count(distinct order_delivered_customer_date) as unique_count,
	count(*)-count(order_delivered_customer_date) as null_count,
	(
		count(order_delivered_customer_date) - count(distinct order_delivered_customer_date)
	) as duplicate_count
from olist_orders_dataset

UNION ALL

select
	'order_estimated_delivery_date' as column_name,
	count(*) as total_count,
	count(distinct order_estimated_delivery_date) as unique_count,
	count(*)-count(order_estimated_delivery_date) as null_count,
	(
		count(order_estimated_delivery_date) - count(distinct order_estimated_delivery_date)
	) as duplicate_count
from olist_orders_dataset;

/*
Table Name: 'olist_customers_dataset'
*/
------------------------------------------------------

-- table information

select
    column_name,
    data_type,
    is_nullable
from information_schema.columns
where table_name = 'olist_customers_dataset'
order by ordinal_position;

------------------------------------------------------

-- table size

select COUNT(*)
from olist_customers_dataset;

------------------------------------------------------

-- column inforamtion

select
	'customer_id' as column_name,
	count(*) as total_count,
	count(distinct customer_id) as unique_count,
	count(*)-count(customer_id) as null_count,
	(
		count(customer_id) - count(distinct customer_id)
	) as duplicate_count
from olist_customers_dataset

UNION ALL

select
	'customer_unique_id' as column_name,
	count(*) as total_count,
	count(distinct customer_unique_id) as unique_count,
	count(*)-count(customer_unique_id) as null_count,
	(
		count(customer_unique_id) - count(distinct customer_unique_id)
	) as duplicate_count
from olist_customers_dataset

UNION ALL

select
	'customer_zip_code_prefix' as column_name,
	count(*) as total_count,
	count(distinct customer_zip_code_prefix) as unique_count,
	count(*)-count(customer_zip_code_prefix) as null_count,
	(
		count(customer_zip_code_prefix) - count(distinct customer_zip_code_prefix)
	) as duplicate_count
from olist_customers_dataset

UNION ALL

select
	'customer_city' as column_name,
	count(*) as total_count,
	count(distinct customer_city) as unique_count,
	count(*)-count(customer_city) as null_count,
	(
		count(customer_city) - count(distinct customer_city)
	) as duplicate_count
from olist_customers_dataset

UNION ALL

select
	'customer_state' as column_name,
	count(*) as total_count,
	count(distinct customer_state) as unique_count,
	count(*)-count(customer_state) as null_count,
	(
		count(customer_state) - count(distinct customer_state)
	) as duplicate_count
from olist_customers_dataset;

/*
Table Name: 'olist_order_items_dataset'
*/
------------------------------------------------------

-- table information

select
    column_name,
    data_type,
    is_nullable
from information_schema.columns
where table_name = 'olist_order_items_dataset'
order by ordinal_position;

------------------------------------------------------

-- table size

select COUNT(*)
from olist_order_items_dataset;

------------------------------------------------------

-- column inforamtion

select
	'order_id' as column_name,
	count(*) as total_count,
	count(distinct order_id) as unique_count,
	count(*)-count(order_id) as null_count,
	(
		count(order_id) - count(distinct order_id)
	) as duplicate_count
from olist_order_items_dataset

UNION ALL

select
	'order_item_id' as column_name,
	count(*) as total_count,
	count(distinct order_item_id) as unique_count,
	count(*)-count(order_item_id) as null_count,
	(
		count(order_item_id) - count(distinct order_item_id)
	) as duplicate_count
from olist_order_items_dataset

UNION ALL

select
	'product_id' as column_name,
	count(*) as total_count,
	count(distinct product_id) as unique_count,
	count(*)-count(product_id) as null_count,
	(
		count(product_id) - count(distinct product_id)
	) as duplicate_count
from olist_order_items_dataset

UNION ALL

select
	'seller_id' as column_name,
	count(*) as total_count,
	count(distinct seller_id) as unique_count,
	count(*)-count(seller_id) as null_count,
	(
		count(seller_id) - count(distinct seller_id)
	) as duplicate_count
from olist_order_items_dataset

UNION ALL

select
	'shipping_limit_date' as column_name,
	count(*) as total_count,
	count(distinct shipping_limit_date) as unique_count,
	count(*)-count(shipping_limit_date) as null_count,
	(
		count(shipping_limit_date) - count(distinct shipping_limit_date)
	) as duplicate_count
from olist_order_items_dataset

UNION ALL

select
	'price' as column_name,
	count(*) as total_count,
	count(distinct price) as unique_count,
	count(*)-count(price) as null_count,
	(
		count(price) - count(distinct price)
	) as duplicate_count
from olist_order_items_dataset

UNION ALL

select
	'freight_value' as column_name,
	count(*) as total_count,
	count(distinct freight_value) as unique_count,
	count(*)-count(freight_value) as null_count,
	(
		count(freight_value) - count(distinct freight_value)
	) as duplicate_count
from olist_order_items_dataset;

/*
Table Name: 'olist_order_payments_dataset'
*/
------------------------------------------------------

-- table information

select
    column_name,
    data_type,
    is_nullable
from information_schema.columns
where table_name = 'olist_order_payments_dataset'
order by ordinal_position;

------------------------------------------------------

-- table size

select COUNT(*)
from olist_order_payments_dataset;

------------------------------------------------------

-- column inforamtion

select
	'order_id' as column_name,
	count(*) as total_count,
	count(distinct order_id) as unique_count,
	count(*)-count(order_id) as null_count,
	(
		count(order_id) - count(distinct order_id)
	) as duplicate_count
from olist_order_payments_dataset

UNION ALL

select
	'payment_sequential' as column_name,
	count(*) as total_count,
	count(distinct payment_sequential) as unique_count,
	count(*)-count(payment_sequential) as null_count,
	(
		count(payment_sequential) - count(distinct payment_sequential)
	) as duplicate_count
from olist_order_payments_dataset

UNION ALL

select
	'payment_type' as column_name,
	count(*) as total_count,
	count(distinct payment_type) as unique_count,
	count(*)-count(payment_type) as null_count,
	(
		count(payment_type) - count(distinct payment_type)
	) as duplicate_count
from olist_order_payments_dataset

UNION ALL

select
	'payment_installments' as column_name,
	count(*) as total_count,
	count(distinct payment_installments) as unique_count,
	count(*)-count(payment_installments) as null_count,
	(
		count(payment_installments) - count(distinct payment_installments)
	) as duplicate_count
from olist_order_payments_dataset

UNION ALL

select
	'payment_value' as column_name,
	count(*) as total_count,
	count(distinct payment_value) as unique_count,
	count(*)-count(payment_value) as null_count,
	(
		count(payment_value) - count(distinct payment_value)
	) as duplicate_count
from olist_order_payments_dataset;

/*
Table Name: 'olist_products_dataset'
*/
------------------------------------------------------

-- table information

select
    column_name,
    data_type,
    is_nullable
from information_schema.columns
where table_name = 'olist_products_dataset'
order by ordinal_position;

------------------------------------------------------

-- table size

select COUNT(*)
from olist_products_dataset;

------------------------------------------------------

-- column inforamtion

select
	'product_id' as column_name,
	count(*) as total_count,
	count(distinct product_id) as unique_count,
	count(*)-count(product_id) as null_count,
	(
		count(product_id) - count(distinct product_id)
	) as duplicate_count
from olist_products_dataset

UNION ALL

select
	'product_category_name' as column_name,
	count(*) as total_count,
	count(distinct product_category_name) as unique_count,
	count(*)-count(product_category_name) as null_count,
	(
		count(product_category_name) - count(distinct product_category_name)
	) as duplicate_count
from olist_products_dataset

UNION ALL

select
	'product_name_lenght' as column_name,
	count(*) as total_count,
	count(distinct product_name_lenght) as unique_count,
	count(*)-count(product_name_lenght) as null_count,
	(
		count(product_name_lenght) - count(distinct product_name_lenght)
	) as duplicate_count
from olist_products_dataset

UNION ALL

select
	'product_description_lenght' as column_name,
	count(*) as total_count,
	count(distinct product_description_lenght) as unique_count,
	count(*)-count(product_description_lenght) as null_count,
	(
		count(product_description_lenght) - count(distinct product_description_lenght)
	) as duplicate_count
from olist_products_dataset

UNION ALL

select
	'product_photos_qty' as column_name,
	count(*) as total_count,
	count(distinct product_photos_qty) as unique_count,
	count(*)-count(product_photos_qty) as null_count,
	(
		count(product_photos_qty) - count(distinct product_photos_qty)
	) as duplicate_count
from olist_products_dataset

UNION ALL

select
	'product_weight_g' as column_name,
	count(*) as total_count,
	count(distinct product_weight_g) as unique_count,
	count(*)-count(product_weight_g) as null_count,
	(
		count(product_weight_g) - count(distinct product_weight_g)
	) as duplicate_count
from olist_products_dataset

UNION ALL

select
	'product_length_cm' as column_name,
	count(*) as total_count,
	count(distinct product_length_cm) as unique_count,
	count(*)-count(product_length_cm) as null_count,
	(
		count(product_length_cm) - count(distinct product_length_cm)
	) as duplicate_count
from olist_products_dataset

UNION ALL

select
	'product_height_cm' as column_name,
	count(*) as total_count,
	count(distinct product_height_cm) as unique_count,
	count(*)-count(product_height_cm) as null_count,
	(
		count(product_height_cm) - count(distinct product_height_cm)
	) as duplicate_count
from olist_products_dataset

UNION ALL

select
	'product_width_cm' as column_name,
	count(*) as total_count,
	count(distinct product_width_cm) as unique_count,
	count(*)-count(product_width_cm) as null_count,
	(
		count(product_width_cm) - count(distinct product_width_cm)
	) as duplicate_count
from olist_products_dataset;

/*
Table Name: 'olist_order_reviews_dataset'
*/
------------------------------------------------------

-- table information

select
    column_name,
    data_type,
    is_nullable
from information_schema.columns
where table_name = 'olist_order_reviews_dataset'
order by ordinal_position;

------------------------------------------------------

-- table size

select COUNT(*)
from olist_order_reviews_dataset;

------------------------------------------------------

-- column inforamtion

select
	'review_id' as column_name,
	count(*) as total_count,
	count(distinct review_id) as unique_count,
	count(*)-count(review_id) as null_count,
	(
		count(review_id) - count(distinct review_id)
	) as duplicate_count
from olist_order_reviews_dataset

UNION ALL

select
	'order_id' as column_name,
	count(*) as total_count,
	count(distinct order_id) as unique_count,
	count(*)-count(order_id) as null_count,
	(
		count(order_id) - count(distinct order_id)
	) as duplicate_count
from olist_order_reviews_dataset

UNION ALL

select
	'review_score' as column_name,
	count(*) as total_count,
	count(distinct review_score) as unique_count,
	count(*)-count(review_score) as null_count,
	(
		count(review_score) - count(distinct review_score)
	) as duplicate_count
from olist_order_reviews_dataset

UNION ALL

select
	'review_comment_title' as column_name,
	count(*) as total_count,
	count(distinct review_comment_title) as unique_count,
	count(*)-count(review_comment_title) as null_count,
	(
		count(review_comment_title) - count(distinct review_comment_title)
	) as duplicate_count
from olist_order_reviews_dataset

UNION ALL

select
	'review_comment_message' as column_name,
	count(*) as total_count,
	count(distinct review_comment_message) as unique_count,
	count(*)-count(review_comment_message) as null_count,
	(
		count(review_comment_message) - count(distinct review_comment_message)
	) as duplicate_count
from olist_order_reviews_dataset

UNION ALL

select
	'review_creation_date' as column_name,
	count(*) as total_count,
	count(distinct review_creation_date) as unique_count,
	count(*)-count(review_creation_date) as null_count,
	(
		count(review_creation_date) - count(distinct review_creation_date)
	) as duplicate_count
from olist_order_reviews_dataset

UNION ALL

select
	'review_answer_timestamp' as column_name,
	count(*) as total_count,
	count(distinct review_answer_timestamp) as unique_count,
	count(*)-count(review_answer_timestamp) as null_count,
	(
		count(review_answer_timestamp) - count(distinct review_answer_timestamp)
	) as duplicate_count
from olist_order_reviews_dataset;

/*
Table Name: 'olist_sellers_dataset'
*/
------------------------------------------------------

-- table information

select
    column_name,
    data_type,
    is_nullable
from information_schema.columns
where table_name = 'olist_sellers_dataset'
order by ordinal_position;

------------------------------------------------------

-- table size

select COUNT(*)
from olist_sellers_dataset;

------------------------------------------------------

-- column inforamtion

select
	'seller_id' as column_name,
	count(*) as total_count,
	count(distinct seller_id) as unique_count,
	count(*)-count(seller_id) as null_count,
	(
		count(seller_id) - count(distinct seller_id)
	) as duplicate_count
from olist_sellers_dataset

UNION ALL

select
	'seller_zip_code_prefix' as column_name,
	count(*) as total_count,
	count(distinct seller_zip_code_prefix) as unique_count,
	count(*)-count(seller_zip_code_prefix) as null_count,
	(
		count(seller_zip_code_prefix) - count(distinct seller_zip_code_prefix)
	) as duplicate_count
from olist_sellers_dataset

UNION ALL

select
	'seller_city' as column_name,
	count(*) as total_count,
	count(distinct seller_city) as unique_count,
	count(*)-count(seller_city) as null_count,
	(
		count(seller_city) - count(distinct seller_city)
	) as duplicate_count
from olist_sellers_dataset

UNION ALL

select
	'seller_state' as column_name,
	count(*) as total_count,
	count(distinct seller_state) as unique_count,
	count(*)-count(seller_state) as null_count,
	(
		count(seller_state) - count(distinct seller_state)
	) as duplicate_count
from olist_sellers_dataset;

/*
Table Name: 'olist_geolocation_dataset'
*/
------------------------------------------------------

-- table information

select
    column_name,
    data_type,
    is_nullable
from information_schema.columns
where table_name = 'olist_geolocation_dataset'
order by ordinal_position;

------------------------------------------------------

-- table size

select COUNT(*)
from olist_geolocation_dataset;

------------------------------------------------------

-- column inforamtion

select
	'geolocation_zip_code_prefix' as column_name,
	count(*) as total_count,
	count(distinct geolocation_zip_code_prefix) as unique_count,
	count(*)-count(geolocation_zip_code_prefix) as null_count,
	(
		count(geolocation_zip_code_prefix) - count(distinct geolocation_zip_code_prefix)
	) as duplicate_count
from olist_geolocation_dataset

UNION ALL

select
	'geolocation_lat' as column_name,
	count(*) as total_count,
	count(distinct geolocation_lat) as unique_count,
	count(*)-count(geolocation_lat) as null_count,
	(
		count(geolocation_lat) - count(distinct geolocation_lat)
	) as duplicate_count
from olist_geolocation_dataset

UNION ALL

select
	'geolocation_lng' as column_name,
	count(*) as total_count,
	count(distinct geolocation_lng) as unique_count,
	count(*)-count(geolocation_lng) as null_count,
	(
		count(geolocation_lng) - count(distinct geolocation_lng)
	) as duplicate_count
from olist_geolocation_dataset

UNION ALL

select
	'geolocation_city' as column_name,
	count(*) as total_count,
	count(distinct geolocation_city) as unique_count,
	count(*)-count(geolocation_city) as null_count,
	(
		count(geolocation_city) - count(distinct geolocation_city)
	) as duplicate_count
from olist_geolocation_dataset

UNION ALL

select
	'geolocation_state' as column_name,
	count(*) as total_count,
	count(distinct geolocation_state) as unique_count,
	count(*)-count(geolocation_state) as null_count,
	(
		count(geolocation_state) - count(distinct geolocation_state)
	) as duplicate_count
from olist_geolocation_dataset;

/*
Table Name: 'product_category_name_translation'
*/
------------------------------------------------------

-- table information

select
    column_name,
    data_type,
    is_nullable
from information_schema.columns
where table_name = 'product_category_name_translation'
order by ordinal_position;

------------------------------------------------------

-- table size

select COUNT(*)
from product_category_name_translation;

------------------------------------------------------

-- column inforamtion

select
	'product_category_name' as column_name,
	count(*) as total_count,
	count(distinct product_category_name) as unique_count,
	count(*)-count(product_category_name) as null_count,
	(
		count(product_category_name) - count(distinct product_category_name)
	) as duplicate_count
from product_category_name_translation

UNION ALL

select
	'product_category_name_english' as column_name,
	count(*) as total_count,
	count(distinct product_category_name_english) as unique_count,
	count(*)-count(product_category_name_english) as null_count,
	(
		count(product_category_name_english) - count(distinct product_category_name_english)
	) as duplicate_count
from product_category_name_translation;

------------------------------------------------------

/*
=========================================================
TABLE RELATIONSHIP VALIDATION
=========================================================

OBJECTIVE:
Validate relationships between Olist tables by checking
referential integrity, candidate key uniqueness,
relationship cardinality, and ZIP-code lookup coverage.

Note:
These queries validate relationships based on the observed
data. They do not create or confirm database constraints.
=========================================================
*/


-- =======================================================
-- 1. CUSTOMERS → ORDERS
-- =======================================================

-- OBJECTIVE:
-- Verify that every customer_id referenced in the orders
-- table exists in the customers table. Compare the total
-- number of orders with distinct customer IDs.

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customer_ids,
    COUNT(*) FILTER (
        WHERE c.customer_id IS NULL
    ) AS unmatched_customer_ids
FROM olist_orders_dataset AS o
LEFT JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id;


-- OBJECTIVE:
-- Check whether a customer_id appears more than once in
-- the orders table. This helps validate the observed
-- customer_id-to-orders cardinality.

SELECT
    customer_id,
    COUNT(*) AS order_count
FROM olist_orders_dataset
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY order_count DESC;


-- =======================================================
-- 2. ORDERS → ORDER ITEMS
-- =======================================================

-- OBJECTIVE:
-- Verify that every order_id referenced in the order items
-- table exists in the orders table. Count total item
-- records, distinct orders, and unmatched references.

SELECT
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT oi.order_id) AS unique_order_ids,
    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS unmatched_order_items
FROM olist_order_items_dataset AS oi
LEFT JOIN olist_orders_dataset AS o
    ON oi.order_id = o.order_id;


-- OBJECTIVE:
-- Check whether the combination of order_id and
-- order_item_id contains duplicate records. This helps
-- validate the combination as a candidate composite key.

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS record_count
FROM olist_order_items_dataset
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


-- OBJECTIVE:
-- Check whether the proposed composite key columns
-- (order_id and order_item_id) contain NULL values.

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_ids,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS null_item_ids
FROM olist_order_items_dataset;


-- =======================================================
-- 3. ORDERS → ORDER PAYMENTS
-- =======================================================

-- OBJECTIVE:
-- Verify that every order_id referenced in the payment
-- table exists in the orders table. Count total payment
-- records, distinct orders, and unmatched references.

SELECT
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT p.order_id) AS unique_order_ids,
    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS unmatched_payment_records
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id;


-- OBJECTIVE:
-- Check whether the combination of order_id and
-- payment_sequential contains duplicate records. This
-- helps validate the combination as a candidate composite key.

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS record_count
FROM olist_order_payments_dataset
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;


-- OBJECTIVE:
-- Identify orders associated with multiple payment records.
-- This helps establish the observed one-to-many relationship
-- between orders and payment records.

SELECT
    order_id,
    COUNT(*) AS payment_count
FROM olist_order_payments_dataset
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_count DESC;


-- =======================================================
-- 4. ORDERS → ORDER REVIEWS
-- =======================================================

-- OBJECTIVE:
-- Verify that every order_id referenced in the review
-- table exists in the orders table. Count total review
-- records, distinct orders, and unmatched references.

SELECT
    COUNT(*) AS total_review_records,
    COUNT(DISTINCT r.order_id) AS unique_order_ids,
    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS unmatched_review_records
FROM olist_order_reviews_dataset AS r
LEFT JOIN olist_orders_dataset AS o
    ON r.order_id = o.order_id;


-- OBJECTIVE:
-- Identify duplicate review_id values to determine whether
-- review_id alone can be treated as a unique candidate key.

SELECT
    review_id,
    COUNT(*) AS record_count
FROM olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


-- OBJECTIVE:
-- Identify orders associated with multiple review records.
-- This helps understand the observed cardinality between
-- orders and reviews.

SELECT
    order_id,
    COUNT(*) AS review_count
FROM olist_order_reviews_dataset
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_count DESC;


-- =======================================================
-- 5. PRODUCTS → ORDER ITEMS
-- =======================================================

-- OBJECTIVE:
-- Verify that every product_id referenced in the order
-- items table exists in the products table. Identify
-- unmatched product references.

SELECT
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT oi.product_id) AS unique_product_ids,
    COUNT(*) FILTER (
        WHERE p.product_id IS NULL
    ) AS unmatched_product_ids
FROM olist_order_items_dataset AS oi
LEFT JOIN olist_products_dataset AS p
    ON oi.product_id = p.product_id;


-- OBJECTIVE:
-- Identify products appearing in multiple order item
-- records. This helps validate the one-to-many relationship
-- between products and order items.

SELECT
    product_id,
    COUNT(*) AS order_item_count
FROM olist_order_items_dataset
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY order_item_count DESC;


-- =======================================================
-- 6. SELLERS → ORDER ITEMS
-- =======================================================

-- OBJECTIVE:
-- Verify that every seller_id referenced in the order
-- items table exists in the sellers table. Identify
-- unmatched seller references.

SELECT
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT oi.seller_id) AS unique_seller_ids,
    COUNT(*) FILTER (
        WHERE s.seller_id IS NULL
    ) AS unmatched_seller_ids
FROM olist_order_items_dataset AS oi
LEFT JOIN olist_sellers_dataset AS s
    ON oi.seller_id = s.seller_id;


-- OBJECTIVE:
-- Identify sellers associated with multiple order item
-- records. This helps validate the one-to-many relationship
-- between sellers and order items.

SELECT
    seller_id,
    COUNT(*) AS order_item_count
FROM olist_order_items_dataset
GROUP BY seller_id
HAVING COUNT(*) > 1
ORDER BY order_item_count DESC;


-- =======================================================
-- 7. CATEGORY TRANSLATION → PRODUCTS
-- =======================================================

-- OBJECTIVE:
-- Check whether product category names in the products
-- table have corresponding entries in the category
-- translation table. Separately identify NULL category
-- values and non-NULL categories without a matching
-- translation record.

SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (
        WHERE p.product_category_name IS NULL
    ) AS null_category_count,
    COUNT(*) FILTER (
        WHERE p.product_category_name IS NOT NULL
          AND ct.product_category_name IS NULL
    ) AS unmatched_category_count
FROM olist_products_dataset AS p
LEFT JOIN product_category_name_translation AS ct
    ON p.product_category_name = ct.product_category_name;


-- OBJECTIVE:
-- Check whether product_category_name contains duplicate
-- values in the category translation table. This helps
-- validate its uniqueness as a candidate key.

SELECT
    product_category_name,
    COUNT(*) AS record_count
FROM product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;


-- =======================================================
-- 8. CUSTOMERS → GEOLOCATION
-- =======================================================

-- OBJECTIVE:
-- Assess geolocation coverage by comparing distinct
-- customer ZIP code prefixes with the ZIP code prefixes
-- available in the geolocation table.

SELECT
    COUNT(DISTINCT c.customer_zip_code_prefix) AS customer_zip_prefixes,
    COUNT(DISTINCT g.geolocation_zip_code_prefix) AS matched_zip_prefixes
FROM olist_customers_dataset AS c
LEFT JOIN olist_geolocation_dataset AS g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;


-- OBJECTIVE:
-- Identify ZIP code prefixes associated with multiple
-- geolocation records. This checks whether a ZIP code
-- prefix uniquely identifies a geolocation record.

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS location_record_count
FROM olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY location_record_count DESC;


-- =======================================================
-- 9. SELLERS → GEOLOCATION
-- =======================================================

-- OBJECTIVE:
-- Assess geolocation coverage by comparing distinct
-- seller ZIP code prefixes with the ZIP code prefixes
-- available in the geolocation table.

SELECT
    COUNT(DISTINCT s.seller_zip_code_prefix) AS seller_zip_prefixes,
    COUNT(DISTINCT g.geolocation_zip_code_prefix) AS matched_zip_prefixes
FROM olist_sellers_dataset AS s
LEFT JOIN olist_geolocation_dataset AS g
    ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix;


-- OBJECTIVE:
-- Identify seller ZIP code prefixes that do not have
-- corresponding records in the geolocation table.

SELECT
    s.seller_zip_code_prefix,
    COUNT(*) AS seller_count
FROM olist_sellers_dataset AS s
LEFT JOIN olist_geolocation_dataset AS g
    ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL
GROUP BY s.seller_zip_code_prefix;


-- =======================================================
-- 10. CUSTOMER IDENTIFICATION VALIDATION
-- =======================================================

-- OBJECTIVE:
-- Identify customer_unique_id values associated with
-- multiple customer_id records. This distinguishes
-- individual customer records from unique customers
-- across the dataset.

SELECT
    customer_unique_id,
    COUNT(*) AS customer_record_count
FROM olist_customers_dataset
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY customer_record_count DESC;
