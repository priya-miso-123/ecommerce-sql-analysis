/*
--------------------------------------------
How many customer records are available?
How many customer records exist in each state?
What is the distribution of customer ZIP-code prefixes?
Which states have the highest number of customer records?
How many customer records share the same customer_unique_id?
What is the maximum number of customer records associated with one customer_unique_id?
Are there any missing customer location fields?
Are there customer records with identical location details?
How many distinct cities are represented?

Note: Customer identity and purchase behaviour are different topics. We can inspect the identity structure here without calculating repeat purchases or retention.
--------------------------------------------
*/

--How many customer records are available?

select 
	count(*) as customer_count
from olist_customers_dataset;

--How many customer records exist in each state?

select 
	customer_state,
	count(*) as customer_record
from olist_customers_dataset
group by 
	customer_state;

--What is the distribution of customer ZIP-code prefixes?

select 
	customer_zip_code_prefix,
	count(*) as customer_count,
	round(
		count(*) *100.0 /(select count(*) from olist_customers_dataset)
	,3) as zip_code_distribution
from olist_customers_dataset
group by 
	customer_zip_code_prefix
order by 
	customer_count DESC;

--Which states have the highest number of customer records?

select 
	customer_state,
	count(*) as customer_record
from olist_customers_dataset
group by 
	customer_state
order by
	customer_record DESC
limit 1;

--How many customer records share the same customer_unique_id?

select 
	count(*) as SUCIR
from
(
	select 
		customer_id,
		customer_unique_id,
		count (*) over (
			partition by customer_unique_id
		) as customer_records
	from olist_customers_dataset
) as customer_count

where customer_records > 1;

--What is the maximum number of customer records associated with one customer_unique_id?

select 
	max(customer_records) as max_CRACUI
from
(
	select 
		customer_id,
		customer_unique_id,
		count (*) over (
			partition by customer_unique_id
		) as customer_records
	from olist_customers_dataset
) as customer_count;

--Are there any missing customer location fields?

select
	count(*) as customer_with_missing_location_field
from(
select 
	customer_id,
	((case when customer_state is null then 1 else 0 end)+
	(case when customer_city is null then 1 else 0 end)+
	(case when customer_zip_code_prefix is null then 1 else 0 end)) as missing_location_field
from olist_customers_dataset)

where missing_location_field > 0;

--Are there customer records with identical location details?

select
sum(customer_count)
from(
	select
		customer_city,
		customer_state,
		customer_zip_code_prefix,
		count(*) as customer_count
	from olist_customers_dataset
	group by
		customer_city,
		customer_state,
		customer_zip_code_prefix
	having count(*) > 1
	) as same_location_customers;

--How many distinct cities are represented?

select
	count(distinct customer_city) as city_count
from olist_customers_dataset;