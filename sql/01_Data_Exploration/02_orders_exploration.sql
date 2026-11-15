/*
--------------------------------------------
What are the available order statuses?
How many orders belong to each order status?
What are the earliest and latest purchase timestamps?
How many orders have missing approval timestamps?
How many orders have missing carrier timestamps?
How many orders have missing customer delivery timestamps?
How many orders have inconsistent timestamps, such as approval occurring before purchase?
What is the distribution of orders across weekdays?
What is the distribution of orders across hours of the day?
How many orders have multiple missing lifecycle timestamps?
--------------------------------------------
*/

--What are the available order statuses?

select
	order_status
from olist_orders_dataset
group by order_status;

--How many orders belong to each order status?

select
	order_status,
	count(*) as order_count
from olist_orders_dataset
group by order_status;

--What are the earliest and latest purchase timestamps?

select
	min(order_purchase_timestamp) as earliest_purchase_timestamp,
	max(order_purchase_timestamp) as latest_purchase_timestamp
from olist_orders_dataset;

--How many orders have missing approval timestamps?

select
	count(*) as missing_approval_timestamps
from olist_orders_dataset
where order_approved_at is null;

--How many orders have missing carrier timestamps?

select
	count(*) as missing_carrier_timestamps
from olist_orders_dataset
where order_delivered_carrier_date is null;

--How many orders have missing customer delivery timestamps?

select
	count(*) as missing_customer_timestamps
from olist_orders_dataset
where order_delivered_customer_date is null;

--How many orders have inconsistent timestamps, such as approval occurring before purchase?

select
	count(*) filter (where order_approved_at::timestamp < order_purchase_timestamp) as inconsistent_timestamps
from olist_orders_dataset
where 
	order_purchase_timestamp is not null 
	and order_approved_at is not null;

--What is the distribution of orders across weekdays?

select
	count(*) as total_orderd,
	count(*) filter(where to_char(order_purchase_timestamp,'D') in ('2','3','4','5','6')) as weekday_orders,
	count(*) filter(where to_char(order_purchase_timestamp,'D') in ('1','7')) as weekend_orders
from olist_orders_dataset
where 
	order_purchase_timestamp is not null;

--What is the distribution of orders across hours of the day?

select
	to_char(order_purchase_timestamp,'HH24') as hours,
	count(to_char(order_purchase_timestamp,'HH24')) as hourly_orders,
	 ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM olist_orders_dataset
         WHERE order_purchase_timestamp IS NOT NULL),
        2
    ) AS order_percentage
from olist_orders_dataset
where 
	order_purchase_timestamp is not null
group by 
	to_char(order_purchase_timestamp,'HH24')
order by
	hours;

--How many orders have multiple missing lifecycle timestamps?

with missing_timestamps as(
select
	order_id,
	(case when order_purchase_timestamp is null then 1 else 0 end +
	case when order_approved_at is null then 1 else 0 end +
	case when order_delivered_carrier_date is null then 1 else 0 end +
	case when order_delivered_customer_date is null then 1 else 0 end) as missing_timestamp
from olist_orders_dataset
where order_status is distinct from 'cancelled'
)
select
	count(*) as count_
from missing_timestamps
where missing_timestamp > 1;