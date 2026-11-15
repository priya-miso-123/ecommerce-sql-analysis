/*
=================================================
BUSINESS QUESTION:
Average Order-to-Delivery Time (Days)

OBJECTIVE:
To calculate the average time taken to deliver orders from the purchase timestamp to the actual customer delivery timestamp, expressed in days and hours

METHODOLOGY:

1. Data Filtering: Selected only successfully delivered orders using order_status = 'delivered' and excluded records with NULL actual delivery timestamps.

2. Delivery Duration Calculation: Calculated the time difference between order_purchase_timestamp and order_delivered_customer_date to determine the delivery duration for each order.

3. Time Conversion: Converted the delivery duration into seconds using EXTRACT(EPOCH FROM ...).

4. Average Delivery Days: Calculated the average delivery duration in seconds and divided it by 86,400 to obtain the average delivery time in days.

5. Average Delivery Hours: Converted the average delivery duration into hours by dividing the average seconds by 3,600.

6. Total Delivered Orders: Used COUNT(*) to count the total number of records in the filtered dataset, where each record represents one delivered order.

BUSINESS LOGIC:

Average Delivery Time = sum(Delivery Duration) / Total Delivered orders

where,
	Delivery Duration = Actual Delivery Date - Order Purchase Date

=================================================
*/

with order_time as(
select 
	order_id,
	order_purchase_timestamp,
	order_delivered_customer_date,
	extract(epoch from (
			order_delivered_customer_date - order_purchase_timestamp
			)) as delivery_seconds
from olist_orders_dataset
where 
	order_status = 'delivered' and 
	order_delivered_customer_date is not null and
	order_purchase_timestamp is not null	
)
select 
	count(*) as total_delivered_orders,
	round(avg(delivery_seconds)/86400,2) as average_delivery_days,
	round(avg(delivery_seconds)/3600,2) as average_delivery_hours
from order_time;

/*
=================================================
BUSINESS QUESTION:
How many orders are delivered late?

OBJECTIVE:

To identify the total numbers of orders that are delivered after the estimated delivery time.

METHODOLOGY:

1. Data Filtering: Selected only successfully delivered orders using order_status = 'delivered'.

2. NULL Handling: Excluded records with NULL order_estimated_delivery_date to ensure that delivery delays are calculated only for orders with an available estimated delivery date.

3. Total Delivered Orders: Used COUNT(*) to calculate the total number of delivered orders with a valid estimated delivery date.

4. Delayed Delivery Identification: Used the FILTER clause with a conditional check to identify orders where order_delivered_customer_date is later than order_estimated_delivery_date.

5. Total Delayed Orders: Counted the orders satisfying the delayed delivery condition using COUNT(*) FILTER.

Business Calculation Logic:

Metric					Calculation:
Total Orders		 -	Count of all delivered orders with a valid estimated delivery date
Total Delayed Orders -	Count of delivered orders where actual delivery date is later than estimated delivery date

Business Rule:

An order is classified as delayed when:

	Actual Delivery Date > Estimated Delivery Date

Note: An order delivered exactly on its estimated delivery date is considered on time, not delayed.
=================================================
*/

select
	count(*) as total_orders,
	count(*) filter (where order_delivered_customer_date > order_estimated_delivery_date) as total_delayed_orders
from olist_orders_dataset
where 
	order_status = 'delivered' and
	order_estimated_delivery_date is not null and
	order_delivered_customer_date is not null;

/*
=================================================
BUSINESS QUESTION:
Which customer states have a high proportion of orders with longer-than-average delivery times?

OBJECTIVE:
Identify customer states with higher-than-average delivery times by comparing their average delivery hours and the proportion of orders exceeding the overall average delivery time.

METHODOLOGY:

1. Calculate the Overall Average Delivery Time:
	Calculate the average time between order purchase and actual customer delivery, in hours, across all successfully delivered orders with valid timestamps.

2. Group Delivered Orders by Customer State:
	Join the orders dataset with the customers dataset using customer_id and group the results by customer_state.

3. Calculate State-Level Delivery Metrics:
	For each state, calculate:
	- Total number of distinct delivered orders.
	- Average delivery time in hours.

4. Identify Slower-than-Average Orders:
	Count the distinct delivered orders in each state whose delivery time exceeds the overall average delivery time.

5. Calculate the Percentage of Slower-than-Average Orders:
	Divide the number of orders exceeding the overall average by the total delivered orders in that state and multiply by 100.

6. Apply Minimum Order-Volume Criteria:
	Consider only states with at least 50 delivered orders to exclude states with relatively small order volumes from the analysis.

7. Identify States with a High Proportion of Slower-than-Average Orders:
	Retain states that satisfy both conditions:
	- Their regional average delivery time is higher than the overall average delivery time.
	- More than 70% of their delivered orders exceed the overall average delivery time.

8. Rank the Results:
	Sort the qualifying states by regional average delivery time in descending order to identify states with the longest average delivery times.


BUSINESS CALCULATION LOGIC:

Metric							Calculation

Overall Average Delivery Time	Total delivery hours across all delivered orders / Total delivered orders
State Average Delivery Time		Total delivery hours for a state / Total delivered orders in that state
Orders Above Average			Count of orders where delivery hours exceed overall average delivery hours
Percentage Above Average		(Orders Above Average / Total Delivered Orders in the State) × 100


BUSINESS RULES:

Condition 1: Average delivery time

A customer state must have an average delivery time greater than the overall average delivery time.

State Average Delivery Hours > Overall Average Delivery Hours

Condition 2: Percentage of orders exceeding the overall average

More than 70% of delivered orders in that state must take longer than the overall average delivery time.

		(Orders Above Overall Average / Total Delivered Orders in State) * 100 > 70%

Condition 3: Minimum order volume

A customer state must have at least 50 orders to qualify for the analysis.

		Total Delivered Orders >= 50

A customer state is classified as having a higher-than-average delivery-time pattern only when all three conditions are satisfied.

=================================================
*/

with order_time as(
select 
	order_id,
	order_purchase_timestamp,
	order_delivered_customer_date,
	extract(epoch from (
			order_delivered_customer_date - order_purchase_timestamp
			)) as delivery_seconds
from olist_orders_dataset
where 
	order_status = 'delivered' and 
	order_delivered_customer_date is not null and
	order_purchase_timestamp is not null
),
avg_hours as(select 
	avg(delivery_seconds)/3600 as average_delivery_hours
from order_time),

regional_avg_hours as (

select
	t1.customer_state as state,
	
	count(distinct t2.order_id) as total_delivered_orders,
	
	avg(extract(epoch from (
            t2.order_delivered_customer_date -
            t2.order_purchase_timestamp
        )) / 3600) as regional_average_delivery_hours,
		
	count(distinct t2.order_id) filter(
		where extract(epoch from (
			t2.order_delivered_customer_date - t2.order_purchase_timestamp
			))/3600 > (select average_delivery_hours from avg_hours)
	) as orders_above_average_hours
	
from olist_customers_dataset as t1
left join olist_orders_dataset as t2
	on t1.customer_id = t2.customer_id and
	t2.order_status = 'delivered' and
	t2.order_delivered_customer_date is not null and
	t2.order_purchase_timestamp is not null
group by 
	t1.customer_state
)
select 
	state,
	total_delivered_orders,
	round(regional_average_delivery_hours,2) as regional_average_delivery_hours,
	orders_above_average_hours,
	round(orders_above_average_hours * 100.00
		/nullif(total_delivered_orders,0),2) as percentage_above_average
from regional_avg_hours
where
	total_delivered_orders >= 50 and
	regional_average_delivery_hours  > (select average_delivery_hours from avg_hours) and
	orders_above_average_hours * 100.00 / nullif(total_delivered_orders,0) > 70
order by regional_average_delivery_hours DESC;

/*
=================================================
BUSINESS QUESTION:
Is there an association between delivery delays and customer ratings?

OBJECTIVE:

To determine whether delivery delays are associated with customer ratings by measuring the correlation between delivery delay (in days) and average customer review scores.

Additionally, compare customer rating patterns across different delivery-delay severity categories to identify whether longer delivery delays are associated with lower average ratings and a higher proportion of low-rated orders.

METHODOLOGY:

1. Review Aggregation: Aggregated customer review records at the order level by calculating the average review score for each order. Excluded records with NULL review scores.

2. Data Integration: Joined the aggregated review data with the orders dataset using order_id to combine customer ratings with delivery information.

3. Data Filtering: Included only delivered orders with valid actual and estimated delivery timestamps and matching non-NULL review scores.

4. Delivery Delay Calculation: Calculated delivery delay in days by subtracting the estimated delivery timestamp from the actual delivery timestamp.

	--Positive values indicate delayed deliveries.
	--Negative values indicate early deliveries.
	--Zero indicates delivery on the estimated date.

5. Correlation Analysis: Used Pearson's correlation coefficient (CORR) to measure the direction and strength of the linear association between delivery delay (in days) and average customer review scores.

6. Delivery Severity Categorization: Classified orders into four categories based on delivery delay:
	--On-time or early
	--1–3 days late
	--4–7 days late
	--More than 7 days late
Used the CEIL() function to assign partial-day delays to the corresponding full-day severity range.

7. Customer Rating Analysis: Calculated the following metrics for each delivery category:

	--Total number of orders
	--Average customer review rating (Where multiple review records exist for an order, their scores are averaged to produce one order-level rating, ensuring that each order contributes equally to the analysis.)
	--Number of low-rated orders (average review score ≤ 2)
	--Percentage of low-rated orders

8. Comparative Analysis: Compared average customer ratings and low-rating percentages across delivery categories to identify patterns between delivery-delay severity and customer satisfaction.

Business Calculation Logic:

Metric							Business calculation
Delivery Delay (Days)			Delivery Delay (Days) = (Actual Delivery Timestamp − Estimated Delivery Timestamp) / 86,400 (The timestamps' difference is converted from seconds into days.)
Average Review Rating			Sum of review scores for an order / Number of valid review scores for that order
Correlation Coefficient			Pearson correlation between order-level average review ratings and delivery delay in days
Delivery Delay Category			Categorize orders based on delivery delay using the defined severity ranges
Total Orders					Count of orders in each delivery-delay category
Average Customer Rating			Sum of order-level average review ratings / Total orders in the category
Low-Rated Orders				Count of orders where average review score ≤ 2
Low-Rating Percentage			(Low-Rated Orders / Total Orders) × 100

Business Rules:

1. Orders with positive delay values are classified as late deliveries.
2. Orders with zero or negative delay values are classified as on-time or early deliveries.
3. Partial-day delays are assigned to the corresponding full-day category using CEIL().
4. An order is classified as low-rated when its average review score is less than or equal to 2.

Delivery Delay Categorization:

Condition								Category
Delay ≤ 0								On-time/early
CEIL(delay_days) BETWEEN 1 AND 3		1–3 days late
CEIL(delay_days) BETWEEN 4 AND 7		4–7 days late
CEIL(delay_days) > 7					More than 7 days late

Interpretation note:

The correlation coefficient measures the direction and strength of the linear association between delivery delays and customer ratings. 
A negative value indicates that longer delays tend to be associated with lower ratings. It does not establish causation.
=================================================
*/

WITH order_reviews AS (
	select 
	order_id,
	avg(review_score::numeric) as review_score_avg
from public.olist_order_reviews_cleaned
where review_score is not null
group by order_id
),

delivery_reviews as (
select 
	t1.order_id,
	t1.review_score_avg,
	extract(epoch from (
			t2.order_delivered_customer_date - t2.order_estimated_delivery_date
			))/86400.0 as delay_days
from order_reviews as t1
inner join olist_orders_dataset as t2
	on t1.order_id = t2.order_id
where 
	t2.order_status = 'delivered' and
	t2.order_delivered_customer_date is not null and
	t2.order_estimated_delivery_date is not null
),

delivery_rating_correlation as(
select 
	CORR(review_score_avg, delay_days) as correlation_coefficient
from delivery_reviews
),

categorized_orders as(
select 
	order_id,
	review_score_avg,
	delay_days,
	case
		when delay_days <= 0 then 'On-time/early'
		when CEIL(delay_days) <= 3 then '1–3 days late'
		when CEIL(delay_days) <= 7 then '4–7 days late'
		else 'More than 7 days late'
	end as delay_category
from delivery_reviews
),

delivery_rating_summary as(
select 
	delay_category,
	count(*) as total_orders,
	round(avg(review_score_avg),2) as average_review_rating,
	count(*) filter(where review_score_avg <= 2) as low_rated_orders,
	round(count(*) filter(where review_score_avg <= 2)*100.0 / count(*),2) as low_rating_percentage
from categorized_orders
group by 
	delay_category
)
select * 
from delivery_rating_summary as t1
cross join delivery_rating_correlation as t2
order by 
	CASE
        WHEN delay_category = 'On-time/early' THEN 1
        WHEN delay_category = '1–3 days late' THEN 2
        WHEN delay_category = '4–7 days late' THEN 3
        WHEN delay_category = 'More than 7 days late' THEN 4
    END ASC;


