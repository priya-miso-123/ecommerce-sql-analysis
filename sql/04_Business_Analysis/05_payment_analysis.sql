/*
=================================================
BUSINESS QUESTION:
Which payment method is most popular?

OBJECTIVE:

To identify the most popular payment methods by comparing the number of distinct orders associated with each payment type and determining which payment method is used most frequently.

METHODOLOGY:

1. Data Source: Used the public.olist_order_payments_cleaned table containing order payment details.
2. Payment Method Grouping: Grouped payment records based on payment_type.
3. Order Counting: Counted distinct order_id values for each payment type to avoid duplicate order counting within the same payment method.
4. Ranking: Sorted payment methods in descending order based on the number of distinct orders.
5. Result Identification: Identified the most popular payment method based on the highest distinct order count.

Interpretation Note:

An order may contain multiple payment records associated with different payment methods. In such cases, the order is counted once under each payment method used.
Therefore, the sum of order counts across all payment methods may exceed the total number of distinct orders in the dataset.
=================================================
*/

select 	
	payment_type,
	count(distinct order_id) as no_of_orders
from public.olist_order_payments_cleaned
group by 
	payment_type
order by 
	no_of_orders DESC;

/*
=================================================
BUSINESS QUESTION:
What is the average payment value?

OBJECTIVE:

To calculate the average payment value per payment record by dividing the total payment value by the total number of payment records, providing an overview of the average transaction amount.

METHODOLOGY:

1. Data Source: Used the public.olist_order_payments_cleaned table containing payment records and their corresponding payment values.
2. Total Payment Calculation: Calculated the sum of all payment values using SUM(payment_value).
3. Payment Record Count: Counted the total number of payment records using COUNT(*).
4. Average Calculation: Divided the total payment value by the total number of payment records.
5. Numeric Precision: Converted payment_value to NUMERIC and rounded the final average to two decimal places.

Business Calculation Logic:
	
	Average Payment Value = Total Payment Value / Total Payment Records
	
Interpretation Note:

Each payment record is treated as an individual transaction. 
If an order contains multiple payment records, each record contributes separately to the average payment value.

=================================================
*/

select 	
	round(
	(sum(payment_value::numeric))/
	(count(*)),2
	) as Average_Payment_Value_per_Payment_Record
from public.olist_order_payments_cleaned;

/*
=================================================
BUSINESS QUESTION:
What proportion of orders use instalment payments?

OBJECTIVE:

To determine the proportion of orders that use instalment payments by identifying orders with more than one payment instalment and calculating their percentage relative to the total distinct orders in the payment dataset.

METHODOLOGY:

1. Data Source: Used the public.olist_order_payments_cleaned table containing payment details, including order IDs and the number of instalments.
2. Instalment Identification: Identified payment records with payment_installments > 1 as instalment payments.
3. Instalment Order Count: Counted distinct order_id values associated with at least one payment record having more than one instalment.
4. Total Order Count: Counted all distinct order_id values in the payment dataset.
5. Usage Percentage: Calculated the percentage of instalment orders relative to the total distinct orders.
6. Numeric Precision: Multiplied the instalment order count by 100.0 to ensure decimal division and rounded the resulting percentage to two decimal places.

Business Calculation Logic:
	
	Instalment Usage % = Distinct Orders Using Instalments / Total Distinct Orders \times 100

Important Business Rule:

If an order contains multiple payment records and at least one record has more than one instalment, the entire order is classified as an instalment order.

=================================================
*/

select 	
	count(distinct order_id) filter(where payment_installments > 1) as 	instalment_order_count,
	round((count(distinct order_id) filter(where payment_installments > 1))*100.0/
	(count(distinct order_id)),2) as instalment_usage_percentage
from public.olist_order_payments_cleaned;
