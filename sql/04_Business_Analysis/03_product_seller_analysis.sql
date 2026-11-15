/*
=================================================
BUSINESS QUESTION:
Which sellers generate the highest total item sales value?

OBJECTIVE:
Identify the sellers who generate the highest sale value.

METHODOLOGY:
1. Used the order items table as the main table.

2. Grouped the records by seller_id.

3. Added the product prices to calculate the
   total sales value for each seller.

4. Sorted the sellers by total sales value
   in descending order.

5. Selected the top 1 sellers.

NOTE:
Used the price column from the order items table
instead of payment_value to avoid duplicating
order payments when an order contains multiple items. 
=================================================
*/

SELECT
    seller_id,
    ROUND(SUM(price::numeric), 2) AS total_sales_value
FROM public.olist_order_items_cleaned
GROUP BY seller_id
ORDER BY total_sales_value DESC
FETCH FIRST 1 ROWS WITH TIES;

/*
=================================================
BUSINESS QUESTION:
Which product categories generate the highest average sales value per order?

OBJECTIVE:
Identify product categories that generate the highest average sales value per order.

METHODOLOGY:

1. Used the products table as the main table.

2. Joined the order items table using `product_id` to retrieve sales details, including only products with sales.

3. Joined the category translation table using `product_category_name` to retrieve English product category names.

4. Used `COALESCE()` to display the English category name when available; otherwise, used the original category name.

5. Grouped the records by product category.

6. Counted the product IDs to calculate the total units sold in each category.

7. Counted distinct order IDs to calculate the number of orders containing each category.

8. Summed the product prices to calculate the total sales value for each category.

9. Divided the total category sales value by the number of distinct orders to calculate the average category sales value per order.

10. Sorted the categories by average category sales value in descending order.
=================================================
*/

select 
	COALESCE(
    t3.product_category_name_english,
    t1.product_category_name
	) AS product_category,
	count(t2.product_id) as units_sold,
	count(distinct t2.order_id) as total_orders,
	round(sum(t2.price::numeric),2) as category_sales_value,
	round((sum(t2.price::numeric))/(count(distinct t2.order_id)),2) as avg_category_sales_per_order
from public.olist_products_cleaned as t1
inner join public.olist_order_items_cleaned as t2
	on t1.product_id = t2.product_id
left join public.product_category_name_translation_cleaned as t3
	on t1.product_category_name = t3.product_category_name
group by 
	COALESCE(
    t3.product_category_name_english,
    t1.product_category_name
	)
order by 
	avg_category_sales_per_order DESC
fetch first 5 rows with ties;

/*
=================================================
BUSINESS QUESTION:
Which sellers have the highest cancellation rates?

OBJECTIVE:
To identify sellers with the highest order cancellation rates by comparing the proportion of canceled orders against their total orders.

METHODOLOGY:
1. Join the cleaned order items table with the orders dataset using order_id to associate sellers with their corresponding order statuses.
2. Group the records by seller_id.
3. Calculate the total number of distinct orders associated with each seller.
4. Count the distinct orders with a canceled status for each seller.
5. Calculate the seller cancellation rate by dividing the number of canceled orders by the total number of orders and multiplying by 100.
6. Consider only sellers with at least 50 orders to reduce the influence of sellers with very low order volumes.
7. Exclude sellers with a 0% cancellation rate.
8. Sort sellers by cancellation rate in descending order and retrieve the top five sellers, including ties.

Metric definitions:

Metric							Meaning
Total Orders					Total number of distinct orders associated with each seller.
Total Orders Canceled			Number of distinct orders associated with each seller that have a canceled status.
Seller Cancellation Rate (%)	Percentage of a seller's total orders that were canceled.

Business calculation:

Cancellation Rate = Total Orders Canceled / Total Orders \times 100

Business Rules:
	Only sellers with at least 50 orders are considered.
	Sellers with a 0% cancellation rate are excluded.
	The top five sellers are selected based on cancellation rate, with ties included.

=================================================
*/

with cancellation_rating as 
(
	select 
		t1.seller_id,
		count(distinct t1.order_id) as total_orders,
		count(distinct t1.order_id) 
			filter(where t2.order_status = 'canceled') as total_orders_canceled,
		round(
				((count(distinct t1.order_id) filter(where t2.order_status = 'canceled'))*100.0)/
				(count(distinct t1.order_id)),
				2
		) as cancellation_rate
	from public.olist_order_items_cleaned as t1
	left join olist_orders_dataset as t2
		on t1.order_id = t2.order_id
	group by t1.seller_id
)
select 
	seller_id,
	total_orders,
	total_orders_canceled,
	cancellation_rate
from cancellation_rating
where 
	total_orders >= 50
  and cancellation_rate > 0
order by cancellation_rate DESC
fetch first 5 rows with ties;

/*
=================================================
BUSINESS QUESTION:
Which products receive the lowest ratings?

OBJECTIVE:
To identify products with a high proportion of low customer ratings
by evaluating the percentage of reviews with scores of 1 or 2.

METHODOLOGY:
1. Join the cleaned order reviews table with the cleaned order items
   table using order_id to associate customer reviews with products.
2. Group the records by product_id.
3. Count the total number of non-null reviews associated with each product.
4. Count reviews with scores of 1 or 2 as low-rated reviews.
5. Calculate the low-rating percentage by dividing the number of
   low-rated reviews by the total number of rated reviews and
   multiplying by 100.
6. Consider only products with at least 15 reviews.
7. Retain products with a low-rating percentage greater than 70%.

RANKING:
Sort eligible products by low-rating percentage in descending order
to identify products associated with the highest proportion of
negative customer feedback.

BUSINESS RULES:
1. Review scores of 1 or 2 are classified as low ratings.
2. Only products with at least 15 reviews are considered.
3. Products must have a low-rating percentage greater than 70%
   to be included.

NOTE:
The Olist dataset associates customer reviews with order_id rather
than product_id. When an order contains multiple products, the same
review score is associated with each product in that order.

Therefore, this analysis identifies products associated with
negatively reviewed orders rather than products receiving direct
product-specific ratings. The review score may reflect the overall
order experience and may not indicate dissatisfaction with every
product in the order.

=================================================
*/

with product_review as(
select 
	t2.product_id,
	count(t1.review_score) as total_reviews,
	count(*) filter(where t1.review_score in (1,2)) as low_rating_value,
	round(
		(count(*) filter(where t1.review_score in (1,2)))*100.0 / nullif(count(t1.review_score),0)
		,2
	) as low_rating_percentage
from public.olist_order_reviews_cleaned as t1
inner join public.olist_order_items_cleaned as t2
	on t1.order_id = t2.order_id
group by 
	t2.product_id
	)
select
	product_id,
	total_reviews,
	low_rating_value,
	low_rating_percentage
from product_review
where
	low_rating_percentage > 70.00
	and total_reviews >= 15
order by 
	low_rating_percentage DESC;