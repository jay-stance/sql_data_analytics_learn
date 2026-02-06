/*
  DIMENTIONS AND MEASURES

  is it Numeric?
  NO: it is a dimension
  YES: 
    Does it make sense to aggregate it?
    YES: it is a measure
    NO: it is a dimension

  - why do we need dimensions and measures?
  we need dimensions for grouping the data (S axios in a chart), and we need measure for answering how much, quantifying data, to what measure is this dimension (Y axis
  
  
  STEPS TAKEN IN DOING ANALYTICS FOR DATASETS
  
  - data exploratio: just to know what we have here, the number of tables, columns present etc)
  - Dimensions exploration: helps us identify unique values in each dimension, recognizing how data might be grouped or segmented, which is useful for later analysis. juse use DISTINCT COLUMN NAME
      - date explorations
        - identify the earliest adn latest boundaries
        - understand the scope of data and the timespan using MIN/MAX[DATE]

  
  - MEASURESX EXPLORATION
      calculate key metrics of the business, the bi numbers. hihgest level of aggregation, lowest level of details

  - MAGNITUDE ANALYSIS
      compare the measure values by categories, it helps us understand the importance of different caegories
      [MEASURE] BY [DIMENSION] - we need the diension in order to split the measure
      eg: total sales by country 

  - RANKING ANALYSIS
      order the value of dimensions by measure to identify top or bottom performers 
      Rank [DIMENSION] by [MEASURE] eg rank countries by total sales, top products by category, bottoom three customers by total orders
*/

-- Create the database if it does not exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'DataWarehouseAnalytics')
BEGIN
    CREATE DATABASE DataWarehouseAnalytics;
END

USE DataWarehouseAnalytics;

-- Explore all objects in the database
SELECT * FROM INFORMATION_SCHEMA.TABLES

-- Explore all columns in the database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_NAME = 'dim_customers'

-- 2. DIMENSIONS EXPLORATION
SELECT DISTINCT country FROM gold.dim_customers

-- 3. DATE EXPLORATION: identify the earliest adn latest boundaries
SELECT * FROM gold.fact_sales
SELECT 
  MIN(order_date) first_order,
  MAX(order_date) last_order,
  DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) order_range_yars
FROM gold.fact_sales

-- find the youngest and oldest customers 
SELECT
  MIN(birthdate) youngest_customer,
  MAX(birthdate) oldest_customer,
  DATEDIFF(YEAR, MIN(birthdate), GETDATE()) youngest_customer_age,
  DATEDIFF(YEAR, MAX(birthdate), GETDATE()) oldest_customer_age
FROM gold.dim_customers

/*
  MEASURES

  - find the total sales
  - fiind how many items are sold
  - find the aerage selling price
  - find the total number of orders
  - find the total number of products
  - find the total number of customers
  - find the total number of customers that have placed an order
*/

SELECT * FROM gold.fact_sales ORDER BY order_number

-- TOTAL SALES
SELECT SUM(sales_amount) total_sales FROM gold.fact_sales

-- how many items are sold 
SELECT SUM(quantity) total_number_of_items FROM gold.fact_sales

-- average selling price
SELECT AVG(price) avg_selling_price FROM gold.fact_sales

-- total number of orders
    SELECT * FROM gold.fact_sales ORDER BY order_number
    SELECT order_number, COUNT(*) FROM gold.fact_sales GROUP BY order_number HAVING COUNT(*) > 1 -- checking if there are orders spaning across more than one row, and yes there is
    SELECT order_number, COUNT(*) FROM gold.fact_sales GROUP BY order_number HAVING COUNT(*) > 1 -- checking if there are orders spaning across more than one row, and yes there is

SELECT 
  COUNT(DISTINCT order_number) total_orders
FROM gold.fact_sales

-- find the total number of products
SELECT product_name -- no repetition of product_key, product_id, product_number, product_name: so that means all rows are unique
-- , product_id, product_number, product_name
FROM gold.dim_products
GROUP BY product_name
HAVING COUNT(*) > 1

SELECT COUNT(product_key) total_no_of_products FROM gold.dim_products

-- find total number of customers
SELECT * FROM gold.dim_customers

  -- check for duplicates in customer key, id and number
  SELECT 
    customer_number
  FROM gold.dim_customers
  GROUP BY customer_number -- no duplicates found for all entries
  HAVING COUNT(*) > 1

SELECT COUNT(customer_key) total_customers FROM gold.dim_customers

-- find total number of customers that have placed an order
    SELECT TOP 10 * FROM gold.dim_customers
    SELECT TOP 10 * FROM gold.fact_sales


-- always try to get all the data you need from one or least table, only join when that is the way around it. like here, I could easily just count customer key from the sales table but i went to start using join statement
SELECT 
  COUNT(DISTINCT c.customer_key)
FROM gold.dim_customers c
LEFT JOIN gold.fact_sales f
  ON c.customer_key = f.customer_key

SELECT COUNT(DISTINCT customer_key) FROM gold.fact_sales

/*
  GENERATE A REPORT THAT SOWS ALL THESE KEY METRICS

  I would first get all the single aggregateeable ones from the tables
*/

WITH 
  CTE_products AS (
    SELECT COUNT(product_key) total_products FROM gold.dim_products
  )
SELECT 
  SUM(sales_amount) total_sales,
  SUM(quantity) total_number_of_items,
  AVG(price) avg_selling_price,
  COUNT(DISTINCT order_number) total_orders,
  MAX(p.total_products) AS total_products,
  COUNT(DISTINCT customer_key) customers_with_orders,
  (SELECT COUNT(customer_key) FROM gold.dim_customers) total_customers
FROM gold.fact_sales, CTE_products p

-- Another method, here we use only 2 columns, nto rows this tiem around: value: column name
SELECT 'Total Sales' AS "Measure Name", SUM(sales_amount) AS 'Measure Value' FROM gold.fact_sales
UNION ALL 
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales -- we must add the column headers again as they are gotten from the first table as per union all
UNION ALL 
SELECT 'Average Selling Price', AVG(price) FROM gold.fact_sales
UNION ALL 
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL 
SELECT 'Total Products', COUNT(product_key) FROM gold.dim_products
UNION ALL 
SELECT 'Total Customers With Orders', COUNT(DISTINCT customer_key) FROM gold.fact_sales
UNION ALL 
SELECT 'Total Customers', COUNT(customer_key) FROM gold.dim_customers


-- MAGNOTUDE ANALYSYS

-- find the total number of customers by countries
SELECT 
  country,
  COUNT(DISTINCT customer_key) total_customers 
FROM gold.dim_customers
GROUP BY ((country))

-- find total customers by genders
SELECT gender, COUNT(DISTINCT customer_key) FROM gold.dim_customers GROUP BY gender

-- find total products by category
SELECT category_id, category, COUNT(DISTINCT product_key) FROM gold.dim_products
GROUP BY category_id, category

-- what is the average costs in each category
SELECT category_id, category, AVG(cost) average_cost FROM gold.dim_products 
GROUP BY category_id, category

-- toal revenue generatd for each category
SELECT 
  dp.category_id, dp.category, SUM(fs.sales_amount) revenue_per_category
FROM gold.fact_sales fs 
LEFT JOIN gold.dim_products dp
  ON fs.product_key = dp.product_key
GROUP BY dp.category_id, dp.category
ORDER BY category_id, category

-- find total revenue generated by each customer
SELECT customer_key, SUM(sales_amount) FROM gold.fact_sales
GROUP BY customer_key
ORDER BY SUM(sales_amount) DESC

-- what is the distribution of sold items across countries
SELECT 
  dc.country country,
  SUM(fs.sales_amount) total_sales
FROM gold.fact_sales fs 
LEFT JOIN gold.dim_customers dc 
  ON fs.customer_key = dc.customer_key
GROUP BY dc.country

-- RANK ANALYSIS

SELECT TOP 10 * FROM gold.fact_sales
SELECT TOP 10 * FROM gold.dim_customers
SELECT TOP 10 * FROM gold.dim_products


-- which 5 products generate the highest revenue
SELECT product_key, total_sales, rank FROM (
  SELECT -- TOP 5
    product_key,
    SUM(sales_amount) total_sales,
    ROW_NUMBER() OVER(ORDER BY SUM(sales_amount) DESC) rank 
  FROM gold.fact_sales
  GROUP BY product_key
  -- ORDER BY SUM(sales_amount) DESC
) t 
WHERE rank < 6

-- 5 worst performing is just the inverse