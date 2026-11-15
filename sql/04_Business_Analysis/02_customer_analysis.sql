/*
=================================================
BUSINESS QUESTION:
How many unique customers have made purchases?

OBJECTIVE:
To identify the total number of unique customers recorded in the cleaned customer dataset.

METHODOLOGY:
1. Use the public.olist_customers_cleaned table.
2. Count the distinct values of customer_unique_id to determine the total number of unique customers.
=================================================
*/

select 
	count(distinct customer_unique_id) as "Total unique customers" 
from public.olist_customers_cleaned;

/*
=================================================
BUSINESS QUESTION:
How many customers make repeat purchases and what is their percentage?

OBJECTIVE:
To identify the number and percentage of unique customers who have placed more than one order, thereby measuring the repeat purchase behaviour of customers.

METHODOLOGY:

Repeat Purchase Customers:
1. Join public.olist_customers_cleaned with olist_orders_dataset using customer_id to associate customers with their orders.
2. Group the records by customer_unique_id and calculate the number of distinct orders placed by each customer.
3. Use the HAVING clause to retain customers with more than one distinct order.
4. Count the resulting customers to determine the total number of repeat purchase customers.

Repeat Purchase Percentage:
1. Identify customers who have placed more than one distinct order using the same grouping and filtering logic.
2. Count the resulting repeat purchase customers.
3. Divide the repeat purchase customer count by the total number of distinct customers in public.olist_customers_cleaned.
4. Multiply by 100 and round the result to two decimal places.

Repeat Purchase Rate =
(Customers with more than one order / Total Unique Customers) * 100
=================================================
*/

--Repeat Purchase Customers:
select 
	count(*) as "Total Repeat Customers"
from 
(
	select 
		t1.customer_unique_id, 
		count(distinct t2.order_id) as total_orders
	from public.olist_customers_cleaned as t1
	left join olist_orders_dataset as t2
		on t1.customer_id = t2.customer_id
	group by 
		t1.customer_unique_id
	having 
		count(distinct t2.order_id) > 1
) as repeat_customers;

-------------------------------------------------------

--Repeat Purchase percentage:

select
	(round(
		count(*) * 100.0
		/
		(select 
			count(distinct customer_unique_id) 
		 from public.olist_customers_cleaned
		 )
		 ,2) 
	) AS repeat_purchase_percentage
from
(
	select 
		t1.customer_unique_id
	from public.olist_customers_cleaned as t1
	left join olist_orders_dataset as t2
		on t1.customer_id = t2.customer_id
	group by 
		t1.customer_unique_id
	having 
		count(distinct t2.order_id) > 1
) as repeat_customers;

/*
=================================================
BUSINESS QUESTION:
Who are the top 10 customers by lifetime spending?

OBJECTIVE:
To identify the top 10 customers based on their cumulative spending on delivered orders, including product prices and freight charges, and examine their corresponding order counts.

METHODOLOGY:
1. Customer and Order Association:
   Join public.olist_customers_cleaned with olist_orders_dataset using customer_id to associate customers with their orders.

2. Order Item Association:
   Join the resulting records with public.olist_order_items_cleaned using order_id to retrieve product prices and freight charges associated with each order.

3. Order Filtering:
   Include only orders with order_status = 'delivered'.

4. Customer-level Aggregation:
   A. Group the records by customer_unique_id.
   B. Count distinct order IDs to calculate the number of delivered orders per customer.
   C. Calculate total spending by summing product prices and freight charges across the customer's delivered orders.

5. Ranking and Selection:
   A. Sort customers by total spending in descending order.
   B. Use FETCH FIRST 10 ROWS WITH TIES to retrieve the top 10 customers, including any additional customers tied at the tenth position.
=================================================
*/

select 
	t1.customer_unique_id, 
	count(distinct t2.order_id) as total_orders,
	round(COALESCE(sum((t3.freight_value+t3.price)),0)::NUMERIC, 2) as "Total Spent"
from public.olist_customers_cleaned as t1
left join olist_orders_dataset as t2
	on t1.customer_id = t2.customer_id
left join public.olist_order_items_cleaned as t3
	on t2.order_id = t3.order_id
where 
	t2.order_status = 'delivered'
group by 
	t1.customer_unique_id
order by 
	"Total Spent" DESC
fetch first 10 rows with ties;

/*
=================================================
BUSINESS QUESTION:
Which customer segments generate the most revenue?

OBJECTIVE:
To segment customers based on their number of delivered orders and compare the total spending and average spending per customer across each segment to identify which customer group contributes the most revenue.

METHODOLOGY:
1. Customer and Order Association:
   Join public.olist_customers_cleaned with olist_orders_dataset using customer_id.

2. Payment Association:
   Join the resulting records with public.olist_order_payments_cleaned using order_id to retrieve payment values associated with the orders.

3. Order Filtering:
   Include only orders with order_status = 'delivered'.

4. Customer-level Aggregation and Segmentation:
   A. Group the records by customer_unique_id.
   B. Count distinct order IDs to calculate the number of delivered orders per customer.
   C. Sum payment values to calculate the total spending per customer.
   D. Use a CASE expression to classify customers into three groups:
      - No Purchase: Customers with zero delivered orders.
      - One-time Customers: Customers with exactly one delivered order.
      - Repeat Customers: Customers with more than one delivered order.

5. Customer Segment Aggregation:
   A. Group customers according to their assigned customer segment.
   B. Count distinct customers in each segment.
   C. Sum customer-level order counts to calculate the total orders per segment.
   D. Sum customer-level spending to calculate total spending per segment.
   E. Calculate average spending per customer by dividing total segment spending by the number of distinct customers in that segment.

Average Spending per Customer =
Total Segment Spending / Total Customers in Segment
=================================================
*/

select 
	"Customer Group", 
	count(distinct customer_unique_id) as "Total Customers",
	sum("Total Orders") as "Orders", 
	sum("Total Spending") as "Total Spent",
	round(sum("Total Spending") / NULLIF(COUNT(DISTINCT customer_unique_id), 0),2) as "Average Spending per Customer"
from (
	select 
		t1.customer_unique_id,
		count(distinct t2.order_id) as "Total Orders",
		round(coalesce(sum(t3.payment_value),0)::numeric,2) as "Total Spending",
		case 
			when count(DISTINCT t2.order_id) = 0 THEN 'No Purchase'
			when count(DISTINCT t2.order_id) > 1 then 'Repeat Customer'
			else 'One-time Customers'
		end as "Customer Group"
		from public.olist_customers_cleaned as t1
		left join olist_orders_dataset as t2
			on t1.customer_id = t2.customer_id
		left join public.olist_order_payments_cleaned as t3
			on t2.order_id = t3.order_id
		where 
			t2.order_status = 'delivered'
		group by t1.customer_unique_id
) as "Customer Segment"
group by "Customer Group";

/*
=================================================
BUSINESS QUESTION:
What is the month-over-month customer retention rate?

OBJECTIVE:
To analyse month-over-month customer retention behaviour by identifying new, retained, and reactivated customers, calculating monthly active customer counts, 
and measuring the percentage of customers who make consecutive-month purchases.

METHODOLOGY:

1. MONTHLY CUSTOMER ACTIVITY (Monthly_Customer_Activity)
   - Join the customers and orders tables using customer_id.
   - Filter orders with 'delivered' status.
   - Identify the months in which each customer made a purchase.
   - Use customer_unique_id to identify customers consistently
     across multiple orders.
   - Group records by customer_unique_id and purchase month to
     count each customer only once per month.

2. FIRST PURCHASE IDENTIFICATION (First_Purchase_Month)
   - Identify each customer's first delivered purchase date using MIN().
   - Extract the month of the first purchase to establish
     whether the customer is new or existing.

3. CUSTOMER CLASSIFICATION (Customer_Group)
   - Compare each customer's purchase month with their
     first purchase month.
   - Classify customers as:
       A. New Customer
       B. Existing Customer

4. CUSTOMER ACTIVITY STATUS (Customer_Activity_Status)
   - Compare each customer's current-month activity with
     their activity in the immediately preceding calendar month.
   - Classify customers into three categories:
       A. New Customer:
          Customers making their first delivered purchase.
       B. Retained Customer:
          Existing customers who made purchases in both
          the current and previous calendar months.
       C. Reactivated Customer:
          Existing customers who made a purchase in the
          current month but not in the previous calendar month.

5. MONTHLY CUSTOMER SUMMARY (Monthly_Customer_Summary)
   - Group customer records by purchase month.
   - Calculate the number of new, retained, and reactivated
     customers for each month using conditional aggregation.

6. CONTINUOUS MONTHLY CALENDAR (Month_Range and Monthly_Calendar)
   - Identify the earliest and latest purchase months.
   - Generate a continuous sequence of calendar months
     using GENERATE_SERIES().
   - Include months without recorded delivered purchases.

7. COMPLETE MONTHLY CUSTOMER SUMMARY
   (Monthly_Customer_Activity_Summary)
   - LEFT JOIN the monthly customer summary with the
     continuous monthly calendar.
   - Preserve all calendar months, including months without
     customer activity.
   - Use COALESCE() to replace missing customer counts with zero.

8. STARTING AND ENDING CUSTOMER CALCULATION
   - Calculate ending customers by adding new, retained,
     and reactivated customers for each month.
   - Use LAG() to retrieve the previous month's ending
     customer count as the current month's starting
     customer count.

9. MONTH-OVER-MONTH CUSTOMER RETENTION CALCULATION
   - Calculate the monthly retention rate using the number
     of retained customers and the starting customer count.

   Formula:

       Retention Rate (%) =
       (Retained Customers / Starting Customers) * 100

   - Use NULLIF() to prevent division by zero.
   - Round retention percentages to two decimal places.

10. FINAL OUTPUT
    - Return monthly starting customers, ending customers,
      and retention rates in chronological order.

IMPORTANT INTERPRETATION NOTES:
-------------------------------------------------------
- New Customer: A customer making their first delivered purchase.
- Retained Customer: A customer who made delivered purchases
  in both the current and immediately preceding calendar month.
- Reactivated Customer: A previously acquired customer who
  returned after skipping at least one calendar month.
- Starting Customers: Customers active in the previous
  calendar month.
- Ending Customers: Total distinct active customers in
  the current calendar month.
- Retention Rate: Percentage of starting customers who
  made a purchase in the current month.

- Months without delivered purchases are included with
  zero customer counts.
- A NULL retention rate indicates that no starting
  customer base is available for the calculation.
- The first observed month has no preceding month within
  the analysis period, so its retention rate is NULL.
- Customers who skip a month and return later are classified
  as reactivated rather than retained.

OUTPUT GRANULARITY:
One row per calendar month, containing starting customers,
ending customers, and month-over-month retention rate.

=================================================
*/

with 
Monthly_Customer_Activity as 
(
	select
		date_trunc('month',t2.order_purchase_timestamp)::date as month_start,
		t1.customer_unique_id
	from public.olist_customers_cleaned as t1
	inner join olist_orders_dataset as t2
		on t1.customer_id = t2.customer_id
	where 
		t2.order_status = 'delivered'
	group by
		date_trunc('month', t2.order_purchase_timestamp),
		t1.customer_unique_id
),

First_Purchase_Month as (
	select
		t1.customer_unique_id,
		date_trunc('month',min(t2.order_purchase_timestamp))::date AS first_purchase_month
	from public.olist_customers_cleaned as t1
	inner join olist_orders_dataset as t2
		on t1.customer_id = t2.customer_id
	where 
		t2.order_status = 'delivered'
	group by
		t1.customer_unique_id
),

Customer_Group as
(
	select
		t1.month_start,
		t1.customer_unique_id,
		case
			when t1.month_start = t2.first_purchase_month then 'New Customer'
			else 'Existing Customer'
		end as customer_group
	
	from Monthly_Customer_Activity as t1
	left join First_Purchase_Month as t2
		on t1.customer_unique_id = t2.customer_unique_id
),

Customer_Activity_Status as (
	select 
		current_month.customer_unique_id,
		t3.customer_group,
		current_month.month_start as current_purchase_month,
		previous_month.month_start as previous_purchase_month,
		case
			when previous_month.customer_unique_id  is not null then 'Yes'
			else 'No'
		end as purchased_in_previous_month,
	
		case
			when t3.customer_group = 'New Customer' then 'New Customer'
			when previous_month.customer_unique_id is not null then 'Retained Customer'
			else 'Reactivated Customer'
		end as customer_activity_status
	
		
	from Monthly_Customer_Activity as current_month
	left join Monthly_Customer_Activity as previous_month
		on 
			current_month.customer_unique_id = previous_month.customer_unique_id
			and previous_month.month_start = current_month.month_start - INTERVAL '1 month'
	left join Customer_Group as t3
		on 
			current_month.customer_unique_id =  t3.customer_unique_id 
			and current_month.month_start = t3.month_start
),

Monthly_Customer_Summary as
(
	select 
		current_purchase_month as month_start,
		count(*) filter(where customer_activity_status = 'New Customer') as new_customers,
		count(*) filter(where customer_activity_status = 'Retained Customer') as retained_customers,
		count(*) filter(where customer_activity_status = 'Reactivated Customer') as reactivated_customers
		
	from Customer_Activity_Status
	group by 
		current_purchase_month
),

Month_Range as
(
	select
		min(month_start) as start_month,
		max(month_start) as end_month
	from Monthly_Customer_Activity
),

Monthly_Calendar as
(
	select
		generate_series(start_month,end_month,interval '1 month')::date as calendar_month
	from Month_Range
),

Monthly_Customer_Activity_Summary as
(
	select 
		t1.calendar_month as month_start,
		COALESCE(t2.new_customers, 0) AS new_customers,
		COALESCE(t2.retained_customers, 0) AS retained_customers,
		COALESCE(t2.reactivated_customers, 0) AS reactivated_customers
	from Monthly_Calendar as t1
	left join Monthly_Customer_Summary as t2
		on t1.calendar_month = t2.month_start
)

select 
	month_start,
	(new_customers+retained_customers+reactivated_customers) as ending_customers,
	LAG(new_customers+retained_customers+reactivated_customers) OVER (ORDER BY month_start) as starting_customers,
	round(
		(retained_customers *100.0 / nullif(LAG(new_customers+retained_customers+reactivated_customers) OVER (ORDER BY month_start),0))::numeric
	,2)	as retention_rate
from Monthly_Customer_Activity_Summary 
order by month_start;