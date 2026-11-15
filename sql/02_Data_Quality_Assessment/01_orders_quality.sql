-- Table name: olist_orders_dataset

-- validate the timestamps
with timestamp_check as
(
	select
		order_id,
		order_status,
		order_purchase_timestamp,
		order_approved_at,
		order_delivered_carrier_date,
		order_delivered_customer_date,
		
		case when order_purchase_timestamp <= (order_approved_at::timestamp) then 1 else 0 end as purchase_approved,
		
		case when (order_approved_at::timestamp) < order_delivered_carrier_date then 1 else 0 end as approved_carrier,
		
		case when order_delivered_carrier_date < order_delivered_customer_date then 1 else 0 end as carrier_customer,
		
		(case when order_purchase_timestamp <= (order_approved_at::timestamp) then 1 else 0 end +
		case when (order_approved_at::timestamp) < order_delivered_carrier_date then 1 else 0 end +
		case when order_delivered_carrier_date < order_delivered_customer_date then 1 else 0 end) as correct_time_count
	from olist_orders_dataset
	where 
		order_purchase_timestamp is not null 
		and order_approved_at is not null
		and order_delivered_carrier_date is not null
		and order_delivered_customer_date is not null
)

select 
	order_id,
	order_status,
	order_delivered_carrier_date,
	order_delivered_customer_date,
	purchase_approved,
	approved_carrier,
	carrier_customer,
	correct_time_count
from timestamp_check
where correct_time_count < 3
	and carrier_customer = 0;

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

-- check if any order_id has no customer_id

select
	order_id
from olist_orders_dataset
where customer_id is null;

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

-- check if any order_id has no order_status

select
	order_id
from olist_orders_dataset
where order_status is null;

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

-- check if any order_id has no order_status

--step 1: To find the toal unique order_id in the olist_orders_dataset table

select
	count(distinct order_id) as total_unique_order_id
from olist_orders_dataset;

--step 2: To find the total unique order_id of olist_orders_dataset table that alos exists in olist_order_items_dataset table.

select
	count(distinct t1.order_id) as order_ids_in_OID
from olist_orders_dataset as t1
inner join olist_order_items_dataset as t2
	on t1.order_id = t2.order_id;

--step 3: To find the remaing order_id that is not pressent in the olist_order_items_dataset table and their order_status

select
	t1.order_status,
	count(t1.order_status) as status_count
from olist_orders_dataset as t1
left join olist_order_items_dataset as t2
	on t1.order_id = t2.order_id
where t2.order_id is null
group by
	t1.order_status;

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

--validate the payment_value of each order_id in the olist_order_payments_dataset with the price and freight_value of olist_order_items_dataset

--step 1: To find the total unique order_id present in olist_order_payments_dataset

select
	count(distinct order_id) as total_unique_order_id
from olist_order_payments_dataset;

--step 2: Check if there is a differance in the order_id count while joing the table olist_order_payments_dataset with olist_order_items_dataset

select
	count(distinct t1.order_id) as order_ids_in_OID
from olist_order_payments_dataset as t1
inner join olist_order_items_dataset as t2
	on t1.order_id = t2.order_id;

--step 3: Find the count of missing order_ids that are not present in olist_order_items_dataset

select
	count(distinct t1.order_id) as total_diff
from olist_order_payments_dataset as t1
left join olist_order_items_dataset as t2
	on t1.order_id = t2.order_id
where t2.order_id is null;

--step 4: Find the order_status of missing order_ids that are not present in olist_order_items_dataset

select
	t3.order_status,
	count(t3.order_status) as status_count
from olist_order_payments_dataset as t1
left join olist_order_items_dataset as t2
	on t1.order_id = t2.order_id
left join olist_orders_dataset as t3
	on t1.order_id = t3.order_id
where t2.order_id is null
group by
	t3.order_status;

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

--validate the payment_value of each order_id in the olist_order_payments_dataset with the price and freight_value of olist_order_items_dataset

--step 1: To find the total unique order_id present in olist_order_items_dataset

select
	count(distinct order_id) as total_unique_order_id
from olist_order_items_dataset;

--step 2: Check if there is a differance in the order_id count while joing the table olist_order_items_dataset with olist_order_payments_dataset

select
	count(distinct t1.order_id) as order_ids_in_OID
from olist_order_items_dataset as t1
inner join olist_order_payments_dataset as t2
	on t1.order_id = t2.order_id;

--step 3: Find the missing order_ids that are not present in olist_order_payments_dataset

select
	distinct t1.order_id as total_diff
from olist_order_items_dataset as t1
left join olist_order_payments_dataset as t2
	on t1.order_id = t2.order_id
where t2.order_id is null;

--step 4: Find the order details of missing order_ids that are not present in olist_order_items_dataset

select
    t1.order_id,
    t1.order_status,
    t2.product_id,
    t2.price,
    t2.freight_value
from olist_orders_dataset as t1
inner join olist_order_items_dataset as t2
    on t1.order_id = t2.order_id
left join olist_order_payments_dataset as t3
    on t1.order_id = t3.order_id
where t1.order_id = 'bfbd0f9bdef84302105ad712db648a6c'
    and t3.order_id is null;

--step 5: Check the occurance of the missing order_id in the olist_order_items_dataset table.

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price,
    freight_value
from olist_order_items_dataset
where order_id = 'bfbd0f9bdef84302105ad712db648a6c';	

--step 6: Check the occurance of the missing order_id in the olist_order_payments_dataset table as additional check.

select
    *
from olist_order_payments_dataset
where order_id = 'bfbd0f9bdef84302105ad712db648a6c';

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

--validate the payment value of olist_order_payments_dataset table is the sum of price and freight_value of olist_order_items_dataset table for all 98,665 the order_id

--step 1: Check if multiple records for same order_id is present.

select
    order_id,
    count(*) as payment_records
from olist_order_payments_dataset
group by order_id
having count(*) > 1
order by payment_records desc;

--step 2: Calculate the payment_value and price + freight_value for the 98,665 order_id.

with order_items as
(
	select 
		order_id,
		round(sum(price+freight_value)::numeric,2) as price_freight
	from olist_order_items_dataset
	group by 
		order_id
),

order_payments as
(
	select
		order_id,
		round(sum(payment_value)::numeric,2) as total_payment
	from olist_order_payments_dataset
	group by 
		order_id
),

--step 3: Check if the total_payment and price_freight are same for all order ids.

payment_price_freight_check as 
(
	select
		t1.order_id,
		t1.price_freight,
		t2.total_payment,
		case
			when t1.price_freight = t2.total_payment then 'same'
			else 'not same'
		end as equal_check
	from order_items as t1
	inner join order_payments as t2
		on t1.order_id = t2.order_id
),

--step 4: To consolidate the payment and price+freight difference.

equal_count as
(
	select 
		equal_check,
		count(equal_check) as count_equal
	from payment_price_freight_check 
	group by
		equal_check
),

--step 5: To analize the order_id with equal_check as 'not same'

not_same_records as
(
	select 
		order_id,
		price_freight,
		total_payment,
		round((total_payment-price_freight)::numeric,2) as difference_payment
	from payment_price_freight_check
	where equal_check = 'not same'
	order by 
		abs(total_payment - price_freight) desc
)

--step 6: To group the difference

select
    count(n.order_id) filter (
        where abs(n.difference_payment) <= 0.5
    ) as abs_diff_le_0_5,

    count(n.order_id) filter (
        where abs(n.difference_payment) > 0.5
    ) as abs_diff_grt_0_5,

    count(n.order_id) filter (
        where n.difference_payment < 0
    ) as price_freight_is_grt,

    count(n.order_id) filter (
        where n.difference_payment > 0
    ) as payment_value_is_grt

from not_same_records as n;

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
