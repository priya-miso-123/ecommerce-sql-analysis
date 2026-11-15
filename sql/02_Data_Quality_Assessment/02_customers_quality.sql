--Total unique customers in the record

select 
	count(distinct customer_unique_id) as Total_unique_customers
from olist_customers_dataset;

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--Customer with different address

with location_count as
(
select
	distinct customer_unique_id,
	count(distinct customer_zip_code_prefix) as zip_count,
	count(distinct customer_city) as city_count,
	count(distinct customer_state) as state_count
from olist_customers_dataset
group by 
	customer_unique_id
)

select 
	customer_unique_id
from location_count
where zip_count > 1 or city_count > 1 or state_count > 1;

-------------------------------------------------------------------------
-------------------------------------------------------------------------

-- Identify customers with different recorded locations within 60 minutes of each other

-- Retrieve order status and recorded customer location for orders
-- belonging to the same customer within 60 minutes

with location_variations as
(
    -- Step 1: Identify customers associated with multiple locations

    select
        customer_unique_id
    from olist_customers_dataset
    group by
        customer_unique_id
    having
        count(distinct customer_zip_code_prefix) > 1
        or count(distinct customer_city) > 1
        or count(distinct customer_state) > 1
),

order_location_details as
(
    -- Step 2: Retrieve customer location and corresponding order details

    select
        c.customer_unique_id,
        c.customer_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp
    from olist_customers_dataset c

    inner join location_variations v
        on c.customer_unique_id = v.customer_unique_id

    inner join olist_orders_dataset o
        on c.customer_id = o.customer_id
)

-- Step 3: Compare pairs of orders belonging to the same customer

select
    a.customer_unique_id,

    a.customer_id as customer_id_1,
    a.customer_zip_code_prefix as zip_code_1,
    a.customer_city as city_1,
    a.customer_state as state_1,
    a.order_id as order_id_1,
    a.order_status as order_status_1,
    a.order_purchase_timestamp as purchase_timestamp_1,

    b.customer_id as customer_id_2,
    b.customer_zip_code_prefix as zip_code_2,
    b.customer_city as city_2,
    b.customer_state as state_2,
    b.order_id as order_id_2,
    b.order_status as order_status_2,
    b.order_purchase_timestamp as purchase_timestamp_2,

    round(
        abs(extract(epoch from (
            b.order_purchase_timestamp - a.order_purchase_timestamp
        )) / 60)::numeric,
        2
    ) as time_difference_minutes

from order_location_details a

inner join order_location_details b
    on a.customer_unique_id = b.customer_unique_id
    and a.customer_id < b.customer_id

where
    (
        a.customer_zip_code_prefix is distinct from b.customer_zip_code_prefix
        or a.customer_city is distinct from b.customer_city
        or a.customer_state is distinct from b.customer_state
    )
    and abs(extract(epoch from (
        b.order_purchase_timestamp - a.order_purchase_timestamp
    ))) <= 3600

order by
    a.customer_unique_id,
    time_difference_minutes;
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
