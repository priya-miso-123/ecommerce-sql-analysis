# E-Commerce SQL Analysis | Brazilian E-Commerce Public Dataset

## Project Overview

This project analyses the Brazilian E-Commerce Public Dataset by Olist using PostgreSQL. It covers data exploration, data quality assessment, data cleaning, and business analysis across sales, customers, products, sellers, delivery operations, and payments.

The work is organised as a reproducible SQL portfolio project. Each business-analysis script contains the business question, objective, methodology, and query logic. Supporting documents record data-cleaning decisions, data-quality findings, metric definitions, and analytical observations.

## Project Objectives

- Examine the structure and quality of the source e-commerce datasets.
- Investigate data-quality issues and document cleaning decisions.
- Prepare cleaned tables for downstream analysis.
- Translate business questions into SQL queries and measurable metrics.
- Interpret results while considering table grain, metric definitions, and dataset limitations.

## Dataset

**Dataset:** Brazilian E-Commerce Public Dataset by Olist  
**Source:** [Kaggle – Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
**Period covered:** 2016–2018

The source dataset contains nine CSV files covering customers, geolocation, orders, order items, payments, reviews, products, sellers, and product-category translations.

> The raw CSV files are not required to be committed to this repository. Download the dataset from the source above and place the CSV files in the local `data/` folder before importing them into PostgreSQL. Check the dataset's licence and attribution requirements when redistributing the source files.

## Tools and Technologies

- **PostgreSQL** – relational database, data preparation, and SQL analysis.
- **pgAdmin 4** – database management and query execution.
- **SQL** – joins, aggregations, CTEs, subqueries, conditional aggregation, date/time functions, window functions, NULL handling, and statistical functions.
- **Python (pandas and SQLAlchemy)** – used by the included CSV import utility to load source files into PostgreSQL.

## AI-Assisted Learning and Development

ChatGPT (OpenAI) was used as a supplementary learning and problem-solving tool throughout this project.

It supported the development process through:
- Understanding SQL concepts and exploring alternative query approaches.
- Troubleshooting SQL errors and reviewing query logic.
- Refining business questions, objectives, and analytical methodologies.
- Understanding metric definitions and interpreting query results.
- Reviewing documentation and identifying analytical limitations.

ChatGPT served as a learning assistant throughout the project. SQL queries, data investigations, validation decisions, and analytical interpretations were reviewed and understood as part of my learning and development process.

## Repository Structure

```text
ecommerce-sql-analysis/
│
├── data/                              # Local source CSV files (not committed)
│
├── documentation/
│   ├── 01_ER_Diagram/
│   │   ├── olist_er_diagram.mmd
│   │   └── olist_er_diagram.png
│   ├── data_cleaning.docx
│   ├── data_dictionary.docx
│   └── data_quality_validation.docx
│
├── findings/
│   ├── 01_sales_analysis.docx
│   ├── 02_customer_analysis.docx
│   ├── 03_product_seller_analysis.docx
│   ├── 04_delivery_analysis.docx
│   └── 05_payment_analysis.docx
│
├── sql/
│   ├── 01_Data_Exploration/
│   ├── 02_Data_Quality_Assessment/
│   ├── 03_Data_Cleaning/
│   └── 04_Business_Analysis/
│
├── import_os.py
└── README.md
```

## Project Workflow

### 1. Data Exploration

Explored the source tables to understand their structure, columns, record counts, relationships, and levels of detail.

### 2. Data Quality Assessment

Investigated data-quality conditions across the orders, customers, order items, and payment datasets. The checks include missing values, duplicate or repeated records, key relationships, and order/timestamp consistency.

### 3. Data Cleaning

Created and documented cleaned versions for the following eight datasets:

- Customers
- Orders
- Order items
- Payments
- Reviews
- Products
- Sellers
- Product-category translation

Cleaning decisions were documented rather than automatically replacing every missing or unusual value. NULL values that were consistent with the order lifecycle were retained where appropriate.

### 4. Business Analysis

The business-analysis SQL scripts cover 21 questions across five areas.

#### Sales Analysis

- What is the monthly and yearly revenue?
- Which product categories have the highest total order value, including freight charges?
- What are the top 10 best-selling products?
- What is the average order value (AOV)?
- Which months have the highest order volume?

#### Customer Analysis

- How many unique customers have made purchases?
- How many customers make repeat purchases and what is their percentage?
- Who are the top 10 customers by lifetime spending?
- Which customer segments generate the most revenue?
- What is the month-over-month customer retention rate?

#### Product and Seller Analysis

- Which sellers generate the highest total item sales value?
- Which product categories generate the highest average sales value per order?
- Which sellers have the highest cancellation rates?
- Which products receive the lowest ratings?

#### Delivery Analysis

- What is the average order-to-delivery time?
- How many orders are delivered late?
- Which customer states have a high proportion of orders with longer-than-average delivery times?
- Is there an association between delivery delays and customer ratings?

#### Payment Analysis

- Which payment method is most popular?
- What is the average payment value?
- What proportion of orders use instalment payments?

## Selected Findings

The following are examples of findings documented in the project:

- **Customer behaviour:** 96,096 unique purchasing customers were identified. The repeat-purchase analysis identified 2,997 repeat customers, representing approximately 3.12% of the unique customer base.
- **Customer segments:** Repeat customers had higher average spending per customer than one-time customers in the delivered-order segment analysis.
- **Delivery performance:** The average order-to-delivery time was 12.56 days across 96,470 delivered orders. Of these, 7,826 orders (8.11%) were delivered after the estimated delivery date.
- **Delivery and ratings:** The analysis found a negative association between delivery delays and customer ratings. Correlation indicates association, not causation.
- **Payments:** Approximately 51.46% of orders in the payment dataset used instalment payments.
- **Seller performance:** Among sellers with at least 50 orders, the highest cancellation rate in the returned top-five results was 5.66%.

See the `findings/` folder for the supporting tables, observations, and metric definitions.

## Analytical Considerations and Limitations

- **Table grain:** The project distinguishes order-level, order-item-level, payment-record-level, and customer-level metrics. This matters when joining tables and aggregating values.
- **Revenue definitions:** Product sales value, freight charges, product sales including freight, and customer payment value are treated as distinct measures where applicable.
- **Customer identity:** `customer_unique_id` is used for unique-customer and repeat-purchase analysis because a customer may be associated with more than one `customer_id`.
- **Review attribution:** Reviews are associated with `order_id`, not directly with `product_id`. When an order contains multiple products, the same order review can be associated with each product in the analysis. Product-rating results should therefore be interpreted as products associated with negatively reviewed orders, not direct product-specific ratings.
- **Delivery analysis:** Order-to-delivery time measures the elapsed time from purchase to customer delivery; it is not carrier transit time alone.
- **Incomplete calendar years:** The dataset covers partial years at the beginning and end of the period. Year-over-year comparisons should account for unequal coverage.
- **Correlation:** The relationship between delivery delay and review score is observational and does not establish causation.

## How to Run the Project

1. Install PostgreSQL and pgAdmin 4.
2. Create a PostgreSQL database for the project.
3. Download the Olist dataset from the Kaggle source and place the CSV files in the local `data/` folder.
4. Import the source CSV files into PostgreSQL. The included `import_os.py` utility can be used after configuring its local folder path and database connection securely.
5. Run the SQL scripts in the following order:
   1. `sql/01_Data_Exploration/`
   2. `sql/02_Data_Quality_Assessment/`
   3. `sql/03_Data_Cleaning/`
   4. `sql/04_Business_Analysis/`
6. Review the supporting documentation and findings in the `documentation/` and `findings/` folders.

**Important:** Update the import utility's local path and database connection settings for your environment. Do not store database passwords in a public repository; use environment variables or another local secret-management method.

## Project Documentation

- `documentation/data_dictionary.docx` – table and column reference.
- `documentation/data_quality_validation.docx` – data-quality checks and validation results.
- `documentation/data_cleaning.docx` – cleaning investigations, decisions, and outcomes.
- `documentation/01_ER_Diagram/` – entity-relationship diagram source and image.
- `findings/` – five analysis documents containing query outputs, observations, and metric definitions.

## Future Enhancements

- Build an interactive dashboard to communicate the SQL findings.
- Extend the analysis with additional business metrics.
- Explore predictive modelling opportunities using the prepared data.

## Author

**Padma Priya**  
SQL Data Analysis Portfolio Project  
