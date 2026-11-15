-- Check whether the combination of order_id and order_item_id
-- uniquely identifies each order item.

select
    order_id,
    order_item_id,
    count(*) as record_count
from olist_order_items_dataset
group by
    order_id,
    order_item_id
having count(*) > 1
order by record_count desc;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Retrieve complete records for duplicate candidate key combinations.

select *
from olist_order_items_dataset
where (order_id, order_item_id) in (
    select
        order_id,
        order_item_id
    from olist_order_items_dataset
    group by
        order_id,
        order_item_id
    having count(*) > 1
)
order by order_id, order_item_id;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Check whether all order item records reference
-- an existing order in the orders table.

select
    oi.order_id
from olist_order_items_dataset oi
left join olist_orders_dataset o
    on oi.order_id = o.order_id
where o.order_id is null;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Check whether all product IDs in the order items table
-- exist in the products table.

select
    oi.product_id
from olist_order_items_dataset oi
left join olist_products_dataset p
    on oi.product_id = p.product_id
where p.product_id is null;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Check whether all seller IDs in the order items table
-- exist in the sellers table.

select
    oi.seller_id
from olist_order_items_dataset oi
left join olist_sellers_dataset s
    on oi.seller_id = s.seller_id
where s.seller_id is null;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Identify order items with zero or negative prices.

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price
from olist_order_items_dataset
where price <= 0
order by price;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Identify order items with zero or negative freight values.

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    freight_value
from olist_order_items_dataset
where freight_value <= 0
order by freight_value;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Identify product-seller combinations associated with zero freight values

select
    product_id,
    seller_id,
    count(*) as order_item_count,
    count(distinct order_id) as distinct_order_count,
    round(avg(price)::numeric, 2) as avg_product_price,
    min(price) as min_product_price,
    max(price) as max_product_price
from olist_order_items_dataset
where freight_value = 0
group by
    product_id,
    seller_id
order by order_item_count desc;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Check the frequency and percentage of zero-freight items for each seller

select
    seller_id,
    count(*) as total_order_items,
    count(*) filter (where freight_value = 0) as zero_freight_items,
    count(distinct order_id) as total_orders,
    count(distinct order_id) filter (where freight_value = 0) as zero_freight_orders,
    round(
        count(*) filter (where freight_value = 0) * 100.0 / count(*),
        2
    ) as zero_freight_percentage
from olist_order_items_dataset
group by seller_id
having count(*) filter (where freight_value = 0) > 0
order by zero_freight_items desc;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Check the distribution of zero-freight order items across order statuses

select
    t1.order_status,
    count(*) as total_order_items,
    count(*) filter (where t2.freight_value = 0) as zero_freight_items,
    round(
        count(*) filter (where t2.freight_value = 0) * 100.0 / count(*),
        2
    ) as zero_freight_percentage
from olist_orders_dataset as t1
join olist_order_items_dataset as t2
    on t1.order_id = t2.order_id
group by t1.order_status
order by zero_freight_items desc;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Identify order items with a shipping limit date earlier than the order purchase timestamp.

select
    oi.order_id,
    oi.order_item_id,
    oi.seller_id,
    o.order_purchase_timestamp,
    oi.shipping_limit_date
from olist_order_items_dataset as oi
join olist_orders_dataset as o
    on oi.order_id = o.order_id
where oi.shipping_limit_date < o.order_purchase_timestamp
order by o.order_purchase_timestamp;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Identify orders with missing order_item_id values in their item sequence.

select
    order_id,
    count(*) as total_items,
    min(order_item_id) as minimum_item_id,
    max(order_item_id) as maximum_item_id,
    array_agg(order_item_id order by order_item_id) as item_id_sequence
from olist_order_items_dataset
group by order_id
having
    min(order_item_id) <> 1
    or max(order_item_id) <> count(*)
order by order_id;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Identify the number of distinct sellers associated with each order.

select
    order_id,
    count(*) as total_order_items,
    count(distinct seller_id) as distinct_seller_count,
    array_agg(distinct seller_id) as seller_ids
from olist_order_items_dataset
group by order_id
order by distinct_seller_count desc, total_order_items desc;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Calculate the distribution of orders based on the number of distinct sellers.

select
    distinct_seller_count,
    count(*) as order_count,
    round(
        count(*) * 100.0 / sum(count(*)) over (),
        2
    ) as order_percentage
from (
    select
        order_id,
        count(distinct seller_id) as distinct_seller_count
    from olist_order_items_dataset
    group by order_id
) as seller_distribution
group by distinct_seller_count
order by distinct_seller_count;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Identify products appearing in multiple order-item records within the same order.

select
    order_id,
    product_id,
    count(*) as product_item_count,
    array_agg(order_item_id order by order_item_id) as order_item_ids
from olist_order_items_dataset
group by
    order_id,
    product_id
having count(*) > 1
order by product_item_count desc, order_id;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Summarize repeated product occurrences within orders.

with repeated_products as (
    select
        order_id,
        product_id,
        count(*) as product_item_count
    from olist_order_items_dataset
    group by
        order_id,
        product_id
    having count(*) > 1
)

select
    count(*) as repeated_product_combinations,
    count(distinct order_id) as orders_with_repeated_products,
    sum(product_item_count) as total_items_in_repeated_combinations,
    sum(product_item_count - 1) as additional_item_records,
    max(product_item_count) as maximum_product_item_count
from repeated_products;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Examine seller and price consistency for products appearing 20 times within an order.

select
    order_id,
    product_id,
    order_item_id,
    seller_id,
    price,
    freight_value
from olist_order_items_dataset
where (order_id, product_id) in (
    select
        order_id,
        product_id
    from olist_order_items_dataset
    group by
        order_id,
        product_id
    having count(*) = 20
)
order by
    order_id,
    product_id,
    order_item_id;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Check seller and price consistency across repeated product combinations within orders.

select
    order_id,
    product_id,
    count(*) as product_item_count,
    count(distinct seller_id) as distinct_seller_count,
    count(distinct price) as distinct_price_count,
    count(distinct freight_value) as distinct_freight_count,
    min(price) as min_price,
    max(price) as max_price,
    min(freight_value) as min_freight,
    max(freight_value) as max_freight
from olist_order_items_dataset
group by
    order_id,
    product_id
having count(*) > 1
    and (
        count(distinct seller_id) > 1
        or count(distinct price) > 1
        or count(distinct freight_value) > 1
    )
order by product_item_count desc;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

