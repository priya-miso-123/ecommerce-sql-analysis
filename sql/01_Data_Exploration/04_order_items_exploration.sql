/*
--------------------------------------------
How many order-item records are available?

How many distinct order_id, product_id, and seller_id values exist?

What is the distribution of order_item_id?

What is the minimum, maximum, and average item price?

What is the minimum, maximum, and average freight value?

Are there zero or negative item prices?

Are there zero or negative freight values?

Are there missing values in important order-item columns?

How many orders have multiple order-item records?

Are there duplicate combinations of order_id and order_item_id?
--------------------------------------------
*/

--How many order-item records are available?

select 
	count(order_item_id) as total_order_item_records
from olist_order_items_dataset;

--How many distinct order_id, product_id, and seller_id values exist?

select 
	count(distinct order_id) as total_order_id,
	count(distinct product_id) as total_product_id,
	count(distinct seller_id) as total_seller_id
from olist_order_items_dataset;

--What is the distribution of order_item_id?

select 
	distinct order_item_id,
	count(*) as item_count,
	round(
		(count(*))*100.0 / (select count(*) from olist_order_items_dataset)
	,3)
from olist_order_items_dataset
group by 
	order_item_id;

--What is the minimum, maximum, and average item price?

select 
	distinct order_item_id,
	min(price) as minimum_price,
	max(price) as maximum_price,
	avg(price) as average_price
from olist_order_items_dataset
group by 
	order_item_id;

--What is the minimum, maximum, and average freight value?

select 
	distinct order_item_id,
	min(freight_value) as minimum_freight_value,
	max(freight_value) as maximum_freight_value,
	avg(freight_value) as average_freight_value
from olist_order_items_dataset
group by 
	order_item_id;

--Are there zero or negative item prices?

select
	case
		when min(price) = 0 and min(price) < 0 then 'Zero and negative item price exists'
		when min(price) = 0 and min(price) <> 0 then 'Zero item price exists'
		when min(price) <>0 and min(price) < 0 then 'Negative item price exists'
		else 'No negative or zero item price exists'
	end
from olist_order_items_dataset;


--Are there zero or negative freight values?

select
	case
		when min(freight_value) <= 0 then 'Zero or negative item freight value exists'
		else 'No negative or zero item freight value exists'
	end
from olist_order_items_dataset;

--Are there missing values in important order-item columns?

select 
	count(*) filter(where order_id is null) as order_id_null_count,
	count(*) filter(where order_item_id is null) as order_item_id_null_count,
	count(*) filter(where product_id is null) as product_id_null_count,
	count(*) filter(where seller_id is null) as seller_id_null_count,
	count(*) filter(where price is null) as price_null_count,
	count(*) filter(where freight_value is null) as freight_value_null_count
from olist_order_items_dataset;

--How many orders have multiple order-item records?

select
	count(*) 
from(
	select 
		order_id,
		count(order_item_id) as order_item_count
	from olist_order_items_dataset
	group by order_id
	having count(order_item_id) >  1
	) as multi_order_item
;

--Are there duplicate combinations of order_id and order_item_id?

select 
	count(*) as duplicate
from(
	select
		order_id,
		order_item_id,
		count(*) as occurance
	from olist_order_items_dataset
	group by 
		order_id,
		order_item_id
	having count(*) > 1
)	
;