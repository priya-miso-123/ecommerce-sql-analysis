/*
--------------------------------------------
What payment types are available?

What are the distinct installment counts?

How many payment records are available?

How many distinct orders have payment records?

Are there missing values in payment columns?

Are there zero or negative payment values?

What is the minimum and maximum payment value?

Are there orders with multiple payment records?

Are there duplicate combinations of order_id and payment_sequential?

Are there unusual payment-sequential values?
--------------------------------------------
*/

--What payment types are available?

select 
	distinct payment_type
from olist_order_payments_dataset;

--What are the distinct installment counts?

select
	distinct payment_installments
from olist_order_payments_dataset
order by 
	payment_installments;

--How many payment records are available?

select
	count(*) filter(where payment_value is not null) as total_payment_record
from olist_order_payments_dataset;

--How many distinct orders have payment records?

select
	count(*) as orders_with_payment_record
from(
	select 
		distinct order_id,
		count(payment_value) filter(where payment_value is not null) as payment_record
	from olist_order_payments_dataset
	group by
		order_id
	having 
		count(payment_value) > 0
	);

--Are there missing values in payment columns?

select
	count(*) filter(where payment_value is null) as missing_payment_value
from olist_order_payments_dataset;
	
--Are there zero or negative payment values?

select
	case 
		when min(payment_value) <=0 then 'zero or negative payment values exists'
		else 'no zero or negative payment values exists'
	end as payment_value_issue
from olist_order_payments_dataset;

--What is the minimum and maximum payment value?

select
	min(payment_value) as min_payment_value,
	max(payment_value) as max_payment_value
from olist_order_payments_dataset;

--Are there orders with multiple payment records?

select
	count(*)
from(
select
	order_id,
	count(*) filter(where payment_value is not null) as payment_count
from olist_order_payments_dataset
group by
	order_id
having 
	count(*) filter(where payment_value is not null) > 1);

--Are there duplicate combinations of order_id and payment_sequential?

select
	order_id,
	payment_sequential,
	count(*) as group_count
from olist_order_payments_dataset
group by 
	order_id,
	payment_sequential
having count(*) > 1;

--Are there unusual payment-sequential values?

select
	distinct payment_sequential
from olist_order_payments_dataset
order by payment_sequential;