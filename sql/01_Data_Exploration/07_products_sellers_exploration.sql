/*
--------------------------------------------
Products:

1. How many product records are available?
2. How many product categories are represented?
3. How many products have missing category information?
4. How many products have missing product dimensions?
5. What are the minimum and maximum product dimensions?
6. Are there products with zero or negative dimensions?
7. What is the distribution of product weight?
8. Are there duplicate product IDs?
9. How many products are associated with each category in the product dataset?

Sellers:

10. How many seller records are available?
11. How many states and cities are represented in the seller dataset?
12. How many sellers belong to each state?
13. How many sellers share the same ZIP-code prefix?
14. Are there missing seller location fields?
15. Are there duplicate seller IDs?
--------------------------------------------
*/

-- How many product records are available?

select 
	count(*) as total_product_record
from olist_products_dataset;

-- How many product categories are represented?

select
	count(distinct product_category_name) as total_category_record
from olist_products_dataset;

-- How many products have missing category information?

select
	count(*) filter(where product_category_name is null) as procut_without_category
from olist_products_dataset;

-- How many products have missing product dimensions?

select
	count(*) as total_product_with_missing_dimention
from
(
	select
		product_id,
		(
		case when product_length_cm is null then 1 else 0 end +
		case when product_height_cm is null then 1 else 0 end +
		case when product_width_cm is null then 1 else 0 end
		) as missing_dimention_count
	from olist_products_dataset
) as product_dimensions
where missing_dimention_count > 0 ;

-- What are the minimum and maximum product dimensions?

select
	max(product_length_cm) as max_product_length_cm,
	min(product_length_cm) as min_product_length_cm,
	max(product_height_cm) as max_product_height_cm,
	min(product_height_cm) as min_product_height_cm,
	max(product_width_cm) as max_product_width_cm,
	min(product_width_cm) as min_product_width_cm
from olist_products_dataset;

-- Are there products with zero or negative dimensions?

select
	case
	when min(product_length_cm) <=0 or min(product_height_cm)<=0 or min(product_width_cm)<=0 then 'Yes, zero or negative dimensions exists'
	else 'No, zero or negative dimensions do not exists'
	end
from olist_products_dataset;

-- What is the distribution of product weight?

select
	product_weights,
	count(*) as product_count
from(
select
	product_id,
	product_weight_g,
	case
		when product_weight_g >=0 and product_weight_g <= 500 then '0–500 g'
		when product_weight_g >=501 and product_weight_g <= 1000 then '501–1,000 g'
		when product_weight_g >=1001 and product_weight_g <= 2000 then '1,001–2,000 g'
		when product_weight_g >=2001 and product_weight_g <= 5000 then '2,001–5,000 g'
		when product_weight_g >=5001 and product_weight_g <= 10000 then '5,001–10,000 g'
		when product_weight_g >=10001 and product_weight_g <= 20000 then '10,001–20,000 g'
		when product_weight_g >=20001 and product_weight_g <= 40000 then '20,001–40,000 g'
		when product_weight_g >=40001 then 'above 40,000 g'
		when product_weight_g is null then 'Missing weight'
		when product_weight_g < 0 then 'Negative weight'
	end as product_weights
from olist_products_dataset
) as product_weight_data
group by 
	product_weights
order by
    case product_weights
        when '0–500 g' then 1
        when '501–1,000 g' then 2
        when '1,001–2,000 g' then 3
        when '2,001–5,000 g' then 4
        when '5,001–10,000 g' then 5
        when '10,001–20,000 g' then 6
        when '20,001–40,000 g' then 7
        when 'above 40,000 g' then 8
		when 'Missing weight' then 9
		when 'Negative weight' then 10
    end;

-- Are there duplicate product IDs?

select
	case
	when (count(product_id) - count(distinct product_id)) > 0 then 'Yes, duplicate product_ids exists'
	else 'No, duplicate product_ids do not exist'
	end as duplicate_product_id_check
from olist_products_dataset
where product_id is not null;

--How many products are associated with each category in the product dataset?

select 
	distinct product_category_name,
	count(distinct product_id) as product_count
from olist_products_dataset
group by 
	product_category_name
order by
	product_count DESC;

--------------------------------------------------------------------------------------------------------------------

--How many seller records are available?

select
	count(*) as total_seller_record
from olist_sellers_dataset;

--How many states and cities are represented in the seller dataset?

select
	count(distinct seller_city) as toal_cities,
	count(distinct seller_state) as toal_states
from olist_sellers_dataset;

--How many sellers belong to each state?

select
	distinct seller_state,
	count(distinct seller_id) as seller_count
from olist_sellers_dataset
group by 
	seller_state
order by
	seller_count DESC;

--How many sellers share the same ZIP-code prefix?

select
	distinct seller_zip_code_prefix,
	count(distinct seller_id) as seller_count
from olist_sellers_dataset
group by
	seller_zip_code_prefix
having 
	count(distinct seller_id) > 1
order by
	seller_count DESC;

--Are there missing seller location fields?

select
	count(*) as total_missing_field_sellers
from
(
	select
		seller_id,
		(case when seller_zip_code_prefix is null then 1 else 0 end + 
		case when seller_state is null then 1 else 0 end + 
		case when seller_city is null then 1 else 0 end) as missing_location_field_count
	from olist_sellers_dataset
) as seller_locations
where missing_location_field_count > 0;
		

--Are there duplicate seller IDs?

select
	case
	when (count(seller_id) - count(distinct seller_id)) > 0 then 'Yes, duplicate seller_id exists'
	else 'No, duplicate seller_id do not exist'
	end as duplicate_seller_id_check
from olist_sellers_dataset
where seller_id is not null;